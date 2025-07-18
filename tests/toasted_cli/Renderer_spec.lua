local Renderer = require "toasted_cli.Renderer"

describe("Renderer", function()
    describe("renderFailures", function()
        it("returns blank for empty input", function()
            assert.equals("", Renderer.renderFailures())
            assert.equals("", Renderer.renderFailures({}))
        end)

        it("renders basic error entry", function()
            local failures = {{
                message = "Failed at {step}",
                code = "E001",
                field = "foo",
                step = "parse"
            }}
            local output = Renderer.renderFailures(failures)
            assert.is_not_nil(output:match("Error %[E001%] %(foo%)"))
            assert.is_not_nil(output:match("Failed at parse"))
        end)

        it("renders multiple failures in order", function()
            local failures = {{
                message = "First"
            }, {
                message = "Second"
            }}
            local output = Renderer.renderFailures(failures)
            assert.is_not_nil(output:match("First"))
            assert.is_not_nil(output:match("Second"))
            local pos1 = assert(output:find("First"))
            local pos2 = assert(output:find("Second"))
            assert.is_true(pos1 < pos2)
        end)

        it("includes detail if present", function()
            local failures = {{
                message = "Oh no",
                detail = "extra info"
            }, {
                message = "Err",
                detail = {
                    abc = 1
                }
            }}
            local output = Renderer.renderFailures(failures)
            assert.is_not_nil(output:match("Detail: extra info"))
            assert.is_not_nil(output:match("Detail: %[table%]"))
        end)
    end)

    describe("renderWarnings", function()
        it("returns blank for empty input", function()
            assert.equals("", Renderer.renderWarnings())
            assert.equals("", Renderer.renderWarnings({}))
        end)

        it("renders basic warning entry", function()
            local warnings = {{
                message = "Something may be wrong",
                code = "W42",
                field = "bar"
            }}
            local output = Renderer.renderWarnings(warnings)
            assert.is_not_nil(output:match("Warning %[W42%] %(bar%)"))
            assert.is_not_nil(output:match("Something may be wrong"))
        end)
    end)

    describe("renderHelp", function()
        it("renders minimal usage", function()
            local command = {
                name = "app"
            }
            local output = Renderer.renderHelp(command)
            assert.is_not_nil(output:match("Usage: app"))
        end)

        it("includes description, arguments, and options where available", function()
            local command = {
                name = "app",
                description = "Does stuff",
                arguments = {{
                    name = "file",
                    description = "A file to use"
                }},
                options = {{
                    names = {"-v", "--verbose"},
                    description = "Be noisy"
                }}
            }
            local output = Renderer.renderHelp(command)
            assert.is_not_nil(output:match("Does stuff"))
            assert.is_not_nil(output:match("Arguments:"))
            assert.is_not_nil(output:match("file"))
            assert.is_not_nil(output:match("Options:"))
            assert.is_not_nil(output:match("verbose"))
        end)

        it("renders both ungrouped and grouped subcommands if present", function()
            local cmd = {
                name = "demo",
                subcommands = {{
                    name = "foo",
                    description = "Foo desc"
                }, {
                    name = "bar",
                    description = "Bar desc"
                }},
                subcommand_groups = {{
                    name = "group 1",
                    subcommands = {{
                        name = "baz",
                        description = "Baz desc"
                    }, {
                        name = "qux",
                        description = "Qux desc"
                    }}
                }, {
                    name = "tools",
                    subcommands = {{
                        name = "deploy",
                        description = "Deploy stuff"
                    }}
                }}
            }
            local output = Renderer.renderHelp(cmd)

            local pos_foo = assert(output:find("foo"))
            local pos_bar = assert(output:find("bar"))
            local pos_supergroup = assert(output:find("group 1"))
            local pos_tools = assert(output:find("tools"))
            local pos_baz = assert(output:find("baz"))
            local pos_qux = assert(output:find("qux"))
            local pos_deploy = assert(output:find("deploy"))

            assert.is_true(pos_foo < pos_supergroup)
            assert.is_true(pos_bar < pos_supergroup)

            assert.is_true(pos_supergroup < pos_baz)
            assert.is_true(pos_tools < pos_deploy)

            assert.is_not_nil(output:match("Foo desc"))
            assert.is_not_nil(output:match("Bar desc"))
            assert.is_not_nil(output:match("Baz desc"))
            assert.is_not_nil(output:match("Qux desc"))
            assert.is_not_nil(output:match("Deploy stuff"))
        end)
    end)
end)
