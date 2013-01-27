Car = require './car'

module.exports = class PoliceCar extends Car
	constructor: (@world, @playerCar, @map) ->
		super
		@position =
			x: 5
			y: 5
		@lastForward = 0
		@texture = "textures/police.png"

	loadPartsJSON: (bodyURL) =>
		@bodyGeometry = new THREE.PlaneGeometry 128 * 1.8, 256 * 1.8
		matrix = new THREE.Matrix4()
		@bodyGeometry.applyMatrix matrix.makeRotationX -Math.PI / 2
		@bodyGeometry.applyMatrix matrix.makeRotationY Math.PI
		#@updateSprite(0)
		map = THREE.ImageUtils.loadTexture(@texture)
		map.wrapS = map.wrapT = THREE.RepeatWrapping
		@bodyMaterials = [
			new THREE.MeshLambertMaterial( { ambient: 0xbbbbbb, map: map, transparent: true, side: THREE.DoubleSide } ),
		]
		@wheelGeometry = new THREE.SphereGeometry 5, 5, 4
		@createCar()

	lookAhead: (direction) =>
		posX = Math.round (@root.position.x + Math.sin(direction) * 500) / 500 + @map.height / 2
		posY = Math.round (@root.position.z + Math.cos(direction) * 500) / 500 + @map.width / 2
		idx = (posY * @map.width + posX) * 4
		return (@map.data[idx] << 8) + @map.data[idx + 1]

	kiUpdate: (delta) =>
		# Get direction vector towards player.
		angle = @body.GetAngle() + Math.PI
		direction = @playerCar.root.position.clone().sub(@root.position).normalize()
		relativeDirection =
			x: direction.x * Math.cos(angle) - direction.z * Math.sin(angle)
			y: direction.x * Math.sin(angle) + direction.z * Math.cos(angle)

		# Sophisticated decision chain.
		steerLeft = relativeDirection.x > 0.03 or relativeDirection.y < -0.03
		steerRight = not steerLeft and relativeDirection.x < -0.05
		driveFast = relativeDirection.y > 0 and Math.abs(relativeDirection.x) < 0.2
		steerHard = relativeDirection.y < 0 or Math.abs(relativeDirection.x) > 0.15

		# WATCH OUT THE WALL... skreeech
		tileAhead = @lookAhead angle
		if tileAhead in [0x8080, 0xffff]
			tileLeft = @lookAhead(angle + Math.PI / 3)
			tileRight = @lookAhead(angle - Math.PI / 3)
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

		@controls =
			moveLeft: steerLeft and (@lastForward is 0 or steerHard)
			moveRight: steerRight and (@lastForward is 0 or steerHard)
			moveForward: (@lastForward is 0) or driveFast