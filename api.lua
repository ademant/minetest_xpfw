
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

local player_add_attribute=function(player,attrib,val)
	local pm=player:get_meta()
	local old_val=pm:get_float(attrib) or 0
	pm:set_float(attrib,old_val+val)
	print(attrib,val)
	print(pm:get_float(attrib))
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
		if player:get_attribute("xp_"..colu) == nil then
			player:set_attribute("xp_"..colu,0)
		end
	end
	if M.player[playername]==nil then
		M.player[playername]={last_pos=player:get_pos(),} --actual position
	end
	local pm=player:get_meta()
	pm:set_int("xp_lastlogin",os.time()) -- last login time
end
)

minetest.register_on_placenode(function(pos, newnode, player, oldnode, itemstack, pointed_thing)
	if player ~= nil then
		local playername = player:get_player_name()
		player_add_attribute(player,"xp_build",1)
	end
end)

minetest.register_on_dieplayer(function(player, reason)
	print(dump2(reason))
	if player ~= nil then
		player_add_attribute(player,"xp_deaths",1)
	end
end)

minetest.register_on_chat_message(function(player, reason)
	if player ~= nil then
		player_add_attribute(player,"xp_spoke",1)
	end
end)

minetest.register_on_dignode(function(pos,oldnoe,player)
	if player ~= nil then
		player_add_attribute(player,"xp_dug",1)
	end
end)

minetest.register_on_leaveplayer(function(player)
	if player ~= nil then
		local leave=os.time()
		player_add_attribute(player,"xp_logon",player:get_attribute("xp_lastlogin")-leave)
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
					player_add_attribute(player,"xp_distance",tdist)
					playerdata.last_pos = act_pos
				end
			else
				playerdata.last_pos = player:get_pos()
			end
			local tvel=player:get_player_velocity()
			if tvel ~= nil then
				local tvelo=vector.distance(tvel,{x=0,y=0,z=0})
				if tvelo>0 then
					player_add_attribute(player,"xp_walked",tvelo*dtime)
				end
			end
		end
	end
end)
