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
local warntime = -999       -- Wait this long while a warning is playing.
local nexttime = -999       -- Wait this long before starting next.
local playtime = -999       -- Wait this long before quitting splitscreen minigames.

-- game phase timing stuff
local faster_interval = 2   -- play 5 games, then get faster
local faster_inc = 0.05     -- add to timescale by this much every faster_interval
local warn_of_faster = false   -- display a warning that the game is getting faster
local boss_interval = 6    -- play 15 games, then play a boss. (don't get faster.)
local warn_of_boss = false  -- display a waning that a boss is coming up
local games_played = 0      -- we've played this many games so far

-- graphics for in-game
local graphics = {}
local graphics_scale = {}   -- scaling ratios for resolution independence

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
    love.mouse.setVisible(false)

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
        tick = love.audio.newSource("assets/tick.wav"),
        tock = love.audio.newSource("assets/tock.wav"),
        win = love.audio.newSource("assets/sw_win.wav")
    }
    graphics = {
        faster_sign = love.graphics.newImage("assets/faster.png"),
        boss_sign = love.graphics.newImage("assets/boss.png")
    }
    -- TODO: don't manually handle graphics_scale like this. use a for loop like a smart person.
    graphics_scale = {
        faster_sign = (love.graphics.getHeight() / 3) / graphics.faster_sign:getHeight(),
        boss_sign = (love.graphics.getHeight() / 3) / graphics.boss_sign:getHeight()
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

    splitScreen.left.load(0, screenCenter.x, screenCenter.y * 2)
    splitScreen.right.load(screenCenter.x, screenCenter.x, screenCenter.y * 2)
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

    splitScreen.left.update(dt, bindings.pl)
    splitScreen.right.update(dt, bindings.pr)
end

function splitScreen:draw()
    splitScreen.left.draw()
    splitScreen.right.draw()

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
    boss.game.update(dt, bindings)
end

function boss:draw()
    boss.game.draw(0, screenCenter.x * 2, screenCenter.y * 2)
end
--------------------------------------------------------------------------------

-- Rest gamestate -------------------------------------------------------
function rest:enter()
    set_timescale(1)    -- gotta reset properly
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
    local playnext = true

    -- wait while win/lose tune plays, then play the next appropriate thing
    if resttime > 0 then
        resttime = resttime - dt
    elseif -999 < resttime and resttime <= 0 then
        resttime = -999
        -- no more lives. game over. Leave this state.
        if rest.lives <= 0 then
            set_timescale(1)
            music.gameover:play()
            Gamestate.pop()

        -- incoming boss: insert boss warning before nexttime
        elseif games_played % boss_interval == 0 and games_played ~= 0 then
            warn_of_boss = true
            music.boss:play()
            warntime = time8beats

        -- speed up: insert speed warning before nexttime
        elseif games_played % faster_interval == 0 and games_played ~= 0 then
            warn_of_faster = true
            music.faster:play()
            warntime = time8beats
            timescale = timescale + faster_inc
            set_timescale(timescale)

        -- nothing special. just move to next minigame.
        else
            nexttime = time4beats
        end
    end

    -- wait while warning plays, then proceed to nexttime
    if warntime > 0 then
        warntime = warntime - dt
    elseif -999 < warntime and warntime <= 0 then
        warn_of_boss = false
        warn_of_faster = false
        nexttime = time4beats
        warntime = -999
    end

    -- wait while next tune plays, then move to minigames
    if nexttime > 0 then
        if playnext then music.nextgame:play() end
        playnext = false
        nexttime = nexttime - dt
    elseif -999 < nexttime and nexttime <= 0 then
        love.audio.stop()
        Gamestate.push(splitScreen)
        nexttime = -999
    end
end

function rest:draw()
    if not rest.fromMenu then
        if rest.lastWin.pl then
            love.graphics.setColor(color.playerblue)
            love.graphics.setFont(bigtext)
            love.graphics.printf("Pass!", 0, screenCenter.y, screenCenter.x, "center", 0, 1, 1, 0, bigtext:getHeight() / 1.7)
        elseif not rest.lastWin.pl then
            love.graphics.setColor(color.white)
            love.graphics.setFont(bigtext)
            love.graphics.printf("Miss!", 0, screenCenter.y, screenCenter.x, "center", 0, 1, 1, 0, bigtext:getHeight() / 1.7)
            love.graphics.setFont(generictext)
            love.graphics.printf("-1 life", 0, screenCenter.y + 50, screenCenter.x, "center", 0, 1, 1, 0, generictext:getHeight() / 1.7)
        end

        if rest.lastWin.pr then
            love.graphics.setColor(color.playerred)
            love.graphics.setFont(bigtext)
            love.graphics.printf("Pass!", screenCenter.x, screenCenter.y, screenCenter.x, "center", 0, 1, 1, 0, bigtext:getHeight() / 1.7)
        elseif not rest.lastWin.pr then
            love.graphics.setColor(color.white)
            love.graphics.setFont(bigtext)
            love.graphics.printf("Miss!", screenCenter.x, screenCenter.y, screenCenter.x, "center", 0, 1, 1, 0, bigtext:getHeight() / 1.7)
            love.graphics.setFont(generictext)
            love.graphics.printf("-1 life", screenCenter.x, screenCenter.y + 50, screenCenter.x, "center", 0, 1, 1, 0, generictext:getHeight() / 1.7)
        end

        if warn_of_faster then
            love.graphics.setColor(color.white)
            love.graphics.draw(graphics.faster_sign, screenCenter.x, screenCenter.y-200, 0, 1, 1, graphics.faster_sign:getWidth() / 2, graphics.faster_sign:getHeight() / 2)
        elseif warn_of_boss then
            love.graphics.setColor(color.white)
            love.graphics.draw(graphics.boss_sign, screenCenter.x, screenCenter.y-200, 0, 1, 1, graphics.boss_sign:getWidth() / 2, graphics.boss_sign:getHeight() / 2)
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
