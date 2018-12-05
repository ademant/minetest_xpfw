
M=xpfw
M.experiences={}
M.players={}

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
	local playername=player:get_player_name()
	if M.player[playername]==nil then
		M.player[playername].walked=0 -- really walked distances
		M.player[playername].distance=0 -- including teleport etc.
		M.player[playername].logon=0 -- logon time
		M.player[playername].logstat={} -- detailed logons (if configured)
		M.player[playername].dug=0 -- count of nodes dugged
		M.player[playername].build=0 -- count of build nodes
		M.player[playername].deaths=0 -- count of deaths
		M.player[playername].killed_mobs=0 -- count of killed mobs
		M.player[playername].killed_player=0 --count of killed players
	end
	M.player[playername].lastlogin=os.clock() -- last login time
end
)
