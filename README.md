[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
# Minetest Game mod: XPFW

See license.txt for license information.

Main repository:

https://notabug.org/ademant/minetest_xpfw.git

Mirrors:

https://gitlab.com/ademant/minetest_xpfw.git

https://github.com/ademant/minetest_xpfw.git

## Short description
XPFW provide an API for storing values relevant for experience mechanism into player metadata (Identified with prefix "XPFW_"). It also stores several statistic values during playtime:
- Walked distances calculated out of velocity (important: teleporting does not influence this value)
- accumulated distance out of comparing with last known position (important: teleporting is included in this value)
- whole playtime on the server
- amount of dug nodes
- amount of build nodes
- amount of crafted items
- amount of occured deahts
- amount of text messages
- amount of logins

For several amounts also a kind of speed is calculated, like walking speed or crafting speed.

## Chat Commands
Following chat commands are available:

/xpfw 
	prints stored values of XPFW in the chat window
	
/xphud 
	toggle the visible statistics in players hud on/off
	
/xpreset
	set all values to default
	
/xpset <variable> <value>
	need xpfwset privilege
	Set variable of user to new value
	
## Usage
Usage (roughly), for Details see api.lua:

- xpfw.register_attribute(name,data) to register new attribute <name>
- xpfw.player_get_attribute(player,name) Get stored value of attribute <name> for ObjectRef player
- xpfw.player_set_attribute(player,name, value) Set attribute <name> for ObjectRef player to <value>
- xpfw.player_ping_attribute(player,name) "Ping" attribute: Get max value which is defined for attribute and add to attribute. For an attribute, which is defined as moving average attribute this pinging increase the value. High frequency of pinging lead to faster increase, e.g. by pinging a digging attribute you get kind of digging speed, which can be used for an exhaustion mechanism.
- xpfw.player_add/sub_attribute(player,name,diff) Adds or substract <diff> to attribute <name> of for ObjectRef player

## Authors of source code

ademant (MIT)

## Authors of media (textures)
  
Created by ademant (CC BY 3.0):
