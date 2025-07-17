--- Command-line interface (CLI) command definition and parser.
-- Supports subcommands, arguments, options, actions, and specification-based validation.
-- @module toasted_cli.command

local Command = {}
Command.__index = Command

local Context = require("toasted_cli.context")
local specs = require("toasted_cli.specification")
local cli_parse_specs = require("toasted_cli.internal.cli_parse_specs")
local cli_specs = require("toasted_cli.cli_specs")

--- Create a new Command object.
-- @tparam[opt] table opts Table of command options (e.g., name, description, pattern, matchFunc).
-- @treturn Command The new command object.
function Command:new(opts)
    opts = opts or {}
    local instance = setmetatable({}, self)
    instance.name = opts.name or "cli"
    instance.description = opts.description or ""
    instance.pattern = opts.pattern
    instance.matchFunc = opts.matchFunc
    instance.subcommands = {}
    instance.arguments = {}
    instance.options = {}
    instance.actionFunc = nil
    instance.specs = {}
    return instance
end

--- Add a subcommand to this command.
-- @tparam string name The subcommand name.
-- @tparam string description The subcommand description.
-- @tparam[opt] table opts Table of subcommand options (pattern, matchFunc).
-- @treturn Command The new subcommand object.
function Command:subcommand(name, description, opts)
    local cmd = Command:new({
        name = name,
        description = description,
        pattern = opts and opts.pattern,
        matchFunc = opts and opts.matchFunc
    })
    table.insert(self.subcommands, cmd)
    return cmd
end

--- Add a positional argument to this command.
-- @tparam string name The argument name.
-- @tparam string desc The argument description.
-- @tparam[opt] table opts Table of argument options (specs, etc.).
-- @treturn Command self (for chaining).
function Command:argument(name, desc, opts)
    opts = opts or {}
    local arg = {
        name = name,
        description = desc,
        opts = opts,
        specs = opts.specs or {}
    }
    table.insert(self.arguments, arg)
    return self
end

--- Add an option (flag or option with value) to this command.
-- @tparam string flags Space-separated option flags (e.g., "--foo -f").
-- @tparam string desc The option description.
-- @tparam[opt] table opts Table of option options (argument, default, specs).
-- @treturn Command self (for chaining).
function Command:option(flags, desc, opts)
    opts = opts or {}
    local option = {
        flags = flags,
        description = desc,
        argument = opts.argument,
        default = opts.default,
        names = {},
        specs = opts.specs or {}
    }
    for flag in string.gmatch(flags, "%-%-?[%w%-]+") do
        table.insert(option.names, flag)
    end
    table.insert(self.options, option)
    return self
end

--- Set the action function for this command.
-- The function will be called with the parsed arguments/options table.
-- @tparam function fn The function to call when this command is executed.
-- @treturn Command self (for chaining).
function Command:action(fn)
    self.actionFunc = fn
    return self
end

