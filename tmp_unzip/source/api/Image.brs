'import "pkg:/source/api/sdk.bs"
'import "pkg:/source/enums/ImageType.bs"

function ItemImages(id = "" as string, params = {} as object)
    if not isValidAndNotEmpty(id) then
        return []
    end if
    data = api_items_GetImages(id)
    if not isValid(data) then
        return invalid
    end if
    results = []
    for each item in data
        tmp = CreateObject("roSGNode", "ImageData")
        tmp.imagetype = item.imagetype
        tmp.size = item.size
        tmp.height = item.height
        tmp.width = item.width
        tmp.url = ImageURL(id, tmp.imagetype, params)
        results.push(tmp)
    end for
    return results
end function

function PosterImage(id as string, params = {} as object)
    if not isValidAndNotEmpty(id) then
        return invalid
    end if
    images = ItemImages(id, params)
    if not isValid(images) then
        return invalid
    end if
    primary_image = invalid
    for each image in images
        if isStringEqual(image.imagetype, "Primary")
            primary_image = image
        else if isStringEqual(image.imagetype, "Logo") and primary_image = invalid
            primary_image = image
        else if isStringEqual(image.imagetype, "Thumb") and primary_image = invalid
            primary_image = image
        end if
    end for
    return primary_image
end function

function ImageURL(id, version = "Primary", params = {})
    if not isValidAndNotEmpty(id) then
        return ""
    end if
    ' set defaults
    if params.maxHeight = invalid
        param = {
            "maxHeight": "384"
        }
        params.append(param)
    end if
    if params.maxWidth = invalid
        param = {
            "maxWidth": "196"
        }
        params.append(param)
    end if
    if params.quality = invalid
        param = {
            "quality": "90"
        }
        params.append(param)
    end if
    url = Substitute("Items/{0}/Images/{1}", id, version)
    return buildURL(url, params)
end function

function UserImageURL(id, params = {})
    if not isValidAndNotEmpty(id) then
        return ""
    end if
    ' set defaults
    if params.maxHeight = invalid
        params.append({
            "maxHeight": "300"
        })
    end if
    if params.maxWidth = invalid
        params.append({
            "maxWidth": "300"
        })
    end if
    if params.quality = invalid
        params.append({
            "quality": "90"
        })
    end if
    return buildURL(("Users/" + bslib_toString(id) + "/Images/Primary"), params)
end function
'//# sourceMappingURL=./Image.brs.map