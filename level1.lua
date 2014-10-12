-----------------------------------------------------------------------------------------
--
-- level1.lua
--
-----------------------------------------------------------------------------------------

local storyboard = require("storyboard")
local scene = storyboard.newScene()

-- include Corona's "physics" library
local physics = require "physics"
physics.start()
physics.pause()

--------------------------------------------

-- forward declarations and other locals
local screenW, screenH, halfW, halfH = display.contentWidth, display.contentHeight, display.contentWidth*0.5, display.contentHeight*0.5

-----------------------------------------------------------------------------------------
-- BEGINNING OF YOUR IMPLEMENTATION
-- 
-- NOTE: Code outside of listener functions (below) will only be executed once,
--		 unless storyboard.removeScene() is called.
-- 
-----------------------------------------------------------------------------------------

function colorFromId(id)
	-- Red, Green, Blue
	if id == 0 then return { 1, 0, 0 }
	elseif id == 1 then return { 0, 1, 0 }
	elseif id == 2 then return { 0.2, 0.2, 1 }
	end
end

-- Called when the scene's view does not exist:
function scene:createScene(event)
	local group = self.view

	-- background image
	local background = display.newImageRect("assets/background.png", screenW, screenH)
	background.anchorX = 0
	background.anchorY = 0
	
	centerObject = display.newImageRect("assets/portal.png", 90, 90)
	centerObject.x, centerObject.y = halfW, halfH
	--centerObject = display.newRect(halfW, halfH, 90, 90)
	colorId = math.random(0, 2)
	setFill(centerObject, colorId)
	centerObject.rotation = 0
	oldrotation = 0
	
	-- add physics to the galaxy
	physics.addBody(centerObject, "static", { density=1.0, friction=0.3, bounce=0.3 })
	physics.setGravity(0, 0)
	
	-- all display objects must be inserted into group
	group:insert(background)
	group:insert(centerObject)
	
	stars = display.newGroup()
	
	bgm = audio.loadStream("assets/starstrike.mp3")
	audio.play(bgm)
	
	if not spawnrate then spawnrate = 30 end
end

function setFill(object, colId)
	local color = colorFromId(colId)
	object:setFillColor(color[1], color[2], color[3])
end

-- Called immediately after scene has moved onscreen:
function scene:enterScene(event)
	local group = self.view
	inscene = true
	physics.start()
end

function cycleColors(event)
	if event.phase ~= "began" then return nil end
	colorId = (colorId + 1) % 3
	setFill(centerObject, colorId)
end

spawnDelay = 0
stopGame = false
score = 0

function starCollide(event)
	-- Make sure the object is colliding with the center, otherwise return as error
	if event.other == centerObject then
		-- Destroy this object
		event.target:removeSelf()
		stars:remove(event.target)
		-- Mark the game as stopped if the colours are not the same
		if event.target.colorId ~= colorId then 
			stopGame = true
		else score = score + 1
		end
	end
end

accelerationMult = 0
-- c/110 *45
local starVertices = { 0,-45, 12.15,-14.32, 42.95,-14.32, 17.59,6.55, 26.59,36.81, 0,18.41, -26.59,36.81, -17.59,6.13, -42.95,-14.32, -11.04,-14.32 }

function enterFrame()
	-- Stop the game if it is over
	if stopGame == true then
		storyboard.gotoScene("gameover", "fade", 500)
		storyboard.removeScene("level1")
	end
	-- Do not execute code if the game is not running
	if inscene == false then return nil end
	-- Rotate portal
	oldrotation = oldrotation + 1
	centerObject.rotation = oldrotation
	-- Perform actions on each star
	for i = 1, stars.numChildren do
		local star = stars[i]
		local vx, vy = star:getLinearVelocity()
		local accel = 1.05 + accelerationMult
		star:setLinearVelocity(vx*accel, vy*accel) -- Increase current velocity by 5%
		star.rotation = star.rotation + star.rotationSpeed -- Rotate the star
	end
	-- Spawn loop
	if spawnDelay == 30 then
		-- Create rectangle
		local star = display.newImageRect("assets/star.png", 45, 45)
		-- Spawn rectangle at the edges of the screen
		if math.random(4) == 1 then
			if math.random(2) == 1 then star.x = 0
			else star.x = screenW
			end
			star.y = math.random(screenH)
		else
			if math.random(2) == 1 then star.y = 0
			else star.y = screenH
			end
			star.x = math.random(screenW)
		end
		-- Select a random color
		star.colorId = math.random(0, 2)
		setFill(star, star.colorId)
		-- Randomly rotate the star
		star.rotation = math.random(0, 360)
		star.rotationSpeed = math.random(5, 10)
		-- Apply physics
		physics.addBody(star, { density=1.0, friction=0.3, bounce=0.3 })
		-- Calculate velocity
		local xOffs = centerObject.x - star.x
		local yOffs = centerObject.y - star.y
		local distance = math.sqrt((xOffs*xOffs) + (yOffs*yOffs))
		local speed = math.random(40, 45)
		star:setLinearVelocity(speed*xOffs/distance, speed*yOffs/distance)
		accelerationMult = accelerationMult + 0.001
		-- Set up collisions
		star:addEventListener("collision", starCollide)
		stars:insert(star)
		-- Reset spawns
		spawnDelay = 0
	else spawnDelay = spawnDelay + 1
	end
end

Runtime:addEventListener("enterFrame", enterFrame)
Runtime:addEventListener("touch", cycleColors)

-- Called when scene is about to move off-screen:
function scene:exitScene(event)
	local group = self.view
	physics.stop()
	audio.fadeOut(500)
	inscene = false
end

-- If scene's view is removed, scene:destroyScene() will be called just prior to being destroyed:
function scene:destroyScene(event)
	local group = self.view
	
	for i = 1, stars.numChildren do
		local star = stars[i]
		star:removeSelf()
	end
	stars = nil
	
	package.loaded[physics] = nil
	physics = nil
	
	Runtime:removeEventListener("enterFrame", enterFrame)
	Runtime:removeEventListener("touch", cycleColors)
	
	audio.stop()
	audio.dispose(bgm)
end

-----------------------------------------------------------------------------------------
-- END OF YOUR IMPLEMENTATION
-----------------------------------------------------------------------------------------

-- "createScene" event is dispatched if scene's view does not exist
scene:addEventListener( "createScene", scene )

-- "enterScene" event is dispatched whenever scene transition has finished
scene:addEventListener( "enterScene", scene )

-- "exitScene" event is dispatched whenever before next scene's transition begins
scene:addEventListener( "exitScene", scene )

-- "destroyScene" event is dispatched before view is unloaded, which can be
-- automatically unloaded in low memory situations, or explicitly via a call to
-- storyboard.purgeScene() or storyboard.removeScene().
scene:addEventListener( "destroyScene", scene )

-----------------------------------------------------------------------------------------

return scene