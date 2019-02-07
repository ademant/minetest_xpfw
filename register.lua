local M=xpfw

minetest.register_on_joinplayer(function(player)
	local playername = player:get_player_name()
	for i,att_def in pairs(xpfw.attributes) do
		if player:get_attribute(xpfw.prefix.."_"..att_def.name) == nil then
			local defval=att_def.min or 0
			if att_def.default ~= nil then
				defval=att_def.default
			end
			player:set_attribute(xpfw.prefix.."_"..att_def.name,defval)
		end
	end
	if M.player[playername]==nil then
		M.player[playername]={last_pos=player:get_pos(), --actual position
			flags={},
			attributes=table.copy(xpfw.attributes),
			}
		local playerhud=xpfw.mod_storage:get_int(playername.."_hud")
		if playerhud==nil then playerhud=1 end
		if playerhud == 1 then
			M.player[playername].hud=1
		end
		for i,tdef in pairs(M.player[playername].attributes) do
			local rf=xpfw.mod_storage:get_int(playername.."_"..i.."_rf")
			local maf=xpfw.mod_storage:get_int(playername.."_"..i.."_maf")
			if rf>0 then
				M.player[playername].attributes[i].recreation_factor=rf
			end
			if maf>0 then
				M.player[playername].attributes[i].moving_average_factor=maf
			end
		end
		xpfw.player_set_attribute_to_nil(player,"meanlight")
	end
	local playerdata=M.player[playername]
	local pm=player:get_meta()
	xpfw.player_set_attribute(player,"lastlogin",os.time()) -- last login time
	xpfw.player_add_attribute(player,"login",1)
	if playerdata.hud~=nil then
		xpfw.player_add_hud(player)
	end
	playerdata.dtime=0
	playerdata.gtimer1=0
end
)

minetest.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv)
	if player ~= nil then
		local playername = player:get_player_name()
		xpfw.player_add_attribute(player,"craft",1)
		xpfw.player_add_attribute(player,"mean_craft_speed")
	end
end)

minetest.register_on_placenode(function(pos, newnode, player, oldnode, itemstack, pointed_thing)
	if player ~= nil then
		local playername = player:get_player_name()
		xpfw.player_add_attribute(player,"build",1)
		xpfw.player_add_attribute(player,"mean_build_speed")
	end
end)

minetest.register_on_dieplayer(function(player, reason)
	if player ~= nil then
		xpfw.player_add_attribute(player,"deaths",1)
		if reason == nil then return end
		if reason.type ~= "punch" then return end
		if reason.puncher == nil then return end
		local puncher = reason.puncher
		local puncher_name = puncher:get_player_name()
		if puncher_name == nil or puncher_name == "" then return end
		xpfw.player_add_attribute(puncher,"killed_player",1)
	end
end)

minetest.register_on_chat_message(function(player, reason)
	if player ~= nil then
		xpfw.player_add_attribute(minetest.get_player_by_name(player),"spoke",1)
	end
end)

minetest.register_on_dignode(function(pos,oldnode,player)
	if player ~= nil then
		xpfw.player_add_attribute(player,"dug",1)
		xpfw.player_add_attribute(player,"mean_dig_speed")
	end
end)

minetest.register_on_leaveplayer(function(player)
	if player ~= nil then
		local playerdata=M.player[player:get_player_name()]
		local leave=os.time()
		xpfw.player_add_attribute(player,"logon",xpfw.player_get_attribute(player,"lastlogin")-leave)
		local playerhud=playerdata.hud
		if playerhud==nil then playerhud=0 end
		xpfw.mod_storage:set_int(player:get_player_name().."_hud",playerhud)
	end
end)

minetest.register_on_shutdown(function()
	local leave=os.time()
	local players = minetest.get_connected_players()
	for i=1, #players do
		local player=players[i]
		xpfw.save_player_data(player)
		local playerdata=M.player[player]
		xpfw.player_add_attribute(player,"logon",xpfw.player_get_attribute(player,"lastlogin")-leave)
		local playerdata=M.player[player:get_player_name()]
		local playerhud=playerdata.hud
		if playerhud==nil then playerhud=0 end
		xpfw.mod_storage:set_int(player:get_player_name().."_hud",playerhud)
	end
end
)

