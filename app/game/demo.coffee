fogExp2 = true
container = undefined
stats = undefined
camera = undefined
controls = undefined
scene = undefined
renderer = undefined
mesh = undefined
mat = undefined
worldWidth = 32
worldDepth = 32
worldHalfWidth = worldWidth / 2
worldHalfDepth = worldDepth / 2
Controls = require 'game/controls'
{tiles, palette} = require './palette'

init = ->
	container = document.getElementById("container")
	camera = new THREE.PerspectiveCamera(90, window.innerWidth / window.innerHeight, 1, 20000)
	camera.position.y = 1000 #getY(worldHalfWidth, worldHalfDepth) * 100 + 100
	camera.lookAt new THREE.Vector3 0,0,0
	scene = new THREE.Scene()
	scene.fog = new THREE.FogExp2(0xffffff, 0) # 0.00015 );
	
	
	player = new THREE.Mesh new THREE.CubeGeometry 400, 200, 200
	console.log player
	player.position.x = 0
	player.position.y = 0
	player.position.z = 0
	scene.add player

	controls = new Controls camera, player
	controls.movementSpeed = 1000
	controls.lookSpeed = 0.125
	controls.lookVertical = true
	controls.constrainVertical = true
	controls.verticalMin = 1.1
	controls.verticalMax = 2.2
	controls.activeLook = false

	# sides
	light = new THREE.Color(0xeeeeee)
	shadow = new THREE.Color(0x505050)
	
	# sides
	matrix = new THREE.Matrix4()
	pxGeometry = new THREE.PlaneGeometry(100, 100)

	{tiles, palette} = require './palette'

	geometry = new THREE.Geometry()
	dummy = new THREE.Mesh()
	z = 0
	index = 0

	while z < worldDepth
		x = 0

		while x < worldWidth
			tile = map.data[index] * 256 + map.data[index + 1]
			index += 4
			stack = palette[tile]
			for item, h in stack
				continue unless tiles[item]?
				dummy.position.x = x * 500  - worldHalfWidth * 500
				dummy.position.y = h * 500
				dummy.position.z = z * 500  - worldHalfDepth * 500
				px = getY(x + 1, z)
				nx = getY(x - 1, z)
				pz = getY(x, z + 1)
				nz = getY(x, z - 1)
				dummy.geometry = tiles[item]
				#dummy.geometry = pxGeometry
				THREE.GeometryUtils.merge geometry, dummy


			x++
		z++
	textureStreetH = THREE.ImageUtils.loadTexture("textures/street_h.png")
	textureStreetV = THREE.ImageUtils.loadTexture("textures/street_v.png")
	textureStreetCrossing = THREE.ImageUtils.loadTexture("textures/street_x4.png")
	textureWhite = THREE.ImageUtils.loadTexture("textures/white.png")
	material1 = new THREE.MeshLambertMaterial(
		map: textureStreetH
		ambient: 0xbbbbbb
		vertexColors: THREE.VertexColors
	)
	material2 = new THREE.MeshLambertMaterial(
		map: textureStreetV
		ambient: 0xbbbbbb
		vertexColors: THREE.VertexColors
	)
	material3 = new THREE.MeshLambertMaterial(
		map: textureStreetCrossing
		ambient: 0xbbbbbb
		vertexColors: THREE.VertexColors
	)
	material4 = new THREE.MeshLambertMaterial(
		map: textureWhite
		ambient: 0xbbbbbb
		vertexColors: THREE.VertexColors
	)
	material5 = new THREE.MeshLambertMaterial(
		map: THREE.ImageUtils.loadTexture("textures/walkway.png")
		ambient: 0xbbbbbb
		vertexColors: THREE.VertexColors
	)
	mesh = new THREE.Mesh(geometry, new THREE.MeshFaceMaterial([material1, material2, material3, material4, material5]))
	scene.add mesh
	ambientLight = new THREE.AmbientLight(0xcccccc)
	scene.add ambientLight
	directionalLight = new THREE.DirectionalLight(0xffffff, 0.5)
	directionalLight.position.set(1, 1, 0.5).normalize()
	scene.add directionalLight
	renderer = new THREE.WebGLRenderer(clearColor: 0xffffff)
	renderer.setSize window.innerWidth, window.innerHeight
	container.innerHTML = ""
	container.appendChild renderer.domElement
	stats = new Stats()
	stats.domElement.style.position = "absolute"
	stats.domElement.style.top = "0px"
	container.appendChild stats.domElement

	#
	window.addEventListener "resize", onWindowResize, false
onWindowResize = ->
	camera.aspect = window.innerWidth / window.innerHeight
	camera.updateProjectionMatrix()
	renderer.setSize window.innerWidth, window.innerHeight
	controls.handleResize()
loadTexture = (path, callback) ->
	image = new Image()
	image.onload = ->
		callback()

	image.src = path
	image
generateHeight = (width, height) ->
	data = []
	perlin = new ImprovedNoise()
	size = width * height
	quality = 2
	z = Math.random() * 100
	j = 0

	while j < 4
		if j is 0
			i = 0

			while i < size
				data[i] = 0
				i++
		i = 0

		while i < size
			x = i % width
			y = (i / width) | 0
			data[i] += perlin.noise(x / quality, y / quality, z) * quality
			i++
		quality *= 4
		j++
	data
getY = (x, z) ->
	(data[x + z * worldWidth] * 0.2) | 0

#
animate = ->
	requestAnimationFrame animate
	render()
	stats.update()
render = ->
	controls.update clock.getDelta()
	renderer.render scene, camera
unless Detector.webgl
	Detector.addGetWebGLMessage()
	document.getElementById("container").innerHTML = ""

loadImage = require 'game/loadimage'
console.log loadImage

map = undefined
loadImage 'maps/test2.png', (imageData) ->
	console.log 'loaded', imageData
	map = imageData
	worldWidth = map.width
	worldDepth = map.height
	worldHalfWidth = worldWidth / 2
	worldHalfDepth = worldDepth / 2
	init()
	animate()

data = generateHeight(worldWidth, worldDepth)
clock = new THREE.Clock()


