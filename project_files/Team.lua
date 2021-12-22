Team = {}

function Team:new(name)
    local o = {
        name = name or "Un-named",
        players = {},
        score = 0,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Team:scored(points)
    self.score = self.score + points
end

function Team:addPlayer(player)
    table.insert(self.players,player)
end

function Team:tostring()
    print_table(self)
end

function print_table(table, level)
    level = level or 0
    for k, v in pairs(table) do
        print(string.rep("\t",level)..k, v)
        if type(v) == "table" then
            print_table(v,level + 1)
        end
    end
end

return Team