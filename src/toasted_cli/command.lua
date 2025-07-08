local Command = {}
Command.__index = Command

function Command:new(opts)
    opts = opts or {}
    local instance = setmetatable({}, self)
    instance.name = opts.name or "cli"
    instance.description = opts.description or ""
    instance.pattern = opts.pattern
    instance.matchFunc = opts and opts.matchFunc
    instance.subcommands = {}
    instance.arguments = {}
    instance.options = {}
    instance.actionFunc = nil
    return instance
end

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

function Command:argument(name, desc, opts)
    table.insert(self.arguments, {
        name = name,
        description = desc,
        opts = opts or {}
    })
    return self
end

function Command:option(flags, desc, opts)
    opts = opts or {}
    local option = {
        flags = flags,
        description = desc,
        argument = opts.argument,
        default = opts.default,
        names = {}
    }
    for flag in string.gmatch(flags, "%-%-?[%w%-]+") do
        table.insert(option.names, flag)
    end
    table.insert(self.options, option)
    return self
end

function Command:action(fn)
    self.actionFunc = fn
    return self
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
        error("Unknown subcommand: " .. tostring(arg))
    end

    local optionMap = buildOptionMap(self.options)
    local seenOptions = {}
    local positionals = {}
    local i = argIdx
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
                        table.insert(warnings, "Option " .. optKey .. " specified multiple times; using last value.")
                    end
                    for _, name in ipairs(opt.names) do
                        parsed[name] = val
                    end
                    seenOptions[optKey] = true
                else
                    error("Unknown option: " .. arg)
                end
            else
                optKey = opt.names[#opt.names]
                if seenOptions[optKey] then
                    table.insert(warnings, "Option " .. optKey .. " specified multiple times; using last value.")
                end
                seenOptions[optKey] = true
                if opt.argument then
                    local val = args[i + 1]
                    if not val then
                        error("Option " .. arg .. " expects a value")
                    end
                    for _, name in ipairs(opt.names) do
                        parsed[name] = val
                    end
                    i = i + 1
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
            error("Missing required argument: " .. argDef.name)
        end
        parsed[argDef.name] = positionals[idx]
    end
    if #positionals > #self.arguments then
        error("Unexpected extra argument: " .. tostring(positionals[#self.arguments + 1]))
    end

    for _, opt in ipairs(self.options) do
        local key = opt.names[#opt.names]
        if parsed[key] == nil and opt.default ~= nil then
            parsed[key] = opt.default
        end
    end

    local actionResult
    if self.actionFunc then
        actionResult = self.actionFunc(parsed)
    end

    return actionResult, parsed or {}, warnings
end

return Command
