Player = {}

function Player:new(name)
    local o = {
        name = name or "Un-named",
        isActive = false
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

return Player