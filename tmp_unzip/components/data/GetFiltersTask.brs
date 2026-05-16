'import "pkg:/source/utils/config.bs"
'import "pkg:/source/api/sdk.bs"

sub init()
    m.top.functionName = "getFiltersTask"
end sub

sub getFiltersTask()
    m.filters = api_items_GetFilters(m.top.params)
    m.top.filters = m.filters
end sub
'//# sourceMappingURL=./GetFiltersTask.brs.map