--- @diagnostic disable: deprecated

Button = {}

function Button:new(text,x1,y1,x2,y2)
    local o = {
        text = text or "Button",
        coords = {
            top_left = {
                x = x1 or 0,
                y = y1 or 0
            },
            bottom_right = {
                x = x2 or 0,
                y = y2 or 0
            }
        },
        callback = nil,
        btn_color = {},
        txt_color = {}
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Button:isClicked(callback,args)
    if args then
        callback(unpack(args))
    else
        callback()
    end
end

function Button:setCoords(x1,y1,x2,y2)
    self.coords.top_left.x = x1
    self.coords.top_left.y = y1
    self.coords.bottom_right.x = x2
    self.coords.bottom_right.y = y2
end

function Button:setButtonColor(color)
    self.btn_color = {unpack(color)}    
end

function Button:setTextColor(color)
    self.txt_color = {unpack(color)}    
end

return Button