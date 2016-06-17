local Gamestate = require "hump.gamestate"
Timer = require "hump.timer"
local tick = require "tick"
local Wave = require "wave"

-- Gamestates ------------------------------------------------------------------
local menu = {}
local splitScreen = {}
local boss = {}
local rest = {}
local postgame = {}
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
local menubgm
local timescale = 1               -- represents the speed of the game. timescale = 1.5 means 1.5 times the speed.
local time4beats = 2.122    -- time in seconds, scaled by timescale
local time8beats = 4.256

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
    -- should this audio be loaded statically to reduce load delays?
    music = {
        begin = Wave:newSource("assets/audio_rest/sw_begin.wav", "static"),
        boss = Wave:newSource("assets/audio_rest/sw_boss.wav", "static"),
        faster = Wave:newSource("assets/audio_rest/sw_faster.wav", "static"),
        gameover = Wave:newSource("assets/audio_rest/sw_gameover.wav", "static"),
        intro = Wave:newSource("assets/audio_rest/sw_intro.wav", "static"),
        lose = Wave:newSource("assets/audio_rest/sw_lose.wav", "static"),
        nextgame = Wave:newSource("assets/audio_rest/sw_next.wav", "static"),
        tick = Wave:newSource("assets/audio_rest/tick.wav", "static"),
        win = Wave:newSource("assets/audio_rest/sw_win.wav", "static"),
        postgame = Wave:newSource("assets/audio_outofgame/sw_postgame.wav"):setLooping(true):setVolume(.6),
    }
    for i,f in ipairs(love.filesystem.getDirectoryItems("assets/audio_splitscreen")) do
        table.insert(minigame_bgm, Wave:newSource("assets/audio_splitscreen/"..f, "static"))
    end
    menubgm = Wave:newSource("assets/audio_outofgame/fchp_kt.wav", "static")
        :parse()
        :setIntensity(10)
        :setBPM(128):onBeat(function() tweens.pulse(0) end)
        :setLooping(true)
        :setTargetPitch(1)
        :setTargetVolume(1)
        
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
    menubgm:update(dt)
end


-- Menu gamestate --------------------------------------------------------------
function menu:enter()
    menu:resume()
end

function menu:resume()
    menubgm:play()
end

function menu:draw()
    local logo_scalefactor = 1 + 1/20*menubgm:getEnergy() * (1 - tweens_scale.pulse)
    
    love.graphics.setColor(color.white)
    love.graphics.draw(graphics.logo, screenCenter.x, screenCenter.y / 1.5, 0,
        graphics_scale.logo * (1 + 1/8*menubgm:getEnergy() * (1 - tweens_scale.pulse)), graphics_scale.logo * logo_scalefactor,
        graphics.logo:getWidth() / 2, graphics.logo:getHeight() / 2)
    
    love.graphics.setFont(fonts.generic)
    love.graphics.printf("press ENTER", 0, screenCenter.y * 1.5, screenCenter.x * 2, "center", 0, 1, 1, 0, fonts.generic:getHeight() / 1.7)
    love.graphics.setColor(color.playerblue)
    love.graphics.print("By Jon Liu and Andre Ostrovsky\ngithub.com/PocketEngi/shovelware", 50, 50)
end

function menu:keyreleased(key)
    if key == 'return' then
        menubgm:stop()
        Gamestate.push(rest)
    elseif key == 'escape' then
        love.event.quit()
    end
end
--------------------------------------------------------------------------------

