package = "toasted_cli"
version = "dev-1"

source = {
    url = "git+https://github.com/toasted-mudlet/cli.git",
    tag = "dev-1"
}

description = {
    summary = "Minimal, extensible command-line interface (CLI) library for Lua",
    detailed = [[
        Toasted CLI is a minimal and extensible command-line interface library
        for Lua 5.1 and newer, including LuaJIT. It is runtime-agnostic and
        allows you to define declarative command and subcommand trees,
        positional arguments, and options.
    ]],
    homepage = "https://github.com/toasted-mudlet/cli",
    license = "MIT"
}

dependencies = {
    "lua >= 5.1"
}

build = {
    type = "builtin",
    modules = {
        ["toasted_cli"] = "src/toasted_cli/init.lua",
        ["toasted_cli.cli_specs"] = "src/toasted_cli/cli_specs.lua",
        ["toasted_cli.Command"] = "src/toasted_cli/Command.lua",
        ["toasted_cli.Context"] = "src/toasted_cli/Context.lua",
        ["toasted_cli.Renderer"] = "src/toasted_cli/Renderer.lua",
        ["toasted_cli.specification"] = "src/toasted_cli/specification.lua",
        ["toasted_cli.internal.cli_parse_specs"] = "src/toasted_cli/internal/cli_parse_specs.lua"
    }
}
