local Gamestate = require "hump.gamestate"
local tick = require "tick"

Timer = require "hump.timer"

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
    playerred = {230, 56, 56},
    white = {255, 255, 255},
    black = {0, 0, 0},
    slate = {57, 69, 74},
}

-- music timing stuff
local music = {}
local minigame_bgm = {}
local timescale = 1               -- represents the speed of the game. timescale = 1.5 means 1.5 times the speed.
local time4beats = 2.122    -- time in seconds, scaled by timescale
local time8beats = 4.256
local resttime = -999       -- Wait this long once rest is started. -999 is a magic sentinel value.
local warntime = -999       -- Wait this long while a warning is playing.
local nexttime = -999       -- Wait this long before starting next.
local playtime = -999       -- Wait this long before quitting splitscreen minigames.

-- game phase timing stuff
local faster_interval = 2   -- play this many games, then get faster
local faster_inc = 0.1     -- add to timescale by this much every faster_interval
local warn_of_faster = false   -- display a warning that the game is getting faster
local boss_interval = 999    -- play 15 games, then play a boss. (don't get faster.)
local warn_of_boss = false  -- display a waning that a boss is coming up
local games_played = 0      -- we've played this many games so far

local next_game = {}
local show_next_instruction = false

-- graphics for in-game
local graphics = {}
local graphics_scale = {}   -- scaling ratios for resolution independence

-- fonts
fonts = {}

-- tweening stuff
-- TODO: still need to figure out how to organize tweens
tweens_scale = {
    pulse = 1,
    popin = 1,
    backslide = 0,
}

tweens = {
    pulse = function(scale)
        tweens_scale.pulse = scale
        Timer.tween(time4beats/4,
            tweens_scale,
            {pulse = 1},
            "out-quad")
    end,
    popin = function()
        tweens_scale.popin = 0
        Timer.tween(time4beats/2,
            tweens_scale,
            {popin = 1},
            "in-bounce")
    end,
    backslide = function()
        tweens_scale.backslide = 0
        Timer.tween(time4beats/4,
            tweens_scale,
            {backslide = 1},
            "in-back")
    end,
}
anim = {
    lives_pulse = function()
        Timer.script(function(wait)
            for i=1,4 do
                tweens.pulse(1.5)
                wait(time4beats/4)
            end
        end)
    end,
    letsplay_popin = function()
        tweens_scale.popin = 0
        Timer.script(function(wait)
            wait(3.5*time4beats/4)
            tweens.popin()
        end)
    end,
    show_sign = function()
        tweens_scale.backslide = 0
        Timer.script(function(wait)
            tweens.popin()
            wait(time8beats*7/8)
            tweens.backslide()
        end)
    end,
}

-- TODO: figure out how to timescale sounds provided by minigames
function set_timescale(speed)
    tick.timescale = speed
    music.boss:setPitch(speed)
    music.faster:setPitch(speed)
    music.lose:setPitch(speed)
    music.nextgame:setPitch(speed)
    music.win:setPitch(speed)
    
    for i,x in ipairs(minigame_bgm) do
        x:setPitch(speed)
    end
end

function love.load()
    love.mouse.setVisible(false)

    bindings = {pl = {left = "a", right = "d", up = "w", down = "s", action = "f"},
                pr = {left = "left", right = "right", up = "up", down = "down", action = "return"}}
    screenCenter.x = love.graphics.getWidth() / 2
    screenCenter.y = love.graphics.getHeight() / 2
    
    fonts.big = love.graphics.newFont("assets/fonts/Rubik-Bold.ttf", 64)
    fonts.generic = love.graphics.newFont("assets/fonts/Rubik-Light.ttf", 40)
    fonts.generic:setLineHeight(0.8)

    games = love.filesystem.getDirectoryItems("games")
    bosses = love.filesystem.getDirectoryItems("bosses")
    music = {
        begin = love.audio.newSource("assets/audio_rest/sw_begin.wav"),
        boss = love.audio.newSource("assets/audio_rest/sw_boss.wav"),
        faster = love.audio.newSource("assets/audio_rest/sw_faster.wav"),
        gameover = love.audio.newSource("assets/audio_rest/sw_gameover.wav"),
        intro = love.audio.newSource("assets/audio_rest/sw_intro.wav"),
        lose = love.audio.newSource("assets/audio_rest/sw_lose.wav"),
        nextgame = love.audio.newSource("assets/audio_rest/sw_next.wav"),
        tick = love.audio.newSource("assets/audio_rest/tick.wav"),
        win = love.audio.newSource("assets/audio_rest/sw_win.wav")
    }
    -- TODO: load these by scanning the directory, not by individually loading
    minigame_bgm = {
        love.audio.newSource("assets/audio_splitscreen/sw_a_brief_romance.wav"),
        love.audio.newSource("assets/audio_splitscreen/sw_a_misstep.wav"),
        love.audio.newSource("assets/audio_splitscreen/sw_a_offbeat.wav"),
        love.audio.newSource("assets/audio_splitscreen/sw_a_sadaghdar.wav"),
        love.audio.newSource("assets/audio_splitscreen/sw_b_diurnal_crush.wav"),
        love.audio.newSource("assets/audio_splitscreen/sw_b_nocturnal_strike.wav")
    }
    graphics = {
        faster_sign = love.graphics.newImage("assets/faster.png"),
        boss_sign = love.graphics.newImage("assets/boss.png"),
        heart = love.graphics.newImage("assets/heart.png"),
        logo = love.graphics.newImage("assets/new_logo.png")
    }
    -- TODO: unite graphics_scale and graphics because it makes no sense for these two to be separate.
    graphics_scale = {
        faster_sign = (love.graphics.getHeight() / 3) / graphics.faster_sign:getHeight(),
        boss_sign = (love.graphics.getHeight() / 3) / graphics.boss_sign:getHeight(),
        heart = (love.graphics.getHeight() / 6) / graphics.heart:getHeight(),
        logo = (love.graphics.getHeight() / 2) / graphics.logo:getHeight()
    }
    tick.framerate = 60
    set_timescale(timescale)

    Gamestate.registerEvents()
    Gamestate.push(menu)
end

function love.update(dt)
    Timer.update(dt)
end


-- Menu gamestate --------------------------------------------------------------
function menu:enter()
end

function menu:draw()
    love.graphics.setColor(color.white)
    love.graphics.draw(graphics.logo, screenCenter.x, screenCenter.y / 1.5, 0, graphics_scale.logo, graphics_scale.logo, graphics.logo:getWidth() / 2, graphics.logo:getHeight() / 2)
    
    love.graphics.setFont(fonts.generic)
    love.graphics.printf("press ENTER", 0, screenCenter.y * 1.5, screenCenter.x * 2, "center", 0, 1, 1, 0, fonts.generic:getHeight() / 1.7)
    love.graphics.setColor(color.playerblue)
    love.graphics.print("By Jon Liu and Andre Ostrovsky\ngithub.com/PocketEngi/shovelware", 50, 50)
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
    playtime = time8beats
    
    love.audio.play(minigame_bgm[love.math.random(#minigame_bgm)])

    next_game.l.load(0, screenCenter.x, screenCenter.y * 2)
    next_game.r.load(screenCenter.x, screenCenter.x, screenCenter.y * 2)
end

function splitScreen:leave()
    rest.lastWin.pl = next_game.l.win
    rest.lastWin.pr = next_game.r.win
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
    next_game.l.keypressed(key, bindings.pl)
    next_game.r.keypressed(key, bindings.pr)
end

function splitScreen:update(dt)
    if playtime > 0 then
        playtime = playtime - dt
    elseif -999 < playtime and playtime <= 0 then
        playtime = -999
        Gamestate.pop()
    end

    next_game.l.update(dt, bindings.pl)
    next_game.r.update(dt, bindings.pr)
end

-- these two variables track when a beat has passed. Used in splitScreen:draw().
local old_beats_left = 4
local beats_left = 3
function splitScreen:draw()
    next_game.l.draw()
    next_game.r.draw()
    
    old_beats_left = beats_left
    beats_left = math.max(math.floor(playtime/time8beats*8), 0)
    if beats_left <= 8 then
        -- wtf??? screenCenter.y * 2 / 4 * 3
        love.graphics.setColor(color.black)
        love.graphics.circle("fill", screenCenter.x, screenCenter.y * 2 / 4 * 3, 64)
        
        if beats_left <= 3 then
            if beats_left < old_beats_left then
                music.tick:play()
                tweens.pulse(2.5)
            end
            love.graphics.setColor(color.white)
        else
            love.graphics.setColor(color.slate)
        end
        
        love.graphics.printf(math.max(beats_left, 0),
            screenCenter.x, screenCenter.y * 2 / 4 * 3 + 5, screenCenter.x * 2,
            "center", 0,
            tweens_scale.pulse, tweens_scale.pulse,
            screenCenter.x, fonts.big:getHeight() / 1.7)
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
    timescale = 1
    set_timescale(timescale)    -- gotta reset properly
    
    games_played = 0
    
    anim.letsplay_popin()

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
        anim.lives_pulse()
    else
        if rest.lives <= 0 then
            set_timescale(1)
        end
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
            music.gameover:play()
            Gamestate.pop()

        -- incoming boss: insert boss warning before nexttime
        elseif games_played % boss_interval == 0 and games_played ~= 0 then
            warn_of_boss = true
            music.boss:play()
            anim.show_sign()
            warntime = time8beats

        -- speed up: insert speed warning before nexttime
        elseif games_played % faster_interval == 0 and games_played ~= 0 then
            warn_of_faster = true
            music.faster:play()
            anim.show_sign()
            warntime = time8beats

        -- nothing special. just move to next minigame.
        else
            nexttime = time4beats
            -- load two games. don't let them be the same.
            next_game.l = require("games/" .. games[love.math.random(#games)]:sub(1, -5))
            repeat
                next_game.r = require("games/" .. games[love.math.random(#games)]:sub(1, -5))
            until next_game.r ~= next_game.l
            show_next_instruction = true
        end
    end

    -- wait while warning plays, then proceed to nexttime
    if warntime > 0 then
        warntime = warntime - dt
    elseif -999 < warntime and warntime <= 0 then
        -- play speed warning before speed up occurs
        if warn_of_faster then
            timescale = timescale + faster_inc
            set_timescale(timescale)
        end
        
        -- warn flags
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
            love.graphics.setFont(fonts.big)
            love.graphics.printf("Pass!", 0, screenCenter.y, screenCenter.x, "center", 0, 1, 1, 0, fonts.big:getHeight() / 1.7)
        elseif not rest.lastWin.pl then
            love.graphics.setColor(color.white)
            love.graphics.setFont(fonts.big)
            love.graphics.printf("Miss!", 0, screenCenter.y, screenCenter.x, "center", 0, 1, 1, 0, fonts.big:getHeight() / 1.7)
            love.graphics.setFont(fonts.generic)
            love.graphics.printf("-1 life", 0, screenCenter.y + 50, screenCenter.x, "center", 0, 1, 1, 0, fonts.generic:getHeight() / 1.7)
        end

        if rest.lastWin.pr then
            love.graphics.setColor(color.playerred)
            love.graphics.setFont(fonts.big)
            love.graphics.printf("Pass!", screenCenter.x, screenCenter.y, screenCenter.x, "center", 0, 1, 1, 0, fonts.big:getHeight() / 1.7)
        elseif not rest.lastWin.pr then
            love.graphics.setColor(color.white)
            love.graphics.setFont(fonts.big)
            love.graphics.printf("Miss!", screenCenter.x, screenCenter.y, screenCenter.x, "center", 0, 1, 1, 0, fonts.big:getHeight() / 1.7)
            love.graphics.setFont(fonts.generic)
            love.graphics.printf("-1 life", screenCenter.x, screenCenter.y + 50, screenCenter.x, "center", 0, 1, 1, 0, fonts.generic:getHeight() / 1.7)
        end

        if warn_of_faster then
            love.graphics.setColor(color.white)
            love.graphics.draw(graphics.faster_sign,
                screenCenter.x + 2*screenCenter.x*tweens_scale.backslide, screenCenter.y/2, 0,
                graphics_scale.faster_sign*tweens_scale.popin, graphics_scale.faster_sign*tweens_scale.popin,
                graphics.faster_sign:getWidth() / 2, graphics.faster_sign:getHeight() / 2)
        elseif warn_of_boss then
            love.graphics.setColor(color.white)
            love.graphics.draw(graphics.boss_sign,
                screenCenter.x, screenCenter.y/2, 0,
                graphics_scale.faster_sign*tweens_scale.popin, graphics_scale.faster_sign*tweens_scale.popin,
                graphics.boss_sign:getWidth() / 2, graphics.boss_sign:getHeight() / 2)
        end
    else
        love.graphics.printf("Let's play!",
            screenCenter.x, screenCenter.y/2,
            screenCenter.x * 2, "center", 0,
            1*tweens_scale.popin, 1*tweens_scale.popin,
            screenCenter.x, fonts.big:getHeight() / 1.7)
    end

    love.graphics.setColor(color.white)
    love.graphics.setFont(fonts.generic)
    love.graphics.printf("Games played: "..games_played.."\nTimescale: "..timescale, 0, screenCenter.y + 200, screenCenter.x * 2, "center", 0, 1, 1, 0, fonts.generic:getHeight() / 1.7)

    love.graphics.setFont(fonts.big)
    love.graphics.setColor(color.white)
    love.graphics.draw(graphics.heart,
        screenCenter.x, screenCenter.y, 0,
        graphics_scale.heart*tweens_scale.pulse, graphics_scale.heart*tweens_scale.pulse,
        graphics.heart:getWidth() / 2, graphics.heart:getHeight() / 2)
    love.graphics.printf(math.max(rest.lives, 0),
        screenCenter.x, screenCenter.y,
        screenCenter.x * 2, "center", 0,
        1*tweens_scale.pulse, 1*tweens_scale.pulse,
        screenCenter.x, fonts.big:getHeight() / 1.7 * tweens_scale.pulse)
end
--------------------------------------------------------------------------------
