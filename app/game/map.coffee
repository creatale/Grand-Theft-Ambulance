makeFloor = (materialIndex, rotation = 0) ->
	matrix = new THREE.Matrix4()

	floor = new THREE.PlaneGeometry(500, 500)
	floor.applyMatrix(matrix.makeRotationZ( rotation * Math.PI / 2 ))
	floor.applyMatrix(matrix.makeRotationX( -Math.PI / 2 ))
	floor.applyMatrix(matrix.makeTranslation(0, -10, 0 ));
	floor.faces[ 0 ].materialIndex = floor.faces[ 1 ].materialIndex = materialIndex
	return floor

makeBox = (materialIndex = 6) ->
	matrix = new THREE.Matrix4();
	geometry = new THREE.Geometry()

	pxGeometry = new THREE.PlaneGeometry( 500, 500 );
	pxGeometry.faces[ 0 ].materialIndex = pxGeometry.faces[ 1 ].materialIndex = materialIndex;
	pxGeometry.applyMatrix( matrix.makeRotationY( Math.PI / 2 ) );
	pxGeometry.applyMatrix( matrix.makeTranslation( 250, 240, 0 ) );

	nxGeometry = new THREE.PlaneGeometry( 500, 500 );
	nxGeometry.faces[ 0 ].materialIndex = nxGeometry.faces[ 1 ].materialIndex = materialIndex;
	nxGeometry.applyMatrix( matrix.makeRotationY( - Math.PI / 2 ) );
	nxGeometry.applyMatrix( matrix.makeTranslation( - 250, 240, 0 ) );

	pyGeometry = new THREE.PlaneGeometry( 500, 500 );
	pyGeometry.faces[ 0 ].materialIndex = pyGeometry.faces[ 1 ].materialIndex = 3;
	pyGeometry.applyMatrix( matrix.makeRotationX( - Math.PI / 2 ) );
	pyGeometry.applyMatrix( matrix.makeTranslation( 0, 490, 0 ) );

	pzGeometry = new THREE.PlaneGeometry( 500, 500 );
	pzGeometry.faces[ 0 ].materialIndex = pzGeometry.faces[ 1 ].materialIndex = materialIndex;
	pzGeometry.applyMatrix( matrix.makeTranslation( 0, 240, 250 ) );

	nzGeometry = new THREE.PlaneGeometry( 500, 500 );
	nzGeometry.faces[ 0 ].materialIndex = nzGeometry.faces[ 1 ].materialIndex = materialIndex;
	nzGeometry.applyMatrix( matrix.makeRotationY( Math.PI ) );
	nzGeometry.applyMatrix( matrix.makeTranslation( 0, 240, -250 ) );

	geometry.merge pxGeometry
	geometry.merge nxGeometry
	geometry.merge pyGeometry
	geometry.merge pzGeometry
	geometry.merge nzGeometry

	return geometry

tiles =
	1: makeFloor(0)
	2: makeFloor(0, 1)
	3: makeFloor(0, 3)
	4: makeFloor(0, 2)
	5: makeFloor(5, 0)
	6: makeFloor(5, 1)
	7: makeFloor(5, 2)
	8: makeFloor(5, 3)
	9: makeFloor(1, 0)
	10: makeFloor(1, 1)
	11: makeFloor(1, 2)
	12: makeFloor(1, 3)
	13: makeFloor(2)
	15: makeFloor(4, 1)
	16: makeBox(6)
	17: makeBox(7)
	18: makeBox(8)
	19: makeFloor(9, 1)
	20: makeFloor(10)
	42: new THREE.SphereGeometry(50, 8, 4)

palette =
	0x1000: [1]
	0x2000: [2]
	0x3000: [2]
	0x4000: [1]
	0xe000: [13, 0, 0]  # lonely 4-way
	0xe001: [13, 0, 0]  # shouldn't exist
	0xe002: [13, 0, 0]  # shouldn't exist
	0xe003: [12, 0, 0]  # Corner
	0xe004: [13, 0, 0]  # shouldn't exist
	0xe005: [13, 0, 0]  # straight
	0xe006: [9, 0, 0]   # Corner
	0xe007: [8, 0, 0]   # T
	0xe008: [13, 0, 0]  # shouldn't exist
	0xe009: [11, 0, 0]  # Corner
	0xe00a: [12, 0, 0]  # straight
	0xe00b: [7, 0, 0]   # T
	0xe00c: [10, 0, 0]  # Corner
	0xe00d: [6, 0, 0]   # T
	0xe00e: [5, 0, 0]   # T
	0xe00f: [13, 0, 0]  # 4-way
	0x00ff: [15, 0, 0]	# walkway
	0x0080: [20]        # Park
	0x8080: [16, 0, 0]  # one story house
	0x7f7f: [17]        # alternativve
	0xffff: [16, 16, 0] # two story house
	0xfffe: [17, 17]    # alternative
	0x0000: [18, 42]    # butchery; goal
	0x0101: [19]        # butchery: entrance


b2BodyDef = Box2D.Dynamics.b2BodyDef
b2Body = Box2D.Dynamics.b2Body
b2FixtureDef = Box2D.Dynamics.b2FixtureDef
b2Fixture = Box2D.Dynamics.b2Fixture
b2PolygonShape = Box2D.Collision.Shapes.b2PolygonShape

loadImage = require 'game/loadimage'


