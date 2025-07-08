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

function Command:action(fn)
    self.actionFunc = fn
    return self
end

function Command:parse(args, argIdx, parsed)
    args = args or {}
    argIdx = argIdx or 1
    parsed = parsed or {}

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
                return subCmd:parse(args, argIdx + 1, parsed)
            end
        end
        error("Unknown subcommand: " .. tostring(arg))
    end

    local argPos = 1
    for i = argIdx, #args do
        local argDef = self.arguments[argPos]
        if not argDef then
            error("Unexpected extra argument: " .. tostring(args[i]))
        end
        parsed[argDef.name] = args[i]
        argPos = argPos + 1
    end

    if argPos <= #self.arguments then
        local missingArg = self.arguments[argPos].name
        error("Missing required argument: " .. missingArg)
    end

    local actionResult
    if self.actionFunc then
        actionResult = self.actionFunc(parsed)
    end

    return actionResult, parsed or {}
end

return Command
