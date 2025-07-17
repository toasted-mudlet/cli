local Command = require("toasted_cli.Command")

local function assert_set_equal(t1, t2)
    assert.are.equal(#t1, #t2)
    local lookup = {}
    for _, v in ipairs(t1) do
        lookup[v] = (lookup[v] or 0) + 1
    end
    for _, v in ipairs(t2) do
        assert.is_not_nil(lookup[v], "Missing element: " .. tostring(v))
        lookup[v] = lookup[v] - 1
        assert.is_true(lookup[v] >= 0, "Extra element: " .. tostring(v))
    end
end

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

            local result, _, _, failures = root:parse({"goodbye"})
            assert.is_nil(result)
            assert.is_truthy(failures and #failures > 0)
            assert.are.equal("UNKNOWN_SUBCOMMAND", failures[1].code)
            assert.are.equal("goodbye", failures[1].field)
        end)

        it("raises an error if too few arguments are provided", function()
            local root = Command:new{
                name = "root"
            }
            root:subcommand("delete", "Delete entity"):argument("entity", "Entity type"):argument("id", "Entity ID")
                :action(function(args)
                    return "ACTION_CALLED"
                end)

            local result, _, _, failures = root:parse({"delete", "user"})
            assert.is_nil(result)
            assert.is_truthy(failures and #failures > 0)
            assert.are.equal("ARGUMENT_MISSING", failures[1].code)
            assert.are.equal("id", failures[1].field)
        end)

        it("raises an error if too many arguments are provided", function()
            local root = Command:new{
                name = "root"
            }
            root:subcommand("delete", "Delete entity"):argument("entity", "Entity type"):argument("id", "Entity ID")
                :action(function(args)
                    return "ACTION_CALLED"
                end)

            local result, _, _, failures = root:parse({"delete", "user", "user_1", "extra"})
            assert.is_nil(result)
            assert.is_truthy(failures and #failures > 0)
            assert.are.equal("ARGUMENT_EXTRA", failures[1].code)
            assert.are.equal("extra", failures[1].field)
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

            local result, parsed = root:parse({"noop"})
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
            assert.is_truthy(warnings and #warnings > 0)
            assert.are.equal("OPTION_MULTIPLE", warnings[1].code)
            assert.are.equal("--foo", warnings[1].field)
        end)

        it("raises an error for unknown options", function()
            local root = Command:new{
                name = "root"
            }
            root:option("--foo", "Foo"):action(function(args)
            end)

            local result, _, _, failures = root:parse({"--bar"})
            assert.is_nil(result)
            assert.is_truthy(failures and #failures > 0)
            assert.are.equal("OPTION_UNKNOWN", failures[1].code)
            assert.are.equal("--bar", failures[1].field)
        end)

        it("raises an error if a value is required but missing", function()
            local root = Command:new{
                name = "root"
            }
            root:option("--foo --foo2 -f -f2", "Foo", {
                argument = true
            }):action(function(args)
            end)

            local result, _, _, failures = root:parse({"--foo"})
            assert.is_nil(result)
            assert.is_truthy(failures and #failures > 0)
            assert.are.equal("OPTION_VALUE_MISSING", failures[1].code)
            assert.are.equal("--foo", failures[1].field)
            assert_set_equal({"--foo", "-f", "--foo2", "-f2"}, failures[1].aliases)
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

    describe("post-parse spec failures", function()
        local specs = require("toasted_cli.specification")
        local RequireBarSpec = {
            code = "FOO_MUST_BE_BAR",
            message = "The value for --foo must be 'bar'",
            isSatisfiedBy = function(self, context)
                local val = context:get("--foo")
                if val ~= "bar" then
                    return false, {
                        field = "--foo",
                        value = val
                    }
                end
                return true
            end
        }
        setmetatable(RequireBarSpec, {
            __index = specs.Specification
        })

        it("getUnsatisfiedSpecs attaches the parser context", function()
            local root = Command:new{
                name = "root"
            }
            root:option("--foo", "Foo", {
                argument = true,
                specs = {RequireBarSpec}
            })
            local _, parsed, _, failures = root:parse({"--foo", "baz"})
            local found = false
            for _, failure in ipairs(failures) do
                if failure.code == "FOO_MUST_BE_BAR" then
                    found = true
                    assert.is_table(failure.context)
                    assert.are.equal(parsed, failure.context.parsed)
                    assert.are.equal(root, failure.context.command)
                    assert.is_function(failure.context.get)
                end
            end
            assert.is_true(found, "Expected to find FOO_MUST_BE_BAR failure")
        end)
    end)
end)
