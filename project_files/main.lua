--- @diagnostic disable: deprecated

COLORS = require "Colors"
Team = require "Team"
Player = require "Player"
Button = require "Button"
Prompt_List = require  "Prompt_List"

WINDOW_WIDTH, WINDOW_HEIGHT = love.window.getDesktopDimensions()

TITLE = "Wavelength"
TITLE_FONT = love.graphics.setNewFont(75)
TITLE_WIDTH = TITLE_FONT.getWidth(TITLE_FONT,TITLE)
TITLE_HEIGHT = TITLE_FONT.getHeight(TITLE_FONT)
TITLE_WIDTH_OFFSET = (WINDOW_WIDTH - TITLE_WIDTH)/2
TITLE_HEIGHT_OFFSET = 25
TITLE_AREA = TITLE_HEIGHT + 2 * TITLE_HEIGHT_OFFSET

BOARD_WIDTH = 1280
BOARD_HEIGHT = WINDOW_HEIGHT - TITLE_AREA - 20
BOARD_WIDTH_OFFET = (WINDOW_WIDTH - BOARD_WIDTH)/2
BOARD_HEIGHT_OFFET = TITLE_AREA
BOARD_COLOR = COLORS.BLUE

follow_mouseX = false
last_mouse_point = 0

CIRCLE_ORIGIN = {
    x = WINDOW_WIDTH/2,
    y = WINDOW_HEIGHT/2 + 50
}

NUM_SPOKES = 35
SPOKES = {}

