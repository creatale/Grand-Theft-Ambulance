quadraticEaseOut = (k) -> -k*(k-2)
cubicEaseOut = (k) -> --k * k * k + 1
circularEaseOut = (k) -> Math.sqrt( 1 - --k * k )
sinusoidalEaseOut = (k) -> Math.sin( k * Math.PI / 2 )
exponentialEaseOut = (k) -> if k is 1 then 1 else -Math.pow(2,-10*k)+1

b2Vec2 = Box2D.Common.Math.b2Vec2
b2BodyDef = Box2D.Dynamics.b2BodyDef
b2Body = Box2D.Dynamics.b2Body
b2FixtureDef = Box2D.Dynamics.b2FixtureDef
b2Fixture = Box2D.Dynamics.b2Fixture
# b2MassData = Box2D.Collision.Shapes.b2MassData
b2PolygonShape = Box2D.Collision.Shapes.b2PolygonShape
# b2CircleShape = Box2D.Collision.Shapes.b2CircleShape
# b2DebugDraw = Box2D.Dynamics.b2DebugDraw

b2RevoluteJointDef = Box2D.Dynamics.Joints.b2RevoluteJointDef
b2Joint = Box2D.Dynamics.Joints.b2Joint
b2PrismaticJointDef = Box2D.Dynamics.Joints.b2PrismaticJointDef

