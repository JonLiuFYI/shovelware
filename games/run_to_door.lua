local run_to_door = {}
local sodapop = require 'sodapop'
local player
local enemy
local speed
local enemyScale
local stop


function run_to_door.load(x, w, h)
    run_to_door.win = false
    run_to_door.instruction = "Run!"
    run_to_door.x = x
    run_to_door.w = w
    run_to_door.h = h

    stop = false
    speed = love.graphics.getWidth() / 256

    player = sodapop.newAnimatedSprite(run_to_door.x + run_to_door.w / 8 * 5, run_to_door.h / 2)
    player:addAnimation('run', {
        image        = love.graphics.newImage('assets/running_mascot.png'),
        frameWidth   = 307,
        frameHeight  = 445,
        frames       = {{1, 1, 5, 1, .1},},
    })
    player.sx = (love.graphics.getHeight() / 8) / 445
    player.sy = (love.graphics.getHeight() / 8) / 445
    player.flipX = true

    enemy = sodapop.newSprite(love.graphics.newImage('assets/ufo_enemy.png'), run_to_door.x + run_to_door.w / 8 * 7 , run_to_door.h / 2)
    enemy.sx = (love.graphics.getHeight() / 8) / 491
    enemy.sy = (love.graphics.getHeight() / 8) / 491
end

function run_to_door.keypressed(key, pBindings)

end

function run_to_door.update(dt, pBindings)
    if not run_to_door.win and not stop then
        player:update(dt)
        if love.keyboard.isDown(pBindings.left) then
            player.x = player.x - speed
        end
        enemy.x = enemy.x - speed * 0.7
        if player.x == run_to_door.x then
            run_to_door.win = true
        elseif enemy.x <= player.x then
            stop = true
        end
    end
end

function run_to_door.draw()
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", run_to_door.x, 0, run_to_door.w, run_to_door.h)
    player:draw()
    enemy:draw()
    if run_to_door.win then
        love.graphics.printf("Safe!", run_to_door.x, run_to_door.h / 3, run_to_door.w, "center")
    end
end

return run_to_door
