
xpfw = {}
xpfw.path = minetest.get_modpath("xpfw")
xpfw.modname=minetest.get_current_modname()
xpfw.mod_storage=minetest.get_mod_storage()
xpfw.store_table={}--xpfw.mod_storage:to_table()
xpfw.attributes={}

--print(dump2(xpfw.mod_store))
minetest.log("action", "[MOD]"..minetest.get_current_modname().." -- start loading from "..minetest.get_modpath(minetest.get_current_modname()))
-- Load files

-- import settingtypes.txt
basic_functions.import_settingtype(xpfw.path .. "/settingtypes.txt")

dofile(xpfw.path .. "/api.lua") -- API
dofile(xpfw.path .. "/config.lua") -- API
dofile(xpfw.path .. "/chat_commands.lua")

minetest.log("action", "[MOD]"..minetest.get_current_modname().." -- loaded ")