module.exports = class Car
	# car geometry manual parameters
	constructor: (world) ->
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

		@FRONT_ACCELERATION = 250
		@BACK_ACCELERATION = 500

		@WHEEL_ANGULAR_ACCELERATION = 2.5

		@FRONT_DECCELERATION = 1750
		@WHEEL_ANGULAR_DECCELERATION = 2.0

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

		# API


		bodyLength = 80
		bodyWidth = 40
		bodyPosX = -250
		bodyPosY = -250

		wheelLength = 10
		wheelWidth = 4
		# physics
		bodyDef = new b2BodyDef()
		bodyDef.type = b2Body.b2_dynamicBody
		fixDef = new b2FixtureDef()
		fixDef.density = 1.0
		fixDef.friction = 0.0
		fixDef.restitution = 0.25
		fixDef.shape = new b2PolygonShape()
		fixDef.shape.SetAsBox bodyWidth, bodyLength
		bodyDef.position.Set bodyPosX, bodyPosY

		@physics = {}

		@physics.body = world.CreateBody(bodyDef)
		@physics.body.CreateFixture(fixDef)

		initFrontJoint = (wheel) =>
			jointDef = new b2RevoluteJointDef()
			jointDef.Initialize @physics.body , wheel, wheel.GetWorldCenter()

			jointDef.enableMotor = true
			jointDef.maxMotorTorque = 100000
			
			jointDef.enableLimit = true
			jointDef.lowerAngle =  -1 * Math.PI/3
			jointDef.upperAngle =  Math.PI/3

			wheel.joint = world.CreateJoint jointDef

		initRearJoint = (wheel) =>

			jointDef = new b2PrismaticJointDef()
			jointDef.Initialize @physics.body , wheel, wheel.GetWorldCenter(), new b2Vec2(1,0)

			jointDef.enableLimit = true
			jointDef.lowerTranslation = jointDef.upperTranslation = 0.0

			wheel.joint = world.CreateJoint jointDef

		fixDef.shape.SetAsBox wheelWidth, wheelLength
		bodyDef.position.Set bodyPosX-bodyWidth-wheelWidth/2, bodyPosY-bodyLength+20
		@physics.frontLeftWheel = world.CreateBody bodyDef
		@physics.frontLeftWheel.CreateFixture fixDef

		initFrontJoint @physics.frontLeftWheel

		bodyDef.position.Set bodyPosX+bodyWidth+wheelWidth/2, bodyPosY-bodyLength+20
		@physics.frontRightWheel = world.CreateBody bodyDef
		@physics.frontRightWheel.CreateFixture fixDef

		initFrontJoint @physics.frontRightWheel

		bodyDef.position.Set bodyPosX-bodyWidth-wheelWidth/2, bodyPosY+bodyLength-20
		@physics.rearLeftWheel = world.CreateBody bodyDef
		@physics.rearLeftWheel.CreateFixture fixDef

		initRearJoint @physics.rearLeftWheel

		bodyDef.position.Set bodyPosX+bodyWidth+wheelWidth/2, bodyPosY+bodyLength-20
		@physics.rearRightWheel = world.CreateBody bodyDef
		@physics.rearRightWheel.CreateFixture fixDef

		initRearJoint @physics.rearRightWheel


	enableShadows: (enable) =>
		for mesh in @meshes
			mesh.castShadow = enable
			mesh.receiveShadow = enable

	setVisible: (enable) =>
		for mesh in @meshes
			mesh.visible = enable

	loadPartsJSON: (bodyURL) =>
		@bodyGeometry = new THREE.CubeGeometry 40, 80, 80
		@wheelGeometry = new THREE.SphereGeometry 5, 5, 4
		@createCar()
		# loader = new THREE.JSONLoader()
		# loader.load bodyURL, (geometry, materials) =>
		# 	@createBody geometry, materials


	# loadPartsBinary: (bodyURL, wheelURL) =>
	# 	loader = new THREE.BinaryLoader()
	# 	loader.load bodyURL, (geometry, materials) =>
	# 		@createBody geometry, materials

	# 	loader.load wheelURL, (geometry, materials) =>
	# 		@createWheels geometry, materials

	# updatePhysics: (controls) =>
	# 	drive = (wheel) ->
	# 		direction = wheel.GetTransform().R.col2.Copy()
	# 		direction.Multiply 100000 #car.engine_speed 

	# 		wheel.ApplyForce direction , wheel.GetPosition()
		
	# 	if controls.moveForward
	# 		drive @physics.rearLeftWheel
	# 		drive @physics.rearRightWheel

	# 	steeringAngle = 0

	# 	if controls.moveLeft
	# 		steeringAngle = Math.PI/3

	# 	if controls.moveRight
	# 		steeringAngle = - Math.PI/3
			

	# 	steer = (wheel) =>
	# 		angleDiff = steeringAngle * wheel.joint.GetJointAngle()
	# 		wheel.joint.SetMotorSpeed(angleDiff * 100000)

	# 	steer @physics.frontLeftWheel
	# 	steer @physics.frontRightWheel

	update: =>
		pos = @physics.body.GetPosition()
		@root.position.x = pos.x + 250
		@root.position.z = pos.y + 250
		# @root.rotation.y = 

	# updateControls: (delta, controls) =>

	# # speed and wheels based on controls

	# 	if controls.moveForward
	# 		@speed = THREE.Math.clamp(@speed + delta * @FRONT_ACCELERATION, @MAX_REVERSE_SPEED, @MAX_SPEED)
	# 		@acceleration = THREE.Math.clamp(@acceleration + delta, -1, 1)

	# 	if controls.moveBackward
	# 		@speed = THREE.Math.clamp(@speed - delta * @BACK_ACCELERATION, @MAX_REVERSE_SPEED, @MAX_SPEED)
	# 		@acceleration = THREE.Math.clamp(@acceleration - delta, -1, 1)

	# 	if controls.moveLeft
	# 		@wheelOrientation = THREE.Math.clamp(@wheelOrientation + delta * @WHEEL_ANGULAR_ACCELERATION, -@MAX_WHEEL_ROTATION, @MAX_WHEEL_ROTATION)
	# 	if controls.moveRight
	# 		@wheelOrientation = THREE.Math.clamp(@wheelOrientation - delta * @WHEEL_ANGULAR_ACCELERATION, -@MAX_WHEEL_ROTATION, @MAX_WHEEL_ROTATION)

	# 	# speed decay

	# 	unless controls.moveForward or controls.moveBackward
	# 		if @speed > 0
	# 			k = exponentialEaseOut(@speed / @MAX_SPEED)
	# 			@speed = THREE.Math.clamp(@speed - k * delta * @FRONT_DECCELERATION, 0, @MAX_SPEED)
	# 			@acceleration = THREE.Math.clamp(@acceleration - k * delta, 0, 1)
	# 		else
	# 			k = exponentialEaseOut(@speed / @MAX_REVERSE_SPEED)
	# 			@speed = THREE.Math.clamp(@speed + k * delta * @BACK_ACCELERATION, @MAX_REVERSE_SPEED, 0)
	# 			@acceleration = THREE.Math.clamp(@acceleration + k * delta, -1, 0)


	# 	# steering decay

	# 	unless controls.moveLeft or controls.moveRight
	# 		if @wheelOrientation > 0
	# 			@wheelOrientation = THREE.Math.clamp(@wheelOrientation - delta * @WHEEL_ANGULAR_DECCELERATION, 0, @MAX_WHEEL_ROTATION)
	# 		else
	# 			@wheelOrientation = THREE.Math.clamp(@wheelOrientation + delta * @WHEEL_ANGULAR_DECCELERATION, -@MAX_WHEEL_ROTATION, 0)

	# 	# car update

	# 	forwardDelta = @speed * delta
	# 	@carOrientation += (forwardDelta * @STEERING_RADIUS_RATIO) * @wheelOrientation

	# 	# displacement

	# 	@root.position.x += Math.sin(@carOrientation) * forwardDelta
	# 	@root.position.z += Math.cos(@carOrientation) * forwardDelta

	# 	# steering

	# 	@root.rotation.y = @carOrientation

	# 	# tilt

	# 	if @loaded
	# 		@bodyMesh.rotation.z = @MAX_TILT_SIDES * @wheelOrientation * (@speed / @MAX_SPEED)
	# 		@bodyMesh.rotation.x = -@MAX_TILT_FRONTBACK * @acceleration

	# 	# wheels rolling

	# 	angularSpeedRatio = 1 / (@modelScale * (@wheelDiameter / 2))
	# 	wheelDelta = forwardDelta * angularSpeedRatio
	# 	if @loaded
	# 		@frontLeftWheelMesh.rotation.x += wheelDelta
	# 		@frontRightWheelMesh.rotation.x += wheelDelta
	# 		@backLeftWheelMesh.rotation.x += wheelDelta
	# 		@backRightWheelMesh.rotation.x += wheelDelta

	# 	# front wheels steering

	# 	@frontLeftWheelRoot.rotation.y = @wheelOrientation
	# 	@frontRightWheelRoot.rotation.y = @wheelOrientation


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
			@bodyMesh = new THREE.Mesh @bodyGeometry #, bodyFaceMaterial)
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