--- CLI parsing context wrapper.
-- Provides unified accessors for all parsed values (options, arguments, etc.).
-- Typically used for validation and command actions.
-- @module toasted_cli.context

--- Context class.
-- Wraps the parsed table and command for use in validation and feedback.
-- @type Context
local Context = {}
Context.__index = Context

--- Creates a new Context.
-- @tparam table parsed The parsed values table.
-- @tparam table command The command object.
-- @treturn Context The new context object.
function Context:new(parsed, command)
    return setmetatable({
        parsed = parsed or {},
        command = command
    }, self)
end

--- Gets the value for a given key (option, argument, etc.).
-- @tparam string name The key name.
-- @treturn any The value, or nil if not present.
function Context:get(name)
    return self.parsed[name]
end

--- Checks if a value is present for a given key.
-- @tparam string name The key name.
-- @treturn boolean True if present, false otherwise.
function Context:has(name)
    return self.parsed[name] ~= nil
end

--- Gets the count of values for a given key.
-- @tparam string name The key name.
-- @treturn number The number of occurrences (0 if not present).
function Context:count(name)
    local val = self.parsed[name]
    if type(val) == "table" then
        return #val
    elseif val ~= nil then
        return 1
    else
        return 0
    end
end

--- Gets the command object for this context.
-- @treturn table The command object.
function Context:getCommand()
    return self.command
end

--- Gets the command name for this context.
-- Returns nil if the command is not set.
-- @treturn string|nil The command name, or nil if not set.
function Context:getCommandName()
    return self.command and self.command.name
end

return Context
