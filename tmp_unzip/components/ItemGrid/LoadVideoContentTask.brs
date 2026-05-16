'import "pkg:/source/api/baserequest.bs"
'import "pkg:/source/api/Image.bs"
'import "pkg:/source/api/Items.bs"
'import "pkg:/source/api/userauth.bs"
'import "pkg:/source/enums/ImageType.bs"
'import "pkg:/source/enums/ItemType.bs"
'import "pkg:/source/enums/MediaSegmentType.bs"
'import "pkg:/source/enums/PlaybackMethod.bs"
'import "pkg:/source/enums/String.bs"
'import "pkg:/source/enums/SubtitleSelection.bs"
'import "pkg:/source/utils/CompatibilityBypass.bs"
'import "pkg:/source/utils/deviceCapabilities.bs"
'import "pkg:/source/utils/misc.bs"

sub init()
    m.top.filter = "All"
    m.top.sortField = "SortName"
    m.top.functionName = "loadItems"
end sub

sub loadItems()
    ' Reset intro tracker in case task gets reused
    m.top.isIntro = false
    ' Only show preroll once per queue
    if m.global.queueManager.callFunc("isPrerollActive")
        ' Prerolls not allowed if we're resuming video
        if m.global.queueManager.callFunc("getCurrentItem").startingPoint = 0
            preRoll = GetIntroVideos(m.top.itemId)
            if isValid(preRoll) and preRoll.TotalRecordCount > 0 and isValid(preRoll.items[0])
                ' If an error is thrown in the Intros plugin, instead of passing the error they pass the entire rick roll music video.
                ' Bypass the music video and treat it as an error message
                if lcase(preRoll.items[0].name) <> "rick roll'd"
                    m.global.queueManager.callFunc("push", m.global.queueManager.callFunc("getCurrentItem"))
                    m.top.itemId = preRoll.items[0].id
                    m.global.queueManager.callFunc("setPrerollStatus", false)
                    m.top.isIntro = true
                end if
            end if
        end if
    end if
    if m.top.selectedAudioStreamIndex = 0
        currentItem = m.global.queueManager.callFunc("getCurrentItem")
        if isChainValid(currentItem, "json")
            m.top.selectedAudioStreamIndex = FindPreferredAudioStream(currentItem.json.MediaStreams)
        end if
    end if
    id = m.top.itemId
    mediaSourceId = invalid
    audio_stream_idx = m.top.selectedAudioStreamIndex
    m.top.content = [
        LoadItems_VideoPlayer(id, mediaSourceId, audio_stream_idx)
    ]
end sub

function LoadItems_VideoPlayer(id as string, mediaSourceId = invalid as dynamic, audio_stream_idx = 1 as integer) as dynamic
    video = {}
    video.id = id
    video.content = createObject("RoSGNode", "ContentNode")
    LoadItems_AddVideoContent(video, mediaSourceId, audio_stream_idx)
    if video.content = invalid
        return invalid
    end if
    return video
end function

