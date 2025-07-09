local Command = require("toasted_cli.command")
local Renderer = require("toasted_cli.renderer")

local greet = Command:new{
    name = "greet",
    description = "Greet someone from the CLI"
}
:argument("name", "Name of the person to greet")
:option("--shout -s", "Shout the greeting")
:action(function(parsed)
    local greeting = "Hello, " .. (parsed.name or "world")
    if parsed["--shout"] then
        greeting = string.upper(greeting) .. "!"
    end
    print(greeting)
end)

local actionResult, parsed, warnings, failures = greet:parse(arg)  -- luacheck: ignore actionResult

if #failures > 0 then
    print(Renderer.renderFailures(failures))
    os.exit(1)
end

if #warnings > 0 then
    print(Renderer.renderWarnings(warnings))
end

if not parsed.name then
    print(Renderer.renderHelp(greet))
end
