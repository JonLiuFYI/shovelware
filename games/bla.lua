local bla = {}

function bla.load()
    bla.win = false
    bla.instruction = "Do this!"
end

function bla.keypressed(key, pBindings)
    if key == pBindings.left then
        bla.win = true
    end
end

function bla.update(dt)

end

function bla.draw(x, w, h)
    love.graphics.setColor(0, 100, 100)
    love.graphics.rectangle("fill", x, 0, w, h)
    love.graphics.setColor(255, 255, 255)
    love.graphics.printf("press LEFT", x, h / 2, w, "center")
    if bla.win then
        love.graphics.printf("You did it!", x, h / 3, w, "center")
    end
end

return bla
