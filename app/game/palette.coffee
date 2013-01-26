makeFloor = (materialIndex) ->
	matrix = new THREE.Matrix4()

	floor = new THREE.PlaneGeometry(100, 100)
	floor.applyMatrix(matrix.makeRotationX( -Math.PI / 2 ))
	floor.applyMatrix(matrix.makeTranslation(0, -50, 0 ));
	floor.faces[ 0 ].materialIndex = materialIndex
	return floor

makeBox = () ->
	matrix = new THREE.Matrix4();
	geometry = new THREE.Geometry()

	pxGeometry = new THREE.PlaneGeometry( 100, 100 );
	pxGeometry.faces[ 0 ].materialIndex = 1;
	pxGeometry.applyMatrix( matrix.makeRotationY( Math.PI / 2 ) );
	pxGeometry.applyMatrix( matrix.makeTranslation( 50, 0, 0 ) );

	nxGeometry = new THREE.PlaneGeometry( 100, 100 );
	nxGeometry.faces[ 0 ].materialIndex = 1;
	nxGeometry.applyMatrix( matrix.makeRotationY( - Math.PI / 2 ) );
	nxGeometry.applyMatrix( matrix.makeTranslation( - 50, 0, 0 ) );

	pyGeometry = new THREE.PlaneGeometry( 100, 100 );
	pyGeometry.faces[ 0 ].materialIndex = 2;
	pyGeometry.applyMatrix( matrix.makeRotationX( - Math.PI / 2 ) );
	pyGeometry.applyMatrix( matrix.makeTranslation( 0, 50, 0 ) );

	pzGeometry = new THREE.PlaneGeometry( 100, 100 );
	pzGeometry.faces[ 0 ].materialIndex = 1;
	pzGeometry.applyMatrix( matrix.makeTranslation( 0, 0, 50 ) );

	nzGeometry = new THREE.PlaneGeometry( 100, 100 );
	nzGeometry.faces[ 0 ].materialIndex = 1;
	nzGeometry.applyMatrix( matrix.makeRotationY( Math.PI ) );
	nzGeometry.applyMatrix( matrix.makeTranslation( 0, 0, -50 ) );

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
	128: [42, 42, 0]
	255: [3, 0, 0]


