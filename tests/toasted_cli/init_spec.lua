local pkg = require "toasted_cli"

describe("toasted_cli package init", function()
    it("includes command module", function()
        assert.is_table(pkg.Command)
        assert.is_function(pkg.Command.new)
    end)

    it("includes context module", function()
        assert.is_table(pkg.Context)
        assert.is_function(pkg.Context.new)
    end)

    it("includes renderer module", function()
        assert.is_table(pkg.Renderer)
    end)

    it("includes specification module", function()
        assert.is_table(pkg.specification)
        assert.is_function(pkg.specification.Specification.new)
    end)
end)
