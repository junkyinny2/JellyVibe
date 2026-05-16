'import "pkg:/source/enums/ColorPalette.bs"
'import "pkg:/source/utils/misc.bs"

sub init()
    m.content = m.top.findNode("content")
    setPalette()
    m.top.id = "OKDialog"
    m.top.height = 900
    m.top.title = ("What's New In " + bslib_toString(m.global.app.version))
    m.top.buttons = [
        tr("OK")
    ]
    dialogStyles = {
        "default": {
            "fontSize": 27
            "fontUri": "font:SystemFontFile"
            "color": chainLookupReturn(m.global.session, "user.settings.colorDialogText", "#ffffff")
        }
        "b": {
            "fontSize": 27
            "fontUri": "font:SystemFontFile"
            "color": chainLookupReturn(m.global.session, "user.settings.colorDialogBoldText", "#1F8DBA")
        }
        "author": {
            "fontSize": 27
            "fontUri": "font:SystemFontFile"
            "color": chainLookupReturn(m.global.session, "user.settings.colorWhatsNewAuthor", "#7B2FBE")
        }
    }
    whatsNewList = ParseJSON(ReadAsciiFile("pkg:/source/static/whatsNew/" + m.global.app.version.ToStr().trim() + ".json"))
    for each item in whatsNewList
        textLine = m.content.CreateChild("StdDlgMultiStyleTextItem")
        textLine.drawingStyles = dialogStyles
        textLine.text = "• " + item.description + " <author>" + item.author + "</author>"
    end for
end sub

sub setPalette()
    dlgPalette = createObject("roSGNode", "RSGPalette")
    dlgPalette.colors = {
        DialogBackgroundColor: chainLookupReturn(m.global.session, "user.settings.colorDialogBackground", "#020B2A")
        DialogFocusColor: chainLookupReturn(m.global.session, "user.settings.colorCursor", "#7B2FBE")
        DialogFocusItemColor: chainLookupReturn(m.global.session, "user.settings.colorDialogSelectedText", "#ffffff")
        DialogSecondaryTextColor: "#FF0000"
        DialogSecondaryItemColor: chainLookupReturn(m.global.session, "user.settings.colorDialogBorderLine", "#c8fafa")
        DialogTextColor: chainLookupReturn(m.global.session, "user.settings.colorDialogText", "#ffffff")
    }
    m.top.palette = dlgPalette
end sub
'//# sourceMappingURL=./WhatsNewDialog.brs.map