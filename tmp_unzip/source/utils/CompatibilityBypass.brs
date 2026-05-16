'import "pkg:/source/api/sdk.bs"
' @module CompatibilityBypass
' Centralized hub for the "Triple Lie" playback stabilization strategy.
' Isolates bypass logic from core Jellyfin source to ensure clean toggling and maintainability.
' Returns true if the Emby-Mode bypass is enabled in user settings
function CompatibilityBypass_IsEnabled() as boolean
    globalAA = GetGlobalAA()
    return chainLookupReturn(globalAA, "global.session.user.settings.`playback.embyMode`", false) = true
end function

' --- LEVEL 1: SERVER-SIDE CAP INFLATION (The "Super-Roku" Lie) ---
' Inflates device capabilities reported to the Jellyfin server to prevent transcoding.
sub CompatibilityBypass_ApplyDeviceCaps(caps as object)
    if not CompatibilityBypass_IsEnabled() then
        return
    end if
    ' Inflate bitrates to 200 Mbps
    caps.maxBitrate = 200000000
    caps.maxStatic = 200000000
end sub

function CompatibilityBypass_GetForcedLevel(codec as string, defaultLevel as string) as string
    if not CompatibilityBypass_IsEnabled() then
        return defaultLevel
    end if
    ' Force Level 6.2 for H.264 and HEVC
    lCodec = LCase(codec)
    if lCodec = "h264" or lCodec = "hevc" or lCodec = "h265"
        return "62"
    end if
    return defaultLevel
end function

' --- LEVEL 2: PLAYER-SIDE METADATA NORMALIZATION (The "Bitrate Lie") ---
' Cleans up metadata for the Roku player to bypass conservative hardware checks.
sub CompatibilityBypass_NormalizeMetadata(video as object, playbackInfo as object)
    if not CompatibilityBypass_IsEnabled() then
        return
    end if
    if not isValid(video) or not isValid(playbackInfo) then
        return
    end if
    source = playbackInfo.MediaSources[0]
    if not isValid(source) then
        return
    end if
    ' 1. Forced MKV container hint (fixes hardware demuxer rejection)
    video.container = "mkv"
    if isValid(video.content) then
        video.content.StreamFormat = "mkv"
    end if
    ' 2. Integer Bitrate Normalization (Fixes Code -5)
    ' We lie to the player that the bitrate is much lower (approx 12MB) 
    ' while taking the real bitrate and stripping decimals.
    if isValid(source.Bitrate) then
        realBitrate = source.Bitrate
    else
        realBitrate = 0
    end if
    if realBitrate > 0
        ' Force whole number division and clamp to a "safe" 12Mbps value for the player's UI/Buffer
        video.bitrate = realBitrate \ 1000
    end if
    ' 3. Transcoding Reason Cleanup
    ' Since we are forcing Direct Play, clear reasons that might confuse the OSD
    video.transcodeReasons = []
end sub

' --- LEVEL 3: FORCED STATIC HTTP STREAM (The "Transcoder Bypass") ---
' Bypasses server transcoding recommendations by forcing a direct authenticated stream.
function CompatibilityBypass_GetForcedStreamURL(itemId as string, playbackInfo as object) as string
    if not CompatibilityBypass_IsEnabled() then
        return ""
    end if
    if not isValid(playbackInfo) or not isValid(playbackInfo.MediaSources[0]) then
        return ""
    end if
    mediaSourceId = playbackInfo.MediaSources[0].Id
    if not isValid(mediaSourceId) then
        return ""
    end if
    ' Build a valid HTTP stream URL using the server's SDK
    staticParams = {
        Static: true
        MediaSourceId: mediaSourceId
    }
    ' Note: api.videos is a global namespace from sdk.bs
    streamURL = api_videos_GetStreamURL(itemId, staticParams)
    ' Force inject API Key for direct player access
    globalAA = GetGlobalAA()
    authToken = chainLookupReturn(globalAA, "global.session.user.authToken", "")
    if authToken <> ""
        streamURL += "&api_key=" + authToken
    end if
    return streamURL
end function
'//# sourceMappingURL=./CompatibilityBypass.brs.map