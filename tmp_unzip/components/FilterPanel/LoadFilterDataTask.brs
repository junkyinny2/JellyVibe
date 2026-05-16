'import "pkg:/source/utils/misc.bs"

' ──────────────────────────────────────────────
' LoadFilterDataTask  –  fetches genres + tags
' from the Jellyfin /Items/Filters2 endpoint
' ──────────────────────────────────────────────
sub init()
    m.top.functionName = "loadFilterData"
end sub

sub loadFilterData()
    genres = []
    tags = []
    serverUrl = m.global.session.server.url
    userId = m.global.session.user.id
    token = m.global.session.user.token
    if not isValid(serverUrl) or serverUrl = ""
        m.top.genres = genres
        m.top.tags = tags
        m.top.dataLoaded = true
        return
    end if
    ' ── Build URL ──────────────────────────────
    url = (bslib_toString(serverUrl) + "/Items/Filters2?UserId=" + bslib_toString(userId))
    if isValidAndNotEmpty(m.top.parentId)
        url = url + ("&ParentId=" + bslib_toString(m.top.parentId))
    end if
    if isValidAndNotEmpty(m.top.itemType)
        url = url + ("&IncludeItemTypes=" + bslib_toString(m.top.itemType))
    end if
    ' ── HTTP request ───────────────────────────
    http = CreateObject("roUrlTransfer")
    http.setUrl(url)
    http.setCertificatesFile("common:/certs/ca-bundle.crt")
    http.initClientCertificates()
    http.setPort(CreateObject("roMessagePort"))
    http.addHeader("X-Emby-Authorization", ("MediaBrowser Token=" + chr(34) + bslib_toString(token) + chr(34)))
    http.addHeader("Content-Type", "application/json")
    if http.asyncGetToString()
        msg = wait(10000, http.getPort()) ' 10 s timeout
        if isValid(msg) and type(msg) = "roUrlEvent"
            code = msg.getResponseCode()
            if code = 200
                raw = msg.getString()
                json = parseJSON(raw)
                if isValid(json)
                    ' ── Parse genres ───────────
                    if isValid(json.Genres)
                        for each g in json.Genres
                            if isValid(g.Name) and g.Name <> ""
                                genres.push(g.Name)
                            end if
                        end for
                    end if
                    ' ── Parse tags ─────────────
                    if isValid(json.Tags)
                        for each t in json.Tags
                            tagVal = ""
                            tagType = type(t)
                            if tagType = "roString" or tagType = "String"
                                tagVal = t
                            else if (tagType = "roAssociativeArray" or tagType = "AssociativeArray") and isValid(t.Name)
                                tagVal = t.Name
                            else if isValid(t) and isValid(t.LookupCI("Name"))
                                tagVal = t.LookupCI("Name")
                            end if
                            if isValidAndNotEmpty(tagVal)
                                ' Fetch sample item image for this tag
                                imageUrl = getTagSampleImage(serverUrl, userId, token, m.top.parentId, tagVal)
                                tags.push({
                                    name: tagVal
                                    imageUrl: imageUrl
                                })
                            end if
                        end for
                    end if
                end if
            else
                print ("LoadFilterDataTask: HTTP " + bslib_toString(code))
            end if
        else
            print "LoadFilterDataTask: request timed out"
        end if
    end if
    ' ── Publish results ────────────────────────
    m.top.genres = genres
    m.top.tags = tags
    m.top.dataLoaded = true
end sub

' Fetch a sample item image for a tag by querying items with that tag
function getTagSampleImage(serverUrl as string, userId as string, token as string, parentId as string, tagName as string) as string
    ' Build query URL for items with this tag
    url = (bslib_toString(serverUrl) + "/Items?UserId=" + bslib_toString(userId) + "&Tags=" + bslib_toString(tagName) + "&Limit=1&Recursive=true")
    if isValidAndNotEmpty(parentId)
        url = url + ("&ParentId=" + bslib_toString(parentId))
    end if
    ' Add image fields to get image info
    url = url + "&Fields=PrimaryImageAspectRatio,ImageTags"
    http = CreateObject("roUrlTransfer")
    http.setUrl(url)
    http.setCertificatesFile("common:/certs/ca-bundle.crt")
    http.initClientCertificates()
    http.setPort(CreateObject("roMessagePort"))
    http.addHeader("X-Emby-Authorization", ("MediaBrowser Token=" + chr(34) + bslib_toString(token) + chr(34)))
    http.addHeader("Content-Type", "application/json")
    if http.asyncGetToString()
        msg = wait(5000, http.getPort()) ' 5 s timeout for image fetch
        if isValid(msg) and type(msg) = "roUrlEvent"
            code = msg.getResponseCode()
            if code = 200
                raw = msg.getString()
                json = parseJSON(raw)
                if isValid(json) and isValid(json.Items) and json.Items.Count() > 0
                    item = json.Items[0]
                    if isValid(item.Id) and isValid(item.ImageTags) and isValid(item.ImageTags.Primary)
                        ' Build primary image URL
                        imageUrl = (bslib_toString(serverUrl) + "/items/" + bslib_toString(item.Id) + "/images/primary?maxWidth=200&maxHeight=200")
                        return imageUrl
                    end if
                end if
            end if
        end if
    end if
    return ""
end function
'//# sourceMappingURL=./LoadFilterDataTask.brs.map