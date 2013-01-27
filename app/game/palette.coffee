makeFloor = (materialIndex, rotation = 0) ->
	matrix = new THREE.Matrix4()

	floor = new THREE.PlaneGeometry(500, 500)
	floor.applyMatrix(matrix.makeRotationZ( rotation * Math.PI / 2 ))
	floor.applyMatrix(matrix.makeRotationX( -Math.PI / 2 ))
	floor.applyMatrix(matrix.makeTranslation(0, -10, 0 ));
	floor.faces[ 0 ].materialIndex = materialIndex
	return floor

makeBox = (materialIndex = 6) ->
	matrix = new THREE.Matrix4();
	geometry = new THREE.Geometry()

	pxGeometry = new THREE.PlaneGeometry( 500, 500 );
	pxGeometry.faces[ 0 ].materialIndex = materialIndex;
	pxGeometry.applyMatrix( matrix.makeRotationY( Math.PI / 2 ) );
	pxGeometry.applyMatrix( matrix.makeTranslation( 250, 240, 0 ) );

	nxGeometry = new THREE.PlaneGeometry( 500, 500 );
	nxGeometry.faces[ 0 ].materialIndex = materialIndex;
	nxGeometry.applyMatrix( matrix.makeRotationY( - Math.PI / 2 ) );
	nxGeometry.applyMatrix( matrix.makeTranslation( - 250, 240, 0 ) );

	pyGeometry = new THREE.PlaneGeometry( 500, 500 );
	pyGeometry.faces[ 0 ].materialIndex = 3;
	pyGeometry.applyMatrix( matrix.makeRotationX( - Math.PI / 2 ) );
	pyGeometry.applyMatrix( matrix.makeTranslation( 0, 490, 0 ) );

	pzGeometry = new THREE.PlaneGeometry( 500, 500 );
	pzGeometry.faces[ 0 ].materialIndex = materialIndex;
	pzGeometry.applyMatrix( matrix.makeTranslation( 0, 240, 250 ) );

	nzGeometry = new THREE.PlaneGeometry( 500, 500 );
	nzGeometry.faces[ 0 ].materialIndex = materialIndex;
	nzGeometry.applyMatrix( matrix.makeRotationY( Math.PI ) );
	nzGeometry.applyMatrix( matrix.makeTranslation( 0, 240, -250 ) );

	THREE.GeometryUtils.merge geometry, pxGeometry
	THREE.GeometryUtils.merge geometry, nxGeometry
	THREE.GeometryUtils.merge geometry, pyGeometry
	THREE.GeometryUtils.merge geometry, pzGeometry
	THREE.GeometryUtils.merge geometry, nzGeometry

	return geometry

exports.tiles =
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

exports.palette =
	0x1000: [1]
	0x2000: [2]
	0x3000: [2]
	0x4000: [1]
	0xe000: [13, 0, 0]  # lonely 4-way
	0xe001: [13, 0, 0]	# shouldn't exist
	0xe002: [13, 0, 0]	# shouldn't exist
	0xe003: [12, 0, 0]	# Corner
	0xe004: [13, 0, 0]	# shouldn't exist
	0xe005: [13, 0, 0]	# straight
	0xe006: [9, 0, 0]		# Corner
	0xe007: [6, 0, 0]	# T
	0xe008: [13, 0, 0]	# shouldn't exist
	0xe009: [11, 0, 0]	# Corner
	0xe00a: [12, 0, 0]	# straight
	0xe00b: [5, 0, 0]	# T
	0xe00c: [10, 0, 0]	# Corner
	0xe00d: [8, 0, 0]	# T
	0xe00e: [7, 0, 0]	# T
	0xe00f: [13, 0, 0]	# 4-way
	0x00ff: [15, 0, 0]	#	walkway
	0x0080: [20]				# Park
	0x8080: [16, 0, 0]	# one story house
	0x7f7f: [17]				# alternativve
	0xffff: [16, 16, 0]	# two story house
	0xfffe: [17, 17]		# alternative
	0x0000: [18, 42] 		# butchery; goal
	0x0101: [19]				# butchery: entrance

