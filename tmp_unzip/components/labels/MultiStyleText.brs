'import "pkg:/source/enums/ColorPalette.bs"
'import "pkg:/source/enums/String.bs"
'import "pkg:/source/utils/misc.bs"

sub init()
    setFont()
    m.top.observeFieldScoped("font", "onFontChanged")
end sub

sub setFont()
    if m.global.fallbackFont = "" then
        return
    end if
    if not chainLookupReturn(m.global.session, "user.settings.useFallbackFont", false) then
        return
    end if
    m.top.font.uri = m.global.fallbackFont
end sub

sub onFontChanged()
    setFont()
end sub
'//# sourceMappingURL=./MultiStyleText.brs.map