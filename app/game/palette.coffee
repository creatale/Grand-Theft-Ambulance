makeFloor = (materialIndex) ->
	matrix = new THREE.Matrix4()

	floor = new THREE.PlaneGeometry(500, 500)
	floor.applyMatrix(matrix.makeRotationX( -Math.PI / 2 ))
	floor.applyMatrix(matrix.makeTranslation(0, -250, 0 ));
	floor.faces[ 0 ].materialIndex = materialIndex
	return floor

makeBox = () ->
	matrix = new THREE.Matrix4();
	geometry = new THREE.Geometry()

	pxGeometry = new THREE.PlaneGeometry( 500, 500 );
	pxGeometry.faces[ 0 ].materialIndex = 1;
	pxGeometry.applyMatrix( matrix.makeRotationY( Math.PI / 2 ) );
	pxGeometry.applyMatrix( matrix.makeTranslation( 250, 0, 0 ) );

	nxGeometry = new THREE.PlaneGeometry( 500, 500 );
	nxGeometry.faces[ 0 ].materialIndex = 1;
	nxGeometry.applyMatrix( matrix.makeRotationY( - Math.PI / 2 ) );
	nxGeometry.applyMatrix( matrix.makeTranslation( - 250, 0, 0 ) );

	pyGeometry = new THREE.PlaneGeometry( 500, 500 );
	pyGeometry.faces[ 0 ].materialIndex = 2;
	pyGeometry.applyMatrix( matrix.makeRotationX( - Math.PI / 2 ) );
	pyGeometry.applyMatrix( matrix.makeTranslation( 0, 250, 0 ) );

	pzGeometry = new THREE.PlaneGeometry( 500, 500 );
	pzGeometry.faces[ 0 ].materialIndex = 1;
	pzGeometry.applyMatrix( matrix.makeTranslation( 0, 0, 250 ) );

	nzGeometry = new THREE.PlaneGeometry( 500, 500 );
	nzGeometry.faces[ 0 ].materialIndex = 1;
	nzGeometry.applyMatrix( matrix.makeRotationY( Math.PI ) );
	nzGeometry.applyMatrix( matrix.makeTranslation( 0, 0, -250 ) );

	THREE.GeometryUtils.merge geometry, pxGeometry
	THREE.GeometryUtils.merge geometry, nxGeometry
	THREE.GeometryUtils.merge geometry, pyGeometry
	THREE.GeometryUtils.merge geometry, pzGeometry
	THREE.GeometryUtils.merge geometry, nzGeometry

	return geometry

exports.tiles =
	1: makeFloor(0)
	2: makeFloor(1)
	3: makeBox()
	42: new THREE.SphereGeometry(50, 8, 4)

exports.palette =
	0: [1, 0, 0]
	16: [2, 0, 0]
	128: [3, 3, 42]
	255: [3, 0, 0]


