
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
	xpfw.player_set_attribute(player,attrib,oldvalue+val)
	print(attrib,val,oldvalue)
	print(player:get_meta():get_float(xpfw.prefix.."_"..attrib))
end

xpfw.player_get_attribute=function(player,attrib)
	local pm=player:get_meta()
	return pm:get_float(xpfw.prefix.."_"..attrib) or 0
end
xpfw.player_set_attribute=function(player,attrib,val)
	local pm=player:get_meta()
	print(attrib,val)
	local att_def=xpfw.attributes[attrib]
	print(dump2(att_def))
	local setvalue=math.min(att_def.max or math.huge,math.max(att_def.min or 0,val))
	pm:set_float(xpfw.prefix.."_"..attrib,setvalue)
end

M.register_experience=function(name,indata)
	local tid=table.copy(indata)
	tid.name=name
	check_value(tid,"default",0)
	check_value(tid,"decay",0)
	M.experiences[name]=tid
end

minetest.register_on_joinplayer(function(player)
	local playername = player:get_player_name()

	for i,colu in ipairs({"walked","distance","login","dug","build","deaths","spoke","killed_mobs","killed_player",
		"lastlogin"}) do
		if player:get_attribute(xpfw.prefix.."_"..colu) == nil then
			player:set_attribute(xpfw.prefix.."_"..colu,0)
		end
	end
	if M.player[playername]==nil then
		M.player[playername]={last_pos=player:get_pos(),} --actual position
	end
	local pm=player:get_meta()
	pm:set_int(xpfw.prefix.."_lastlogin",os.time()) -- last login time
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

minetest.register_on_dignode(function(pos,oldnoe,player)
	if player ~= nil then
		xpfw.player_add_attribute(player,"dug",1)
	end
end)

minetest.register_on_leaveplayer(function(player)
	if player ~= nil then
		local leave=os.time()
		xpfw.player_add_attribute(player,"logon",player:get_attribute("lastlogin")-leave)
	end
	print(dump2(player:get_meta()))
end)

--[[
minetest.register_on_shutdown(function()
	print(dump2(M))
--	xpfw.mod_storage:from_table(M)
end
)
]]

minetest.register_globalstep(function(dtime)
	local players = minetest.get_connected_players()
	for i=1, #players do
		local player=players[i]
		local name = player:get_player_name()
		if M.player[name] ~= nil then
			local playerdata=M.player[name]
			if playerdata.last_pos ~= nil then
				local act_pos=player:get_pos()
				local tdist=vector.distance(act_pos,playerdata.last_pos)
				if tdist > 0 then
					xpfw.player_add_attribute(player,"distance",tdist)
					playerdata.last_pos = act_pos
				end
			else
				playerdata.last_pos = player:get_pos()
			end
			local tvel=player:get_player_velocity()
			if tvel ~= nil then
				local tvelo=vector.distance(tvel,{x=0,y=0,z=0})
				if tvelo>0 then
					xpfw.player_add_attribute(player,"walked",tvelo*dtime)
				end
			end
		end
	end
end)
