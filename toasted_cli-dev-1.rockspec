package = "toasted_cli"
version = "dev-1"

source = {
    url = "git+https://github.com/toasted-mudlet/cli.git",
    tag = "dev-1"
}

description = {
    summary = "Minimal, extensible command-line interface (CLI) library for Lua.",
    detailed = [[
        Toasted CLI is a minimal and extensible command-line interface library
        for Lua 5.1 and newer, including LuaJIT.
    ]],
    homepage = "https://github.com/toasted-mudlet/cli",
    license = "MIT"
}

dependencies = {
    "lua >= 5.1"
}

build = {
    type = "builtin",
    modules = {}
}
