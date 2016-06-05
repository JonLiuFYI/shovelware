local foo = {}

function foo.load(x, w, h)
    foo.win = false
    foo.instruction = "Run!"
    foo.x = x
    foo.w = w
    foo.h = h
end

function foo.keypressed(key, bindings)

end

function foo.update(dt, bindings)
    if love.keyboard.isDown(bindings.pl.left) then

    end
    if love.keyboard.isDown(bindings.pl.right) then

    end
    if love.keyboard.isDown(bindings.pl.up) then

    end
    if love.keyboard.isDown(bindings.pl.down) then

    end
    if love.keyboard.isDown(bindings.pr.left) then

    end
    if love.keyboard.isDown(bindings.pr.right) then

    end
    if love.keyboard.isDown(bindings.pr.up) then

    end
    if love.keyboard.isDown(bindings.pr.down) then

    end
end

function foo.draw()
    love.graphics.printf("It Works", foo.x, foo.h / 2, foo.w, "center")
end

return foo
