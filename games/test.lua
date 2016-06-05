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

function test.draw(x, w, h)
    love.graphics.setColor(100, 100, 0)
    love.graphics.rectangle("fill", x, 0, w, h)
    love.graphics.setColor(255, 255, 255)
    love.graphics.printf("Don't press ACTION", x, h / 2, w, "center")
    if not test.win then
        love.graphics.printf("Oops!", x, h / 3, w, "center")
    end
end

return test