sub LoadItems_AddVideoContent(video as object, mediaSourceId as dynamic, audio_stream_idx = 1 as integer)
    meta = ItemMetaData(video.id)
    subtitle_idx = m.top.selectedSubtitleIndex
    if not isValid(meta)
        video.errorMsg = "Error loading metadata"
        video.content = invalid
        return
    end if
    videotype = LCase(meta.type)
    ' Check for any Live TV streams or Recordings coming from other places other than the TV Guide
    if videotype = "recording" or (isValid(meta.json) and isValid(meta.json.ChannelId))
        if isValid(meta.json.EpisodeTitle)
            meta.title = meta.json.EpisodeTitle
        else if isValid(meta.json.Name)
            meta.title = meta.json.Name
        end if
        meta.live = true
        if LCase(meta.json.type) = "program"
            video.id = meta.json.ChannelId
        else
            video.id = meta.json.id
        end if
    end if
    video.overview = meta.json.overview
    if not isValid(video.overview) and isValid(meta.json.CurrentProgram)
        ' Live TV is under CurrentProgram.Overview
        video.overview = meta.json.CurrentProgram.overview
    end if
    video.trickplay = meta.json.Trickplay
    video.chapters = meta.json.Chapters
    video.content.title = meta.title
    video.showID = meta.showID
    logoLookupID = video.id
    if isStringEqual(videotype, "tvchannel") and isChainValid(meta, "json.CurrentProgram")
        video.content.contenttype = "episode"
    end if
    if isStringEqual(videotype, "episode") or isStringEqual(videotype, "series")
        video.content.contenttype = "episode"
        if isValid(meta.json.ParentIndexNumber)
            video.content.TitleSeason = (bslib_toString(tr("Season")) + " " + bslib_toString(meta.json.ParentIndexNumber))
        end if
        if isValid(meta.json.IndexNumber)
            video.content.SecondaryTitle = (bslib_toString(tr("Episode")) + " " + bslib_toString(meta.json.IndexNumber))
            if isValid(meta.json.IndexNumberEnd)
                video.content.SecondaryTitle += ("-" + bslib_toString(meta.json.IndexNumberEnd))
            end if
        end if
        video.seasonNumber = meta.json.ParentIndexNumber
        video.episodeNumber = meta.json.IndexNumber
        video.episodeNumberEnd = meta.json.IndexNumberEnd
        if isValid(meta.showID)
            logoLookupID = meta.showID
        end if
    end if
    video.mediaSegments = {}
    if isValidAndNotEmpty(meta.json.MediaSources)
        if isValid(meta.json.MediaSources[0].HasSegments)
            if meta.json.MediaSources[0].HasSegments
                video.mediaSegments = api_MediaSegments_Get(video.id)
            end if
        end if
    end if
    hasOutroSegment = false
    if isValidAndNotEmpty(video.mediaSegments)
        for i = 0 to video.mediaSegments.TotalRecordCount - 1
            mediaSegment = video.mediaSegments.items[i]
            if isStringEqual(mediaSegment.type, "outro")
                hasOutroSegment = true
                exit for
            end if
        end for
    end if
    ' If an episode does not have an outro segment, create a fake one at the user's requested timestamp
    if video.content.contenttype = 4
        if not hasOutroSegment
            if isValid(meta.json.RunTimeTicks)
                if m.global.session.user.settings["playback.nextupbuttonseconds"].ToInt() <> 0
                    outroSegment = {
                        EndTicks: meta.json.RunTimeTicks
                        Id: ""
                        ItemId: ""
                        StartTicks: meta.json.RunTimeTicks - (m.global.session.user.settings["playback.nextupbuttonseconds"].ToInt() * 10000000)
                        Type: "Outro"
                    }
                    if isValidAndNotEmpty(video.mediaSegments.LookupCI("items"))
                        video.mediaSegments.Items.push(outroSegment)
                        video.mediaSegments.TotalRecordCount++
                    else
                        video.mediaSegments = {
                            Items: [
                                outroSegment
                            ]
                            StartIndex: 0
                            TotalRecordCount: 1
                        }
                    end if
                end if
            end if
        end if
    end if
    if isValid(meta.json.extratype)
        if LCase(meta.json.extratype) = "trailer"
            if isValidAndNotEmpty(meta.json.parentlogoitemid)
                logoLookupID = meta.json.parentlogoitemid
                video.extraType = "trailer"
            end if
        end if
    end if
    if isStringEqual(videotype, "tvchannel") then
        logoSource = "Primary"
    else
        logoSource = "Logo"
    end if ' TV Channel logos are stored under '/primary' instead of '/logo'
    logoImageExists = api_items_HeadImageURLByName(logoLookupID, logoSource)
    if logoImageExists
        video.logoImage = api_items_GetImageURL(logoLookupID, logoSource, 0, {
            "format": "Png"
            "maxHeight": 65
            "maxWidth": 300
            "quality": "90"
        })
    end if
    additionalParts = api_videos_GetAdditionalParts(video.id)
    additionalPartsCount = 0
    if isValid(additionalParts) and additionalParts.Items.Count() > 0
        additionalPartsCount = additionalParts.Items.Count()
        for i = 0 to additionalPartsCount - 1
            m.global.queueManager.callFunc("push", additionalParts.Items[i])
        end for
    end if
    if isValid(video.showID)
        if m.global.session.user.Configuration.EnableNextEpisodeAutoPlay
            episodeQueueLimit = chainLookupReturn(m.global.session, "user.settings.episodeQueueLimit", "50")
            episodeQueueLimit = episodeQueueLimit.ToInt()
            addNextEpisodesToQueue(video.showID, additionalPartsCount, episodeQueueLimit)
        else
            gotoNextEpisodeAfterCurrentEnds = chainLookupReturn(m.global.session, "user.settings.`playback.showNextUpAfterFinish`", false)
            if gotoNextEpisodeAfterCurrentEnds
                addEpisodeToShowAtFinish(video.showID)
            end if
        end if
    end if
    playbackPosition = 0!
    currentItem = m.global.queueManager.callFunc("getCurrentItem")
    if isValid(currentItem) and isValid(currentItem.startingPoint)
        playbackPosition = currentItem.startingPoint
    else if isChainValid(currentItem, "json.UserData.PlaybackPositionTicks")
        playbackPosition = currentItem.json.UserData.PlaybackPositionTicks
    end if
    ' PlayStart requires the time to be in seconds
    video.content.PlayStart = int(playbackPosition / 10000000)
    if not isValid(mediaSourceId) then
        mediaSourceId = video.id
    end if
    if meta.live then
        mediaSourceId = ""
    end if
    m.playbackInfo = ItemPostPlaybackInfo(video.id, mediaSourceId, audio_stream_idx, subtitle_idx, playbackPosition)
    if not isValid(m.playbackInfo)
        video.errorMsg = "Error loading playback info"
        video.content = invalid
        return
    end if
    ' Collect Roku hardware compatibility warnings from the source video stream.
    ' These are stored on the video object and displayed by VideoPlayerView only
    ' when the content is being direct-played (server transcoding handles these itself).
    if isValid(m.playbackInfo.MediaSources) and isValid(m.playbackInfo.MediaSources[0])
        video.compatibilityWarnings = checkRokuVideoCompatibility(m.playbackInfo.MediaSources[0].MediaStreams)
        ' --- Path length check ---
        ' Windows MAX_PATH is 260 characters. If the server is Windows-hosted and
        ' the file path exceeds this limit, the server may fail to open/transcode
        ' the file even though the item appears in the library.
        filePath = m.playbackInfo.MediaSources[0].LookupCI("Path")
        if isValid(filePath) and filePath.Len() > 260
            video.compatibilityWarnings.push(tr("File path too long for server to access.") + " (" + filePath.Len().ToStr() + " " + tr("characters") + ")")
        end if
        ' --- Triple Lie: normalize metadata AFTER warnings are captured ---
        ' This ensures the user still gets a meaningful error if playback fails,
        ' while giving the player the best chance of succeeding on first try.
        if CompatibilityBypass_IsEnabled()
            traceStep("PLAY_TRACE", "Emby-Mode: Executing modular bypass normalization")
            CompatibilityBypass_NormalizeMetadata(video, m.playbackInfo)
        end if
    else
        video.compatibilityWarnings = []
    end if
    ' If forceTranscode setting is enabled, but we haven't set the transcode codec yet, set it now and update Playback Info
    if isStringEqual("forceTranscodeDisableRemux", chainLookupReturn(m.global.session, "user.settings.`playback.media.forceTranscode`", "playNormally"))
        if isStringEqual(m.global.queueManager.callFunc("getTranscodeCodec"), "")
            for i = 0 to m.playbackInfo.MediaSources[0].MediaStreams.Count() - 1
                if m.playbackInfo.MediaSources[0].MediaStreams[i].Type = "Video"
                    m.global.queueManager.callFunc("setForceTranscode", "forceTranscodeDisableRemux", m.playbackInfo.MediaSources[0].MediaStreams[i].Codec)
                    exit for
                end if
            end for
            m.playbackInfo = ItemPostPlaybackInfo(video.id, mediaSourceId, audio_stream_idx, subtitle_idx, playbackPosition)
            if not isValid(m.playbackInfo)
                video.errorMsg = "Error loading playback info"
                video.content = invalid
                return
            end if
        end if
    end if
    addSubtitlesToVideo(video, meta)
    ' Enable default subtitle track
    if subtitle_idx = -2
        defaultSubtitleIndex = defaultSubtitleTrackFromVid(video.id)
        if defaultSubtitleIndex <> -1
            video.SelectedSubtitle = defaultSubtitleIndex
            subtitle_idx = defaultSubtitleIndex
            m.playbackInfo = ItemPostPlaybackInfo(video.id, mediaSourceId, audio_stream_idx, subtitle_idx, playbackPosition)
            if not isValid(m.playbackInfo)
                video.errorMsg = "Error loading playback info"
                video.content = invalid
                return
            end if
            addSubtitlesToVideo(video, meta)
        else
            video.SelectedSubtitle = subtitle_idx
        end if
    else
        video.SelectedSubtitle = subtitle_idx
    end if
    video.videoId = video.id
    video.mediaSourceId = mediaSourceId
    video.audioIndex = audio_stream_idx
    video.PlaySessionId = m.playbackInfo.PlaySessionId
    if meta.live
        video.content.live = true
        video.content.StreamFormat = "hls"
    end if
    video.container = getContainerType(meta)
    if not isValid(m.playbackInfo.MediaSources[0])
        m.playbackInfo = meta.json
    end if
    addAudioStreamsToVideo(video)
    if meta.live
        video.transcodeParams = {
            "MediaSourceId": m.playbackInfo.MediaSources[0].Id
            "LiveStreamId": m.playbackInfo.MediaSources[0].LiveStreamId
            "PlaySessionId": video.PlaySessionId
        }
    end if
    ' 'TODO: allow user selection of subtitle track before playback initiated, for now set to no subtitles
    video.directPlaySupported = m.playbackInfo.MediaSources[0].SupportsDirectPlay
    ' For h264/hevc video, Roku spec states that it supports specfic encoding levels
    ' The device can decode content with a Higher Encoding level but may play it back with certain
    ' artifacts. If the user preference is set, and the only reason the server says we need to
    ' transcode is that the Encoding Level is not supported, then try to direct play but silently
    ' fall back to the transcode if that fails.
    if m.playbackInfo.MediaSources[0].MediaStreams.Count() > 0 and meta.live = false
        tryDirectPlay = m.global.session.user.settings["playback.tryDirect.h264ProfileLevel"] and m.playbackInfo.MediaSources[0].MediaStreams[0].codec = "h264"
        tryDirectPlay = tryDirectPlay or (m.global.session.user.settings["playback.tryDirect.hevcProfileLevel"] and m.playbackInfo.MediaSources[0].MediaStreams[0].codec = "hevc")
        if tryDirectPlay and isValid(m.playbackInfo.MediaSources[0].TranscodingUrl)
            transcodingReasons = getTranscodeReasons(m.playbackInfo.MediaSources[0].TranscodingUrl)
            if transcodingReasons.Count() = 1 and transcodingReasons[0] = "VideoLevelNotSupported"
                video.directPlaySupported = true
                video.transcodeAvailable = true
            end if
        end if
    end if
    ' Direct play video
    if video.directPlaySupported
        video.isTranscoded = false
        addVideoContentURL(video, mediaSourceId, audio_stream_idx)
        ' Restore StreamFormat to help Roku identify the container (fixes Code -5)
        if isValid(video.container) and video.container <> ""
            video.content.StreamFormat = video.container
        end if
        setCertificateAuthority(video.content)
        video.content = authRequest(video.content)
        return
    end if
    ' Stream media From URL
    if isHTTPStream()
        video.isTranscoded = false
        video.content.url = m.playbackInfo.MediaSources[0].Path
        ' Also set StreamFormat here for consistency
        if isValid(video.container) and video.container <> ""
            video.content.StreamFormat = video.container
        end if
        setCertificateAuthority(video.content)
        return
    end if
    ' Transcode media
    if m.playbackInfo.MediaSources[0].TranscodingUrl = invalid
        ' If server does not provide a transcode URL, display a message to the user
        m.global.sceneManager.callFunc("userMessage", tr("Error Getting Playback Information"), tr("An error was encountered while playing this item. Server did not provide required transcoding data."))
        video.errorMsg = "Error getting playback information"
        video.content = invalid
        return
    end if
    ' --- Triple Lie: Bypass transcoder if bypass is on ---
    if CompatibilityBypass_IsEnabled()
        forcedURL = CompatibilityBypass_GetForcedStreamURL(video.id, m.playbackInfo)
        if forcedURL <> ""
            traceStep("PLAY_TRACE", "Emby-Mode: Bypassing server recommendation. Forcing Static HTTP Stream.")
            video.isTranscoded = false
            video.content.url = forcedURL
            ' Standard setup
            if isValid(video.container) and video.container <> "" then
                video.content.StreamFormat = LCase(video.container)
            end if
            setCertificateAuthority(video.content)
            video.content = authRequest(video.content)
            return
        end if
    end if
    ' --- Standard Direct play video ---
    if video.directPlaySupported
        video.isTranscoded = false
        addVideoContentURL(video, mediaSourceId, audio_stream_idx)
        ' Restore StreamFormat to help Roku identify the container (fixes Code -5)
        if isValid(video.container) and video.container <> ""
            video.content.StreamFormat = video.container
        end if
        setCertificateAuthority(video.content)
        video.content = authRequest(video.content)
        return
    end if
    ' --- Standard Stream media From URL ---
    if isHTTPStream()
        video.isTranscoded = false
        video.content.url = m.playbackInfo.MediaSources[0].Path
        ' Also set StreamFormat here for consistency
        if isValid(video.container) and video.container <> ""
            video.content.StreamFormat = video.container
        end if
        setCertificateAuthority(video.content)
        return
    end if
    ' --- Standard Transcode media ---
    if m.playbackInfo.MediaSources[0].TranscodingUrl = invalid
        ' If server does not provide a transcode URL, display a message to the user
        ' Note: VideoPlayerView will show the error via showPlaybackErrorDialog if content is invalid
        video.errorMsg = "Error getting playback information"
        video.content = invalid
        return
    end if
    ' If transcoding...
    if chainLookupReturn(m.global, "session.user.settings.`playback.subs.burnin`", true) and meta.live = false
        m.playbackInfo = ItemPostPlaybackInfo(video.id, mediaSourceId, audio_stream_idx, subtitle_idx, playbackPosition, {
            emptySubtitleProfiles: true
        })
        ' Re-posting playback info will generate a new PlaysessionId
        video.PlaySessionId = m.playbackInfo.PlaySessionId
    end if
    ' Get transcoding reason
    video.transcodeReasons = getTranscodeReasons(m.playbackInfo.MediaSources[0].TranscodingUrl)
    video.content.url = buildURL(m.playbackInfo.MediaSources[0].TranscodingUrl)
    video.isTranscoded = true
    setCertificateAuthority(video.content)
    video.content = authRequest(video.content)
