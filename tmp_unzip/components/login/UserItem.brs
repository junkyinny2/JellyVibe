'import "pkg:/source/enums/ColorPalette.bs"
'import "pkg:/source/enums/PosterLoadStatus.bs"
'import "pkg:/source/utils/misc.bs"

sub init()
    m.top.findNode("profileType").color = "#aaaaaa"
    m.profileImage = m.top.findNode("profileImage")
    m.profileImage.observeField("loadStatus", "onPosterLoadStatusChanged")
end sub

sub onPosterLoadStatusChanged()
    if m.profileImage.loadStatus <> "loading"
        m.profileImage.unobserveField("loadStatus")
    end if
    if isStringEqual(m.profileImage.loadStatus, "failed")
        m.profileImage.uri = "pkg:/images/baseline_person_white_48dp.png"
    end if
end sub

sub onFocusChanged()
    itemData = m.top.itemContent
    if not isValid(itemData) then
        return
    end if
    m.top.findNode("forgetUserIcon").visible = m.top.itemHasFocus
    if m.top.itemHasFocus
        m.top.findNode("profileType").color = "#ffffff"
    else
        m.top.findNode("profileType").color = "#aaaaaa"
    end if
end sub

sub itemContentChanged()
    itemData = m.top.itemContent
    if not isValid(itemData) then
        return
    end if
    profileName = m.top.findNode("profileName")
    if itemData.isPublic then
        m.top.findNode("profileType").text = tr("Public Profile")
    else
        m.top.findNode("profileType").text = tr("Saved Profile")
    end if
    if itemData.imageURL = ""
        m.profileImage.uri = "pkg:/images/baseline_person_white_48dp.png"
    else
        m.profileImage.uri = itemData.imageURL
    end if
    profileName.text = itemData.name
end sub
'//# sourceMappingURL=./UserItem.brs.map