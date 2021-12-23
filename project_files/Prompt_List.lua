Prompt_List = {}

function Prompt_List:new()
    local o = self:getPrompts()
    setmetatable(o, self)
    self.__index = self
    return o
end

function Prompt_List:getPrompts()
    local prompts = {}
    for line in io.lines("Prompts.txt") do
        for i,j in string.gmatch(line,"([^,]+),([^,]+)") do
            table.insert(prompts,{i,j})
        end 
    end

    return prompts
end

return Prompt_List