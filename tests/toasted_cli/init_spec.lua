local pkg = require "toasted_cli"

describe("toasted_cli package init", function()
    it("includes command module", function()
        assert.is_table(pkg.command)
        assert.is_function(pkg.command.new)
    end)

    it("includes context module", function()
        assert.is_table(pkg.context)
        assert.is_function(pkg.context.new)
    end)

    it("includes renderer module", function()
        assert.is_table(pkg.renderer)
    end)

    it("includes specification module", function()
        assert.is_table(pkg.specification)
        assert.is_function(pkg.specification.Specification.new)
    end)
end)
