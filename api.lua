
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

xpfw.player_reset_attributes(player)
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
		M.player[playername]={last_pos=player:get_pos(),} --actual position
	end
	local pm=player:get_meta()
	pm:set_int(xpfw.prefix.."_lastlogin",os.time()) -- last login time
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
	if player ~= nil then
		xpfw.player_add_attribute(player,"spoke",1)
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
	print(dump2(player:get_meta()))
end)

minetest.register_on_shutdown(function()
	local leave=os.time()
	print(dump2(minetest.get_connected_players()))
	local players = minetest.get_connected_players()
	for i=1, #players do
		local player=players[i]
		xpfw.player_add_attribute(player,"logon",xpfw.player_get_attribute(player,"lastlogin")-leave)
		print(dump2(player))
		print(player:get_player_name())
	end
--	xpfw.mod_storage:from_table(M)
end
)

minetest.register_globalstep(function(dtime)
	local players = minetest.get_connected_players()
	for i=1, #players do
		local player=players[i]
		local name = player:get_player_name()
		if M.player[name] ~= nil then
			local playerdata=M.player[name]
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
				local tvelo=vector.distance(tvel,{x=0,y=0,z=0})
				if tvelo>0 then
					xpfw.player_add_attribute(player,"walked",tvelo*dtime)
				end
			end
			--calculating mean sun level
			local light_level=minetest.get_node_light(act_pos)
			if light_level ~= nil then
				xpfw.player_add_attribute(player,"meanlight",light_level)
			end
		end
	end
end)
