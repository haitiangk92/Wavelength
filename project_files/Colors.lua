COLORS = {}

function convert255(r,g,b)
    return {r/255, g/255, b/255}
end

COLORS.YELLOW = convert255(252, 211, 3)
COLORS.DARK_BLUE = convert255(0, 0, 100)
COLORS.LIGHT_BLUE = convert255(100,255,255)
COLORS.PURPLE = convert255(157, 3, 252)
COLORS.ORANGE = convert255(252, 111, 3)
COLORS.RED = convert255(255,0,0)
COLORS.GREEN = convert255(0,255,0)
COLORS.BLUE = convert255(40,40,255)
COLORS.WHITE = convert255(1,1,1)
COLORS.BLACK = convert255(0,0,0)

return COLORS