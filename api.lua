--[[
API for using statistic via meta data
]]

local M=xpfw
if M.player == nil then
	M.player={}
end

if M.experiences == nil then
	M.experiences={}
end

local check_value=function(tab,val,def)
-- check, if <val> exist in table <tab>. If not, set tab.val = def
	if tab[val] == nil then
		tab[val] = def
	end
end

xpfw.register_attribute=function(name,data)
--[[ Register new attribute for all user with spec in data
data = {name = name of attribute,
	min = Minimum value this attribute should be,
	max = Maximum value where the attribute is cut, can be inf,
	default = default value set at initialisation or reset,
	hud = if set, attribute is shown in toggable hud display,
	moving_average_factor = Attribute is moving average with this weighting factor,
	recreation_factor = During recreation the value is reduced with this weighting factor
	}
]]
	check_value(data,"min",0)
	check_value(data,"max",math.huge)
	data.name=name
	xpfw.attributes[name]=data
	if data.hud ~= nil and name ~= "logon" then
		table.insert(xpfw.hud_intern,name)
	end
	if data.recreation_factor ~= nil then
		table.insert(xpfw.attrib_recreates,name)
	end
end

local player_addsub_attribute=function(player,attrib,val,maf)
--internal use for adding and substracting values
	local oldvalue=xpfw.player_get_attribute(player,attrib)
	local att_def=xpfw.attributes[attrib]
	local new_val = oldvalue + val
	if maf ~= nil then
		new_val=(oldvalue*maf + val)/(maf + 1)
		if val < 0 then
			new_val=math.floor(new_val)
		end
	end
	xpfw.player_set_attribute(player,attrib,new_val)
end

xpfw.player_add_attribute=function(player,attrib,val)
-- add <val> to <attrib> for <player>
-- if <val> = nil then set to max value
	local nval=val
	local att_def=xpfw.attributes[attrib]
	if val==nil then
		nval=att_def.max or 20
	end
	if att_def.moving_average_factor ~= nil then
		player_addsub_attribute(player,attrib,nval,att_def.moving_average_factor)
	else
		player_addsub_attribute(player,attrib,nval)
	end
	local playerdata=M.player[player:get_player_name()]
	playerdata.flags[attrib]=1
end

xpfw.player_sub_attribute=function(player,attrib,val)
-- add <val> to <attrib> for <player>
-- if <val> = nil then set to max value
	local nval=val
	local playername=player:get_player_name()
	local att_def=M.player[playername].attributes[attrib]
	if val==nil then
		nval=att_def.max or 20
	end
	if att_def.recreation_factor ~= nil then
		player_addsub_attribute(player,attrib,(-1)*nval,att_def.recreation_factor)
	else
		player_addsub_attribute(player,attrib,(-1)*nval)
	end
end

xpfw.player_get_attribute=function(player,attrib)
--[[
	Get stored attribute (or 0) for specified player:
	- player : ObjectRef to player
	- attrib : name of attribute
]]
	local pm=player:get_meta()
	return pm:get_float(xpfw.prefix.."_"..attrib) or 0
end

xpfw.player_set_attribute=function(player,attrib,val)
--[[
	Set stored attribute (or 0) for specified player:
	- player : ObjectRef to player
	- attrib : name of attribute
	- val : Value to store
]]
	if val == nil then return end
	if attrib == nil then return end
	if player == nil then return end
	local pm=player:get_meta()
	local playername=player:get_player_name()
	if M.player[playername] == nil then
	end
	local att_def=M.player[playername].attributes[attrib]
	pm:set_float(xpfw.prefix.."_"..attrib,math.min(att_def.max,math.max(att_def.min,val)))
	M.player[playername].flags[attrib]=1
end

xpfw.player_init_attributes=function(player)
	local pm=player:get_meta()
	local playername=player:get_player_name()
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

xpfw.player_set_attribute_to_nil=function(player,attrib)
--[[
	Delete attribute for player (set to nil):
	- player : ObjectRef to player
	- attrib : name of attribute
]]
	local pm=player:get_meta()
	local playername=player:get_player_name()
	local att_def=M.player[playername].attributes[attrib]
	pm:set_float(xpfw.prefix.."_"..attrib,-1)
end

xpfw.player_remove_flag=function(player,attrib)
	-- internal usage to check if attribute was changed since last abm call
	M.player[playername].flags[attrib]=nil	
end

xpfw.player_ping_attribute=function(player,attrib)
--[[
	"Ping" an attribute for player:
	- player : ObjectRef to player
	- attrib : name of attribute
used for moving averaged attributes. Get max value from definition and add to attribute, which calcs
a moving average.
]]
	local playername=player:get_player_name()
	local att_def=M.player[playername].attributes[attrib]
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

xpfw.player_reset_single_attribute=function(player,attribute)
	if attribute == nil then
		return
	end
	local att_def=xpfw.attributes[attribute]
	if att_def ~= nil then
		local setval=att_def.min or 0
		if att_def.default ~= nil then
			setval= att_def.default
		end
		xpfw.player_set_attribute(player,att_def.name,setval)
	end
end

xpfw.player_reset_attributes=function(player,attribute)
	if attribute==nil then
		for i,att_def in pairs(xpfw.attributes) do
			xpfw.player_reset_single_attribute(player,i)
		end
	else
		xpfw.player_reset_single_attribute(player,attribute)
	end
end

xpfw.player_hud_toggle=function(name)
	-- toggle hud display for player with string <name>
	local player=minetest.get_player_by_name(name)
	local playerdata=M.player[name]
	if playerdata==nil then
		return
	end
	if playerdata.hidx==nil then
		xpfw.player_add_hud(player)
	else
		xpfw.player_remove_hud(player)
	end
end
xpfw.player_add_hud=function(player)
	local playerdata=M.player[player:get_player_name()]
	if playerdata==nil then
		return
	end
	if playerdata.hud == nil then
		playerdata.hud=1
	end
	playerdata.hidx=player:hud_add({
		hud_elem_type = "text",
		position = {x=1,y=1},
		size = "",
		text = "",
		alignment = {x=-1,y=-1},
	})
end
xpfw.player_remove_hud=function(player)
	local playerdata=M.player[player:get_player_name()]
	if playerdata==nil then
		return
	end
	if playerdata.hidx ~= nil then
		player:hud_remove(playerdata.hidx)
		playerdata.hidx = nil
		playerdata.hud=nil
	end
end

xpfw.save_player_data=function(player)
	local playerdata=M.player[player:get_player_name()]
	for i,tdef in pairs(playerdata.attributes) do
		if tdef.moving_average_factor ~= nil then
			xpfw.mod_storage:set_int(player:get_player_name().."_"..i.."_maf",tdef.moving_average_factor)
		end
		if tdef.recreation_factor ~= nil then
			xpfw.mod_storage:set_int(player:get_player_name().."_"..i.."_rf",tdef.recreation_factor)
		end
	end
end

