'import "pkg:/source/utils/misc.bs"

sub init()
    m.dataLoaded = false
    m.previousLine = m.top.findNode("previousLine")
    m.currentLine = m.top.findNode("currentLine")
    m.nextLine1 = m.top.findNode("nextLine1")
    m.nextLine2 = m.top.findNode("nextLine2")
    m.nextLine3 = m.top.findNode("nextLine3")
    m.seekMode = false
    m.currentLyricIndex = 0
    m.currentLyric = {}
end sub

sub onWidthChange()
    if m.top.width > 0
        m.previousLine.width = m.top.width
        m.currentLine.width = m.top.width
        m.nextLine1.width = m.top.width
        m.nextLine2.width = m.top.width
        m.nextLine3.width = m.top.width
    end if
end sub

sub onLyricDataChange()
    m.dataLoaded = isValidAndNotEmpty(m.top.lyricData)
end sub

sub findPosition(newPosition)
    if not m.dataLoaded then
        return
    end if
    m.seekMode = true
    m.currentLyric.clear()
    m.previousLine.text = ""
    m.currentLine.text = ""
    for lineIndex = 1 to 3
        m[("nextLine" + bslib_toString(lineIndex))].text = ""
    end for
    position = int(newPosition) * 10000000&
    for i = m.top.lyricData.lyrics.count() - 1 to 0 step -1
        if position >= m.top.lyricData.lyrics[i].start
            m.currentLyricIndex = i
            m.seekMode = false
            return
        end if
    end for
    m.currentLyricIndex = 0
    m.seekMode = false
end sub

sub onPositionTimeChange()
    if m.seekMode then
        return
    end if
    if not m.dataLoaded then
        return
    end if
    if not isValidAndNotEmpty(m.top.lyricData.lyrics) then
        return
    end if
    if m.currentLyricIndex >= m.top.lyricData.lyrics.count() then
        return
    end if
    position = int(m.top.positionTime) * 10000000&
    if not isValid(position) then
        return
    end if
    if m.currentLyric.count() = 0
        m.currentLyric = m.top.lyricData.lyrics[m.currentLyricIndex]
    end if
    if not isValid(m.currentLyric.start) then
        return
    end if
    if position >= m.currentLyric.start
        if m.currentLyricIndex > 0
            lyric = m.top.lyricData.lyrics[m.currentLyricIndex - 1].text
            if lyric.trim() <> ""
                m.previousLine.text = lyric
            end if
        else
            m.previousLine.text = ""
        end if
        m.currentLine.text = m.currentLyric.text
        for lineIndex = 1 to 3
            if m.currentLyricIndex < m.top.lyricData.lyrics.count() - lineIndex
                m[("nextLine" + bslib_toString(lineIndex))].text = m.top.lyricData.lyrics[m.currentLyricIndex + lineIndex].text
            else
                m[("nextLine" + bslib_toString(lineIndex))].text = ""
            end if
        end for
        m.currentLyricIndex++
        m.currentLyric.clear()
    end if
end sub
'//# sourceMappingURL=./Lyrics.brs.map