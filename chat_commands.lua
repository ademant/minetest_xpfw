minetest.register_privilege("xpfwset", {description="Set experience level"})

minetest.register_chatcommand("xpset", {
	privs = {
		xpfwset = true
	},
	params = "<name>",
	description = "Set the statistics/experience for yourself",
	func = function(name, param)
		print(name,param)
		local xp= string.split(param, " ")
		print(dump2(xp))
		player=minetest.get_player_by_name(name)
		if xpfw.player_get_attribute(player,xp[1]) ~= nil then
			xpfw.player_set_attribute(player,xp[1],xp[2])
			minetest.chat_send_player(name, "Attribut "..xp[1].." set to "..xp[2])
		else
			minetest.chat_send_player(name, "Attribut "..xp[1].." not fount")
		end
	end
})

minetest.register_chatcommand("xpfw", {
	privs = {
		server = true
	},
	params = "<name>",
	description = "Get the statistics for the given player or yourself",
	func = function(name, param)
		if not param or param == "" then
			param = name
		end
		minetest.chat_send_player(name, param)
		local player = ""
		for att_def in pairs(xpfw.attributes) do
			player=player.."; "..att_def..": "..xpfw.player_get_attribute(minetest.get_player_by_name(name),att_def)
		end

		minetest.chat_send_player(name, dump(player))
	end
})
