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
			return {
				x: -Math.sin angle
				y: Math.cos angle
			}
		else
			return {
				x: Math.sin angle
				y: -Math.cos angle
			}

	getKillVelocityVector: () =>
		# substracts sideways velocity from this wheel's velocity vector and returns the remaining front-facing velocity vector
		velocity = @body.GetLinearVelocity()
		sidewaysAxis = @getDirectionVector()
		dotprod = Math.sqrt(velocity.x*sidewaysAxis.x + velocity.y*sidewaysAxis.y)
		return {
			x:sidewaysAxis.x*dotprod
			y:sidewaysAxis.y*dotprod
		}

	killSidewaysVelocity: () =>
		kv = @getKillVelocityVector()
		@body.SetLinearVelocity( new b2Vec2(kv.x, kv.y))

module.exports = class Car
	constructor: (@world) ->
		@width = 2
		@length = 4
		@position =
			x: -4
			y: -4
		@angle = Math.PI
		@power = 60
		@maxSteerAngle = 20
		@maxSpeed = 60

		@wheelAngle = 0
		def = new b2BodyDef()
		def.type = b2Body.b2_dynamicBody
		def.position = new b2Vec2 @position.x, @position.y
		def.angle = @angle
		def.linearDamping = 0.15
		# def.bullet = true
		def.angularDamping = 0.3
		@body = @world.CreateBody def

		fixDef = new b2FixtureDef()
		fixDef.density = 1
		fixDef.friction = 0.3
		fixDef.restitution = 0.4
		fixDef.shape = new b2PolygonShape()
		fixDef.shape.SetAsBox @width/2, @length/2
		@body.CreateFixture fixDef


		wheelWidth = 0.2
		wheelLength = 0.8

		@wheels = []

		@wheels.push new Wheel @world, @, {x: -1, y: -1.2}, wheelWidth, wheelLength, true, true

		@wheels.push new Wheel @world, @, {x: 1, y: -1.2}, wheelWidth, wheelLength, true, true

		@wheels.push new Wheel @world, @, {x: -1, y: 1.2}, wheelWidth, wheelLength, false, false

		@wheels.push new Wheel @world, @, {x: 1, y: 1.2}, wheelWidth, wheelLength, false, false

		console.log @

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

		incr = @maxSteerAngle/200*delta

		if controls.moveLeft
			@wheelAngle = THREE.Math.clamp @wheelAngle-incr, -@maxSteerAngle, 0
		else if controls.moveRight
			@wheelAngle = THREE.Math.clamp @wheelAngle+incr, 0, @maxSteerAngle
		else
			@wheelAngle = 0

		wheels = @getRevolvingWheels()
		for wheel in wheels
			wheel.addAngle @wheelAngle

		# console.log @getSpeedKMH(), @maxSpeed
		if controls.moveForward and @getSpeedKMH() < @maxSpeed
			baseVect =
				x: 0
				y: -1
		else if controls.moveBackward
			if @getLocalVelocity().y < 0
				baseVect =
					x: 0
					y: 1.3
			else
				baseVect =
					x: 0
					y: 0.7
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