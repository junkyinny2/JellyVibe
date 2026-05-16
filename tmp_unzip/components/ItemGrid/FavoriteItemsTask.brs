'import "pkg:/source/api/baserequest.bs"
'import "pkg:/source/api/sdk.bs"
'import "pkg:/source/utils/config.bs"

sub init()
    m.top.functionName = "setFavoriteStatus"
end sub

sub setFavoriteStatus()
    task = m.top.favTask
    if isStringEqual(task, "favorite")
        api_users_MarkFavorite(m.top.itemId, {
            userId: m.global.session.user.id
        })
    else
        api_users_UnmarkFavorite(m.top.itemId, {
            userId: m.global.session.user.id
        })
    end if
end sub
'//# sourceMappingURL=./FavoriteItemsTask.brs.map