module.exports = class Map
	constructor: (@scene, @world) ->

	isStreet: (x, y) =>
		return false unless x >= 0 and y >= 0 and x < @map.width and y < @map.height
		idx = (x * @worldDepth + y) * 4
		return @map.data[idx + 1] is 0 and @map.data[idx] > 0

	load: (done) =>
		loadImage 'maps/80map.png', (imageData) =>
			console.log 'Map', imageData
			@map = imageData
			@worldWidth = @map.width
			@worldDepth = @map.height
			@worldHalfWidth = @worldWidth / 2
			@worldHalfDepth = @worldDepth / 2

			# sides
			matrix = new THREE.Matrix4()
			pxGeometry = new THREE.PlaneGeometry(100, 100)

			geometry = new THREE.Geometry()
			dummy = new THREE.Mesh()
			z = 0
			index = 0

			# tile physics
			bodyDef = new b2BodyDef()
			bodyDef.type = b2Body.b2_staticBody
			fixDef = new b2FixtureDef()
			fixDef.density = 1.0
			fixDef.friction = 0.05
			fixDef.restitution = 0.0
			fixDef.shape = new b2PolygonShape()
			fixDef.shape.SetAsBox 2.5, 2.5



			while z < @worldDepth
				x = 0

				while x < @worldWidth
					tile = @map.data[index] * 256 + @map.data[index + 1]
					index += 4

					if tile is 0xe000
						tile |= @isStreet(z - 1, x)
						tile |= @isStreet(z, x - 1) << 1
						tile |= @isStreet(z + 1, x) << 2
						tile |= @isStreet(z, x + 1) << 3
					else if tile is 0x8080 and Math.random() > 0.5
						tile = 0x7f7f
					else if tile is 0xffff and Math.random() > 0.5
						tile = 0xfffe
					else if tile is 0x0101
						@parkingPlace = new THREE.Vector3(x * 500  - @worldHalfWidth * 500, 0, z * 500  - @worldHalfDepth * 500)

					stack = palette[tile] or []
					for item, h in stack
						continue unless tiles[item]?
						dummy.position.x = x * 500  - @worldHalfWidth * 500
						dummy.position.y = h * 500
						dummy.position.z = z * 500  - @worldHalfDepth * 500
						dummy.geometry = tiles[item]
						#dummy.geometry = pxGeometry
						dummy.matrixAutoUpdate && dummy.updateMatrix();
						geometry.merge dummy.geometry, dummy.matrix

						# physics
						if tile in [0x8080, 0x7f7f, 0xffff, 0xfffe, 0x0000]
							bodyDef.position.x = x * 5 - @worldHalfWidth * 5
							bodyDef.position.y = z * 5 - @worldHalfDepth * 5
							@world.CreateBody(bodyDef).CreateFixture(fixDef)

					x++
				z++

			matStreetStraight = new THREE.MeshLambertMaterial(
				map: THREE.ImageUtils.loadTexture("textures/street_h.png")
				ambient: 0xbbbbbb
				vertexColors: THREE.VertexColors
			)
			matStreetCorner = new THREE.MeshLambertMaterial(
				map: THREE.ImageUtils.loadTexture("textures/street_corner.png")
				ambient: 0xbbbbbb
				vertexColors: THREE.VertexColors
			)
			matStreetCrossing = new THREE.MeshLambertMaterial(
				map: THREE.ImageUtils.loadTexture("textures/street_x4.png")
				ambient: 0xbbbbbb
				vertexColors: THREE.VertexColors
			)
			matRoof = new THREE.MeshLambertMaterial(
				map: THREE.ImageUtils.loadTexture("textures/roof.png")
				ambient: 0xbbbbbb
				vertexColors: THREE.VertexColors
			)
			matWalk = new THREE.MeshLambertMaterial(
				map: THREE.ImageUtils.loadTexture("textures/walkway.png")
				ambient: 0xbbbbbb
				vertexColors: THREE.VertexColors
			)
			matStreetT = new THREE.MeshLambertMaterial(
				map: THREE.ImageUtils.loadTexture("textures/street_t.png")
				ambient: 0xbbbbbb
				vertexColors: THREE.VertexColors
			)
			matWall1 = new THREE.MeshLambertMaterial(
				map: THREE.ImageUtils.loadTexture("textures/tile_house_blue.png")
				ambient: 0xbbbbbb
				vertexColors: THREE.VertexColors
			)
			matWall2 = new THREE.MeshLambertMaterial(
				map: THREE.ImageUtils.loadTexture("textures/tile_house_red.png")
				ambient: 0xbbbbbb
				vertexColors: THREE.VertexColors
			)
			matButchery = new THREE.MeshLambertMaterial(
				map: THREE.ImageUtils.loadTexture("textures/tile_house_meat.png")
				ambient: 0xbbbbbb
				vertexColors: THREE.VertexColors
			)
			matButcheryEntrance = new THREE.MeshLambertMaterial(
				map: THREE.ImageUtils.loadTexture("textures/tile_parking.png")
				ambient: 0xbbbbbb
				vertexColors: THREE.VertexColors
			)
			matGrass = new THREE.MeshLambertMaterial(
				map: THREE.ImageUtils.loadTexture("textures/gras1.png")
				ambient: 0xbbbbbb
				vertexColors: THREE.VertexColors
			)

			mesh = new THREE.Mesh(geometry, new THREE.MeshFaceMaterial([
				matStreetStraight, matStreetCorner, matStreetCrossing,  matRoof, matWalk, matStreetT,
				matWall1, matWall2, matButchery, matButcheryEntrance, matGrass]))
			@scene.add mesh

			done()
