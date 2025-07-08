--- Internal marker specifications for protocol and parsing errors in the CLI.
-- These are not true validation specs and must never be used for post-parse validation.
-- Attempting to call `isSatisfiedBy` on these marker specs will raise an error.
-- @module toasted_cli.specification.internal

local core = require('toasted_cli.specification')
local Specification = core.Specification

--- Throws an error if called, marking this as an internal marker specification.
-- @tparam table self The specification object.
-- @tparam table context The CLI context.
-- @raise Always throws an error to indicate misuse.
local function markerIsSatisfiedBy(self, context) -- luacheck: ignore self context
    error("Internal marker spec: isSatisfiedBy must never be called on protocol error specifications.", 2)
end

--- Marker spec for unknown option errors.
-- Used internally during parsing.
-- @table unknownOptionSpec
local unknownOptionSpec = Specification:new{
    code = "OPTION_UNKNOWN",
    message = "Unknown option: {field}",
    severity = "error",
    isSatisfiedBy = markerIsSatisfiedBy
}

--- Marker spec for missing option value errors.
-- Used internally during parsing.
-- @table missingOptionValueSpec
local missingOptionValueSpec = Specification:new{
    code = "OPTION_VALUE_MISSING",
    message = "Option {field} expects a value",
    severity = "error",
    isSatisfiedBy = markerIsSatisfiedBy
}

--- Marker spec for missing argument errors.
-- Used internally during parsing.
-- @table missingArgumentSpec
local missingArgumentSpec = Specification:new{
    code = "ARGUMENT_MISSING",
    message = "Missing required argument: {field}",
    severity = "error",
    isSatisfiedBy = markerIsSatisfiedBy
}

--- Marker spec for extra argument errors.
-- Used internally during parsing.
-- @table extraArgumentSpec
local extraArgumentSpec = Specification:new{
    code = "ARGUMENT_EXTRA",
    message = "Unexpected extra argument: {field}",
    severity = "error",
    isSatisfiedBy = markerIsSatisfiedBy
}

--- Marker spec for unknown subcommand errors.
-- Used internally during parsing.
-- @table unknownSubcommandSpec
local unknownSubcommandSpec = Specification:new{
    code = "UNKNOWN_SUBCOMMAND",
    message = "Unknown subcommand: {field}",
    severity = "error",
    isSatisfiedBy = markerIsSatisfiedBy
}

return {
    unknownOptionSpec = unknownOptionSpec,
    missingOptionValueSpec = missingOptionValueSpec,
    missingArgumentSpec = missingArgumentSpec,
    extraArgumentSpec = extraArgumentSpec,
    unknownSubcommandSpec = unknownSubcommandSpec
}
