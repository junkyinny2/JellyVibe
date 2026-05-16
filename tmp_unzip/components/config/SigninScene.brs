'import "pkg:/source/enums/ColorPalette.bs"
'import "pkg:/source/enums/KeyCode.bs"
'import "pkg:/source/enums/PosterLoadStatus.bs"
'import "pkg:/source/enums/String.bs"
'import "pkg:/source/utils/misc.bs"


sub onProfileImageUriChange()
    if not isValid(m.top.profileImageUri)
        m.top.profileImageUri = "pkg:/images/baseline_person_white_48dp.png"
    end if
    if isStringEqual(m.top.profileImageUri, "")
        m.top.profileImageUri = "pkg:/images/baseline_person_white_48dp.png"
    end if
    m.profileImage.uri = m.top.profileImageUri
end sub

sub onPosterLoadStatusChanged()
    if m.profileImage.loadStatus <> "loading"
        m.profileImage.unobserveField("loadStatus")
    end if
    if isStringEqual(m.profileImage.loadStatus, "failed")
        m.top.profileImageUri = "pkg:/images/baseline_person_white_48dp.png"
    end if
end sub

sub init()
    m.top.setFocus(true)
    m.top.optionsAvailable = false
    m.profileImage = m.top.findNode("overlayCurrentUserProfileImage")
    m.profileImage.observeField("loadStatus", "onPosterLoadStatusChanged")
    m.submit = m.top.findNode("submit")
    m.submit.background = "#c8fafa"
    m.submit.color = "#101010"
    m.submit.focusBackground = "#7B2FBE"
    m.submit.focusColor = "#ffffff"
    m.quickConnect = m.top.findNode("quickConnect")
    m.quickConnect.background = "#c8fafa"
    m.quickConnect.color = "#101010"
    m.quickConnect.focusBackground = "#7B2FBE"
    m.quickConnect.focusColor = "#ffffff"
    m.errorContainer = m.top.findNode("errorContainer")
    m.errorContainer.color = "#CC0000"
    m.config = m.top.findNode("configOptions")
    m.config.focusBitmapBlendColor = "#7B2FBE"
    m.config.focusFootprintBlendColor = "0x00000000"
    username_field = CreateObject("roSGNode", "ConfigData")
    username_field.label = tr("Username")
    username_field.type = "string"
    username_field.value = ""
    password_field = CreateObject("roSGNode", "ConfigData")
    password_field.label = tr("Password")
    password_field.type = "password"
    registryPassword = get_setting("password")
    if isValid(registryPassword)
        password_field.value = registryPassword
    end if
    saveCredentials = m.top.findNode("saveCredentials")
    saveCredentials.focusedColor = "#7B2FBE"
    saveCredentials.font.size = 30
    saveCredentials.focusedFont.size = 30
    if not isStringEqual(get_setting("saveCredentials", "true"), "true")
        saveCredentials.checkedState = "[false]"
    end if
    items = [
        username_field
        password_field
    ]
    m.config.configItems = items
    saveCredentials.checkedIconUri = "pkg:/images/icons/checkboxChecked.png"
    saveCredentials.focusedCheckedIconUri = "pkg:/images/icons/checkboxChecked.png"
    saveCredentials.uncheckedIconUri = "pkg:/images/icons/checkboxUnchecked.png"
    saveCredentials.focusedUncheckedIconUri = "pkg:/images/icons/checkboxUnchecked.png"
end sub

sub onAlertChange()
    m.errorContainer.visible = isValidAndNotEmpty(m.top.alert)
    errorMessage = m.top.findNode("errorMessage")
    errorMessage.text = m.top.alert
end sub

sub onUserChange()
    username_field = m.config.content.getChild(0)
    if isStringEqual(m.top.user, "") and isValid(get_setting("username"))
        username_field.value = get_setting("username")
    else
        username_field.value = m.top.user
    end if
    ' Username has been provided, focus on password field
    if not isStringEqual(username_field.value, "")
        m.config.jumpToItem = 1
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    ' Returns true if user navigates to a new focusable element
    if not press then
        return false
    end if
    list = m.top.findNode("configOptions")
    saveCredentials = m.top.findNode("saveCredentials")
    if key = "back"
        m.top.backPressed = true
        return false
    end if
    if key = "down" and list.isInFocusChain()
        limit = list.content.getChildren(-1, 0).count() - 1
        if limit = list.itemFocused
            saveCredentials.setFocus(true)
            group = m.global.sceneManager.callFunc("getActiveScene")
            group.lastFocus = saveCredentials
            return true
        end if
        return false
    end if
    if key = "down" and saveCredentials.isInFocusChain()
        m.submit.setFocus(true)
        m.submit.focus = true
        group = m.global.sceneManager.callFunc("getActiveScene")
        group.lastFocus = m.submit
        return true
    end if
    if key = "up" and m.submit.hasFocus()
        m.submit.focus = false
        saveCredentials.setFocus(true)
        group = m.global.sceneManager.callFunc("getActiveScene")
        group.lastFocus = saveCredentials
        return true
    end if
    if key = "up" and m.quickConnect.hasFocus()
        m.quickConnect.focus = false
        saveCredentials.setFocus(true)
        group = m.global.sceneManager.callFunc("getActiveScene")
        group.lastFocus = saveCredentials
        return true
    end if
    if key = "up" and saveCredentials.isInFocusChain()
        list.setFocus(true)
        group = m.global.sceneManager.callFunc("getActiveScene")
        group.lastFocus = list
        return true
    end if
    if key = "right" and m.submit.hasFocus()
        m.submit.focus = false
        m.quickConnect.setFocus(true)
        m.quickConnect.focus = true
        group = m.global.sceneManager.callFunc("getActiveScene")
        group.lastFocus = m.quickConnect
        return true
    end if
    if key = "left" and m.quickConnect.hasFocus()
        m.quickConnect.focus = false
        m.submit.setFocus(true)
        m.submit.focus = true
        group = m.global.sceneManager.callFunc("getActiveScene")
        group.lastFocus = m.submit
        return true
    end if
    if key = "OK"
        if m.quickConnect.hasFocus()
            m.quickConnect.selected = not m.quickConnect.selected
            return true
        end if
        if m.submit.hasFocus()
            m.submit.selected = not m.submit.selected
            return true
        end if
    end if
    return false
end function
'//# sourceMappingURL=./SigninScene.brs.map