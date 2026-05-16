'
' Returns an object from a URL with its URI components as properties = { proto, host, port, path, query }
' If any of those URI components are missing, they will be set as empty strings = ""
' If the url param provided cannot be parsed, then invalid will be returned
'
' @param url a URL string which will be parsed into URI components
function ParsedUrl(url as string) as object
    rgx = CreateObject("roRegex", "^(?:(.*):\/\/)?([^\/:?]+)(?::(\d+))?(\/[^\r\n?]+)?(?:\?(.*))?$", "")
    match = rgx.Match(url)
    if not isValid(match) then
        return invalid
    end if
    return {
        proto: (function(__bsCondition, match)
                if __bsCondition then
                    return match[1]
                else
                    return ""
                end if
            end function)(isValid(match[1]), match)
        host: (function(__bsCondition, match)
                if __bsCondition then
                    return match[2]
                else
                    return ""
                end if
            end function)(isValid(match[2]), match)
        port: (function(__bsCondition, match)
                if __bsCondition then
                    return match[3]
                else
                    return ""
                end if
            end function)(isValid(match[3]), match)
        path: (function(__bsCondition, len, match)
                if __bsCondition then
                    return (function(__bsCondition, len, match)
                            if __bsCondition then
                                return match[4].left(len(match[4]) - 1)
                            else
                                return match[4]
                            end if
                        end function)(match[4].endswith("/"), len, match)
                else
                    return ""
                end if
            end function)(isValid(match[4]), len, match)
        query: (function(__bsCondition, match)
                if __bsCondition then
                    return match[5]
                else
                    return ""
                end if
            end function)(isValid(match[5]), match)
        toString: __ParsedUrl_ToString
    }
end function

' Returns the parsed URL as a complete URL string
function __ParsedUrl_ToString() as string
    return (bslib_toString((function(__bsCondition, m)
            if __bsCondition then
                return ""
            else
                return (bslib_toString(m.proto) + "://")
            end if
        end function)(m.proto = "", m)) + bslib_toString(m.host) + bslib_toString((function(__bsCondition, m)
            if __bsCondition then
                return ""
            else
                return (":" + bslib_toString(m.port))
            end if
        end function)(m.port = "", m)) + bslib_toString(m.path) + bslib_toString((function(__bsCondition, m)
            if __bsCondition then
                return ""
            else
                return ("?" + bslib_toString(m.query))
            end if
        end function)(m.query = "", m)))
end function
'//# sourceMappingURL=./parsedUrl.brs.map