-- core/audio/sfx_list.lua

local Sound = require("core.audio.sound")

local SfxList = {}

SfxList.move = Sound.new(
    "move",
    "assets/audio/sfx/menu_move.wav",
    "static",
    false
)

SfxList.accept = Sound.new(
    "accept",
    "assets/audio/sfx/menu_accept.wav",
    "static",
    false
)

return SfxList
