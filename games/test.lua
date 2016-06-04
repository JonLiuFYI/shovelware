local test = {}
test.win = true

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
        test.win = false
    end
end

function test.update(dt)

end

function test.draw(x1, x2, y)
    love.graphics.setColor(100, 100, 0)
    love.graphics.rectangle("fill", x1, 0, x2-x1, y)
    love.graphics.setColor(255, 255, 255)
    love.graphics.print("Don't press ACTION", x1, y / 2)
    if not test.win then
        love.graphics.print("Oops!", x1, y/2-200)
    end
end

return test
