--- Specification system for CLI argument and option validation.
-- Provides the base Specification class and combinators for complex validation logic.
--
-- Specification fields:
--   code         (string)   Unique code for this specification
--   message      (string)   Human-readable message
--   severity     (string)   "error", "warning", etc.
--   isSatisfiedBy(function) Validation function (context) -> boolean, [detail]
--   context      (table)    (optional) The CLI context for which this specification was checked
-- @module toasted_cli.specification

--- The Specification class.
-- Used to define validation logic for CLI arguments, options, and commands.
-- @type Specification
-- @field code string Unique code for this specification
-- @field message string Human-readable message
-- @field severity string "error", "warning", etc.
-- @field isSatisfiedBy function Validation function (context) -> boolean, [detail]
-- @field context table (optional) The CLI context for which this specification was checked
local Specification = {}
Specification.__index = Specification

--- Create a new Specification.
-- @tparam table def Table of fields to initialize the specification. Must include code, message, severity, isSatisfiedBy.
-- @treturn Specification The new specification.
function Specification:new(def)
    assert(def.code, "Specification must have a 'code' field")
    assert(def.message, "Specification must have a 'message' field")
    assert(def.severity, "Specification must have a 'severity' field")
    assert(def.isSatisfiedBy, "Specification must have an 'isSatisfiedBy' function")
    setmetatable(def, self)
    return def
end

--- Returns a string description of the specification.
-- @treturn string Human-readable description of this specification.
function Specification:describe()
    return string.format("[%s] %s: %s", self.severity, self.code, self.message)
end

--- Check if the specification is satisfied by the given context.
-- Override this in custom specs.
-- @tparam table context The CLI context.
-- @treturn boolean ok True if satisfied, false otherwise.
-- @treturn[opt] table detail Additional failure detail if not satisfied.
function Specification:isSatisfiedBy(context) -- luacheck: ignore self context
    return true
end

--- Return a copy of this Specification with extra detail/context attached.
-- @tparam[opt] table extra Extra fields to attach to the returned specification.
-- @tparam[opt] table context The CLI context to attach.
-- @treturn Specification A new specification table with merged fields.
function Specification:withDetail(extra, context)
    local newSpec = {}
    for k, v in pairs(self) do
        newSpec[k] = v
    end
    for k, v in pairs(extra or {}) do
        newSpec[k] = v
    end
    if context then
        newSpec.context = context
    end
    setmetatable(newSpec, getmetatable(self))
    return newSpec
end

--- Get all unsatisfied specs from a list, with context attached.
-- @tparam {Specification,...} specs List of specs to check.
-- @tparam table context The CLI context.
-- @treturn {Specification,...} List of unsatisfied specs (with detail/context).
function Specification.getUnsatisfiedSpecs(specs, context)
    local failures = {}
    for _, spec in ipairs(specs) do
        local ok, detail = spec:isSatisfiedBy(context)
        if not ok then
            table.insert(failures, spec:withDetail(detail, context))
        end
    end
    return failures
end

--- Logical AND combinator for specs.
-- Returns a specification that passes only if all sub-specs pass.
-- @tparam {Specification,...} specs List of specs.
-- @treturn Specification The AND-combined specification.
local function andSpec(specs)
    return Specification:new{
        code = "AND",
        message = "All conditions must be met",
        severity = "error",
        specs = specs,
        isSatisfiedBy = function(self, context)
            for _, spec in ipairs(self.specs) do
                local ok, detail = spec:isSatisfiedBy(context)
                if not ok then
                    return false, {
                        failed = spec,
                        detail = detail
                    }
                end
            end
            return true
        end
    }
end

--- Logical OR combinator for specs.
-- Returns a specification that passes if at least one sub-specification passes.
-- @tparam {Specification,...} specs List of specs.
-- @treturn Specification The OR-combined specification.
local function orSpec(specs)
    return Specification:new{
        code = "OR",
        message = "At least one condition must be met",
        severity = "error",
        specs = specs,
        isSatisfiedBy = function(self, context)
            local failures = {}
            for _, spec in ipairs(self.specs) do
                local ok, detail = spec:isSatisfiedBy(context)
                if ok then
                    return true
                else
                    table.insert(failures, {
                        failed = spec,
                        detail = detail
                    })
                end
            end
            return false, failures
        end
    }
end

--- Logical NOT combinator for a specification.
-- Returns a specification that passes only if the sub-specification fails.
-- @tparam Specification specification The specification to negate.
-- @treturn Specification The NOT-combined specification.
local function notSpec(spec)
    return Specification:new{
        code = "NOT",
        message = "Condition must not be met",
        severity = "error",
        spec = spec,
        isSatisfiedBy = function(self, context)
            local ok, detail = self.spec:isSatisfiedBy(context)
            return not ok, ok and nil or detail
        end
    }
end

--- Operator overload: `a + b` is equivalent to `andSpec {a, b}`.
-- This is analogous to logical AND and is inspired by the use of `+` for intersection in probability theory.
-- @tparam Specification a
-- @tparam Specification b
-- @treturn Specification AND-combined specification.
function Specification.__add(a, b)
    return andSpec {a, b}
end

--- Operator overload: `a * b` is equivalent to `orSpec {a, b}`.
-- This is analogous to logical OR and is inspired by the use of `*` for union in probability theory.
-- @tparam Specification a
-- @tparam Specification b
-- @treturn Specification OR-combined specification.
function Specification.__mul(a, b)
    return orSpec {a, b}
end

--- Operator overload: `-a` is equivalent to `notSpec(a)`.
-- This is analogous to logical NOT and is inspired by the use of unary minus for complement in probability theory.
-- @tparam Specification a
-- @treturn Specification NOT-combined specification.
function Specification.__unm(a)
    return notSpec(a)
end

return {
    Specification = Specification,
    andSpec = andSpec,
    orSpec = orSpec,
    notSpec = notSpec
}
