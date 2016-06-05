local test = {}

function test.load()
    test.win = true
end

function test.keypressed(key, pBindings)
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
    love.graphics.printf("Don't press ACTION", x1, y / 2, x2 - x1, "center")
    if not test.win then
        love.graphics.printf("Oops!", x1, y / 3, x2 - x1, "center")
    end
end

return test
