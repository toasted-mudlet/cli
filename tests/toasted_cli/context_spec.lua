local Context = require("toasted_cli.context")

describe("Context", function()
    it("stores parsed table and command reference", function()
        local parsed = {
            ["--foo"] = "bar"
        }
        local command = {
            name = "root"
        }
        local ctx = Context:new(parsed, command)
        assert.are.equal(parsed, ctx.parsed)
        assert.are.equal(command, ctx.command)
    end)

    it("returns option values with get", function()
        local parsed = {
            ["--foo"] = "bar"
        }
        local ctx = Context:new(parsed, {})
        assert.are.equal("bar", ctx:get("--foo"))
        assert.is_nil(ctx:get("--missing"))
    end)

    it("returns argument values with get", function()
        local parsed = {
            arg1 = "val1"
        }
        local ctx = Context:new(parsed, {})
        assert.are.equal("val1", ctx:get("arg1"))
        assert.is_nil(ctx:get("arg2"))
    end)

    it("returns command name with getCommandName", function()
        local ctx = Context:new({}, {
            name = "root"
        })
        assert.are.equal("root", ctx:getCommandName())
    end)
end)
