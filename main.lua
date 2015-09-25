gameState = "title"
player = {
	x = 0, 
	y = 0, 
	width = 32, 
	height = 48, 
	speed = 200,
	velocity = {x = 0, y = 0},
	direction = "down",
	animationFrame = 3
}
rupeeImages = {}
rupeeMaxSizeMultiplier = 1.2
rupeeWidth = 16
rupeeHeight = 28
rupeeAcceleration = 1
rupeeStartingVelocity = 0
rupeeStartingY = 0
rupeeBlinkFrameCount = 5 * 60
rupeeDisappearFrameCount = rupeeBlinkFrameCount + 2 * 60
rupeeBlinkSpeed = 5
rupees = {} -- {x, y, value, framecount}
fallingRupees = {} -- {x, y, finalY, value, velocity}
displayScore = 0
targetScore = 0
font = nil
background = nil
titleScreen = nil
gameOverScreen = nil
pickupSound = nil
pickupSound2 = nil
landingSound = nil
lowTimeSound = nil
gameOverSound = nil
startSound = nil
shadow = nil
hasPlayedLowTimeSound = false
framesSinceRupeeSpawn = {}
rupeeSpawnOddsFunctions = {}
walkanimations = {
	down = {},
	up = {},
	left = {},
	right = {}
}
rupeeSpawnOddsFunctions[1] = function(frames)
	return 1 - frames / 1000
end
rupeeSpawnOddsFunctions[5] = function(frames)
	return 1.1 - frames / 1000
end
rupeeSpawnOddsFunctions[20] = function(frames)
	return math.pow(0.99, frames / 1000)
end
maxPlayTime = 60 --seconds
playTime = 0 --seconds
lowTimeTime = maxPlayTime - 15
playArea = {}

function normalize(vector)
	mag = math.sqrt(vector.x^2 + vector.y^2)
	if (mag == 0) then return {x = 0, y = 0} end
	return {x = vector.x / mag, y = vector.y / mag}
end

function checkRectangleCollsion(x1, y1, w1, h1, x2, y2, w2, h2)
	return x1 < x2 + w2 and x1 + w1 > x2 and y1 < y2 + h2 and y1 + h1 > y2
end

function love.load()
	font = love.graphics.newFont(40)
	love.graphics.setBackgroundColor(0, 0, 0)
	pickupSound = love.audio.newSource("pickup.ogg")
	pickupSound2 = love.audio.newSource("pickup2.ogg")
	landingSound = love.audio.newSource("landing.ogg")
	lowTimeSound = love.audio.newSource("timelow.ogg")
	gameOverSound = love.audio.newSource("gameover.ogg")
	startSound = love.audio.newSource("start.ogg")
	playArea.width = love.graphics.getWidth()
	playArea.height = love.graphics.getHeight() - 40
	background = love.graphics.newImage("background.png")
	titleScreen = love.graphics.newImage("title.png")
	gameOverScreen = love.graphics.newImage("gameover.png")
	rupeeImages[1] = love.graphics.newImage("green.png")
	rupeeImages[5] = love.graphics.newImage("blue.png")
	rupeeImages[20] = love.graphics.newImage("red.png")
	shadow = love.graphics.newImage("shadow.png")
	for i,_ in pairs(rupeeImages) do
		framesSinceRupeeSpawn[i] = 0
	end
	for i = 0, 6 do
		walkanimations.left[i] = love.graphics.newImage("walkleft/" .. i .. ".png")
		walkanimations.right[i] = love.graphics.newImage("walkright/" .. i .. ".png")
		walkanimations.down[i] = love.graphics.newImage("walkdown/" .. i .. ".png")
		walkanimations.up[i] = love.graphics.newImage("walkup/" .. i .. ".png")
	end
	player.x = (playArea.width - player.width) / 2
	player.y = (playArea.height - player.height) / 2
end

