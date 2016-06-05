local bla = {}

function bla.load(x, w, h)
    bla.win = false
    bla.instruction = "Do this!"
    bla.x = x
    bla.w = w
    bla.h = h
end

function bla.keypressed(key, pBindings)
    if key == pBindings.left then
        bla.win = true
    end
end

function bla.update(dt, pBindings)

end

function bla.draw()
    love.graphics.setColor(0, 100, 100)
    love.graphics.rectangle("fill", bla.x, 0, bla.w, bla.h)
    love.graphics.setColor(255, 255, 255)
    love.graphics.printf("press LEFT", bla.x, bla.h / 2, bla.w, "center")
    if bla.win then
        love.graphics.printf("You did it!", bla.x, bla.h / 3, bla.w, "center")
    end
end

return bla
