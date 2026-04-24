-- core/audio/audio_manager.lua

local Settings = require("core.settings")
local MusicList = require("core.audio.music_list")

local AudioManager = {
    music = {},
    currentMusic = nil
}

local function safeNewSource(path, sourceType)
    if not love.filesystem.getInfo(path) then
        print("SOURCE MUSIC NOT FOUND: " .. path)
        return nil
    end

    return love.audio.newSource(path, sourceType)
end

local function applyMusicVolume(source)
    if not source then
        return
    end

    source:setVolume(Settings.masterVolume * Settings.musicVolume)
end

function AudioManager.load()
    for _, musicData in pairs(MusicList) do
        local source = safeNewSource(musicData.path, musicData.sourceType)
        AudioManager.music[musicData.id] = source

        if source and musicData.looping then
            source:setLooping(true)
        end
    end

    for _, source in pairs(AudioManager.music) do
        applyMusicVolume(source)
    end
end

function AudioManager.refreshVolumes()
    for _, source in pairs(AudioManager.music) do
        applyMusicVolume(source)
    end
end

function AudioManager.playMusic(soundData)
    if not soundData or not soundData.id then
        return
    end

    local nextMusic = AudioManager.music[soundData.id]
    if not nextMusic then
        return
    end

    if AudioManager.currentMusic == nextMusic then
        if not nextMusic:isPlaying() then
            nextMusic:play()
        end
        return
    end

    if AudioManager.currentMusic then
        AudioManager.currentMusic:stop()
    end

    AudioManager.currentMusic = nextMusic
    AudioManager.refreshVolumes()
    AudioManager.currentMusic:play()
end

function AudioManager.stopMusic()
    if AudioManager.currentMusic then
        AudioManager.currentMusic:stop()
        AudioManager.currentMusic = nil
    end
end

return AudioManager
