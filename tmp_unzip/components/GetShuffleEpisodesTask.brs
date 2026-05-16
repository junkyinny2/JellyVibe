'import "pkg:/source/utils/config.bs"
'import "pkg:/source/api/sdk.bs"

sub init()
    m.top.functionName = "getShuffleEpisodesTask"
end sub

sub getShuffleEpisodesTask()
    data = api_shows_GetEpisodes(m.top.showID, {
        UserId: m.global.session.user.id
        SortBy: "Random"
        Limit: 200
    })
    m.top.data = data
end sub
'//# sourceMappingURL=./GetShuffleEpisodesTask.brs.map