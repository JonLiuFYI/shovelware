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

local color = {
    playerblue = {51, 181, 229},
    playerred = {217, 69, 69},
    white = {255, 255, 255}
}

-- music timing stuff
local music = {}
local timescale = 1               -- represents the speed of the game. timescale = 1.5 means 1.5 times the speed.
local time4beats = 2.122    -- time in seconds, scaled by timescale
local time8beats = 4.256
local resttime = -999       -- Wait this long once rest is started. -999 is a magic sentinel value.
local nexttime = -999       -- Wait this long before starting next.
local playtime = -999       -- Wait this long before quitting splitscreen minigames.

-- game phase timing stuff
local faster_interval = 5   -- play 5 games, then get faster
local boss_interval = 15    -- play 15 games, then play a boss. (don't get faster.)
local games_played = 0      -- we've played this many games so far

-- fonts
bigtext = love.graphics.newFont("assets/op-b.ttf", 64)
generictext = love.graphics.newFont("assets/op-l.ttf", 40)

function set_timescale(speed)
    tick.timescale = speed
    music.boss:setPitch(speed)
    music.faster:setPitch(speed)
    music.lose:setPitch(speed)
    music.nextgame:setPitch(speed)
    music.win:setPitch(speed)
end

local logo
local heart


function love.load()
    bindings = {pl = {left = "a", right = "d", up = "w", down = "s", action = "f"},
                pr = {left = "left", right = "right", up = "up", down = "down", action = "return"}}
    screenCenter.x = love.graphics.getWidth() / 2
    screenCenter.y = love.graphics.getHeight() / 2

    games = love.filesystem.getDirectoryItems("games")
    bosses = love.filesystem.getDirectoryItems("bosses")
    music = {
        begin = love.audio.newSource("assets/sw_begin.wav"),
        boss = love.audio.newSource("assets/sw_boss.wav"),
        faster = love.audio.newSource("assets/sw_faster.wav"),
        gameover = love.audio.newSource("assets/sw_gameover.wav"),
        intro = love.audio.newSource("assets/sw_intro.wav"),
        lose = love.audio.newSource("assets/sw_lose.wav"),
        nextgame = love.audio.newSource("assets/sw_next.wav"),
        win = love.audio.newSource("assets/sw_win.wav")
    }
    tick.framerate = 60
    set_timescale(timescale)

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
    love.graphics.setFont(generictext)
    love.graphics.printf("press ENTER", 0, screenCenter.y * 1.5, screenCenter.x * 2, "center", 0, 1, 1, 0, generictext:getHeight() / 1.7)
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
    -- load two games. don't let them be the same.
    splitScreen.left = require("games/" .. games[love.math.random(#games)]:sub(1, -5))
    repeat
        splitScreen.right = require("games/" .. games[love.math.random(#games)]:sub(1, -5))
    until splitScreen.right ~= splitScreen.left

    playtime = time8beats

    print(splitScreen.left.load())
    print(splitScreen.right.load())
end

function splitScreen:leave()
    rest.lastWin.pl = splitScreen.left.win
    rest.lastWin.pr = splitScreen.right.win
    if not rest.lastWin.pl then
        rest.lives = rest.lives - 1
    end
    if not rest.lastWin.pr then
        rest.lives = rest.lives - 1
    end
    if rest.lastWin.pl and rest.lastWin.pr then

    end
end

function splitScreen:keypressed(key)
    splitScreen.left.keypressed(key, bindings.pl)
    splitScreen.right.keypressed(key, bindings.pr)
end

function splitScreen:update(dt)
    if playtime > 0 then
        playtime = playtime - dt
    elseif -999 < playtime and playtime <= 0 then
        playtime = -999
        Gamestate.pop()
    end

    splitScreen.left.update(dt)
    splitScreen.right.update(dt)
end

function splitScreen:draw()
    splitScreen.left.draw(0, screenCenter.x, screenCenter.y * 2)
    splitScreen.right.draw(screenCenter.x, screenCenter.x, screenCenter.y * 2)

    local beats_left = math.floor(playtime/time8beats*8)
    if beats_left <= 3 then
        love.graphics.printf(math.max(beats_left, 0), 0, screenCenter.y * 2 / 4 * 3, screenCenter.x * 2, "center")
    end
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

    resttime = time8beats

    heart = love.graphics.newImage("assets/heart.png")
    heartScale = (love.graphics.getHeight() / 6) / heart:getHeight()

    resttime = time8beats

    rest.lives = 2
    rest.lastWin = {}
    rest.fromMenu = true
    music.begin:play()
    music.intro:play()
end

function rest:leave()
    --highscore
end

function rest:resume()
    rest.fromMenu = false
    -- play the right music based on how the team played. Then start the countdown to next game.
    if rest.lastWin.pl and rest.lastWin.pr then
        music.win:play()
    else
        music.lose:play()
    end
    
    games_played = games_played + 1
    
    resttime = time4beats
end

function rest:update(dt)
    if resttime > 0 then
        resttime = resttime - dt
    elseif -999 < resttime and resttime <= 0 then
        resttime = -999
        if rest.lives <= 0 then
            music.gameover:play()
            Gamestate.pop()
        else
            music.nextgame:play()
            nexttime = time4beats
        end
    end

    if nexttime > 0 then
        nexttime = nexttime - dt
    elseif -999 < nexttime and nexttime <= 0 then
        Gamestate.push(splitScreen)
        nexttime = -999
    end
end

function rest:draw()
    if not rest.fromMenu then
        if rest.lastWin.pl then
            love.graphics.setColor(color.playerblue)
            love.graphics.printf("L won!", 0, screenCenter.y, screenCenter.x, "center", 0, 1, 1, 0, bigtext:getHeight() / 1.7)
        elseif not rest.lastWin.pl then
            love.graphics.setColor(color.white)
            love.graphics.printf("L lost!", 0, screenCenter.y, screenCenter.x, "center", 0, 1, 1, 0, bigtext:getHeight() / 1.7)
        end

        if rest.lastWin.pr then
            love.graphics.setColor(color.playerred)
            love.graphics.printf("R won!", screenCenter.x, screenCenter.y, screenCenter.x, "center", 0, 1, 1, 0, bigtext:getHeight() / 1.7)
        elseif not rest.lastWin.pr then
            love.graphics.setColor(color.white)
            love.graphics.printf("R lost!", screenCenter.x, screenCenter.y, screenCenter.x, "center", 0, 1, 1, 0, bigtext:getHeight() / 1.7)
        end
    else
        love.graphics.printf("Let's play!", 0, screenCenter.y, screenCenter.x * 2, "center", 0, 1, 1, 0, bigtext:getHeight() / 1.7)
    end
    
    love.graphics.setColor(color.white)
    love.graphics.setFont(generictext)
    love.graphics.printf("(Games played: "..games_played..")", 0, screenCenter.y + 200, screenCenter.x * 2, "center", 0, 1, 1, 0, generictext:getHeight() / 1.7)
    
    love.graphics.setFont(bigtext)
    love.graphics.setColor(color.white)
    love.graphics.draw(heart, screenCenter.x, screenCenter.y / 4, 0, heartScale, heartScale, heart:getWidth() / 2, heart:getHeight() / 2)
    love.graphics.printf(math.max(rest.lives, 0), 0, screenCenter.y / 4, screenCenter.x * 2, "center", 0, 1, 1, 0, bigtext:getHeight() / 1.7)
end
--------------------------------------------------------------------------------
