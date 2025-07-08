local Command = require("toasted_cli.command")

describe("toasted-cli.command", function()

    describe("subcommand dispatching", function()
        it("dispatches actions for simple subcommands", function()
            local result
            local root = Command:new{
                name = "root"
            }
            root:subcommand("hello", "Say hello"):action(function(args)
                result = "hi!"
            end)

            local _, parsed = root:parse({"hello"})
            assert.are.equal("hi!", result)
            assert.are.same({}, parsed)
        end)

        it("returns the result of the action as the first return value", function()
            local root = Command:new{
                name = "root"
            }
            root:subcommand("hello", "Say hello"):action(function(args)
                return "hi!"
            end)

            local result, parsed = root:parse({"hello"})
            assert.are.equal("hi!", result)
            assert.are.same({}, parsed)
        end)

        it("matches scope subcommands using matchFunc and stores the value", function()
            local value
            local root = Command:new{
                name = "root"
            }
            local validScopes = {
                map = true,
                area = true,
                room = true
            }
            local scopeCmd = root:subcommand("scope", "Scoped ops", {
                matchFunc = function(input)
                    if validScopes[input] then
                        return input
                    end
                end
            })
            scopeCmd:subcommand("list", "List entities"):action(function(args)
                value = args.scope
            end)

            local _, parsedMap = root:parse({"map", "list"})
            assert.are.equal("map", value)
            assert.are.same({
                scope = "map"
            }, parsedMap)
            local _, parsedArea = root:parse({"area", "list"})
            assert.are.equal("area", value)
            assert.are.same({
                scope = "area"
            }, parsedArea)
            local _, parsedRoom = root:parse({"room", "list"})
            assert.are.equal("room", value)
            assert.are.same({
                scope = "room"
            }, parsedRoom)
        end)
    end)

    describe("argument parsing", function()
        it("raises an error if an unknown subcommand is provided", function()
            local root = Command:new{
                name = "root"
            }
            root:subcommand("hello", "Say hello")

            assert.has_error(function()
                root:parse({"goodbye"})
            end, "Unknown subcommand: goodbye")
        end)

        it("raises an error if too few arguments are provided", function()
            local root = Command:new{
                name = "root"
            }
            root:subcommand("delete", "Delete entity"):argument("entity", "Entity type"):argument("id", "Entity ID")
                :action(function(args)
                end)

            assert.has_error(function()
                root:parse({"delete", "user"})
            end, "Missing required argument: id")
        end)

        it("raises an error if too many arguments are provided", function()
            local root = Command:new{
                name = "root"
            }
            root:subcommand("delete", "Delete entity"):argument("entity", "Entity type"):argument("id", "Entity ID")
                :action(function(args)
                end)

            assert.has_error(function()
                root:parse({"delete", "user", "user_1", "extra"})
            end, "Unexpected extra argument: extra")
        end)

        it("passes positional arguments to actions and returns them in parsed table", function()
            local argsOut
            local root = Command:new{
                name = "root"
            }
            root:subcommand("delete", "Delete entity"):argument("entity", "Entity type"):argument("id", "Entity ID")
                :action(function(args)
                    argsOut = args
                end)

            local _, parsed = root:parse({"delete", "user", "user_1"})
            assert.are.same({
                entity = "user",
                id = "user_1"
            }, argsOut)
            assert.are.same({
                entity = "user",
                id = "user_1"
            }, parsed)
        end)

        it("returns no error if no action is defined", function()
            local root = Command:new{
                name = "root"
            }
            root:subcommand("noop", "No operation")

            local result, parsed
            assert.has_no.errors(function()
                result, parsed = root:parse({"noop"})
            end)
            assert.is_nil(result)
            assert.are.same({}, parsed)
        end)
    end)

    describe("option parsing", function()
        it("parses boolean flags", function()
            local parsedOut
            local root = Command:new{
                name = "root"
            }
            root:option("--verbose -v", "Enable verbose mode"):action(function(args)
                parsedOut = args
            end)

            local _, parsed = root:parse({"--verbose"})
            assert.is_true(parsed["--verbose"])
            assert.is_true(parsed["-v"])
            assert.are.same(parsed, parsedOut)
        end)

        it("parses short flags", function()
            local root = Command:new{
                name = "root"
            }
            root:option("-f", "Force"):action(function(args)
            end)

            local _, parsed = root:parse({"-f"})
            assert.is_true(parsed["-f"])
        end)

        it("parses options with values (separate)", function()
            local root = Command:new{
                name = "root"
            }
            root:option("--output -o", "Output file", {
                argument = true
            }):action(function(args)
            end)

            local _, parsed = root:parse({"--output", "file.txt"})
            assert.are.equal("file.txt", parsed["--output"])
            assert.are.equal("file.txt", parsed["-o"])
        end)

        it("parses options with values (equals)", function()
            local root = Command:new{
                name = "root"
            }
            root:option("--output -o", "Output file", {
                argument = true
            }):action(function(args)
            end)

            local _, parsed = root:parse({"--output=file.txt"})
            assert.are.equal("file.txt", parsed["--output"])
            assert.are.equal("file.txt", parsed["-o"])
        end)

        it("sets default option values", function()
            local root = Command:new{
                name = "root"
            }
            root:option("--mode", "Mode", {
                argument = true,
                default = "prod"
            }):action(function(args)
            end)

            local _, parsed = root:parse({})
            assert.are.equal("prod", parsed["--mode"])
        end)

        it("warns if an option is specified multiple times", function()
            local root = Command:new{
                name = "root"
            }
            root:option("--foo", "Foo", {
                argument = true
            }):action(function(args)
            end)

            local _, parsed, warnings = root:parse({"--foo", "bar", "--foo", "baz"})
            assert.are.equal("baz", parsed["--foo"])
            assert.is_true(#warnings > 0)
            assert.is_truthy(warnings[1]:match("specified multiple times"))
        end)

        it("raises an error for unknown options", function()
            local root = Command:new{
                name = "root"
            }
            root:option("--foo", "Foo"):action(function(args)
            end)

            assert.has_error(function()
                root:parse({"--bar"})
            end, "Unknown option: --bar")
        end)

        it("raises an error if a value is required but missing", function()
            local root = Command:new{
                name = "root"
            }
            root:option("--foo", "Foo", {
                argument = true
            }):action(function(args)
            end)

            assert.has_error(function()
                root:parse({"--foo"})
            end, "Option --foo expects a value")
        end)

        it("parses option value that looks like a flag", function()
            local root = Command:new{
                name = "root"
            }
            root:option("--foo", "Foo", {
                argument = true
            })
            local _, parsed = root:parse({"--foo", "-bar"})
            assert.are.equal("-bar", parsed["--foo"])
        end)

        it("sets all aliases for an option", function()
            local root = Command:new{
                name = "root"
            }
            root:option("--foo -f", "Foo", {
                argument = true
            })
            local _, parsed = root:parse({"--foo", "bar"})
            assert.are.equal("bar", parsed["--foo"])
            assert.are.equal("bar", parsed["-f"])
        end)

    end)
end)
