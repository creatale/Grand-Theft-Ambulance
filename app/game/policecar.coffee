Car = require './car'

module.exports = class PoliceCar extends Car
	constructor: (@playerCar, @map) ->
		@lastForward = 0
		super

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

		@lastForward = (@lastForward + 1) % 4

		controls =
			moveLeft: steerLeft and (@lastForward is 0 or steerHard)
			moveRight: steerRight and (@lastForward is 0 or steerHard)
			moveForward: (@lastForward is 0) or driveFast
		super(delta, controls)
