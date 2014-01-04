math =
	normaliseRadians: (radians) ->
		radians=radians % (2*Math.PI)
		if radians < 0
				radians += 2 * Math.PI
		return radians

vectorMath =
	rotate: (v, angle) ->
		angle = math.normaliseRadians angle
		return {
			x: v.x * Math.cos(angle) - v.y * Math.sin(angle)
			y: v.x * Math.sin(angle) + v.y * Math.cos(angle)
		}

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

class Wheel
	constructor: (@world, @car, @position, @width, @length, @revolving, @powered) ->
		def = new b2BodyDef()
		def.type = b2Body.b2_dynamicBody
		def.position = @car.body.GetWorldPoint new b2Vec2 @position.x, @position.y
		def.angle = @car.body.GetAngle()
		@body = @world.CreateBody def

		fixDef = new b2FixtureDef
		fixDef.density = 1
		fixDef.friction = 1
		fixDef.restitution = 0.01
		fixDef.isSensor = true
		fixDef.shape = new b2PolygonShape()
		fixDef.shape.SetAsBox @width/2, @length/2
		@body.CreateFixture fixDef

		jointDef = undefined
		if @revolving
			jointDef = new b2RevoluteJointDef()
			jointDef.Initialize @car.body, @body, @body.GetWorldCenter()
			jointDef.enableMotor = false
		else
			jointDef = new b2PrismaticJointDef()
			jointDef.Initialize @car.body, @body, @body.GetWorldCenter(), new b2Vec2(1,0)
			jointDef.enableLimit = true
			jointDef.lowerTranslation = jointDef.upperTranslation = 0

		@world.CreateJoint jointDef

	addAngle: (angle) =>
		@body.SetAngle(@car.body.GetAngle() + angle)

	getLocalVelocity: () =>
		@car.body.GetLocalVector(@car.body.GetLinearVelocityFromLocalPoint(new b2Vec2(@position.x, @position.y)))

	getDirectionVector: () =>
		# returns a world unit vector pointing in the direction this wheel is moving
		angle = @body.GetAngle()
		if @getLocalVelocity().y > 0
			v =
				x: 0
				y: 1
		else
			v =
				x: 0
				y: -1

		return vectorMath.rotate v, angle

	getKillVelocityVector: () =>
		# substracts sideways velocity from this wheel's velocity vector and returns the remaining front-facing velocity vector
		velocity = @body.GetLinearVelocity()
		sidewaysAxis = @getDirectionVector()
		dotprod = velocity.x*sidewaysAxis.x + velocity.y*sidewaysAxis.y

		return {
			x:sidewaysAxis.x*dotprod
			y:sidewaysAxis.y*dotprod
		}

	killSidewaysVelocity: () =>
		kv = @getKillVelocityVector()
		@body.SetLinearVelocity( new b2Vec2(kv.x, kv.y))