end sub

function isHTTPStream() as boolean
    if not m.playbackInfo.MediaSources[0].LookupCI("isremote") then
        return false
    end if
    if not isStringEqual(m.playbackInfo.MediaSources[0].LookupCI("VideoType"), "VideoFile") then
        return false
    end if
    return true
end function

' defaultSubtitleTrackFromVid: Identifies the default subtitle track given video id
'
' @param {dynamic} videoID - id of video user is playing
' @return {integer} indicating the default track's server-side index. Defaults to {SubtitleSelection.NONE} is one is not found
function defaultSubtitleTrackFromVid(videoID) as integer
    if m.global.session.user.configuration.SubtitleMode = "None"
        return -1 ' No subtitles desired: return none
    end if
    meta = ItemMetaData(videoID)
    if not isValid(meta) then
        return -1
    end if
    if not isValid(meta.json) then
        return -1
    end if
    if not isValidAndNotEmpty(meta.json.mediaSources) then
        return -1
    end if
    if not isValidAndNotEmpty(meta.json.MediaSources[0].MediaStreams) then
        return -1
    end if
    subtitles = sortSubtitles(meta.json.MediaSources[0].MediaStreams)
    selectedAudioLanguage = ""
    audioMediaStream = meta.json.MediaSources[0].MediaStreams[m.top.selectedAudioStreamIndex]
    ' Ensure audio media stream is valid before using language property
    if isValid(audioMediaStream)
        selectedAudioLanguage = (function(audioMediaStream)
                __bsConsequent = audioMediaStream.Language
                if __bsConsequent <> invalid then
                    return __bsConsequent
                else
                    return ""
                end if
            end function)(audioMediaStream)
    end if
    defaultTextSubs = defaultSubtitleTrack(subtitles["text"], selectedAudioLanguage, true) ' Find correct subtitle track (forced text)
    if defaultTextSubs <> -1
        return defaultTextSubs
    end if
    if not m.global.session.user.settings["playback.subs.onlytext"]
        return defaultSubtitleTrack(subtitles["all"], selectedAudioLanguage) ' if no appropriate text subs exist, allow non-text
    end if
    return -1
