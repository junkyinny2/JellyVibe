'import "pkg:/source/enums/ColorPalette.bs"
'import "pkg:/source/enums/String.bs"
'import "pkg:/source/utils/misc.bs"

sub init()
    m.name = m.top.findNode("label")
    m.value = m.top.findNode("value")
    m.value.backgroundUri = "pkg:/images/transparent.png"
    m.value.width = 440
    m.name.color = "#ffffff"
    m.value.textColor = "#101010"
    m.value.hintTextColor = "#777777"
    m.name.width = 240
    m.name.height = 75
    m.name.vertAlign = "center"
    m.name.horizAlign = "center"
    m.value.hintText = tr("Enter a username")
    m.value.maxTextLength = 120
end sub

sub itemContentChanged()
    data = m.top.itemContent
    m.name.text = data.label
    if isStringEqual(data.type, "password")
        m.value.hintText = tr("Enter a password")
        m.value.secureMode = true
    end if
    m.value.text = data.value
end sub
'//# sourceMappingURL=./FormElement.brs.map