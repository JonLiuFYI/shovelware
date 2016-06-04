local Gamestate = require "hump.gamestate"
local tick = require "tick"

-- Gamestates ------------------------------------------------------------------
local menu = {}
local splitScreen = {}
local boss = {}
local rest = {}
--------------------------------------------------------------------------------

local games = {}
local bosses = {}
local screenCenter = {}
local bindings = {}

local music = {}

function love.load()
    bindings = {pl = {left = "a", right = "d", up = "w", down = "s", action = "f"},
                pr = {left = "left", right = "right", up = "up", down = "down", action = "return"}}
    screenCenter.x = love.graphics.getWidth() / 2
    screenCenter.y = love.graphics.getHeight() / 2
    games = love.filesystem.getDirectoryItems("games")
    bosses = love.filesystem.getDirectoryItems("bosses")
    music = {
        begin = love.audio.newSource("assets/sw_begin.wav")
    }
    Gamestate.registerEvents()
    Gamestate.push(menu)
end

-- Menu gamestate --------------------------------------------------------------
function menu:enter()
    logo = love.graphics.newImage("assets/logo.png")
    logoScale = (love.graphics.getHeight() / 4) / logo:getHeight()
end

function menu:draw()
    love.graphics.draw(logo, screenCenter.x, screenCenter.y / 1.5, 0, logoScale, logoScale, logo:getWidth() / 2, logo:getHeight() / 2)
    love.graphics.print("press ENTER", 600, 500)
end

function menu:keyreleased(key)
    if key == 'return' then
        Gamestate.push(rest)
    elseif key == 'escape' then
        love.event.quit()
    end
end
--------------------------------------------------------------------------------

-- SplitScreen gamestate -------------------------------------------------------
function splitScreen:enter()
    splitScreen.left = require("games/" .. games[love.math.random(#games)]:sub(1, -5))
    splitScreen.right = require("games/" .. games[love.math.random(#games)]:sub(1, -5))
    print(splitScreen.left.load())
    print(splitScreen.right.load())
end

function splitScreen:leave()
    if not splitScreen.left.win then
        rest.lives = rest.lives - 1
    end
    if not splitScreen.right.win then
        rest.lives = rest.lives - 1
    end
    if splitScreen.left.win and splitScreen.right.win then

    end
end

function splitScreen:keypressed(key)
    splitScreen.left.keypressed(key, bindings.pl)
    splitScreen.right.keypressed(key, bindings.pr)
end

function splitScreen:update(dt)
    splitScreen.left.update(dt)
    splitScreen.right.update(dt)
end

function splitScreen:draw()
    splitScreen.left.draw(0, screenCenter.x, screenCenter.y * 2)
    splitScreen.right.draw(screenCenter.x, screenCenter.x * 2, screenCenter.y * 2)
end
--------------------------------------------------------------------------------

-- Boss gamestate---------------------------------------------------------------
function boss:enter()
    boss.game = require("bosses/" .. bosses[love.math.random(#bosses)]:sub(1, -5))
    print(boss.game.load())
end

function boss:leave()
    if boss.game.win then
        rest.lives = rest.lives + 1
    else
        rest.lives = rest.lives - 1
    end
end

function boss:keypressed(key)
    boss.game.keypressed(key, bindings)
end

function boss:update(dt)
    boss.game.update(dt)
end

function boss:draw()
    boss.game.draw(0, screenCenter.x * 2, screenCenter.y * 2)
end
--------------------------------------------------------------------------------

-- Rest gamestate -------------------------------------------------------
function rest:enter()
    rest.lives = 10
    rest.lastWin = {}
    rest.fromMenu = true
    music.begin:play()
end

function rest:leave()
    --highscore
end

function rest:resume()
    rest.fromMenu = false
    if rest.lastWin.pl and rest.lastWin.pr then
        --win music
    else
        --loss music
    end
end

function rest:update(dt)

end

function rest:draw()
    if not rest.fromMenu then
        if rest.lastWin.pl then
            --win
        else
            --lose
        end
        if rest.lastWin.pr then
            --win
        else
            --lose
        end
    end
end
--------------------------------------------------------------------------------
