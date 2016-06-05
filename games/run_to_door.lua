local run_to_door = {}
local sodapop = require 'sodapop'
local player
local enemy
local speed
local enemyScale


function run_to_door.load(x, w, h)
    run_to_door.win = false
    run_to_door.instruction = "Run!"
    run_to_door.x = x
    run_to_door.w = w
    run_to_door.h = h

    speed = love.graphics.getWidth() / 128

    player = sodapop.newAnimatedSprite(run_to_door.x + run_to_door.w / 4 * 3, run_to_door.h / 2)
    player:addAnimation('run', {
        image        = love.graphics.newImage('assets/running_mascot.png'),
        frameWidth   = 307,
        frameHeight  = 445,
        frames       = {{1, 1, 5, 1, .08},},
    })
    player.sx = (love.graphics.getHeight() / 8) / 445
    player.sy = (love.graphics.getHeight() / 8) / 445
    player.flipX = true

    enemy = sodapop.newSprite(love.graphics.newImage('assets/ufo_enemy.png'), run_to_door.x + run_to_door.w / 8 * 7 , run_to_door.h / 2)
    enemy.sx = (love.graphics.getHeight() / 8) / 491
    enemy.sy = (love.graphics.getHeight() / 8) / 491
end

function run_to_door.keypressed(key, pBindings)
    if key == pBindings.left then
        player.x = player.x - speed
    end
end

function run_to_door.update(dt, pBindings)
    player:update(dt)
    if love.keyboard.isDown(pBindings.left) then
        player.x = player.x - speed
    end
end

function run_to_door.draw()
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", run_to_door.x, 0, run_to_door.w, run_to_door.h)
    player:draw()
    enemy:draw()
end

return run_to_door
