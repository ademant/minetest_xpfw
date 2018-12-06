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

for i,attr in ipairs({"walked","distance","login","dug","build","deaths","spoke","killed_mobs","killed_player",
		"lastlogin"}) do
	xpfw.register_attribute(attr,{min=0,max=math.huge})
end
