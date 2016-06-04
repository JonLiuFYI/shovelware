local bla = {}
bla.win = false

function bla.load()
    return "bla"
end

function bla.keypressed(key, pBindings)
    if key == pBindings.left then
        bla.win = true
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

function bla.update(dt)

end

function bla.draw(x1, x2, y)
    love.graphics.print("press LEFT", x1, y / 2)
    if bla.win then
        love.graphics.print("You did it!", x1, y/2-200)
    end
end

return bla
