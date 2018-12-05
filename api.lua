
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

M.register_experience=function(name,indata)
	local tid=table.copy(indata)
	tid.name=name
	check_value(tid,"default",0)
	check_value(tid,"decay",0)
	M.experiences[name]=tid
end

minetest.register_on_joinplayer(function(player)
	local playername = player:get_player_name()

	if M.player[playername]==nil then
		M.player[playername]={walked=0, -- really walked distances
			distance=0, -- including teleport etc.
			logon=0, -- logon time
			logstat={}, -- detailed logons (if configured)
			dug=0, -- count of nodes dugged
			build=0, -- count of build nodes
			deaths=0, -- count of deaths
			spoke=0, -- count of chat messages
			killed_mobs=0, -- count of killed mobs
			killed_player=0, --count of killed players
			last_pos=player:get_pos(), --actual position
			}
	end
	M.player[playername].lastlogin=os.time() -- last login time
end
)

minetest.register_on_placenode(function(pos, newnode, player, oldnode, itemstack, pointed_thing)
	if player ~= nil then
		local playername = player:get_player_name()
		local playerdata=M.player[playername]
		if playerdata ~= nil then
			playerdata.build=playerdata.build+1
		end
	end
end)

minetest.register_on_dieplayer(function(player, reason)
	print(dump2(reason))
	if player ~= nil then
		local playername = player:get_player_name()
		local playerdata=M.player[playername]
		if playerdata ~= nil then
			playerdata.death=playerdata.death+1
		end
	end
end)
minetest.register_on_chat_message(function(player, reason)
	print(dump2(reason))
	if player ~= nil then
--		local playername = player:get_player_name()
		local playerdata=M.player[player]
		if playerdata ~= nil then
			playerdata.spoke=playerdata.spoke+1
		end
	end
end)

minetest.register_on_dignode(function(pos,oldnoe,player)
	local playername = player:get_player_name()
	local playerdata=M.player[playername]
	if playerdata ~= nil then
		playerdata.dug=playerdata.dug+1
	end
end)

minetest.register_on_joinplayer(function(player)
	local playername = player:get_player_name()
	local playerdata=M.player[playername]
	if playerdata ~= nil then
		local leave=os.time()
		playerdata.logon=playerdata.logon+(leave-playerdata.lastlogin)
	end
end)

minetest.register_on_shutdown(function()
	print(dump2(M))
	xpfw.mod_storage:from_table(M)
end
)
