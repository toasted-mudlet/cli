# Toasted CLI

A minimal, extensible command-line interface (CLI) library for Lua.

## Features

- Runtime agnostic - works in shell scripts, REPLs, and any Lua environment
- Declarative command and subcommand trees
- Positional arguments and options
- Extensible validation and user feedback based on specifications
- Default renderer for user feedback and help text generation

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

local root = Command:new{ name = "todo", description = "A simple todo CLI" }

root:subcommand("add", "Add a new todo item")
    :argument("text", "The todo text")
    :action(function(args)
        print("Added todo:", args.text)
    end)
    
root:subcommand("list", "List all todo items")
    :action(function(args)
        print("Listing all todos...")
        -- (Your code to list todos here)
    end)

root:subcommand("remove", "Remove a todo item by number")
    :argument("number", "The todo number")
    :action(function(args)
        print("Removed todo number:", args.number)
    end)

root:parse({"add", "Buy milk"})
-- Output: Added todo: Buy milk

root:parse({"list"})
-- Output: Listing all todos...

root:parse({"remove", "2"})
-- Output: Removed todo number: 2
```

See other examples in the [`examples/`](examples/) directory.

> Use [`set_paths.lua`](set_paths.lua) to run examples locally:
>
> ```
> lua -l set_paths examples/basic_usage.lua
> ```

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
```
