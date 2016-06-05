local test = {}

function test.load(x, w, h)
    test.win = true
    test.instruction = "Obey!"
    test.x = x
    test.w = w
    test.h = h
end

function test.keypressed(key, pBindings)
    if key == pBindings.action then
        test.win = false
    end
end

function test.update(dt, pBindings)

end

function test.draw()
    love.graphics.setColor(100, 100, 0)
    love.graphics.rectangle("fill", test.x, 0, test.w, test.h)
    love.graphics.setColor(255, 255, 255)
    love.graphics.printf("Don't press ACTION", test.x, test.h / 2, test.w, "center")
    if not test.win then
        love.graphics.printf("Oops!", test.x, test.h / 3, test.w, "center")
    end
end

return test
