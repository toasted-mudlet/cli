local base_path = os.getenv("BASE_PATH") or "./"
local lua_version = "5.1"
local path_sep = package.config and package.config:sub(3,3) or ';'

package.path = table.concat({
    base_path .. "/src/?.lua",
    base_path .. "/src/?/init.lua",
    base_path .. "/lua_modules/share/lua/" .. lua_version .. "/?.lua",
    base_path .. "/lua_modules/share/lua/" .. lua_version .. "/?/init.lua",
    package.path
}, path_sep)

package.cpath = table.concat({
    base_path .. "/lua_modules/lib/lua/" .. lua_version .. "/?.so",
    package.cpath
}, path_sep)

return true
