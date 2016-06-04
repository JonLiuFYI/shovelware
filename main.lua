local Gamestate = require 'hump.gamestate'

-- Gamestates ------------------------------------------------------------------
local menu = {}
local splitScreen = {}
local boss = {}
--------------------------------------------------------------------------------

local games = {}
local bosses = {}


function love.load()
    screenCenter = {x = love.graphics.getWidth() / 2, y = love.graphics.getHeight() / 2}
    games = love.filesystem.getDirectoryItems("games")
    bosses = love.filesystem.getDirectoryItems("bosses")
    Gamestate.registerEvents()
    Gamestate.switch(menu)
end

-- Menu gamestate --------------------------------------------------------------
function menu:enter()
    logo = love.graphics.newImage("assets/logo.png")
    logoScale = (love.graphics.getHeight() / 4) / logo:getHeight()
end

function menu:draw()
    love.graphics.draw(logo, screenCenter.x, screenCenter.y / 1.5, 0, logoScale, logoScale, logo:getWidth() / 2, logo:getHeight() / 2)
end

function menu:keyreleased(key, code)
    if key == 'return' then
        Gamestate.switch(splitScreen)
    elseif key == 'escape' then
        love.event.quit()
    end
end

--------------------------------------------------------------------------------

-- SplitScreen gamestate -------------------------------------------------------
function splitScreen:enter()
    splitScreen.left = require("games/" .. games[love.math.random(#games)]:sub(1, -5))
    splitScreen.right = require("games/" .. games[love.math.random(#games)]:sub(1, -5))
    print(splitScreen.left.logic())
    print(splitScreen.right.logic())
end

function splitScreen:update(dt)

end

function splitScreen:draw()

end
--------------------------------------------------------------------------------

-- Boss gamestate---------------------------------------------------------------
function boss:enter()
    boss.game = require("bosses/" .. bosses[love.math.random(#bosses)]:sub(1, -5))
end

function boss:update(dt)

end

function boss:draw()

end
--------------------------------------------------------------------------------
