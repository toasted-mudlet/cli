# Toasted CLI

A minimal, extensible command-line interface (CLI) library for Lua.

## Requirements

- **[Lua 5.1](https://www.lua.org/versions.html#5.1)** or higher (including LuaJIT)

## Installation

```
luarocks install toasted_cli
```

Or, if using a custom tree:

```
luarocks install --tree=lua_modules toasted_cli
```

## Usage

Define your CLI command tree and parse arguments:

```
local Command = require("toasted_cli.command")

local root = Command:new{ name = "root", description = "My CLI" }
local valid_scopes = { map = true, area = true }
local scope = root:subcommand("scope", "Scoped operations", {
    matchFunc = function(input)
        if valid_scopes[input] then return input end
    end
})

scope:subcommand("list", "List rooms")
    :action(function(args)
        print("Listing rooms for scope:", args.scope)
    end)

root:parse({"map", "list"})
-- Output: Listing rooms for scope: map
```

## Attribution

If you create a new project based substantially on this CLI library, please
consider adding the following attribution or similar for all derived code:

> This project is based on [Toasted CLI](https://github.com/toasted-mudlet/cli), originally
> licensed under the MIT License (see [LICENSE](LICENSE) for details). All
> original code and documentation remain under the MIT License.

## License

Copyright © 2025 github.com/toasted323

This project is licensed under the MIT License.  
See [LICENSE](LICENSE) in the root of this repository for full details.
