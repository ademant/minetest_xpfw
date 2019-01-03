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
	pm:set_int(xpfw.prefix.."_lastlogin",os.time()) -- last login time
	xpfw.player_add_attribute(player,"login",1)
	if playerdata.hud~=nil then
		xpfw.player_add_hud(player)
	end
	playerdata.dtime=0
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
	local players = minetest.get_connected_players()
	for i=1, #players do
		local player=players[i]
		local name = player:get_player_name()
		if M.player[name] ~= nil then
			local playerdata=M.player[name]
			playerdata.dtime=playerdata.dtime+dtime
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
				if minetest.get_item_group(act_node.name,"water")>0 then
					vel_action="swam"
				end
				local tvelo=vector.distance(tvel,{x=0,y=0,z=0})
				if tvelo>0 then
					xpfw.player_add_attribute(player,vel_action,tvelo*dtime)
					-- add experience
					local mean_speed="mean_"..vel_action.."_speed"
					if xpfw.attributes[mean_speed].max ~= nil then
						-- normal max velocity is 4. If slowed down than also reducing the mean value
						xpfw.player_add_attribute(player,mean_speed,xpfw.attributes[mean_speed].max*tvelo/4)
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
			
			if playerdata.hidx ~= nil then
				local act_logon=os.clock()-xpfw.player_get_attribute(player,"lastlogin")
				local act_print=""
				for i,att_def in pairs(xpfw.attributes) do
					if att_def.hud ~= nil and att_def.name ~= "logon" then
						act_print=act_print..i..": "..math.ceil(xpfw.player_get_attribute(player,att_def.name)).."\n"
					end
				end
				act_print=act_print.."logon: "..math.ceil(xpfw.player_get_attribute(player,"lastlogin")+act_logon)
				player:hud_change(playerdata.hidx,"text",act_print)
			end
			
			if playerdata.dtime>xpfw.rtime then
				playerdata.dtime=0
				for i,att_def in pairs(xpfw.attributes) do
					local att=xpfw.attributes[i]
					if att_def.recreation_factor ~= nil and xpfw.player_get_attribute(player,i) > att.min and playerdata.flags[i] == nil then
						xpfw.player_sub_attribute(player,i)
					end
					playerdata.flags[i]=nil
				end
			end
		end
		
	end
end)