GearSpoke = {}
function GearSpoke:new(o)
    o = o or {
        width = 35,
        height = 340,
        angle = 0
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

NUM_TRIANGLES = 5
TRIANGLES = {}
TRIANGLE_COLORS = {
    COLORS.GREEN,
    COLORS.PURPLE,
    COLORS.ORANGE
}

PointTriangle = {}
function PointTriangle:new(o)
    o = o or {
        vertices = {
            CIRCLE_ORIGIN.x,
            CIRCLE_ORIGIN.y
        },
        color = {},
        angles = {
            left = 0,
            right = 0
        },
        points = {
            value = 0,
            x = 0,
            y = 0,
            angle = 0,
            rotation = 0
        }
    }
    setmetatable(o, self)
    self.__index = self
    return o
end


GEAR_CIRCLE = {
    radius = 350
}

NEEDLE = {
    width = 10,
    height = 250,
    angle = 0,
    knob_radius = 60
}

HOUSING= {
    color = COLORS.DARK_BLUE,
}

SHIELD = {
    color = COLORS.LIGHT_BLUE,
    starting_angle = 0,
    ending_angle = -math.rad(180),
    handle = {
        inner_point = {
            x = 0,
            y = 0
        },
        outer_point = {
            x = 0,
            y = 0
        },
        width = 40
    },
    transformation = 0
}

WAVE_WHEEL = {
    radius = GEAR_CIRCLE.radius - 20,
    isSpinning = false,
    speed = 0
}

GAME_STATE = {
    Prep = false,
    Spin = false,
    Secret = false,
    Active_Team_Guess = false,
    Opposing_Team_Guess = false,
    Reveal = false
}

local shield_transformation = -3
local delta = (math.rad(1) - math.rad(0)) * -shield_transformation
local shield_name_selector = 1

Team1 = Team:new("1")
Team2 = Team:new("2")
prompt_list = Prompt_List:new()

SHIELD_BUTTON = Button:new()
SPIN_BUTTON = Button:new()

PROMPT_CARD = {
    left = {
        card_color = 0,
        text = ""
    },
    right = {
        card_color = 0,
        text = ""
    },
    text_color = 0,
    coords = {
        top_left = {
            x = 0,
            y = 0
        },
        bottom_right = {
            x = 0,
            y = 0
        }
    } 
}

---------------------------------------------
--- Sets up the original state of the game
-----------------------------------------------
function love.load()
    math.randomseed(os.time())

    love.window.setTitle(TITLE)
    love.window.setMode(
        WINDOW_WIDTH,
        WINDOW_HEIGHT, {
            fullscreen = true,
            resizable = false,
            vsync = true,
        }
    )
    
    -- Creating a list of spokes to surround gear
    local last_angle = 0
    for i = 1, NUM_SPOKES do
        local spoke = GearSpoke:new()
        spoke.angle = math.rad(360)/NUM_SPOKES + last_angle
        last_angle = spoke.angle

        spoke.x = CIRCLE_ORIGIN.x + (math.cos(spoke.angle) * spoke.height)
        spoke.y = CIRCLE_ORIGIN.y + (math.sin(spoke.angle) * spoke.height)

        SPOKES[i] = spoke
    end

    -- Creating Spin Button
    local spinOffest = { 150,75 }

    SPIN_BUTTON:setCoords(
        CIRCLE_ORIGIN.x - spinOffest[1] - 125, 
        CIRCLE_ORIGIN.y + spinOffest[2] - 40, 
        CIRCLE_ORIGIN.x - spinOffest[2], 
        CIRCLE_ORIGIN.y + spinOffest[1] - 40
    )

    SPIN_BUTTON:setButtonColor(COLORS.WHITE)
    SPIN_BUTTON:setTextColor(COLORS.PURPLE)
    SPIN_BUTTON.text = "SPIN"

    -- Creating a list of triangles that will determine the scores
    last_angle = 0
    local last_right = {
        x = CIRCLE_ORIGIN.x + WAVE_WHEEL.radius,
        y = CIRCLE_ORIGIN.y
    }
    local dx = 1
    local color = 1
    local point_value = 2

    for i = 1, NUM_TRIANGLES * 2 do
        local triangle = PointTriangle:new()
        
        if i == NUM_TRIANGLES+1 then
            last_right = { 
                x = CIRCLE_ORIGIN.x - WAVE_WHEEL.radius,
                y = CIRCLE_ORIGIN.y
            }
            last_angle = math.rad(180)
            point_value = 2
        end
        
        triangle.angles.right = math.rad(30)/NUM_TRIANGLES + last_angle
        triangle.angles.left = last_angle
        last_angle = triangle.angles.right

        local left = {
            x = last_right.x,
            y = last_right.y
        }

        local right = {
            x = CIRCLE_ORIGIN.x + (math.cos(triangle.angles.right) * WAVE_WHEEL.radius),
            y = CIRCLE_ORIGIN.y + (math.sin(triangle.angles.right) * WAVE_WHEEL.radius)
        }
        
        last_right = right

        table.insert(triangle.vertices,left.x)
        table.insert(triangle.vertices,left.y)
        table.insert(triangle.vertices,right.x)
        table.insert(triangle.vertices,right.y)

        if color > NUM_TRIANGLES/2 or color < 1 then
            dx = -dx
        end

        if color == 0 then color = 1 end
        
        triangle.color = {unpack(TRIANGLE_COLORS[color])}
        color = color + dx

        triangle.points.value = point_value
        point_value = point_value + dx

        triangle.points.angle = (triangle.angles.left + triangle.angles.right - math.pi/56)/2
        triangle.points.rotation = (triangle.angles.left + triangle.angles.right + math.pi)/2

        TRIANGLES[i] = triangle
    end

    -- print_table(TRIANGLES) -- DEBUG

    -- Creating shield that will cover the "waves region"
    SHIELD.handle.inner_point.radius = NEEDLE.height + 40
    SHIELD.handle.outer_point.radius = WAVE_WHEEL.radius + 60
    SHIELD.handle.inner_point.x = CIRCLE_ORIGIN.x - SHIELD.handle.inner_point.radius
    SHIELD.handle.inner_point.y = CIRCLE_ORIGIN.y
    SHIELD.handle.outer_point.x = CIRCLE_ORIGIN.x - SHIELD.handle.outer_point.radius
    SHIELD.handle.outer_point.y = CIRCLE_ORIGIN.y

    -- Creating Shield Toggle Button
    local shieldOffest = { 75,150 }

    SHIELD_BUTTON:setCoords(
        CIRCLE_ORIGIN.x + shieldOffest[1], 
        CIRCLE_ORIGIN.y + shieldOffest[1] - 40, 
        CIRCLE_ORIGIN.x + shieldOffest[2] + 125, 
        CIRCLE_ORIGIN.y + shieldOffest[2] - 40
    )

    SHIELD_BUTTON:setButtonColor(SHIELD.color)
    SHIELD_BUTTON:setTextColor(COLORS.WHITE)
    SHIELD_BUTTON.text = "OPEN"

    -- Creating the needle with knob
    NEEDLE.angle = math.rad(math.random(180,360))
    NEEDLE.x = CIRCLE_ORIGIN.x + (math.cos(NEEDLE.angle) * NEEDLE.height)
    NEEDLE.y = CIRCLE_ORIGIN.y + (math.sin(NEEDLE.angle) * NEEDLE.height)

    PROMPT_CARD.coords.top_left.x = CIRCLE_ORIGIN.x - 175
    PROMPT_CARD.coords.top_left.y = CIRCLE_ORIGIN.y + 175
    PROMPT_CARD.coords.bottom_right.x = CIRCLE_ORIGIN.x + 175
    PROMPT_CARD.coords.bottom_right.y = CIRCLE_ORIGIN.y + 325

    local prompt = prompt_list[math.random(#Prompt_List)]
    PROMPT_CARD.left.card_color = {math.random(),math.random(),math.random()}
    PROMPT_CARD.left.text = prompt[1]
    PROMPT_CARD.right.card_color = {math.random(),math.random(),math.random()}
    PROMPT_CARD.right.text = prompt[2]

end

--------------------------------------------
--- Gets called every computer clock tick
--------------------------------------------
function love.update(dt)
    -- Controls the speed at which things spin
    WAVE_WHEEL.isSpinning = WAVE_WHEEL.speed > 0
    if WAVE_WHEEL.isSpinning then
        WAVE_WHEEL.speed = WAVE_WHEEL.speed - math.random(4)*dt
    else
        WAVE_WHEEL.speed = 0
    end

    -- Spinning the wheel
    for i = 1, #SPOKES do
        local spoke = SPOKES[i]
        
        spoke.angle = spoke.angle + WAVE_WHEEL.speed*dt
        spoke.x = CIRCLE_ORIGIN.x + (math.cos(spoke.angle) * spoke.height)
        spoke.y = CIRCLE_ORIGIN.y + (math.sin(spoke.angle) * spoke.height)
    end

    for i = 1, #TRIANGLES do
        local triangle = TRIANGLES[i]
        triangle.angles.left = triangle.angles.left + WAVE_WHEEL.speed*dt
        triangle.angles.right = triangle.angles.right + WAVE_WHEEL.speed*dt
        triangle.points.angle = triangle.points.angle + WAVE_WHEEL.speed*dt
        triangle.points.rotation = triangle.points.rotation + WAVE_WHEEL.speed*dt

        triangle.vertices[3] = CIRCLE_ORIGIN.x + (math.cos(triangle.angles.left) * WAVE_WHEEL.radius)
        triangle.vertices[4] = CIRCLE_ORIGIN.y + (math.sin(triangle.angles.left) * WAVE_WHEEL.radius)
        triangle.vertices[5] = CIRCLE_ORIGIN.x + (math.cos(triangle.angles.right) * WAVE_WHEEL.radius)
        triangle.vertices[6] = CIRCLE_ORIGIN.y + (math.sin(triangle.angles.right) * WAVE_WHEEL.radius)

        triangle.points.x = CIRCLE_ORIGIN.x + (math.cos(triangle.points.angle) * (WAVE_WHEEL.radius - 25))
        triangle.points.y = CIRCLE_ORIGIN.y + (math.sin(triangle.points.angle) * (WAVE_WHEEL.radius - 25))
    end

    -- Openning/Closing the shield
    if SHIELD.transformation < 0 then
        if SHIELD.starting_angle ~= 0 and SHIELD.ending_angle ~= math.rad(180) then
            if math.abs(SHIELD.starting_angle - math.rad(0)) < delta then
                SHIELD.starting_angle = 0
                SHIELD.ending_angle = -math.rad(180)
                SHIELD.transformation = 0
            else
                SHIELD.starting_angle = SHIELD.starting_angle + SHIELD.transformation*dt
                SHIELD.ending_angle = SHIELD.ending_angle + SHIELD.transformation*dt
            end
        end
    else
        if SHIELD.starting_angle ~= math.rad(180) and SHIELD.ending_angle ~= 0 then
            if math.abs(SHIELD.starting_angle - math.rad(180)) < delta then
                SHIELD.starting_angle = math.rad(180)
                SHIELD.ending_angle = 0
                SHIELD.transformation = 0
            else
                SHIELD.starting_angle = SHIELD.starting_angle + SHIELD.transformation*dt
                SHIELD.ending_angle = SHIELD.ending_angle + SHIELD.transformation*dt
            end
        end
    end

    SHIELD.handle.inner_point.x = CIRCLE_ORIGIN.x + (math.cos(SHIELD.ending_angle) * SHIELD.handle.inner_point.radius)
    SHIELD.handle.inner_point.y = CIRCLE_ORIGIN.y + (math.sin(SHIELD.ending_angle) * SHIELD.handle.inner_point.radius)
    SHIELD.handle.outer_point.x = CIRCLE_ORIGIN.x + (math.cos(SHIELD.ending_angle) * SHIELD.handle.outer_point.radius)
    SHIELD.handle.outer_point.y = CIRCLE_ORIGIN.y + (math.sin(SHIELD.ending_angle) * SHIELD.handle.outer_point.radius)

    -- Moving the needle
    if love.mouse.isDown(1) then
        if follow_mouseX then
            local currentMouseX, currentMouseY = love.mouse.getPosition()
            local deltaMouseY = last_mouse_point - currentMouseY

            NEEDLE.angle = math.min(math.max(NEEDLE.angle + deltaMouseY/2*dt,math.rad(180)),math.rad(360))
            NEEDLE.x = CIRCLE_ORIGIN.x + (math.cos(NEEDLE.angle) * NEEDLE.height)
            NEEDLE.y = CIRCLE_ORIGIN.y + (math.sin(NEEDLE.angle) * NEEDLE.height)

            last_mouse_point = currentMouseY
        end
    else
        follow_mouseX = false
    end
    -- Add points

    -- Change states

end

----------------------------------
--- Called after each update
----------------------------------
function love.draw()
    -- Setting background color
    love.graphics.setBackgroundColor(unpack(COLORS.PURPLE))

    -- Printing the title to the screen
    love.graphics.setColor(1,1,1)
    love.graphics.print(TITLE,TITLE_WIDTH_OFFSET,TITLE_HEIGHT_OFFSET)

    -- Printing the game board to the screen
    love.graphics.setColor(unpack(BOARD_COLOR))
    love.graphics.rectangle('fill',BOARD_WIDTH_OFFET,BOARD_HEIGHT_OFFET,BOARD_WIDTH,BOARD_HEIGHT)

    -- Printing the wheel to the screen
    love.graphics.setColor(1,1,1)
    love.graphics.circle("fill",CIRCLE_ORIGIN.x,CIRCLE_ORIGIN.y,GEAR_CIRCLE.radius)
    for i = 1, #SPOKES do
        local spoke = SPOKES[i]
        love.graphics.setLineWidth(spoke.width)
        love.graphics.circle("fill",spoke.x,spoke.y,spoke.width)
        love.graphics.line(CIRCLE_ORIGIN.x,CIRCLE_ORIGIN.y,spoke.x,spoke.y)
    end

    -- Drawing Score Triangles
    for i = 1, #TRIANGLES do
        local triangle = TRIANGLES[i]
        love.graphics.setColor(unpack(triangle.color))
        love.graphics.polygon("fill",triangle.vertices)
        love.graphics.setColor(0,0,0)
        love.graphics.print(tostring(triangle.points.value),triangle.points.x,triangle.points.y,triangle.points.rotation,.25)
    end

    -- Drawing the shield to the screen
    love.graphics.setColor(unpack(SHIELD.color))
    love.graphics.arc("fill", CIRCLE_ORIGIN.x,CIRCLE_ORIGIN.y, WAVE_WHEEL.radius, SHIELD.starting_angle, SHIELD.ending_angle)

    -- Drawing the housing cover to the screen
    love.graphics.setColor(unpack(HOUSING.color))
    love.graphics.setLineWidth(35)
    love.graphics.circle("line",CIRCLE_ORIGIN.x,CIRCLE_ORIGIN.y,WAVE_WHEEL.radius)
    love.graphics.polygon("fill",
        CIRCLE_ORIGIN.x - WAVE_WHEEL.radius,CIRCLE_ORIGIN.y,
        CIRCLE_ORIGIN.x + WAVE_WHEEL.radius,CIRCLE_ORIGIN.y,
        CIRCLE_ORIGIN.x + WAVE_WHEEL.radius - 80,CIRCLE_ORIGIN.y + WAVE_WHEEL.radius + 80,
        CIRCLE_ORIGIN.x - WAVE_WHEEL.radius + 80,CIRCLE_ORIGIN.y+ WAVE_WHEEL.radius + 80        
    )

    -- Drawing the shield handle to the screen
    love.graphics.setColor(unpack(SHIELD.color))
    love.graphics.setLineWidth(SHIELD.handle.width)
    love.graphics.line(SHIELD.handle.inner_point.x,SHIELD.handle.inner_point.y,SHIELD.handle.outer_point.x,SHIELD.handle.outer_point.y)
    love.graphics.circle("fill", SHIELD.handle.inner_point.x,SHIELD.handle.inner_point.y, SHIELD.handle.width/2)
    love.graphics.circle("fill", SHIELD.handle.outer_point.x,SHIELD.handle.outer_point.y, SHIELD.handle.width/2)

    -- Drawing Knob and needle
    love.graphics.setColor(1,0,0)
    love.graphics.circle("fill",CIRCLE_ORIGIN.x,CIRCLE_ORIGIN.y,NEEDLE.knob_radius)
    love.graphics.setLineWidth(NEEDLE.width)
    love.graphics.line(CIRCLE_ORIGIN.x,CIRCLE_ORIGIN.y,NEEDLE.x,NEEDLE.y)

    -- Printing the team names and scored to the screen
    love.graphics.setColor(0,0,0)
    love.graphics.printf("Team\n"..Team1.name, BOARD_WIDTH_OFFET + 50,BOARD_HEIGHT_OFFET + 25,200,"center")
    love.graphics.printf("Team\n"..Team2.name, BOARD_WIDTH_OFFET + BOARD_WIDTH - 250,BOARD_HEIGHT_OFFET + 25, 200, "center")

    -- Print scored here

    -- Draw Shield toggle button to the screen
    love.graphics.setColor(unpack(SHIELD_BUTTON.btn_color))
    love.graphics.rectangle("fill",
        SHIELD_BUTTON.coords.top_left.x,
        SHIELD_BUTTON.coords.top_left.y,
        math.abs(SHIELD_BUTTON.coords.top_left.x - SHIELD_BUTTON.coords.bottom_right.x),
        math.abs(SHIELD_BUTTON.coords.top_left.y - SHIELD_BUTTON.coords.bottom_right.y),
        20,20
    )

    love.graphics.setNewFont(60)
    love.graphics.setColor(SHIELD_BUTTON.txt_color)
    love.graphics.printf(
        SHIELD_BUTTON.text, 
        SHIELD_BUTTON.coords.top_left.x,
        SHIELD_BUTTON.coords.top_left.y + 5,
        math.abs(SHIELD_BUTTON.coords.top_left.x - SHIELD_BUTTON.coords.bottom_right.x),
        "center"
    )


    -- Drawing spin button to the screen
    love.graphics.setColor(unpack(SPIN_BUTTON.btn_color))
    love.graphics.rectangle("fill",
        SPIN_BUTTON.coords.top_left.x,
        SPIN_BUTTON.coords.top_left.y,
        math.abs(SPIN_BUTTON.coords.top_left.x - SPIN_BUTTON.coords.bottom_right.x),
        math.abs(SPIN_BUTTON.coords.top_left.y - SPIN_BUTTON.coords.bottom_right.y),
        20,20
    )

    love.graphics.setNewFont(60)
    love.graphics.setColor(SPIN_BUTTON.txt_color)
    love.graphics.printf(
        SPIN_BUTTON.text, 
        SPIN_BUTTON.coords.top_left.x,
        SPIN_BUTTON.coords.top_left.y + 5,
        math.abs(SPIN_BUTTON.coords.top_left.x - SPIN_BUTTON.coords.bottom_right.x),
        "center"
    )

    -- Drawing Prompt
    local card_width = math.abs(PROMPT_CARD.coords.top_left.x - PROMPT_CARD.coords.bottom_right.x)/2
    local card_mid = PROMPT_CARD.coords.top_left.x + card_width
    love.graphics.setColor(unpack(PROMPT_CARD.left.card_color))
    love.graphics.rectangle("fill",
        PROMPT_CARD.coords.top_left.x,
        PROMPT_CARD.coords.top_left.y,
        card_width,
        math.abs(PROMPT_CARD.coords.top_left.y - PROMPT_CARD.coords.bottom_right.y),
        5,5
    )

    love.graphics.setColor(unpack(PROMPT_CARD.right.card_color))
    love.graphics.rectangle("fill",
        card_mid,
        PROMPT_CARD.coords.top_left.y,
        card_width,
        math.abs(PROMPT_CARD.coords.top_left.y - PROMPT_CARD.coords.bottom_right.y),
        5,5
    )

    -- love.graphics.setNewFont(60)
    -- love.graphics.setColor(SPIN_BUTTON.txt_color)
    -- love.graphics.printf(
    --     SPIN_BUTTON.text, 
    --     SPIN_BUTTON.coords.top_left.x,
    --     SPIN_BUTTON.coords.top_left.y + 5,
    --     math.abs(SPIN_BUTTON.coords.top_left.x - SPIN_BUTTON.coords.bottom_right.x),
    --     "center"
    -- )

end


function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    end
end


function love.mousepressed(x,y,button,istouch,presses)
    mouseCoords = {x,y}
    if button == 1 then
        if mouseIsOnButton(mouseCoords,SHIELD_BUTTON) then --and GAME_STATE.Secret then
            SHIELD_BUTTON:isClicked(toggleShield,{text})
        end

        if mouseIsOnKnob(mouseCoords) then
           follow_mouseX = true 
           last_mouse_point = y
        end

        if mouseIsOnButton(mouseCoords, SPIN_BUTTON) then
            SPIN_BUTTON:isClicked(spinWheel)
        end
    end
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


function findMidpoint(x1,y1,x2,y2)
    local x = (x1+x2)/2
    local y = (y1+y2)/2

    return x,y
end


function mouseIsOnButton(mousePos,button)
    local mouseX, mouseY = unpack(mousePos)
    local hovering = false

    if mouseX >= button.coords.top_left.x and 
        mouseX <= button.coords.bottom_right.x and
        mouseY >= button.coords.top_left.y and 
        mouseY <= button.coords.bottom_right.y then
        
        hovering = true
    end

    return hovering
end


function mouseIsOnKnob(mousePos)
    local mouseX, mouseY = unpack(mousePos)
   
    local distance = math.sqrt((mouseX - CIRCLE_ORIGIN.x)^2 + (mouseY - CIRCLE_ORIGIN.y)^2)
    
    return distance < NEEDLE.knob_radius
end


function toggleShield()
    if shield_name_selector > 0 then
        text = "CLOSE"
    else
        text = "OPEN"
    end
    shield_name_selector = -shield_name_selector

    shield_transformation = -shield_transformation
    SHIELD.transformation = shield_transformation
    SHIELD_BUTTON.text = text
end


function spinWheel()
    if not WAVE_WHEEL.isSpinning then
        WAVE_WHEEL.speed = WAVE_WHEEL.speed + math.random(5,15)
    end
end