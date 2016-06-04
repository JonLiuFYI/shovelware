function love.conf(t)
	t.title = "game"
	t.version = "0.10.0"
	t.window.fullscreen = true
    t.window.fullscreentype = "desktop"
	t.window.fsaa = 4
	t.window.msaa = 4
	t.window.vsync = true

	-- For Windows debugging
	t.console = true
end
