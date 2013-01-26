quadraticEaseOut = (k) -> -k*(k-2)
cubicEaseOut = (k) -> --k * k * k + 1
circularEaseOut = (k) -> Math.sqrt( 1 - --k * k )
sinusoidalEaseOut = (k) -> Math.sin( k * Math.PI / 2 )
exponentialEaseOut = (k) -> if k is 1 then 1 else -Math.pow(2,-10*k)+1

module.exports = class Car
	# car geometry manual parameters
	constructor: ->
		@modelScale = 1
		@backWheelOffset = 2
		@autoWheelGeometry = true

		# car geometry parameters automatically set from wheel mesh
		# - assumes wheel mesh is front left wheel in proper global
		#   position with respect to body mesh
		#	- other wheels are mirrored against car root
		#	- if necessary back wheels can be offset manually

		@wheelOffset = new THREE.Vector3()

		@wheelDiameter = 1

		# car "feel" parameters

		@MAX_SPEED = 2200
		@MAX_REVERSE_SPEED = -1500

		@MAX_WHEEL_ROTATION = 0.6

		@FRONT_ACCELERATION = 1250
		@BACK_ACCELERATION = 1500

		@WHEEL_ANGULAR_ACCELERATION = 1.5

		@FRONT_DECCELERATION = 750
		@WHEEL_ANGULAR_DECCELERATION = 1.0

		@STEERING_RADIUS_RATIO = 0.0033

		@MAX_TILT_SIDES = 0.05
		@MAX_TILT_FRONTBACK = 0.015

		# internal control variables

		@speed = 0
		@acceleration = 0

		@wheelOrientation = 0
		@carOrientation = 0

		# car rigging

		@root = new THREE.Object3D()

		@frontLeftWheelRoot = new THREE.Object3D()
		@frontRightWheelRoot = new THREE.Object3D()

		@bodyMesh = null

		@frontLeftWheelMesh = null
		@frontRightWheelMesh = null

		@backLeftWheelMesh = null
		@backRightWheelMesh = null

		@bodyGeometry = null
		@wheelGeometry = null

		@bodyMaterials = null
		@wheelMaterials = null

		# internal helper variables

		@loaded = false

		@meshes = []
		
		@grabbing = false

		@texture = "textures/ambulance.png"

		# API

	enableShadows: (enable) =>
		for mesh in @meshes
			mesh.castShadow = enable
			mesh.receiveShadow = enable

	setVisible: (enable) =>
		for mesh in @meshes
			mesh.visible = enable

	loadPartsJSON: (bodyURL) =>
		@bodyGeometry = new THREE.PlaneGeometry 128 * 1.8, 332 * 1.8
		@bodyGeometry.dynamic = true
		matrix = new THREE.Matrix4()
		@bodyGeometry.applyMatrix matrix.makeRotationX -Math.PI / 2
		@bodyGeometry.applyMatrix matrix.makeRotationY Math.PI
		@updateSprite(0)
		map = THREE.ImageUtils.loadTexture(@texture)
		map.wrapS = map.wrapT = THREE.RepeatWrapping
		#map.repeat.set( 1, 2 );
		@bodyMaterials = [
			new THREE.MeshLambertMaterial( { ambient: 0xbbbbbb, map: map, transparent: true, side: THREE.DoubleSide } ),
			#new THREE.MeshBasicMaterial( { color: 0xffffff, wireframe: true, transparent: true, opacity: 0.1, side: THREE.DoubleSide } )
		]
		@wheelGeometry = new THREE.SphereGeometry 5, 5, 4
		@createCar()
		# loader = new THREE.JSONLoader()
		# loader.load bodyURL, (geometry, materials) =>
		# 	@createBody geometry, materials

	updateSprite: (index) =>
		spriteKeyX = index % 5
		spriteKeyY = 3 - ((index / 5) | 0)
		@bodyGeometry.faceVertexUvs[0][0][1].y = 1/4 * spriteKeyY
		@bodyGeometry.faceVertexUvs[0][0][2].y = 1/4 * spriteKeyY
		@bodyGeometry.faceVertexUvs[0][0][0].y = 1/4 * (spriteKeyY + 1)
		@bodyGeometry.faceVertexUvs[0][0][3].y = 1/4 * (spriteKeyY + 1)
		@bodyGeometry.faceVertexUvs[0][0][0].x = 1/5 * spriteKeyX
		@bodyGeometry.faceVertexUvs[0][0][1].x = 1/5 * spriteKeyX
		@bodyGeometry.faceVertexUvs[0][0][2].x = 1/5 * (spriteKeyX + 1)
		@bodyGeometry.faceVertexUvs[0][0][3].x = 1/5 * (spriteKeyX + 1)
		@bodyGeometry.uvsNeedUpdate = true
		

	# loadPartsBinary: (bodyURL, wheelURL) =>
	# 	loader = new THREE.BinaryLoader()
	# 	loader.load bodyURL, (geometry, materials) =>
	# 		@createBody geometry, materials

	# 	loader.load wheelURL, (geometry, materials) =>
	# 		@createWheels geometry, materials


	update: (delta, controls) =>

	# speed and wheels based on controls

		if controls.moveForward
			@speed = THREE.Math.clamp(@speed + delta * @FRONT_ACCELERATION, @MAX_REVERSE_SPEED, @MAX_SPEED)
			@acceleration = THREE.Math.clamp(@acceleration + delta, -1, 1)

		if controls.moveBackward
			@speed = THREE.Math.clamp(@speed - delta * @BACK_ACCELERATION, @MAX_REVERSE_SPEED, @MAX_SPEED)
			@acceleration = THREE.Math.clamp(@acceleration - delta, -1, 1)

		if controls.moveLeft
			@wheelOrientation = THREE.Math.clamp(@wheelOrientation + delta * @WHEEL_ANGULAR_ACCELERATION, -@MAX_WHEEL_ROTATION, @MAX_WHEEL_ROTATION)
		if controls.moveRight
			@wheelOrientation = THREE.Math.clamp(@wheelOrientation - delta * @WHEEL_ANGULAR_ACCELERATION, -@MAX_WHEEL_ROTATION, @MAX_WHEEL_ROTATION)

		# grab
		if controls.grab and not @grabbing
			@grabbing = true
			keyFrame = 0
			animFunc = () =>
				keyFrame++
				@updateSprite(keyFrame)
				if keyFrame < 18
					setTimeout(animFunc, 80)
				else
					@grabbing = false
			animFunc()
		# speed decay

		unless controls.moveForward or controls.moveBackward
			if @speed > 0
				k = exponentialEaseOut(@speed / @MAX_SPEED)
				@speed = THREE.Math.clamp(@speed - k * delta * @FRONT_DECCELERATION, 0, @MAX_SPEED)
				@acceleration = THREE.Math.clamp(@acceleration - k * delta, 0, 1)
			else
				k = exponentialEaseOut(@speed / @MAX_REVERSE_SPEED)
				@speed = THREE.Math.clamp(@speed + k * delta * @BACK_ACCELERATION, @MAX_REVERSE_SPEED, 0)
				@acceleration = THREE.Math.clamp(@acceleration + k * delta, -1, 0)


		# steering decay

		unless controls.moveLeft or controls.moveRight
			if @wheelOrientation > 0
				@wheelOrientation = THREE.Math.clamp(@wheelOrientation - delta * @WHEEL_ANGULAR_DECCELERATION, 0, @MAX_WHEEL_ROTATION)
			else
				@wheelOrientation = THREE.Math.clamp(@wheelOrientation + delta * @WHEEL_ANGULAR_DECCELERATION, -@MAX_WHEEL_ROTATION, 0)

		# car update

		forwardDelta = @speed * delta
		@carOrientation += (forwardDelta * @STEERING_RADIUS_RATIO) * @wheelOrientation

		# displacement

		@root.position.x += Math.sin(@carOrientation) * forwardDelta
		@root.position.z += Math.cos(@carOrientation) * forwardDelta

		# steering

		@root.rotation.y = @carOrientation

		# tilt

		if @loaded
			@bodyMesh.rotation.z = @MAX_TILT_SIDES * @wheelOrientation * (@speed / @MAX_SPEED)
			@bodyMesh.rotation.x = -@MAX_TILT_FRONTBACK * @acceleration

		# wheels rolling

		angularSpeedRatio = 1 / (@modelScale * (@wheelDiameter / 2))
		wheelDelta = forwardDelta * angularSpeedRatio
		if @loaded
			@frontLeftWheelMesh.rotation.x += wheelDelta
			@frontRightWheelMesh.rotation.x += wheelDelta
			@backLeftWheelMesh.rotation.x += wheelDelta
			@backRightWheelMesh.rotation.x += wheelDelta

		# front wheels steering

		@frontLeftWheelRoot.rotation.y = @wheelOrientation
		@frontRightWheelRoot.rotation.y = @wheelOrientation


	# internal helper methods
	createBody: (geometry, materials) =>
		@bodyGeometry = geometry
		@bodyMaterials = materials
		@createCar()

	# createWheels: (geometry, materials) =>
	# 	@wheelGeometry = geometry
	# 	@wheelMaterials = materials
	# 	@createCar()

	createCar: =>
		if @bodyGeometry and @wheelGeometry
			
			# compute wheel geometry parameters
			if @autoWheelGeometry
				@wheelGeometry.computeBoundingBox()
				bb = @wheelGeometry.boundingBox
				@wheelOffset.addVectors bb.min, bb.max
				@wheelOffset.multiplyScalar 0.5
				@wheelDiameter = bb.max.y - bb.min.y
				THREE.GeometryUtils.center @wheelGeometry
			
			# rig the car
			s = @modelScale
			delta = new THREE.Vector3()
			bodyFaceMaterial = new THREE.MeshFaceMaterial(@bodyMaterials)
			wheelFaceMaterial = new THREE.MeshFaceMaterial(@wheelMaterials)
			
			# body
			@bodyMesh = new THREE.Mesh @bodyGeometry, bodyFaceMaterial
			@bodyMesh.scale.set s, s, s
			@root.add @bodyMesh
			
			# front left wheel
			delta.multiplyVectors @wheelOffset, new THREE.Vector3(s, s, s)
			@frontLeftWheelRoot.position.add delta
			@frontLeftWheelMesh = new THREE.Mesh @wheelGeometry #, wheelFaceMaterial)
			@frontLeftWheelMesh.scale.set s, s, s
			@frontLeftWheelRoot.add @frontLeftWheelMesh
			@root.add @frontLeftWheelRoot
			
			# front right wheel
			delta.multiplyVectors @wheelOffset, new THREE.Vector3(-s, s, s)
			@frontRightWheelRoot.position.add delta
			@frontRightWheelMesh = new THREE.Mesh @wheelGeometry #, wheelFaceMaterial)
			@frontRightWheelMesh.scale.set s, s, s
			@frontRightWheelMesh.rotation.z = Math.PI
			@frontRightWheelRoot.add @frontRightWheelMesh
			@root.add @frontRightWheelRoot
			
			# back left wheel
			delta.multiplyVectors @wheelOffset, new THREE.Vector3(s, s, -s)
			delta.z -= @backWheelOffset
			@backLeftWheelMesh = new THREE.Mesh @wheelGeometry #, wheelFaceMaterial)
			@backLeftWheelMesh.position.add delta
			@backLeftWheelMesh.scale.set s, s, s
			@root.add @backLeftWheelMesh
			
			# back right wheel
			delta.multiplyVectors @wheelOffset, new THREE.Vector3(-s, s, -s)
			delta.z -= @backWheelOffset
			@backRightWheelMesh = new THREE.Mesh @wheelGeometry #, wheelFaceMaterial)
			@backRightWheelMesh.position.add delta
			@backRightWheelMesh.scale.set s, s, s
			@backRightWheelMesh.rotation.z = Math.PI
			@root.add @backRightWheelMesh
			
			# cache meshes
			@meshes = [@bodyMesh, @frontLeftWheelMesh, @frontRightWheelMesh, @backLeftWheelMesh, @backRightWheelMesh]
			
			# callback
			@loaded = true
			@callback if @callback