end function

' defaultSubtitleTrack:
'
' @param {dynamic} sortedSubtitles - array of subtitles sorted by type and language
' @param {string} selectedAudioLanguage - language for selected audio track
' @param {boolean} [requireText=false] - indicates if only text subtitles should be considered
' @return {integer} indicating the default track's server-side index. Defaults to {SubtitleSelection.NONE} is one is not found
function defaultSubtitleTrack(sortedSubtitles, selectedAudioLanguage as string, requireText = false as boolean) as integer
    userConfig = m.global.session.user.configuration
    if isValid(userConfig.SubtitleMode) then
        subtitleMode = LCase(userConfig.SubtitleMode)
    else
        subtitleMode = ""
    end if
    allowSmartMode = false
    ' Only evaluate selected audio language if we have a value
    if selectedAudioLanguage <> ""
        allowSmartMode = selectedAudioLanguage <> userConfig.SubtitleLanguagePreference
    end if
    for each item in sortedSubtitles
        ' Only auto-select subtitle if language matches SubtitleLanguagePreference
        languageMatch = true
        if userConfig.SubtitleLanguagePreference <> ""
            languageMatch = (userConfig.SubtitleLanguagePreference = item.Track.Language)
        end if
        ' Ensure textuality of subtitle matches preferenced passed as arg
        matchTextReq = ((requireText and item.IsTextSubtitleStream) or not requireText)
        if languageMatch and matchTextReq
            if subtitleMode = "default" and (item.isForced or item.IsDefault)
                ' Return first forced or default subtitle track
                return item.Index
            else if subtitleMode = "always"
                ' Return the first found subtitle track
                return item.Index
            else if subtitleMode = "onlyforced" and item.IsForced
                ' Return first forced subtitle track
                return item.Index
            else if subtitleMode = "smart" and allowSmartMode
                ' Return the first found subtitle track
                return item.Index
            end if
        end if
    end for
    ' User has chosed smart subtitle mode
    ' We already attempted to load subtitles in preferred language, but none were found.
    ' Fall back to default behaviour while ignoring preferredlanguage
    if subtitleMode = "smart" and allowSmartMode
        for each item in sortedSubtitles
            ' Ensure textuality of subtitle matches preferenced passed as arg
            matchTextReq = ((requireText and item.IsTextSubtitleStream) or not requireText)
            if matchTextReq
                if item.isForced or item.IsDefault
                    ' Return first forced or default subtitle track
                    return item.Index
                end if
            end if
        end for
    end if
    return -1 ' Keep current default behavior of "None", if no correct subtitle is identified
