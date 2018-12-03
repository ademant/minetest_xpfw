
xpfw = {}
xpfw.path = minetest.get_modpath("xpfw")
xpfw.config = minetest.get_mod_storage()
xpfw.modname=minetest.get_current_modname()

minetest.log("action", "[MOD]"..minetest.get_current_modname().." -- start loading from "..minetest.get_modpath(minetest.get_current_modname()))
-- Load files


dofile(farming.path .. "/api.lua") -- API

minetest.log("action", "[MOD]"..minetest.get_current_modname().." -- loaded ")
