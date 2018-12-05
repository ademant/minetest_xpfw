for i,configs in ipairs({"decay"}) do
	if minetest.settings:get("xpfw_"..configs) ~= nil then
		xpfw.mod_storage:set_int(configs,tonumber(minetest.settings:get("xpfw_"..configs)))
	else
		if xpfw.mod_storage:get_int(configs) == nil then
			xpfw.mod_storage:set_int(configs,0)
		end
	end
end