end function

sub addVideoContentURL(video, mediaSourceId, audio_stream_idx)
    protocol = LCase(m.playbackInfo.MediaSources[0].Protocol)
    if protocol <> "file"
        uri = ParsedUrl(m.playbackInfo.MediaSources[0].Path)
        if isLocalhost(uri.host)
            ' if the domain of the URI is local to the server,
            ' create a new URI by appending the received path to the server URL
            ' later we will substitute the users provided URL for this case
            video.content.url = buildURL(uri.path)
        else
            video.content.url = m.playbackInfo.MediaSources[0].Path
        end if
    else
        params = {
            "Static": "true"
            "Container": video.container
            "PlaySessionId": video.PlaySessionId
            "AudioStreamIndex": audio_stream_idx
        }
        if mediaSourceId <> ""
            params.MediaSourceId = mediaSourceId
        end if
        video.content.url = buildURL(Substitute("Videos/{0}/stream", video.id), params)
    end if
end sub

' addAudioStreamsToVideo: Add audio stream data to video
'
' @param {dynamic} video component to add fullAudioData to
sub addAudioStreamsToVideo(video)
    audioStreams = []
    mediaStreams = m.playbackInfo.MediaSources[0].MediaStreams
    audioStreamCount = 1
    for i = 0 to mediaStreams.Count() - 1
        if LCase(mediaStreams[i].Type) = "audio"
            mediaStreams[i].addreplace("RokuTrackName", ("#uniq:" + bslib_toString((function(i, mediaStreams)
                    __bsConsequent = mediaStreams[i].LookupCI("Title")
                    if __bsConsequent <> invalid then
                        return __bsConsequent
                    else
                        return ""
                    end if
                end function)(i, mediaStreams)) + "(" + bslib_toString(audioStreamCount) + ")"))
            audioStreams.push(mediaStreams[i])
            audioStreamCount++
        end if
    end for
    video.fullAudioData = audioStreams
end sub

