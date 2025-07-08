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
end)
