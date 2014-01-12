Car = require './car'

module.exports = class PoliceCar extends Car
	constructor: (@world, @playerCar, @map, @position) ->
		super @world,
			position: @position
			density: 0.9
			power: 40
			renderOffset:
				x: 0
				y: 0
			maxSpeed: 200
		@position =
			x: 5
			y: 5
		@controls =
			move: new THREE.Vector2()
		@crashed = false

	load: () =>
		@bodyGeometry = new THREE.PlaneGeometry 128 * 1.8, 256 * 1.8
		matrix = new THREE.Matrix4()
		@bodyGeometry.applyMatrix matrix.makeRotationX -Math.PI / 2
		@bodyGeometry.applyMatrix matrix.makeRotationY Math.PI
		#@updateSprite(0)
		map = THREE.ImageUtils.loadTexture("textures/police.png")
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
		angle = -@body.GetAngle() + Math.PI
		delta = @playerCar.root.position.clone().sub(@root.position)
		distance = delta.length()
		direction = delta.normalize()
		relativeDirection =
			x: direction.x * Math.cos(angle) - direction.z * Math.sin(angle)
			y: direction.x * Math.sin(angle) + direction.z * Math.cos(angle)

		# Drive towards playes unless crashed.
		@controls.move.x = -relativeDirection.x
		unless @crashed
			@controls.move.y = if relativeDirection.y > 0 then 1 else -1 #1
		else
			@controls.move.y = -1

		# WATCH OUT FOR WALLS... skreeech
		walls = [0x8080, 0xffff]
		tileAhead = @lookAhead angle
		if tileAhead in walls
			tileLeft = @lookAhead(angle + Math.PI / 3)
			tileRight = @lookAhead(angle - Math.PI / 3)
			#console.log tileAhead in walls, tileLeft in walls, tileRight in walls
			if tileRight not in walls
				@controls.move.x = 1
			else if tileLeft not in walls
				@controls.move.x = -1
		
			# Test if police crashed (crashing with the player is ok, though)
			if @getSpeedKMH() < 1 and distance > 500
				@crashed = true
				setTimeout =>
					@crashed = false
				, 1000	
