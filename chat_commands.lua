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
