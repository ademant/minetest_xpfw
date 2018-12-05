
xpfw = {}
xpfw.path = minetest.get_modpath("xpfw")
xpfw.config = minetest.get_mod_storage()
xpfw.modname=minetest.get_current_modname()
xpfw.mod_storage=minetest.get_mod_storage()
xpfw.store_table=xpfw.mod_storage:to_table()

print(dump2(xpfw.mod_store))
minetest.log("action", "[MOD]"..minetest.get_current_modname().." -- start loading from "..minetest.get_modpath(minetest.get_current_modname()))
-- Load files


dofile(xpfw.path .. "/api.lua") -- API
dofile(xpfw.path .. "/config.lua") -- API

minetest.log("action", "[MOD]"..minetest.get_current_modname().." -- loaded ")