function love.update(dt)
	if gameState == "title" then
		if (love.keyboard.isDown(" ")) then 
			gameState = "playing"
			startSound:clone():play()
		end
		return
	end
	if gameState == "gameOver" then
		if (love.keyboard.isDown(" ")) then
			player.x = (playArea.width - player.width) / 2
			player.y = (playArea.height - player.height) / 2
			player.animationFrame = 3
			targetScore = 0
			displayScore = 0
			fallingRupees = {}
			rupees = {}
			hasPlayedLowTimeSound = false
			playTime = 0
			startSound:clone():play()
			gameState = "playing"
			return
		end
	end
	if gameState == "playing" then
		playTime = playTime + dt
		if playTime >= maxPlayTime then 
			gameState = "gameOver"
			gameOverSound:clone():play()
			return
		end
		if not hasPlayedLowTimeSound and playTime > lowTimeTime then 
			hasPlayedLowTimeSound = true
			lowTimeSound:clone():play()
		end
		player.velocity = {x = 0, y = 0}
		if (love.keyboard.isDown("left")) then player.velocity.x = player.velocity.x - 1 end
		if (love.keyboard.isDown("right")) then player.velocity.x = player.velocity.x + 1 end
		if (love.keyboard.isDown("up")) then player.velocity.y = player.velocity.y - 1 end
		if (love.keyboard.isDown("down")) then player.velocity.y = player.velocity.y + 1 end
		player.velocity = normalize(player.velocity)
		player.x = math.min(playArea.width - player.width, 
			math.max(0, player.x + player.velocity.x * player.speed * dt))
		player.y = math.min(playArea.height - player.height, 
			math.max(0, player.y + player.velocity.y * player.speed * dt))
		for i,v in ipairs(fallingRupees) do
			v.y = v.y + v.velocity
			v.velocity = v.velocity + rupeeAcceleration
			if (v.y >= v.finalY) then
				table.insert(rupees, {x = v.x - rupeeWidth / 2, y = v.finalY - rupeeHeight / 2, value = v.value, framecount = 0})
				table.remove(fallingRupees, i)
				landingSound:clone():play()
			end
		end
		olddirection = player.direction
		if player.velocity.y > 0 then player.direction = "down" 
		elseif player.velocity.y < 0 then player.direction = "up"
		elseif player.velocity.x > 0 then player.direction = "right"
		elseif player.velocity.x < 0 then  player.direction = "left" end
		if player.direction == olddirection then
			if player.velocity.x == 0 and player.velocity.y == 0 then player.animationFrame = 3
			else 
				player.animationFrame = player.animationFrame + 0.25
				if player.animationFrame > 6 then player.animationFrame = 0 end
			end
		else player.animationFrame = 0 end
		for i,v in ipairs(rupees) do
			v.framecount = v.framecount + 1
			if v.framecount > rupeeDisappearFrameCount then 
				table.remove(rupees, i) 
			end
			if checkRectangleCollsion(player.x, player.y, 
				player.height, player.width, v.x, v.y, rupeeWidth, rupeeHeight) then
				targetScore = targetScore + v.value
				table.remove(rupees, i)
				pickupSound:clone():play()
				if (v.value == 20) then pickupSound2:clone():play() end
			end
		end
		if displayScore < targetScore then displayScore = displayScore + 1 end
		for i,v in pairs(framesSinceRupeeSpawn) do
			framesSinceRupeeSpawn[i] = framesSinceRupeeSpawn[i] + 1
			if (math.random() > rupeeSpawnOddsFunctions[i](v)) then
				table.insert(fallingRupees, {
					x = math.random(playArea.width),
					y = rupeeStartingVelocity,
					finalY = math.random(1, playArea.height - rupeeWidth / 2),
					velocity = 0,
					value = i
				})
				framesSinceRupeeSpawn[i] = 0
			end
		end
		return
	end
end

function love.draw()
	love.graphics.draw(background, 0, 0)
	love.graphics.setColor(0, 0, 0, 255)
	love.graphics.rectangle("fill", 0, playArea.height, love.graphics.getWidth(), 40)
	love.graphics.setColor(255, 255, 0)
	love.graphics.setFont(font)
	if gameState == "playing" then
	--love.graphics.rectangle("fill", player.x, player.y, player.width, player.height)
		love.graphics.setColor(255, 255, 255, 100)
		for i,v in ipairs(fallingRupees) do
			multiplier = rupeeMaxSizeMultiplier - (rupeeMaxSizeMultiplier - 1) * (v.y / v.finalY)
			width = rupeeWidth * multiplier
			height = rupeeHeight * multiplier
			love.graphics.draw(shadow, v.x - width / 2, v.finalY - height / 2 + rupeeWidth / 4, 0, multiplier, multiplier)
		end
		for i,v in ipairs(rupees) do
			love.graphics.draw(shadow, v.x, v.y + rupeeWidth / 4)
		end
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.draw(walkanimations[player.direction][math.floor(player.animationFrame)], player.x, player.y)
		for i,v in ipairs(fallingRupees) do
			multiplier = rupeeMaxSizeMultiplier - (rupeeMaxSizeMultiplier - 1) * (v.y / v.finalY)
			width = rupeeWidth * multiplier
			height = rupeeHeight * multiplier
			love.graphics.draw(rupeeImages[v.value], v.x - width / 2, v.y - height / 2, 0, multiplier, multiplier)
		end
		for i,v in ipairs(rupees) do
			if v.framecount < rupeeBlinkFrameCount or 
				v.framecount % (rupeeBlinkSpeed * 2) >= rupeeBlinkSpeed then
				love.graphics.draw(rupeeImages[v.value], v.x, v.y)
			end
		end
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.rectangle("fill", 10, 
			playArea.height + (love.graphics.getHeight() - playArea.height) / 4, 150 * (1 - playTime / maxPlayTime), 20 )
	end
	if gameState == "playing" or gameState == "gameOver" then
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.printf("" .. displayScore, playArea.width - 200, playArea.height, 200, "right")
	end
	if gameState == "title" then
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.draw(titleScreen, 0, 0)
	end
	if gameState == "gameOver" then
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.draw(gameOverScreen, 0, 0)
	end
end

