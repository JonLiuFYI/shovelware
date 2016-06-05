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

function bla.draw(x1, x2, y)
    love.graphics.setColor(0, 100, 100)
    love.graphics.rectangle("fill", x1, 0, x2-x1, y)
    love.graphics.setColor(255, 255, 255)
    love.graphics.print("press LEFT", x1, y / 2)
    if bla.win then
        love.graphics.print("You did it!", x1, y/2-200)
    end
end

return bla
