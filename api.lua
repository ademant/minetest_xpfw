
local M=xpfw.store_table
if M.player == nil then
	M.player={}
end
if M.experiences == nil then
	M.experiences={}
end

local check_value=function(tab,val,def)
if tab[val] == nil then
	tab[val] = def
end
end

xpfw.register_attribute=function(name,data)
	check_value(data,"min",0)
	check_value(data,"max",math.huge)
	data.name=name
	xpfw.attributes[name]=data
end

xpfw.player_add_attribute=function(player,attrib,val)
	local oldvalue=xpfw.player_get_attribute(player,attrib)
	local att_def=xpfw.attributes[attrib]
	local new_val = oldvalue + val
	if att_def.moving_average_factor ~= nil then
		new_val=(oldvalue*att_def.moving_average_factor + val)/(att_def.moving_average_factor + 1)
	end
	xpfw.player_set_attribute(player,attrib,new_val)
end

xpfw.player_get_attribute=function(player,attrib)
	local pm=player:get_meta()
	return pm:get_float(xpfw.prefix.."_"..attrib) or 0
end
xpfw.player_set_attribute=function(player,attrib,val)
	local pm=player:get_meta()
	local att_def=xpfw.attributes[attrib]
	local setvalue=math.min(att_def.max or math.huge,math.max(att_def.min or 0,val))
	pm:set_float(xpfw.prefix.."_"..attrib,setvalue)
end

xpfw.player_ping_attribute=function(player,attrib)
	local att_def=xpfw.attributes[attrib]
	local ping_max=att_def.max
	if ping_max == nil then
		ping_max=xpfw.experience_max
		xpfw.attributes[attrib]["max"]=xpfw.experience_max
	else
		if ping_max==math.huge then
			ping_max=xpfw.experience_max
			xpfw.attributes[attrib]["max"]=xpfw.experience_max
		end
	end
	
	if att_def.moving_average_factor == nil then
		att_def.moving_average_factor=xpfw.mean_weight
	end
	xpfw.player_add_attribute(player,attrib,ping_max)
end

M.register_experience=function(name,indata)
	local tid=table.copy(indata)
	tid.name=name
	check_value(tid,"default",0)
	check_value(tid,"decay",0)
	M.experiences[name]=tid
end

xpfw.player_reset_attributes=function(player)
	for i,att_def in ipairs(xpfw.attributes) do
		local setval=att_def.min or 0
		if att_def.default ~= nil then
			setval=att_def.default
		end
		player:set_attribute(xpfw.prefix.."_"..att_def.name,setval)
	end
end

minetest.register_on_joinplayer(function(player)
	local playername = player:get_player_name()

	for i,att_def in ipairs(xpfw.attributes) do
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
			hud=1, --hud on
			} 
	end
	local playerdata=M.player[playername]
	local pm=player:get_meta()
	pm:set_int(xpfw.prefix.."_lastlogin",os.time()) -- last login time
	xpfw.player_add_attribute(player,"login",1)
	playerdata.hidx=player:hud_add({
		hud_elem_type = "text",
		position = {x=1,y=1},
		size = "",
		text = "",
		alignment = {x=-1,y=-1},
	})
	playerdata.dtime=0
--	print(pm:get_int(xpfw.prefix.."_lastlogin"))
end
)

minetest.register_on_placenode(function(pos, newnode, player, oldnode, itemstack, pointed_thing)
	if player ~= nil then
		local playername = player:get_player_name()
		xpfw.player_add_attribute(player,"build",1)
	end
end)

minetest.register_on_dieplayer(function(player, reason)
	print(dump2(reason))
	if player ~= nil then
		xpfw.player_add_attribute(player,"deaths",1)
	end
end)

minetest.register_on_chat_message(function(player, reason)
	print(dump2(player))
	if player ~= nil then
		xpfw.player_add_attribute(minetest.get_player_by_name(player),"spoke",1)
	end
end)

minetest.register_on_dignode(function(pos,oldnode,player)
	if player ~= nil then
		xpfw.player_add_attribute(player,"dug",1)
	end
end)

minetest.register_on_leaveplayer(function(player)
	if player ~= nil then
		local leave=os.time()
		xpfw.player_add_attribute(player,"logon",xpfw.player_get_attribute(player,"lastlogin")-leave)
	end
end)

minetest.register_on_shutdown(function()
	local leave=os.time()
	print(dump2(minetest.get_connected_players()))
	local players = minetest.get_connected_players()
	for i=1, #players do
		local player=players[i]
		xpfw.player_add_attribute(player,"logon",xpfw.player_get_attribute(player,"lastlogin")-leave)
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
--			print(dump2(playerdata))
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
--				print(vel_action,tvelo)
				local mean_speed="mean_"..vel_action.."_speed"
				if xpfw.attributes[mean_speed].max ~= nil then
					xpfw.player_add_attribute(player,mean_speed,xpfw.attributes[mean_speed].max)
				end
				if tvelo>0 then
					xpfw.player_add_attribute(player,vel_action,tvelo*dtime)
				end
			end
			--calculating mean sun level
			local light_level=minetest.get_node_light(act_pos)
			if light_level ~= nil then
				xpfw.player_add_attribute(player,"meanlight",light_level)
			end
			
			if playerdata.hidx ~= nil then
				
				local act_logon=os.clock()-xpfw.player_get_attribute(player,"lastlogin")
				local act_print=""
				for i,att_def in ipairs(xpfw.attributes) do
					print(dump2(att_def))
					if att_def.hud ~= nil and att_def.name ~= "logon" then
						act_print=act_print..attr..": "..math.ceil(xpfw.player_get_attribute(player,att_def.name)).."\n"
					end
				end
				act_print=act_print.."logon: "..math.ceil(xpfw.player_get_attribute(player,"lastlogin")+act_logon)
				player:hud_change(playerdata.hidx,"text",act_print)
			end
			
			if playerdata.dtime>5 then
				playerdata.dtime=0
				for i,att_def in ipairs(xpfw.attributes) do
					if att_def.moving_average_factor ~= nil then
						xpfw.player_add_attribute(player,att_def.name,0)
					end
				end
			end
		end
		
	end
end)
