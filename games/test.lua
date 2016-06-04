local test = {}
test.win = false

function test.load()
    return "test"
end

function test.keypressed(key, pBindings)
    if key == pBindings.left then

    end
    if key == pBindings.right then

    end
    if key == pBindings.up then

    end
    if key == pBindings.down then

    end
    if key == pBindings.action then

    end
end

function test.update(dt)

end

function test.draw(x1, x2, y)
    love.graphics.print("It Works", x1, y / 2)
end

return test