-- SplitScreen gamestate -------------------------------------------------------
local beats_left = 7
function splitScreen:enter()
    start_ticking = true
    beats_left = 7
    Timer.after(time8beats, function()
        Gamestate.pop()
    end)

    Timer.every(time8beats/8, function()
        beats_left = beats_left - 1
        if beats_left <= 3 then
            music.tick:play()
            tweens.pulse(2.5)
        end
    end, 7)
    
    minigame_bgm[love.math.random(#minigame_bgm)]:play()

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
    next_game.l.update(dt, bindings.pl)
    next_game.r.update(dt, bindings.pr)
end

function splitScreen:draw()
    next_game.l.draw()
    next_game.r.draw()
    
    love.graphics.setColor(color.black)
    love.graphics.circle("fill", screenCenter.x, screenCenter.y * 2 / 4 * 3, 64)
    
    if beats_left <= 3 then
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
--------------------------------------------------------------------------------

-- TODO: Boss gamestate---------------------------------------------------------------
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
-- Wat do after playing the win/lose jingle?
function watdo()
    -- no more lives. game over. Leave this state.
    if rest.lives <= 0 then
        Gamestate.switch(postgame)

    -- incoming boss: insert boss warning before next game
    elseif games_played % boss_interval == 0 and games_played ~= 0 then
        warn_of_boss = true
        music.boss:play()
        anim.show_sign()
        Timer.after(time8beats, function() show_warning() end)

    -- speed up: insert speed warning before next game
    elseif games_played % faster_interval == 0 and games_played ~= 0 then
        warn_of_faster = true
        music.faster:play()
        anim.show_sign()
        Timer.after(time8beats, function() show_warning() end)

    -- nothing special. just move to next minigame.
    else
        music.nextgame:play()
        Timer.after(time4beats, function()
            move_to_next_game()
        end)
    
        -- load two games. don't let them be the same.
        next_game.l = require("games/" .. games[love.math.random(#games)]:sub(1, -5))
        repeat
            next_game.r = require("games/" .. games[love.math.random(#games)]:sub(1, -5))
        until next_game.r ~= next_game.l
        show_next_instruction = true
    end
end

-- show warning for speed up or boss
function show_warning()
    if warn_of_faster then
        timescale = timescale + faster_inc
        set_timescale(timescale)
    end
    
    -- warn flags
    warn_of_boss = false
    warn_of_faster = false
    
    music.nextgame:play()
    Timer.after(time4beats, function()
        move_to_next_game()
    end)
end

-- do this immediately before launching the next minigame
function move_to_next_game()
    love.audio.stop()
    -- TODO: conditionally switch to boss
    Gamestate.push(splitScreen)
end

function rest:enter()
    timescale = 1
    set_timescale(timescale)    -- gotta reset properly
    games_played = 0
    
    anim.letsplay_popin()

    Timer.after(time8beats, function() watdo() end)

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

    Timer.after(time4beats, function() watdo() end)
end

function rest:update(dt)

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
                screenCenter.x*(1 + 2.5*tweens_scale.backslide), screenCenter.y/2, 0,
                graphics_scale.faster_sign*(tweens_scale.popin + 4*tweens_scale.backslide), graphics_scale.faster_sign*(tweens_scale.popin - tweens_scale.backslide),
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

-- Postgame state --------------------------------------------------------------
function postgame:enter(score)
    music.gameover:play()
    Timer.after(time4beats, function()
        music.postgame:play()
    end)
end

function postgame:draw()
    love.graphics.setColor(color.white)
    love.graphics.setFont(fonts.big)
    love.graphics.printf("Game over! Games played: "..games_played,
        screenCenter.x, screenCenter.y/2,
        screenCenter.x * 2, "center", 0,
        1, 1,
        screenCenter.x, fonts.big:getHeight() / 1.7)
    
    love.graphics.setFont(fonts.generic)
    love.graphics.printf("(Allan please implement high scores)", 0, screenCenter.y, screenCenter.x * 2, "center", 0, 1, 1, 0, fonts.generic:getHeight() / 1.7)
    love.graphics.printf("ENTER: return to menu", 0, screenCenter.y * 1.5, screenCenter.x * 2, "center", 0, 1, 1, 0, fonts.generic:getHeight() / 1.7)
end
    
function postgame:update(dt)
end

function postgame:keyreleased(key)
    if key == 'return' then
        love.audio.stop()
        Gamestate.pop()
    end
end