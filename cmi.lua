# count each killed mob

if cmi ~= nil then
	cmi.register_on_diemob(function(mob,cmi_death)
		print("pong")
		if mob ~= nil then 
			print(dump2(mob)) 
			print(dump2(mob:get_player_name()))
		end
		if cmi_death == nil then
			return
		end
		print(dump2(cmi_death))
		if cmi_death.type == nil then
			return
		end
		if cmi_death.type ~= "punch" then
			return
		end
		if cmi_death.puncher == nil then
			return
		end
		local puncher=cmi_death.puncher
		for key,value in pairs(cmi_death.puncher) do
			print("found key "..key)
		end
		print(dump2(cmi_death.puncher:get_player_name()))
		print(dump2(puncher))
		local puncer_name=puncher:get_player_name()
		print(dump2(puncher_name))
		print(dump2(puncher:get_entity_name()))
		print(dump2(puncher:get_luaentity()))
		if puncher_name == nil then
			return
		else
			xpfw.player_add_attribute(puncher,"killed_mobs",1)
		end
	end)
end