sub addSubtitlesToVideo(video, meta)
    if not isValid(meta) then
        return
    end if
    if not isValid(meta.id) then
        return
    end if
    if not isValid(m.playbackInfo) then
        return
    end if
    if not isValidAndNotEmpty(m.playbackInfo.MediaSources) then
        return
    end if
    if not isValid(m.playbackInfo.MediaSources[0].MediaStreams) then
        return
    end if
    subtitles = sortSubtitles(m.playbackInfo.MediaSources[0].MediaStreams)
    safesubs = subtitles["all"]
    subtitleTracks = []
    if m.global.session.user.settings["playback.subs.onlytext"] = true
        safesubs = subtitles["text"]
    end if
    for each subtitle in safesubs
        subtitleTracks.push(subtitle.track)
    end for
    video.content.SubtitleTracks = subtitleTracks
    video.fullSubtitleData = safesubs
end sub

'
' Extract array of Transcode Reasons from the content URL
' @returns Array of Strings
function getTranscodeReasons(url as string) as object
    regex = CreateObject("roRegex", "&TranscodeReasons=([^&]*)", "")
    match = regex.Match(url)
    if match.count() > 1
        return match[1].Split(",")
    end if
    return []
end function

function directPlaySupported(meta as object) as boolean
    devinfo = CreateObject("roDeviceInfo")
    if isValid(meta.json.MediaSources[0]) and meta.json.MediaSources[0].SupportsDirectPlay = false
        return false
    end if
    if meta.json.MediaStreams[0] = invalid
        return false
    end if
    streamInfo = {
        Codec: meta.json.MediaStreams[0].codec
    }
    if isValid(meta.json.MediaStreams[0].Profile) and meta.json.MediaStreams[0].Profile.len() > 0
        streamInfo.Profile = LCase(meta.json.MediaStreams[0].Profile)
    end if
    if isValid(meta.json.MediaSources[0].container) and meta.json.MediaSources[0].container.len() > 0
        'CanDecodeVideo() requires the .container to be format: “mp4”, “hls”, “mkv”, “ism”, “dash”, “ts” if its to direct stream
        if meta.json.MediaSources[0].container = "mov"
            streamInfo.Container = "mp4"
        else
            streamInfo.Container = meta.json.MediaSources[0].container
        end if
    end if
    decodeResult = devinfo.CanDecodeVideo(streamInfo)
    return decodeResult <> invalid and decodeResult.result
end function

function getContainerType(meta as object) as string
    ' Determine the file type of the video file source
    if meta.json.mediaSources = invalid then
        return ""
    end if
    container = meta.json.mediaSources[0].container
    if container = invalid
        container = ""
    else if container = "m4v" or container = "mov"
        container = "mp4"
    end if
    return container
end function

' Add next episodes to the playback queue
sub addNextEpisodesToQueue(showID, additionalPartsCount as integer, queueLimit as integer)
    ' Don't queue next episodes if we already have a playback queue
    maxQueueCount = additionalPartsCount + 1
    if m.top.isIntro
        maxQueueCount = 2
    end if
    if m.global.queueManager.callFunc("getCount") > maxQueueCount then
        return
    end if
    videoID = m.top.itemId
    ' If first item is an intro video, use the next item in the queue
    if m.top.isIntro
        currentVideo = m.global.queueManager.callFunc("getItemByIndex", 1)
        if isValid(currentVideo) and isValid(currentVideo.id)
            videoID = currentVideo.id
            ' Override showID value since it's for the intro video
            meta = ItemMetaData(videoID)
            if isValid(meta)
                showID = meta.showID
            end if
        end if
    end if
    url = Substitute("Shows/{0}/Episodes", showID)
    urlParams = {
        "UserId": m.global.session.user.id
    }
    urlParams.Append({
        "StartItemId": videoID
    })
    urlParams.Append({
        "Limit": queueLimit + 1
    })
    urlParams.Append({
        "isMissing": false
    })
    resp = APIRequest(url, urlParams)
    data = getJson(resp)
    if isValid(data) and data.Items.Count() > 1
        for i = 1 to data.Items.Count() - 1
            m.global.queueManager.callFunc("push", data.Items[i])
        end for
    end if
end sub

' Add episode to show at finish of current episode
sub addEpisodeToShowAtFinish(showID)
    videoID = m.top.itemId
    ' If first item is an intro video, use the next item in the queue
    if m.top.isIntro
        currentVideo = m.global.queueManager.callFunc("getItemByIndex", 1)
        if isValid(currentVideo) and isValid(currentVideo.id)
            videoID = currentVideo.id
            ' Override showID value since it's for the intro video
            meta = ItemMetaData(videoID)
            if isValid(meta)
                showID = meta.showID
            end if
        end if
    end if
    url = Substitute("Shows/{0}/Episodes", showID)
    urlParams = {
        "UserId": m.global.session.user.id
    }
    urlParams.Append({
        "StartItemId": videoID
    })
    urlParams.Append({
        "Limit": 2
    })
    urlParams.Append({
        "isMissing": false
    })
    resp = APIRequest(url, urlParams)
    data = getJson(resp)
    if isValid(data) and data.Items.Count() > 1
        m.global.queueManager.callFunc("setEpisodeToShowAtFinish", data.Items[1])
    end if