--- Parse command-line arguments for this command.
-- Returns the result of the action function (if run), the parsed arguments/options table,
-- a list of warnings, and a list of validation failures.
-- @tparam {string,...} args The argument list.
-- @tparam[opt] number argIdx The starting index in args (default 1).
-- @tparam[opt] table parsed The parsed result table (for recursion).
-- @tparam[opt] table warnings The warnings table (for recursion).
-- @treturn any actionResult The result of the action function, or nil if errors.
-- @treturn table parsed The parsed arguments/options table.
-- @treturn table warnings List of warnings.
-- @treturn table failures List of failures (errors).
function Command:parse(args, argIdx, parsed, warnings)
    args = args or {}
    argIdx = argIdx or 1
    parsed = parsed or {}
    warnings = warnings or {}

    if #self.subcommands > 0 then
        local arg = args[argIdx] or ""
        for _, subCmd in ipairs(self.subcommands) do
            local match
            if subCmd.matchFunc then
                match = subCmd.matchFunc(arg)
            elseif subCmd.pattern then
                match = string.match(arg or "", subCmd.pattern)
            elseif subCmd.name == arg then
                match = arg
            end

            if match then
                if (subCmd.pattern or subCmd.matchFunc) then
                    parsed[subCmd.name] = match
                end
                return subCmd:parse(args, argIdx + 1, parsed, warnings)
            end
        end

        return nil, parsed, warnings, { cli_parse_specs.unknownSubcommandSpec:withDetail{
            field = arg
        }}
    end

    local function buildOptionMap(options)
        local map = {}
        for _, opt in ipairs(options) do
            for _, name in ipairs(opt.names) do
                map[name] = opt
            end
        end
        return map
    end

    local function collectAllSpecs(command)
        local all = {}
        for _, s in ipairs(command.specs or {}) do
            table.insert(all, s)
        end
        for _, arg in ipairs(command.arguments or {}) do
            for _, s in ipairs(arg.specs or {}) do
                table.insert(all, s)
            end
        end
        for _, opt in ipairs(command.options or {}) do
            for _, s in ipairs(opt.specs or {}) do
                table.insert(all, s)
            end
        end
        return all
    end

    local optionMap = buildOptionMap(self.options)
    local seenOptions = {}
    local positionals = {}
    local i = argIdx
    local failures = {}

    while i <= #args do
        local arg = args[i]
        if type(arg) == "string" and string.sub(arg, 1, 1) == "-" then
            local opt = optionMap[arg]
            local optKey
            if not opt then
                local key, val = string.match(arg, "^(%-%-?[%w%-]+)=(.+)$")
                if key and optionMap[key] then
                    opt = optionMap[key]
                    optKey = opt.names[#opt.names]
                    if seenOptions[optKey] then
                        table.insert(warnings, cli_specs.optionMultipleSpec:withDetail{
                            field = optKey,
                            aliases = opt.names
                        })
                    end
                    for _, name in ipairs(opt.names) do
                        parsed[name] = val
                    end
                    seenOptions[optKey] = true
                else
                    table.insert(failures, cli_parse_specs.unknownOptionSpec:withDetail{
                        field = arg,
                        aliases = nil
                    })
                end
            else
                optKey = opt.names[#opt.names]
                if seenOptions[optKey] then
                    table.insert(warnings, cli_specs.optionMultipleSpec:withDetail{
                        field = optKey,
                        aliases = opt.names
                    })
                end
                seenOptions[optKey] = true
                if opt.argument then
                    local val = args[i + 1]
                    if not val then
                        table.insert(failures, cli_parse_specs.missingOptionValueSpec:withDetail{
                            field = arg,
                            aliases = opt.names
                        })
                    else
                        for _, name in ipairs(opt.names) do
                            parsed[name] = val
                        end
                        i = i + 1
                    end
                else
                    for _, name in ipairs(opt.names) do
                        parsed[name] = true
                    end
                end
            end
        else
            table.insert(positionals, arg)
        end
        i = i + 1
    end

    for idx, argDef in ipairs(self.arguments) do
        if positionals[idx] == nil then
            table.insert(failures, cli_parse_specs.missingArgumentSpec:withDetail{
                field = argDef.name
            })
        end
        parsed[argDef.name] = positionals[idx]
    end
    if #positionals > #self.arguments then
        table.insert(failures, cli_parse_specs.extraArgumentSpec:withDetail{
            field = positionals[#self.arguments + 1]
        })
    end

    for _, opt in ipairs(self.options) do
        local key = opt.names[#opt.names]
        if parsed[key] == nil and opt.default ~= nil then
            parsed[key] = opt.default
        end
    end

    local context = Context:new(parsed, self)
    local allSpecs = collectAllSpecs(self)
    local specFailures = specs.Specification.getUnsatisfiedSpecs(allSpecs, context)
    for _, fail in ipairs(specFailures) do
        table.insert(failures, fail)
    end

    local actionResult
    if self.actionFunc and #failures == 0 then
        actionResult = self.actionFunc(parsed)
    end

    return actionResult, parsed or {}, warnings, failures
end

return Command
