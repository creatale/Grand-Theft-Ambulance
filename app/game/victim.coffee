module.exports = class Car
# car geometry manual parameters
	constructor: ->
		@modelScale = 1

		@texture = "textures/victim.png"

		@root = new THREE.Object3D()

	loadPartsJSON: (bodyURL) =>
		@bodyGeometry = new THREE.PlaneGeometry 256 * 1.8, 256 * 1.8
		@bodyGeometry.dynamic = true
		matrix = new THREE.Matrix4()
		@bodyGeometry.applyMatrix matrix.makeRotationX -Math.PI / 2
		@bodyGeometry.applyMatrix matrix.makeRotationY Math.PI
		map = THREE.ImageUtils.loadTexture(@texture)
		map.wrapS = map.wrapT = THREE.RepeatWrapping
		#map.repeat.set( 1, 2 );
		@bodyMaterials = [
			new THREE.MeshLambertMaterial( { ambient: 0xbbbbbb, map: map, transparent: true, side: THREE.DoubleSide } ),
			#new THREE.MeshBasicMaterial( { color: 0xffffff, wireframe: true, transparent: true, opacity: 0.1, side: THREE.DoubleSide } )
		]

		bodyFaceMaterial = new THREE.MeshFaceMaterial(@bodyMaterials)

		s = @modelScale
		@bodyMesh = new THREE.Mesh @bodyGeometry, bodyFaceMaterial
		@bodyMesh.scale.set s, s, s
		@root.add @bodyMesh
		@root.position.y = -5