end sub

'Checks available subtitle tracks and puts subtitles in forced, default, and non-default/forced but preferred language at the top
function sortSubtitles(MediaStreams)
    tracks = {
        "forced": []
        "default": []
        "normal": []
        "text": []
    }
    'Too many args for using substitute
    prefered_lang = m.global.session.user.configuration.SubtitleLanguagePreference
    for each stream in MediaStreams
        if stream.type = "Subtitle"
            url = ""
            if isValid(stream.DeliveryUrl)
                url = buildURL(stream.DeliveryUrl)
            end if
            stream = {
                "Track": {
                    "Language": stream.language
                    "Description": stream.displaytitle
                    "TrackName": url
                }
                "IsTextSubtitleStream": stream.IsTextSubtitleStream
                "Index": stream.index
                "IsDefault": stream.IsDefault
                "IsForced": stream.IsForced
                "IsExternal": stream.IsExternal
                "IsEncoded": stream.DeliveryMethod = "Encode"
            }
            if stream.isForced
                trackType = "forced"
            else if stream.IsDefault
                trackType = "default"
            else
                trackType = "normal"
            end if
            if prefered_lang <> "" and prefered_lang = stream.Track.Language
                tracks[trackType].unshift(stream)
                if stream.IsTextSubtitleStream
                    tracks["text"].unshift(stream)
                end if
            else
                tracks[trackType].push(stream)
                if stream.IsTextSubtitleStream
                    tracks["text"].push(stream)
                end if
            end if
        end if
    end for
    tracks["default"].append(tracks["normal"])
    tracks["forced"].append(tracks["default"])
    return {
        "all": tracks["forced"]
        "text": tracks["text"]
    }
end function

function FindPreferredAudioStream(streams as dynamic) as integer
    preferredAudioTrackIndex = m.global.queueManager.callFunc("getPreferredAudioTrackIndex")
    preferredLanguage = m.global.session.user.Configuration.AudioLanguagePreference
    playDefault = chainLookupReturn(m.global.session, "user.Configuration.PlayDefaultAudioTrack", false)
    ' Do we already have the MediaStreams or not?
    if not isValidAndNotEmpty(streams)
        jsonResponse = api_items_GetByID(m.top.itemId, {
            UserId: m.global.session.user.id
        })
        if jsonResponse = invalid or jsonResponse.MediaStreams = invalid then
            return 1
        end if
        streams = jsonResponse.MediaStreams
    end if
    ' User selected something other than the first track?
    if preferredAudioTrackIndex >= 0
        return preferredAudioTrackIndex
    end if
    ' No selection, but they have Default as their preference?
    if playDefault
        return findDefaultTrack(streams)
    end if
    firstAudioTrack = -1
    ' No user selection and not configured to play the default, how about a preferred language?
    if isValid(preferredLanguage)
        for i = 0 to streams.Count() - 1
            if LCase(streams[i].Type) = "audio"
                if firstAudioTrack < 0 then
                    firstAudioTrack = i
                end if
                if isStringEqual(chainLookupReturn(streams[i], "Language", invalid), preferredLanguage)
                    return i
                end if
            end if
        end for
    end if
    ' User doesn't care, play the first track :-)
    return firstAudioTrack
end function