module.exports = class Car
	# car geometry manual parameters
	constructor: (@world, options) ->

		@options = _.extend
			position:
				x: 0
				y: 0
			density: 0.3
			friction: 0.1
			restitution: 0.1
			bullet: true
			linearDamping: 0.45
			angularDamping: 0.6
			power: 12
			width: 1.28 
			length: 3.32
			angle: Math.PI
			maxSteerAngle: Math.PI / 4
			maxSpeed: 100
			frontDrive: false
			frontWheelsY: -1
			rearWheelsY: 0.8
			leftWheelsX: -0.6
			rightWheelsX: 0.6
			wheelWidth: 0.25
			wheelLength: 0.36
			renderOffset:
				x: 0
				y: 100

		, options
		
		#console.log @options
		@modelScale = 1

		@power = @options.power
		# car geometry parameters automatically set from wheel mesh
		# - assumes wheel mesh is front left wheel in proper global
		#   position with respect to body mesh
		#	- other wheels are mirrored against car root
		#	- if necessary back wheels can be offset manually

		# internal control variables
		# car rigging

		@root = new THREE.Object3D()

		@bodyMesh = null
		@bodyGeometry = null
		@bodyMaterials = null
		# internal helper variables

		@loaded = false
		@meshes = []
		
		@grabbing = false
		@texture = "textures/ambulance.png"

		#physics

		@wheelAngle = 0
		def = new b2BodyDef()
		def.type = b2Body.b2_dynamicBody
		def.position = new b2Vec2 @options.position.x, @options.position.y
		def.angle = @options.angle
		def.linearDamping = @options.linearDamping
		def.bullet = @options.bullet
		def.angularDamping = @options.angularDamping
		@body = @world.CreateBody def

		fixDef = new b2FixtureDef()
		fixDef.density = @options.density
		fixDef.friction = @options.friction
		fixDef.restitution = @options.restitution
		fixDef.shape = new b2PolygonShape()
		fixDef.shape.SetAsBox @options.width/2, @options.length/2
		@body.CreateFixture fixDef


		

		@wheels = []

		@wheels.push new Wheel @world, @, {x: @options.leftWheelsX, y: @options.frontWheelsY}, @options.wheelWidth, @options.wheelLength, true, @options.frontDrive

		@wheels.push new Wheel @world, @, {x: @options.rightWheelsX, y: @options.frontWheelsY}, @options.wheelWidth, @options.wheelLength, true, @options.frontDrive

		@wheels.push new Wheel @world, @, {x: @options.leftWheelsX, y: @options.rearWheelsY}, @options.wheelWidth, @options.wheelLength, false, not @options.frontDrive

		@wheels.push new Wheel @world, @, {x: @options.rightWheelsX, y: @options.rearWheelsY}, @options.wheelWidth, @options.wheelLength, false, not @options.frontDrive

	enableShadows: (enable) =>
		for mesh in @meshes
			mesh.castShadow = enable
			mesh.receiveShadow = enable

	setVisible: (enable) =>
		for mesh in @meshes
			mesh.visible = enable

	load: () =>
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
		@createCar()
		# loader = new THREE.JSONLoader()
		# loader.load bodyURL, (geometry, materials) =>
		# 	@createBody geometry, materials

	updateSprite: (index) =>
		framesX = 5
		framesY = 4
		keyX = index % framesX
		keyY = (framesY - 1) - ((index / framesX) | 0)
		scaleX = 1 / framesX
		scaleY = 1 / framesY
		# The quad [a, b, c, d] consists of two triangles [a, b, c] + [a, c, d] with reversed index access.
		@bodyGeometry.faceVertexUvs[0][1][2].x = @bodyGeometry.faceVertexUvs[0][0][2].x = scaleX * (keyX + 1)
		@bodyGeometry.faceVertexUvs[0][1][2].y = @bodyGeometry.faceVertexUvs[0][0][2].y = scaleY * (keyY + 1)
		@bodyGeometry.faceVertexUvs[0][1][1].x = scaleX * (keyX + 1)
		@bodyGeometry.faceVertexUvs[0][1][1].y = scaleY * keyY
		@bodyGeometry.faceVertexUvs[0][1][0].x = @bodyGeometry.faceVertexUvs[0][0][1].x = scaleX * keyX
		@bodyGeometry.faceVertexUvs[0][1][0].y = @bodyGeometry.faceVertexUvs[0][0][1].y = scaleY * keyY
		@bodyGeometry.faceVertexUvs[0][0][0].x = scaleX * keyX
		@bodyGeometry.faceVertexUvs[0][0][0].y = scaleY * (keyY + 1)
		@bodyGeometry.uvsNeedUpdate = true

	update: (delta, controls) =>

		# grab
		if controls? and controls.grab and not @grabbing
			@grabbing = true
			document.getElementById('door1').play()
			keyFrame = 0
			animFunc = () =>
				keyFrame++
				@updateSprite(keyFrame)
				if keyFrame < 18
					if keyFrame is 10
						@onGrabbed() if @onGrabbed?
					setTimeout(animFunc, 80)
				else
					@grabbing = false
					document.getElementById('door2').play()
			animFunc()

		# translate physics representation to renderer
		posOffset = vectorMath.rotate @options.renderOffset, @body.GetAngle()
		pos = @body.GetPosition()
		@root.position.x = pos.x * 100 + posOffset.x
		@root.position.z = pos.y * 100 + posOffset.y
		@root.rotation.y =-1*(@body.GetAngle() + Math.PI)

	# internal helper methods
	createBody: (geometry, materials) =>
		@bodyGeometry = geometry
		@bodyMaterials = materials
		@createCar()

	createCar: =>
		if @bodyGeometry
			
			# rig the car
			s = @modelScale
			delta = new THREE.Vector3()
			bodyFaceMaterial = new THREE.MeshFaceMaterial(@bodyMaterials)
			
			# body
			@bodyMesh = new THREE.Mesh @bodyGeometry, bodyFaceMaterial
			@bodyMesh.scale.set s, s, s
			@root.add @bodyMesh
			# Help against z fighting
			@root.position.y = Math.random() * 10
			
			# cache meshes
			@meshes = [@bodyMesh]
			
			# callback
			@loaded = true
			@callback if @callback

	getPoweredWheels: () =>
		ret = []
		for wheel in @wheels
			ret.push wheel if wheel.powered
		return ret

	getLocalVelocity: () =>
		res = @body.GetLocalVector(@body.GetLinearVelocityFromLocalPoint(new b2Vec2(0, 0)))

	getRevolvingWheels: () =>
		ret = []
		for wheel in @wheels
			if wheel.revolving
				ret.push wheel
		return ret

	getSpeedKMH: () =>
		velocity = @body.GetLinearVelocity()
		return velocity.Length()/1000*3600

	setSpeed: (speed) =>
		velocity = @body.GetLinearVelocity()
		len = velocity.Length()
		velocity = new b2Vec2 (velocity.x/len)*speed*1000/36000, (velocity.y/len)*speed*1000/36000
		@body.SetLinearVelocity velocity

	updatePhysics: (delta, controls) =>
		for wheel in @wheels
			wheel.killSidewaysVelocity()

		incr = @options.maxSteerAngle*delta

		if controls.moveLeft
			@wheelAngle = THREE.Math.clamp @wheelAngle-incr, -@options.maxSteerAngle, 0
		else if controls.moveRight
			@wheelAngle = THREE.Math.clamp @wheelAngle+incr, 0, @options.maxSteerAngle
		else
			@wheelAngle = 0

		wheels = @getRevolvingWheels()
		for wheel in wheels
			wheel.addAngle @wheelAngle

		# console.log @getSpeedKMH(), @maxSpeed
		localVelocity = @getLocalVelocity()
		if controls.moveForward and @getSpeedKMH() < @options.maxSpeed
			baseVect =
				x: 0
				y: -1
		else if controls.moveBackward
			if localVelocity.y < 0
				baseVect =
					x: 0
					y: 1.3
			else
				baseVect =
					x: 0
					y: 0.7
		else
			if localVelocity.y < -0.1
				baseVect =
					x: 0
					y: 1
			else
				baseVect =
					x: 0
					y: 0

		fvect = 
			x: @power*baseVect.x
			y: @power*baseVect.y

		wheels = @getPoweredWheels()
		for wheel in wheels
			position = wheel.body.GetWorldCenter()
			wheel.body.ApplyForce(wheel.body.GetWorldVector(new b2Vec2(fvect.x, fvect.y)), position)

		# if @getSpeedKMH() < 4 and not (controls.moveForward or controls.moveBackward)
		# 	@setSpeed 0
