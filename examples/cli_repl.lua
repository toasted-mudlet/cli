local Command = require("toasted_cli.Command")
local Renderer = require("toasted_cli.Renderer")

local greet = Command:new{
    name = "greet",
    description = "Greet someone"
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

local echo = Command:new{
    name = "echo",
    description = "Echo input"
}
:argument("text", "Text to echo")
:option("--repeat -r", "Repeat count", { default = 1 })
:action(function(parsed)
    for _ = 1, tonumber(parsed["--repeat"]) or 1 do
        print(parsed.text)
    end
end)

local commands = {
    greet = greet,
    echo = echo,
}

-- Helper: split line into args (handles quoted strings)
local function split_args(line)
    local args = {}
    local i = 1
    while i <= #line do
        while i <= #line and line:sub(i,i):match("%s") do i = i + 1 end
        if i > #line then break end
        local c = line:sub(i,i)
        if c == '"' or c == "'" then
            local quote = c
            local j = i + 1
            while j <= #line and line:sub(j,j) ~= quote do j = j + 1 end
            table.insert(args, line:sub(i+1, j-1))
            i = j + 1
        else
            local j = i
            while j <= #line and not line:sub(j,j):match("%s") do j = j + 1 end
            table.insert(args, line:sub(i, j-1))
            i = j
        end
    end
    return args
end

print("toasted_cli command REPL. Type CLI commands (e.g., 'greet Alice --shout').")
print("Type 'help' for help, 'help <command>' for command help, 'exit' to quit.\n")

while true do
    io.write("$ ")
    local line = io.read()
    repeat
        if not line or line:match("^%s*$") then
            -- skip empty input, prompt again
            break
        elseif line == "exit" then
            print("Goodbye!")
            return
        end

        local args = split_args(line)
        local cmdname = args[1]

        if not cmdname then
            -- skip if no command entered
            break
        elseif cmdname == "help" then
            local help_target = args[2]
            if help_target and commands[help_target] then
                print(Renderer.renderHelp(commands[help_target]))
            else
                print("Available commands:")
                for name, cmd in pairs(commands) do
                    print(string.format("  %-12s %s", name, cmd.description or ""))
                end
                print("\nType 'help <command>' for details.")
            end
        elseif commands[cmdname] then
            table.remove(args, 1)
            local _, _, warnings, failures = commands[cmdname]:parse(args)
            if #failures > 0 then
                print(Renderer.renderFailures(failures))
            elseif #warnings > 0 then
                print(Renderer.renderWarnings(warnings))
            end
        else
            print("Unknown command: " .. tostring(cmdname))
            print("Type 'help' for a list of commands.")
        end
    until true
end
