'import "pkg:/source/api/sdk.bs"
'import "pkg:/source/utils/config.bs"

sub init()
    m.top.functionName = "preloadTrickplayImagesTask"
end sub

sub preloadTrickplayImagesTask()
    fs = CreateObject("roFileSystem")
    if m.top.method = "ADD"
        for tileIndex = 0 to m.top.numImagesToLoad
            updatedURL = ("Videos/" + bslib_toString(m.top.videoID) + "/Trickplay/" + bslib_toString(m.top.trickplayWidth) + "/" + bslib_toString(tileIndex) + ".jpg?api_key=" + bslib_toString(get_user_setting("token")))
            if not fs.Exists(("tmp:/" + bslib_toString(m.top.videoID) + "-" + bslib_toString(tileIndex) + ".jpg"))
                APIRequest(updatedURL).gettofile(("tmp:/" + bslib_toString(m.top.videoID) + "-" + bslib_toString(tileIndex) + ".jpg"))
            end if
        end for
        return
    end if
    if m.top.method = "REMOVE"
        for tileIndex = 0 to m.top.numImagesToLoad
            if fs.Exists(("tmp:/" + bslib_toString(m.top.videoID) + "-" + bslib_toString(tileIndex) + ".jpg"))
                fs.Delete(("tmp:/" + bslib_toString(m.top.videoID) + "-" + bslib_toString(tileIndex) + ".jpg"))
            end if
        end for
        return
    end if
end sub
'//# sourceMappingURL=./PreloadTrickplayImagesTask.brs.map