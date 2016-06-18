function love.conf(t)
	t.title = "shovelware"
	t.version = "0.10.0"
    t.window.width = 1200
    t.window.height = 900
	t.window.fullscreen = false
    t.window.fullscreentype = "desktop"
	-- is msaa really needed?
	t.window.msaa = 4
	t.window.vsync = true

	-- For Windows debugging
	t.console = true
end
