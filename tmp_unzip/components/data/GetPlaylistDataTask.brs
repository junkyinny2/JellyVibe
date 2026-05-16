'import "pkg:/source/api/sdk.bs"
'import "pkg:/source/utils/config.bs"

sub init()
    m.top.functionName = "getPlaylistData"
end sub

sub getPlaylistData()
    playlistData = api_playlists_GetUser(m.top.playlistID, m.global.session.user.id)
    m.top.playlistData = playlistData
end sub
'//# sourceMappingURL=./GetPlaylistDataTask.brs.map