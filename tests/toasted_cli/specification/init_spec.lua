local core = require("toasted_cli.specification")
local Specification = core.Specification

describe("Specification mechanics", function()
    it("returns true when satisfied", function()
        local AlwaysPass = setmetatable({
            code = "ALWAYS_PASS",
            message = "Always passes",
            isSatisfiedBy = function(self, context)
                return true
            end
        }, {
            __index = Specification
        })

        assert.is_true(AlwaysPass:isSatisfiedBy({}))
    end)

    it("returns false and detail when unsatisfied", function()
        local AlwaysFail = setmetatable({
            code = "ALWAYS_FAIL",
            message = "Always fails",
            isSatisfiedBy = function(self, context)
                return false, {
                    reason = "nope"
                }
            end
        }, {
            __index = Specification
        })

        local ok, detail = AlwaysFail:isSatisfiedBy({})
        assert.is_false(ok)
        assert.are.same({
            reason = "nope"
        }, detail)
    end)

    it("withDetail attaches extra fields and context", function()
        local Spec = setmetatable({
            code = "X"
        }, {
            __index = Specification
        })
        local context = {
            foo = 1
        }
        local copy = Spec:withDetail({
            bar = 2
        }, context)
        assert.are.equal("X", copy.code)
        assert.are.equal(2, copy.bar)
        assert.are.equal(context, copy.context)
    end)

    it("getUnsatisfiedSpecs returns all unsatisfied specs with context", function()
        local context = {
            foo = 42
        }
        local Pass = setmetatable({
            code = "PASS",
            isSatisfiedBy = function()
                return true
            end
        }, {
            __index = Specification
        })
        local Fail = setmetatable({
            code = "FAIL",
            isSatisfiedBy = function(self, ctx)
                return false, {
                    ctxval = ctx.foo
                }
            end
        }, {
            __index = Specification
        })
        local failures = Specification.getUnsatisfiedSpecs({Pass, Fail}, context)
        assert.are.equal(1, #failures)
        assert.are.equal("FAIL", failures[1].code)
        assert.are.equal(42, failures[1].ctxval)
        assert.are.equal(context, failures[1].context)
    end)
end)