minetest.register_globalstep(function(dtime)
--	local starttime=os.clock()
--	xpfw.gtimer1=xpfw.gtimer1+dtime
	local players = minetest.get_connected_players()
	if #players ~= nil then
		if #players > 0 then
			for i=1, #players do
				local player=players[i]
				local name = player:get_player_name()
				local playerdata=M.player[name]
				if playerdata ~= nil then
					playerdata.dtime=playerdata.dtime+dtime
					playerdata.gtimer1=playerdata.gtimer1+dtime
					
					-- add dtime to playtime of user
					xpfw.player_add_attribute(player,"playtime",dtime)
					
					local act_pos=player:get_pos()
					-- calculating distance to last known position
					if playerdata.last_pos ~= nil then
						local tdist=vector.distance(act_pos,playerdata.last_pos)
						if tdist > 0 then
							xpfw.player_add_attribute(player,"distance",tdist)
							playerdata.last_pos = act_pos
						end
					else
						playerdata.last_pos = act_pos
					end
					-- calculation walk by actual velocity
					local tvel=player:get_player_velocity()
					if tvel ~= nil then
						local act_node=minetest.get_node(act_pos)
						-- check if swimming
						local vel_action="walked"
						local vel_ref=4
						if minetest.get_item_group(act_node.name,"water")>0 then
							vel_action="swam"
							vel_ref=2
						end
		--				local tvelo=vector.distance(tvel,{x=0,y=0,z=0})
						local tvelo=tvel.x*tvel.x+tvel.y*tvel.y+tvel.z*tvel.z
						if tvelo>0 then
							tvelo=math.sqrt(tvelo)
							xpfw.player_add_attribute(player,vel_action,tvelo*dtime)
							-- add experience
							local mean_speed="mean_"..vel_action.."_speed"
							if xpfw.attributes[mean_speed].max ~= nil then
								-- normal max velocity is 4. If slowed down than also reducing the mean value
								xpfw.player_add_attribute(player,mean_speed,xpfw.attributes[mean_speed].max*tvelo/vel_ref)
							end
						end
					end
					--calculating mean sun level
					local light_level=minetest.get_node_light(act_pos)
					if light_level ~= nil then
						if xpfw.player_get_attribute(player,"meanlight") == (-1) then
							local light_level=minetest.get_node_light(act_pos,0.5)
							if light_level > 1 then
								print("light level "..light_level)
								xpfw.player_set_attribute(player,"meanlight",light_level)
							end
						else
							xpfw.player_add_attribute(player,"meanlight",light_level)
						end
					end
					
					if playerdata.gtimer1 > 0.75 then
						playerdata.gtimer1=0
						if playerdata.hidx ~= nil then
							local act_logon=os.time()-xpfw.player_get_attribute(player,"lastlogin")
							local act_print=""
							for i,attn in ipairs(xpfw.hud_intern) do
								act_print=act_print..attn..":"..math.ceil(xpfw.player_get_attribute(player,attn)).."\n"
							end
--							act_print=act_print.."logon: "..math.ceil(xpfw.player_get_attribute(player,"lastlogin")+act_logon)
							act_print=act_print.."logon: "..math.ceil(act_logon)
							player:hud_change(playerdata.hidx,"text",act_print)
						end
					end
					
					if playerdata.dtime>xpfw.rtime then
						playerdata.dtime=0
						local flags=playerdata.flags
						local attrib=xpfw.attributes
						for i,attn in ipairs(xpfw.attrib_recreates) do
							local att=attrib[attn]
							if flags[attn] == nil then
								if xpfw.player_get_attribute(player,attn) > att.min then
									xpfw.player_sub_attribute(player,attn)
								end
							end
							flags[attn]=nil
						end
					end
				end
				
			end
		end
	end
--	print("xpfw_abm: "..1000*(os.clock()-starttime))
end)
