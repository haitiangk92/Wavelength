function print_table(table, level)
    level = level or 0
    for k, v in pairs(table) do
        print(string.rep("\t",level)..k, v)
        if type(v) == "table" then
            print_table(v,level + 1)
        end
    end
end

forceFalse = false
forceTrue = true

print(forceFalse and 7 or 8)