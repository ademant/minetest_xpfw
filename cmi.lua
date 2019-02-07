# count each killed mob

if cmi ~= nil then
	cmi.register_on_diemob(function(mob,cmi_death)
		if cmi_death == nil then
			return
		end
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
		local puncer_name=puncher:get_player_name()
		if puncher_name == nil then
			return
		else
			xpfw.player_add_attribute(puncher,"killed_mobs",1)
		end
	end)
end
