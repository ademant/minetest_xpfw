for i,configs in ipairs({"decay"}) do
	if minetest.settings:get("xpfw_"..configs) ~= nil then
		xpfw.mod_storage:set_int(configs,tonumber(minetest.settings:get("xpfw_"..configs)))
	else
		if xpfw.mod_storage:get_int(configs) == nil then
			xpfw.mod_storage:set_int(configs,0)
		end
	end
end

xpfw.prefix=minetest.settings:get("xpfw.prefix") or "xp"
xpfw.mean_weight=minetest.settings:get("xpfw.mean_weight") or 500
xpfw.experience_max=minetest.settings:get("xpfw.experience_max") or 20

for i,attr in ipairs({"walked","distance","login","dug","build","deaths","spoke","killed_mobs","killed_player",
		"lastlogin","logon"}) do
	xpfw.register_attribute(attr,{min=0,max=math.huge,default=0})
end
xpfw.register_attribute("meanlight",{min=0,max=default.LIGHT_MAX,
	moving_average_factor=minetest.settings:get("xpfw.light_mean_weight") or 500
	default=math.min(default.LIGHT_MAX,minetest.settings:get("xpfw.default")) or 11
	})
