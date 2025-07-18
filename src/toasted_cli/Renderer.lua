--- Default renderer for CLI feedback and help texts.
-- Provides functions to render errors, warnings, and help messages in a consistent format.
-- @module toasted_cli.renderer

local Renderer = {}

--- Interpolates {key} in a template string with primitive fields from the table.
-- @tparam string str The template string.
-- @tparam table fields The table to interpolate from.
-- @treturn string The interpolated string.
local function interpolate_template(str, fields)
    return (str:gsub("{([%w_]+)}", function(key)
        local val = rawget(fields, key)
        if type(val) == "string" or type(val) == "number" or type(val) == "boolean" then
            return tostring(val)
        else
            return "{" .. key .. "}"
        end
    end))
end

--- Render a list of failures (errors).
-- @tparam {table,...} failures List of failure specs (with .message, .code, etc.).
-- @treturn string Rendered error messages.
function Renderer.renderFailures(failures)
    local lines = {}
    for _, fail in ipairs(failures or {}) do
        local msg = interpolate_template(fail.message or "Unknown error", fail)
        local code = fail.code and (" [" .. fail.code .. "]") or ""
        local field = fail.field and (" (" .. tostring(fail.field) .. ")") or ""
        table.insert(lines, string.format("Error%s%s: %s", code, field, msg))
        local detail = rawget(fail, "detail")
        if detail ~= nil then
            if type(detail) == "table" then
                table.insert(lines, "  Detail: [table]")
            else
                table.insert(lines, "  Detail: " .. tostring(detail))
            end
        end
    end
    return table.concat(lines, "\n")
end

--- Render a list of warnings.
-- @tparam {table,...} warnings List of warning specs.
-- @treturn string Rendered warning messages.
function Renderer.renderWarnings(warnings)
    local lines = {}
    for _, warn in ipairs(warnings or {}) do
        local msg = interpolate_template(warn.message or "Unknown warning", warn)
        local code = warn.code and (" [" .. warn.code .. "]") or ""
        local field = warn.field and (" (" .. tostring(warn.field) .. ")") or ""
        table.insert(lines, string.format("Warning%s%s: %s", code, field, msg))
        local detail = rawget(warn, "detail")
        if detail ~= nil then
            if type(detail) == "table" then
                table.insert(lines, "  Detail: [table]")
            else
                table.insert(lines, "  Detail: " .. tostring(detail))
            end
        end
    end
    return table.concat(lines, "\n")
end

--- Render help text for a command, and list subcommands.
-- @tparam table command The command object.
-- @treturn string The help text.
function Renderer.renderHelp(command)
    local lines = {}
    table.insert(lines, "Usage: " .. (command.name or "cli") .. " [options] [arguments]")
    if command.description and command.description ~= "" then
        table.insert(lines, "\n" .. command.description)
    end

    if command.arguments and #command.arguments > 0 then
        table.insert(lines, "\nArguments:")
        for _, arg in ipairs(command.arguments) do
            table.insert(lines, string.format("  %-12s %s", arg.name, arg.description or ""))
        end
    end

    if command.options and #command.options > 0 then
        table.insert(lines, "\nOptions:")
        for _, opt in ipairs(command.options) do
            local flags = opt.names and table.concat(opt.names, ", ") or ""
            local desc = opt.description or ""
            local def = opt.default and (" (default: " .. tostring(opt.default) .. ")") or ""
            table.insert(lines, string.format("  %-12s %s%s", flags, desc, def))
        end
    end

    local ungrouped = (command.subcommands and #command.subcommands > 0) and command.subcommands or nil
    local groups = command.subcommand_groups

    if ungrouped or (groups and #groups > 0) then
        table.insert(lines, "\nSubcommands:")
        if ungrouped then
            for _, sub in ipairs(ungrouped) do
                local name = sub.name or ""
                local desc = sub.description or ""
                table.insert(lines, string.format("  %-12s %s", name, desc))
            end
        end
        if groups then
            for _, group in ipairs(groups) do
                table.insert(lines, string.format("  %s:", group.name))
                for _, sub in ipairs(group.subcommands or {}) do
                    local name = sub.name or ""
                    local desc = sub.description or ""
                    table.insert(lines, string.format("    %-10s %s", name, desc))
                end
            end
        end
    end

    return table.concat(lines, "\n")
end

return Renderer
