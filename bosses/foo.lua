local foo = {}
foo.win = false

function foo.load()
    return "foo"
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

function foo.draw(x1, x2, y)
    love.graphics.print("It Works", x2 / 2, y / 2)
end

return foo
