import re

with open(r'components\movies\MovieDetails.bs', 'rb') as f:
    text = f.read().decode('utf-8')

# 1. Update selectorNodes
text = re.sub(r'm\.selectorNodes\s*=\s*\[\s*m\.top\.findNode\("videoSelector"\),\s*m\.top\.findNode\("audioText"\),\s*m\.top\.findNode\("subtitleButton"\)\s*\]', 
'''    m.selectorNodes = [
        m.top.findNode("videoButton"),
        m.top.findNode("audioButton"),
        m.top.findNode("subtitleButton")
    ]''', text)

# 2. Setup Dropdowns instead of inline selector
old_sel = r'\' Version selector \(inline expanded list\)\s*m\.videoSelector = m\.top\.findNode\("videoSelector"\)\s*m\.videoSelector\.observeField\("selectedIndex", "onVideoSelectorSelect"\)\s*\' Subtitle dropdown \(floating popover\)\s*m\.subtitleDropdown = m\.top\.findNode\("subtitleDropdown"\)\s*m\.subtitleDropdown\.observeField\("selectedIndex", "onSubtitleDropdownSelect"\)'
new_sel = '''    ' Video dropdown (floating popover)
    m.videoDropdown = m.top.findNode("videoDropdown")
    if isValid(m.videoDropdown) then m.videoDropdown.observeField("selectedIndex", "onVideoDropdownSelect")

    ' Audio dropdown (floating popover)
    m.audioDropdown = m.top.findNode("audioDropdown")
    if isValid(m.audioDropdown) then m.audioDropdown.observeField("selectedIndex", "onAudioDropdownSelect")

    ' Subtitle dropdown (floating popover)
    m.subtitleDropdown = m.top.findNode("subtitleDropdown")
    if isValid(m.subtitleDropdown) then m.subtitleDropdown.observeField("selectedIndex", "onSubtitleDropdownSelect")'''
text = re.sub(old_sel, new_sel, text)

# 3. closeAllDropdowns
old_close = r'sub closeAllDropdowns\(\)\s*m\.subtitleDropdown\.callFunc\("hide"\)\s*m\.activeSelectorIndex = -1\s*end sub'
new_close = '''sub closeAllDropdowns()
    if isValid(m.videoDropdown) then m.videoDropdown.callFunc("hide")
    if isValid(m.audioDropdown) then m.audioDropdown.callFunc("hide")
    if isValid(m.subtitleDropdown) then m.subtitleDropdown.callFunc("hide")
    m.activeSelectorIndex = -1
end sub'''
text = re.sub(old_close, new_close, text)

# 4. openSelectorOptionsByIndex
old_open = r'if selectorIndex = 2 and isValid\(m\.subtitleDropdown\)\s*m\.subtitleDropdown\.callFunc\("show"\)\s*end if'
new_open = '''if selectorIndex = 0 and isValid(m.videoDropdown)
        m.videoDropdown.callFunc("show")
    else if selectorIndex = 1 and isValid(m.audioDropdown)
        m.audioDropdown.callFunc("show")
    else if selectorIndex = 2 and isValid(m.subtitleDropdown)
        m.subtitleDropdown.callFunc("show")
    end if'''
text = re.sub(old_open, new_open, text)

# 5. onVideoSelectorSelect -> onVideoDropdownSelect
old_onvideo = r'sub onVideoSelectorSelect\(\)\s*selected = m\.videoSelector\.selectedIndex\s*if selected < 0 then return\s*options = m\.options\.options\s*if not isValid\(options\) or not isValid\(options\.videos\) then return\s*if selected >= options\.videos\.Count\(\) then return\s*selectedVideo = options\.videos\[selected\]\s*if m\.top\.selectedVideoStreamId <> selectedVideo\.StreamID\s*m\.top\.selectedVideoStreamId = selectedVideo\.StreamID\s*end if\s*\' Update video_codec label\s*if isValid\(selectedVideo\.video_codec\) and selectedVideo\.video_codec <> ""\s*setFieldText\("video_codec", tr\("Video"\) \+ ": " \+ selectedVideo\.video_codec\)\s*end if\s*\' Reload audio options for the new video stream'
new_onvideo = '''sub onVideoDropdownSelect()
    selected = m.videoDropdown.selectedIndex
    if selected < 0 then return

    options = m.options.options
    if not isValid(options) or not isValid(options.videos) then return
    if selected >= options.videos.Count() then return

    selectedVideo = options.videos[selected]
    if m.top.selectedVideoStreamId <> selectedVideo.StreamID
        m.top.selectedVideoStreamId = selectedVideo.StreamID
    end if

    ' Update video_codec label
    if isValid(selectedVideo.video_codec) and selectedVideo.video_codec <> ""
        setFieldText("video_codec", tr("Video") + ": " + selectedVideo.video_codec)
    end if

    closeAllDropdowns()

    videoButton = m.top.findNode("videoButton")
    if isValid(videoButton)
        videoButton.text = sanitizeSelectorText(selectedVideo.Title)
    end if

    ' Reload audio options for the new video stream'''