' checkRokuVideoCompatibility: Examines ALL MediaStreams from playback info and
' returns an array of human-readable warning strings for any characteristics that
' may prevent or degrade direct playback on Roku hardware.
'
' Checks:
'   - Data tracks (tmcd, meta, uuid, etc.) — always unsupported by Roku
'   - Video codec / resolution / framerate via CanDecodeVideo (per-device)
'   - Audio codec via CanDecodeAudio (per-device)
'
' Only the first video and first audio stream are inspected since those are
' the tracks that will actually be played.
'
' @param {dynamic} mediaStreams - MediaStreams array from playback info
' @return {object} array of warning strings (empty if no issues found)
function checkRokuVideoCompatibility(mediaStreams as object) as object
    warnings = []
    devInfo = CreateObject("roDeviceInfo")
    embyMode = chainLookupReturn(m.global.session, "user.settings.`playback.embyMode`", false) = true
    checkedVideo = false
    checkedAudio = false
    for each stream in mediaStreams
        stype = LCase((function(stream)
                __bsConsequent = stream.LookupCI("Type")
                if __bsConsequent <> invalid then
                    return __bsConsequent
                else
                    return ""
                end if
            end function)(stream))
        codec = (function(stream)
                __bsConsequent = stream.LookupCI("Codec")
                if __bsConsequent <> invalid then
                    return __bsConsequent
                else
                    return ""
                end if
            end function)(stream)
        ' --- Data track check ---
        ' Data tracks (tmcd, meta, uuid, etc.) are metadata/timecode tracks.
        ' The Roku video player silently ignores stream types it doesn't recognise —
        ' it will not crash. No warning is needed; just skip past them.
        if stype = "data"
            continue for
        end if
        ' --- Video stream checks (first video stream only) ---
        if stype = "video" and not checkedVideo
            checkedVideo = true
            width = stream.LookupCI("Width")
            height = stream.LookupCI("Height")
            level = stream.LookupCI("Level")
            ' --- Bitrate checks ---
            bitrate = stream.LookupCI("BitRate")
            if isValid(bitrate) and bitrate > 0
                if bitrate > 60000000
                    warnings.push(tr("Extreme Bitrate") + " (" + (bitrate / 1000000).ToStr() + " Mbps)")
                else if bitrate > 30000000
                    warnings.push(tr("High Bitrate") + " (" + (bitrate / 1000000).ToStr() + " Mbps)")
                end if
            end if
            ' --- Codec checks ---
            ' Warn if the hardware truly can't decode the codec at all.
            if codec <> ""
                codecLCase = LCase(codec)
                decodeCheck = devInfo.CanDecodeVideo({
                    Codec: codecLCase
                })
                if not isValid(decodeCheck) or not decodeCheck.result
                    warnings.push(tr("Unsupported video codec") + ": " + codec)
                end if
            end if
            ' --- Resolution checks ---
            if isValid(width) and isValid(height)
                if width > 1920 or height > 1080
                    decodeCheck = devInfo.CanDecodeVideo({
                        Codec: (function(__bsCondition, LCase, codec)
                                if __bsCondition then
                                    return LCase(codec)
                                else
                                    return "h264"
                                end if
                            end function)(LCase(codec) <> "", LCase, codec)
                        Width: width
                        Height: height
                    })
                    if not isValid(decodeCheck) or not decodeCheck.result
                        warnings.push(tr("Resolution too high for Roku") + " (" + width.ToStr() + "x" + height.ToStr() + ")")
                    end if
                end if
            end if
            ' --- Framerate checks ---
            videoFps = 0
            if isValid(stream.RealFrameRate) and stream.RealFrameRate > 0
                videoFps = stream.RealFrameRate
            else if isValid(stream.AverageFrameRate) and stream.AverageFrameRate > 0
                videoFps = stream.AverageFrameRate
            end if
            if videoFps > 0 and isValid(height)
                ' Only warn if framerate is truly high (e.g. 50/60fps) OR if the decoder specifically rejects it.
                ' We increase the threshold for 1080p to avoid false-positive warnings.
                if videoFps > 30 or height > 1080
                    decodeCheck = devInfo.CanDecodeVideo({
                        Codec: (function(__bsCondition, LCase, codec)
                                if __bsCondition then
                                    return LCase(codec)
                                else
                                    return "h264"
                                end if
                            end function)(LCase(codec) <> "", LCase, codec)
                        FrameRate: Fix(videoFps)
                        Width: bslib_coalesce(width, 1920)
                        Height: height
                    })
                    if not isValid(decodeCheck) or not decodeCheck.result
                        fpsStr = Str(Fix(videoFps)).Trim()
                        warnings.push(tr("Framerate too high for Roku at this resolution.") + " (" + fpsStr + " fps @ " + height.ToStr() + "p)")
                    end if
                end if
            end if
            ' --- H.264 level checks ---
            ' In Emby-Mode, we ignore Level warnings entirely as we are trying playback regardless.
            if LCase(codec) = "h264" and not CompatibilityBypass_IsEnabled()
                if level <> invalid
                    ' Handle both integer (51) and float (5.1) forms safely
                    levelValue = 0.0
                    lType = Type(level)
                    if lType = "roInt" or lType = "Integer" or lType = "LongInteger"
                        levelValue = level / 10.0
                    else if lType = "roString" or lType = "String"
                        levelValue = level.ToFloat()
                        if levelValue > 10 then
                            levelValue = levelValue / 10.0
                        end if
                    else
                        levelValue = level.ToFloat()
                    end if
                    if levelValue > 4.1
                        warnings.push(tr("H.264 level too high") + ": " + levelValue.ToStr())
                    end if
                end if
            end if
            ' --- HEVC level checks ---
            if (LCase(codec) = "hevc" or LCase(codec) = "h265") and not CompatibilityBypass_IsEnabled()
                if level <> invalid
                    ' Handle both integer (51) and float (5.1) forms safely
                    levelValue = 0.0
                    lType = Type(level)
                    if lType = "roInt" or lType = "Integer" or lType = "LongInteger"
                        levelValue = level / 10.0
                    else if lType = "roString" or lType = "String"
                        levelValue = level.ToFloat()
                        if levelValue > 10 then
                            levelValue = levelValue / 10.0
                        end if
                    else
                        levelValue = level.ToFloat()
                    end if
                    if levelValue > 5.1
                        warnings.push(tr("HEVC level too high") + ": " + levelValue.ToStr())
                    end if
                end if
            end if
        end if
        ' --- Audio stream checks (first audio stream only) ---
        ' Uses CanDecodeAudio for per-device accuracy — e.g. TrueHD and DTS-MA
        ' are only supported on specific Roku models.
        if stype = "audio" and not checkedAudio
            checkedAudio = true
            if codec <> ""
                decodeCheck = devinfo.CanDecodeAudio({
                    Codec: codec
                })
                if not isValid(decodeCheck) or not decodeCheck.result
                    warnings.push(tr("Unsupported audio codec") + ": " + codec)
                end if
            end if
        end if
    end for
    return warnings
end function
'//# sourceMappingURL=./LoadVideoContentTask.brs.map