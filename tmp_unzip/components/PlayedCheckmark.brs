'import "pkg:/source/enums/ColorPalette.bs"
'import "pkg:/source/utils/misc.bs"

sub init()
    m.top.width = 60
    m.top.height = 50
    m.unplayedNumber = m.top.findNode("unplayedNumber")
    m.checkmark = m.top.findNode("checkmark")
    m.checkmark.font.size = 48
    m.top.color = "0x00000000"
    m.checkmark.visible = false
    m.unplayedNumber.visible = false
end sub

sub onDataChange()
    m.top.color = "0x00000000"
    if isValid(m.checkmark)
        m.checkmark.color = chainLookupReturn(m.global.session, "user.settings.colorPlayedCheckmarkIcon", "#ffffff")
        m.checkmark.visible = false
    end if
    if isValid(m.unplayedNumber)
        m.unplayedNumber.color = chainLookupReturn(m.global.session, "user.settings.colorUnplayedCountTextColor", "#ffffff")
        m.unplayedNumber.visible = false
    end if
    if not isValidAndNotEmpty(m.top.data) then
        return
    end if
    if chainLookupReturn(m.top.data, "unplayedCount", 0) > 0
        disableUnwatchedEpisodeCount = chainLookupReturn(m.global.session, "user.settings.`ui.tvshows.disableUnwatchedEpisodeCount`", false)
        if disableUnwatchedEpisodeCount then
            return
        end if
        unplayedCount = m.top.data.unplayedCount.ToStr()
        unplayedCountLength = len(unplayedCount)
        m.top.color = chainLookupReturn(m.global.session, "user.settings.colorPlayedCheckmarkBackground", "#6F7FB7")
        if isValid(m.unplayedNumber)
            if unplayedCountLength = 4 then
                m.unplayedNumber.font.size = 25
            else
                m.unplayedNumber.font.size = 30
            end if
            m.unplayedNumber.visible = true
            m.unplayedNumber.text = unplayedCount
        end if
        return
    end if
    if not chainLookupReturn(m.top.data, "showWatchedCheckmark", true) then
        return
    end if
    if chainLookupReturn(m.top.data, "played", false)
        m.top.color = chainLookupReturn(m.global.session, "user.settings.colorPlayedCheckmarkBackground", "#6F7FB7")
        if isValid(m.checkmark)
            m.checkmark.visible = true
        end if
        return
    end if
end sub
'//# sourceMappingURL=./PlayedCheckmark.brs.map