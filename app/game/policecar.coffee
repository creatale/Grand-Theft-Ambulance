Car = require './car'

module.exports = class PoliceCar extends Car
	constructor: (@playerCar, @map) ->
		@lastForward = 0
		super

	lookAhead: (direction) =>
		posX = Math.round (@root.position.x + Math.sin(direction) * 500) / 500 + @map.height / 2
		posY = Math.round (@root.position.z + Math.cos(direction) * 500) / 500 + @map.width / 2
		idx = (posY * @map.width + posX) * 4
		return (@map.data[idx] << 8) + @map.data[idx + 1]

	update: (delta) =>
		# Get direction vector towards player.
		direction = @playerCar.root.position.clone().sub(@root.position).normalize()
		relativeDirection =
			x: direction.x * Math.cos(@carOrientation) - direction.z * Math.sin(@carOrientation)
			y: direction.x * Math.sin(@carOrientation) + direction.z * Math.cos(@carOrientation)

		# Sophisticated decision chain.
		steerLeft = relativeDirection.x > 0.03 or relativeDirection.y < -0.03
		steerRight = not steerLeft and relativeDirection.x < -0.05
		driveFast = relativeDirection.y > 0 and Math.abs(relativeDirection.x) < 0.2
		steerHard = relativeDirection.y < 0 or Math.abs(relativeDirection.x) > 0.15

		# WATCH OUT THE WALL... skreeech
		tileAhead = @lookAhead(@carOrientation)
		if tileAhead in [0x8080, 0xffff]
			tileLeft = @lookAhead(@carOrientation + Math.PI / 3)
			tileRight = @lookAhead(@carOrientation - Math.PI / 3)
			steerHard = true
			if tileRight not in [0x8080, 0xffff]
				steerRight = true
				steerLeft = false
			else if tileLeft not in [0x8080, 0xfff]
				steerLeft = true
				steerRight = false
			else
				# AAAAAAAHHHH...


		@lastForward = (@lastForward + 1) % 4

		controls =
			moveLeft: steerLeft and (@lastForward is 0 or steerHard)
			moveRight: steerRight and (@lastForward is 0 or steerHard)
			moveForward: (@lastForward is 0) or driveFast
		super(delta, controls)
