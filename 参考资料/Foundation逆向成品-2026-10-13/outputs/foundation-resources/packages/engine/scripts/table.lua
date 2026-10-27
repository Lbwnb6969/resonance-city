--------------------------------------------------------------------------
table._LUA_TABLE_CONCAT = table.concat
table.concat = function(tab, sep, i, j)
    if type(tab) == "userdata" then
        sep = sep or ""
        i = i or 1
        j = j or #tab
        result = ""
        for it = i,j do
            if (#result ~= 0) then
                result = result .. sep
            end
            result = result .. tab[it]
        end
        return result
    else
        return table._LUA_TABLE_CONCAT(tab, sep, i, j)
    end
end

--------------------------------------------------------------------------
table._LUA_TABLE_INSERT = table.insert
table.insert = function(tab, pos, value)
    if type(tab) == "userdata" then
        table._HURRICANE_TABLE_INSERT(tab, pos, value)
    else
        if type(value) == "nil" then
            table._LUA_TABLE_INSERT(tab, pos)
        else
            table._LUA_TABLE_INSERT(tab, pos, value)
        end
    end
end

--------------------------------------------------------------------------
table._LUA_TABLE_MAXN = table.maxn
table.maxn = function(tab)
    if type(tab) == "userdata" then
        return #tab
    else
        return table._LUA_TABLE_MAXN(tab)
    end
end

--------------------------------------------------------------------------
table._LUA_TABLE_REMOVE = table.remove
table.remove = function(tab, pos)
    if type(tab) == "userdata" then
        return table._HURRICANE_TABLE_REMOVE(tab, pos)
    else
        return table._LUA_TABLE_REMOVE(tab, pos)
    end
end

--------------------------------------------------------------------------
table.mergearray = function(table1, table2)
	local new = {}
	
	for i = 1, #table1 do
		table.insert(new, table1[i])
	end
	
	for i = 1, #table2 do
		table.insert(new, table2[i])
	end
	
	return new
end

--------------------------------------------------------------------------
return function()
	table.concat = table._LUA_TABLE_CONCAT
	table._LUA_TABLE_CONCAT = nil
	
	table.insert = table._LUA_TABLE_INSERT
	table._LUA_TABLE_INSERT = nil
	
	table.maxn = table._LUA_TABLE_MAXN
	table._LUA_TABLE_MAXN = nil

	table.remove = table._LUA_TABLE_REMOVE
	table._LUA_TABLE_REMOVE = nil
end
