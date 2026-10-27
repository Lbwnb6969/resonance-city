function print(_valueToPrint)
    _CONSOLE:print(tostring(_valueToPrint))
end

function _CONSOLE_INDEX(table, _index)
    for i, v in ipairs(table["_CONSOLE_GLOBALS"]) do
        local result = v[_index]
        if (type(result) == "function") then
            return function(...)
                return result(v, ...)
            end
        end
    end

    return nil
end
