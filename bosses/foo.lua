local foo = {}

function foo.load(x, w, h)
    foo.win = false
    foo.instruction = "Run!"
    foo.x = x
    foo.w = w
    foo.h = h
end

function foo.keypressed(key, bindings)
    if key == bindings.pl.left then

    end
    if key == bindings.pl.right then

    end
    if key == bindings.pl.up then

    end
    if key == bindings.pl.down then

    end
    if key == bindings.pr.left then

    end
    if key == bindings.pr.right then

    end
    if key == bindings.pr.up then

    end
    if key == bindings.pr.down then

    end
end

function foo.update(dt)

end

function foo.draw()
    love.graphics.printf("It Works", foo.x, foo.h / 2, foo.w, "center")
end

return foo