text = re.sub(old_onvideo, new_onvideo, text)

# 6. SetUpVideoOptions
old_video_setup = r'\' Build ContentNode for version selector \(inline expanded list\)\s*versionContent = CreateObject\("roSGNode", "ContentNode"\)\s*for each v in videos\s*child = versionContent\.CreateChild\("ContentNode"\)\s*child\.title = v\.Title\s*child\.addField\("description", "string", true\)\s*child\.description = v\.Description\s*child\.addField\("selected", "boolean", true\)\s*child\.selected = v\.Selected\s*child\.addField\("streamid", "string", true\)\s*child\.streamid = v\.StreamID\s*end for\s*m\.videoSelector\.content = versionContent'
new_video_setup = '''' Build ContentNode for version selector (inline expanded list)
    versionContent = CreateObject("roSGNode", "ContentNode")
    for each v in videos
        child = versionContent.CreateChild("ContentNode")
        child.title = v.Title
        child.addField("description", "string", true)
        child.description = v.Description
        child.addField("selected", "boolean", true)
        child.selected = v.Selected
        child.addField("streamid", "string", true)
        child.streamid = v.StreamID
    end for
    if isValid(m.videoDropdown) then m.videoDropdown.content = versionContent

    videoButton = m.top.findNode("videoButton")
    if isValid(videoButton)
        for each v in videos
            if v.Selected
                videoButton.text = sanitizeSelectorText(v.Title)
                exit for
            end if
        end for
    end if'''
text = re.sub(old_video_setup, new_video_setup, text)

# 7. SetUpAudioOptions
old_audio_setup = r'\' Set static audio text \(no dropdown\)\s*audioText = m\.top\.findNode\("audioText"\)\s*if isValid\(audioText\) and m\.top\.selectedAudioStreamIndex >= 0 and m\.top\.selectedAudioStreamIndex < streams\.Count\(\)\s*audioLabel = buildAudioLabel\(streams\[m\.top\.selectedAudioStreamIndex\]\)\s*defaultIdx = getDefaultAudioTrackIndex\(streams\)\s*if m\.top\.selectedAudioStreamIndex = defaultIdx\s*audioLabel = audioLabel \+ " \(Default\)"\s*end if\s*audioText\.text = audioLabel\s*end if'
new_audio_setup = '''' Set button text
    audioButton = m.top.findNode("audioButton")
    if isValid(audioButton) and m.top.selectedAudioStreamIndex >= 0 and m.top.selectedAudioStreamIndex < streams.Count()
        audioLabel = buildAudioLabel(streams[m.top.selectedAudioStreamIndex])
        defaultIdx = getDefaultAudioTrackIndex(streams)
        if m.top.selectedAudioStreamIndex = defaultIdx
            audioLabel = audioLabel + " (Default)"
        end if
        audioButton.text = sanitizeSelectorText(audioLabel)
    end if

    audioContent = CreateObject("roSGNode", "ContentNode")
    for each a in audioTracks
        child = audioContent.CreateChild("ContentNode")
        child.title = a.Title
        child.addField("description", "string", true)
        child.description = a.Description
        child.addField("selected", "boolean", true)
        child.selected = a.Selected
        child.addField("streamIndex", "integer", true)
        child.streamIndex = a.StreamIndex
    end for
    if isValid(m.audioDropdown) then m.audioDropdown.content = audioContent'''
text = re.sub(old_audio_setup, new_audio_setup, text)

with open(r'components\movies\MovieDetails.bs', 'wb') as f:
    f.write(text.encode('utf-8'))
print('SUCCESS')
