--- Common reusable specifications for CLI validation.
-- These are intended for use as post-parse validation specs.
-- @module toasted_cli.specification.common

local core = require('toasted_cli.specification')
local Specification = core.Specification

--- Specification: Option is required.
-- Fails if the specified option is not present in the context.
-- @table requiredOptionSpec
local requiredOptionSpec = Specification:new{
    code = "REQUIRED_OPTION",
    message = "Option is required",
    field = nil,
    severity = "error",
    isSatisfiedBy = function(self, context)
        return context:hasOption(self.field)
    end
}

--- Specification: Argument is required.
-- Fails if the specified argument is not present in the context.
-- @table requiredArgumentSpec
local requiredArgumentSpec = Specification:new{
    code = "REQUIRED_ARGUMENT",
    message = "Argument is required",
    field = nil,
    severity = "error",
    isSatisfiedBy = function(self, context)
        return context:hasArgument(self.field)
    end
}

--- Specification: Value must be of correct type.
-- Fails if the value for the given field is not of the specified type.
-- @table valueTypeSpec
local valueTypeSpec = Specification:new{
    code = "VALUE_TYPE",
    message = "Value must be of correct type",
    field = nil,
    type = nil,
    severity = "error",
    isSatisfiedBy = function(self, context)
        local val = context:getOption(self.field) or context:getArgument(self.field)
        if self.type == "number" then
            return tonumber(val) ~= nil
        elseif self.type == "string" then
            return type(val) == "string"
        end
        return true
    end
}

--- Specification: Option specified multiple times.
-- Fails if the option was specified more than once.
-- @table optionMultipleSpec
local optionMultipleSpec = Specification:new{
    code = "OPTION_MULTIPLE",
    message = "Option specified multiple times; using last value.",
    field = nil,
    severity = "warning",
    isSatisfiedBy = function(self, context)
        local count = context.getOptionCount and context:getOptionCount(self.field) or 1
        return count <= 1
    end
}

return {
    requiredOptionSpec = requiredOptionSpec,
    requiredArgumentSpec = requiredArgumentSpec,
    valueTypeSpec = valueTypeSpec,
    optionMultipleSpec = optionMultipleSpec
}
