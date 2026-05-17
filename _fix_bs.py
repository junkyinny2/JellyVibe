import re

with open(r'components\movies\MovieDetails.bs', 'rb') as f:
    data = f.read()

text = data.decode('utf-8')

# 1. Update selectorNodes
old_nodes = '''    m.selectorNodes = [
        m.top.findNode("videoSelector"),
        m.top.findNode("audioText"),
        m.top.findNode("subtitleButton")
    ]'''
new_nodes = '''    m.selectorNodes = [
        m.top.findNode("videoButton"),
        m.top.findNode("audioButton"),
        m.top.findNode("subtitleButton")
    ]'''
text = text.replace(old_nodes, new_nodes)

# 2. Setup Dropdowns instead of inline selector
old_selectors = '''    ' Version selector (inline expanded list)
    m.videoSelector = m.top.findNode("videoSelector")
    m.videoSelector.observeField("selectedIndex", "onVideoSelectorSelect")

    ' Subtitle dropdown (floating popover)
    m.subtitleDropdown = m.top.findNode("subtitleDropdown")
    m.subtitleDropdown.observeField("selectedIndex", "onSubtitleDropdownSelect")'''
new_selectors = '''    ' Video dropdown (floating popover)
    m.videoDropdown = m.top.findNode("videoDropdown")
    if isValid(m.videoDropdown) then m.videoDropdown.observeField("selectedIndex", "onVideoDropdownSelect")

    ' Audio dropdown (floating popover)
    m.audioDropdown = m.top.findNode("audioDropdown")
    if isValid(m.audioDropdown) then m.audioDropdown.observeField("selectedIndex", "onAudioDropdownSelect")

    ' Subtitle dropdown (floating popover)
    m.subtitleDropdown = m.top.findNode("subtitleDropdown")
    if isValid(m.subtitleDropdown) then m.subtitleDropdown.observeField("selectedIndex", "onSubtitleDropdownSelect")'''
text = text.replace(old_selectors, new_selectors)

# 3. closeAllDropdowns
old_close = '''sub closeAllDropdowns()
    m.subtitleDropdown.callFunc("hide")
    m.activeSelectorIndex = -1
end sub'''
new_close = '''sub closeAllDropdowns()
    if isValid(m.videoDropdown) then m.videoDropdown.callFunc("hide")
    if isValid(m.audioDropdown) then m.audioDropdown.callFunc("hide")
    if isValid(m.subtitleDropdown) then m.subtitleDropdown.callFunc("hide")
    m.activeSelectorIndex = -1
end sub'''
text = text.replace(old_close, new_close)

# 4. openSelectorOptionsByIndex
old_open = '''    if selectorIndex = 2 and isValid(m.subtitleDropdown)
        m.subtitleDropdown.callFunc("show")
    end if'''
new_open = '''    if selectorIndex = 0 and isValid(m.videoDropdown)
        m.videoDropdown.callFunc("show")
    else if selectorIndex = 1 and isValid(m.audioDropdown)
        m.audioDropdown.callFunc("show")
    else if selectorIndex = 2 and isValid(m.subtitleDropdown)
        m.subtitleDropdown.callFunc("show")
    end if'''
text = text.replace(old_open, new_open)

# 5. onVideoSelectorSelect -> onVideoDropdownSelect
old_onvideo = '''sub onVideoSelectorSelect()
    selected = m.videoSelector.selectedIndex
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

    ' Reload audio options for the new video stream'''
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
text = text.replace(old_onvideo, new_onvideo)

# 6. SetUpVideoOptions
old_video_setup = '''    ' Build ContentNode for version selector (inline expanded list)
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
    m.videoSelector.content = versionContent'''
new_video_setup = '''    ' Build ContentNode for version selector (inline expanded list)
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
text = text.replace(old_video_setup, new_video_setup)

# 7. SetUpAudioOptions
old_audio_setup = '''    ' Set static audio text (no dropdown)
    audioText = m.top.findNode("audioText")
    if isValid(audioText) and m.top.selectedAudioStreamIndex >= 0 and m.top.selectedAudioStreamIndex < streams.Count()
        audioLabel = buildAudioLabel(streams[m.top.selectedAudioStreamIndex])
        defaultIdx = getDefaultAudioTrackIndex(streams)
        if m.top.selectedAudioStreamIndex = defaultIdx
            audioLabel = audioLabel + " (Default)"
        end if
        audioText.text = audioLabel
    end if'''
new_audio_setup = '''    ' Set button text
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
text = text.replace(old_audio_setup, new_audio_setup)

# 8. Add onAudioDropdownSelect function right after onVideoDropdownSelect
on_video_end_idx = text.find('    updateFocus()\r\nend sub\r\n\r\nsub onSubtitleDropdownSelect()')
if on_video_end_idx > 0:
    insert_pos = on_video_end_idx + 24
    on_audio = '''

sub onAudioDropdownSelect()
    selected = m.audioDropdown.selectedIndex
    if selected < 0 then return

    options = m.options.options
    if not isValid(options) or not isValid(options.audios) then return
    if selected >= options.audios.Count() then return

    selectedAudio = options.audios[selected]
    if m.top.selectedAudioStreamIndex <> selectedAudio.StreamIndex
        m.top.selectedAudioStreamIndex = selectedAudio.StreamIndex
    end if

    closeAllDropdowns()

    audioButton = m.top.findNode("audioButton")
    if isValid(audioButton)
        audioButton.text = sanitizeSelectorText(selectedAudio.Title)
    end if

    m.focusRow = 1
    updateFocus()
end sub'''
    text = text[:insert_pos] + on_audio + text[insert_pos:]

with open(r'components\movies\MovieDetails.bs', 'wb') as f:
    f.write(text.encode('utf-8'))
print('SUCCESS: MovieDetails.bs patched')
