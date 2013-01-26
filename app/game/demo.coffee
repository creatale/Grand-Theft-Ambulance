fogExp2 = true
container = undefined
stats = undefined
camera = undefined
controls = undefined
playerCar = undefined
scene = undefined
renderer = undefined
mesh = undefined
mat = undefined
worldWidth = 32
worldDepth = 32
worldHalfWidth = worldWidth / 2
worldHalfDepth = worldDepth / 2
Controls = require 'game/controls'
Car = require 'game/car'
{tiles, palette} = require './palette'

init = ->
	container = document.getElementById("container")
	camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 1, 20000)
	camera.position.y = 1000 #getY(worldHalfWidth, worldHalfDepth) * 100 + 100
	scene = new THREE.Scene()
	scene.fog = new THREE.FogExp2(0xffffff, 0) # 0.00015 );
	
	playerCar = new Car()

	playerCar.loadPartsJSON 'textures/Male02_dds.js', 'textures/Male02_dds.js'


	scene.add playerCar.root
	scene.add camera
	camera.rotation.z = Math.PI
	controls = new Controls()

	# sides
	light = new THREE.Color(0xeeeeee)
	shadow = new THREE.Color(0x505050)
	
	# sides
	matrix = new THREE.Matrix4()
	pxGeometry = new THREE.PlaneGeometry(100, 100)

	geometry = new THREE.Geometry()
	dummy = new THREE.Mesh()
	z = 0
	index = 0

	isStreet = (x, y) ->
		return false unless x >= 0 and y >= 0 and x < map.width and y < map.height
		idx = (x * worldDepth + y) * 4
		return map.data[idx + 1] is 0 and map.data[idx] > 0


	while z < worldDepth
		x = 0

		while x < worldWidth
			tile = map.data[index] * 256 + map.data[index + 1]
			index += 4

			if tile is 0xe000
				tile |= isStreet(z - 1, x)
				tile |= isStreet(z, x - 1) << 1
				tile |= isStreet(z + 1, x) << 2
				tile |= isStreet(z, x + 1) << 3
			else if tile is 0x8080 and Math.random() > 0.5
				tile = 0x7f7f
			else if tile is 0xffff and Math.random() > 0.5
				tile = 0xfffe

			stack = palette[tile] or []
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
	mesh = new THREE.Mesh(geometry, new THREE.MeshFaceMaterial([
		matStreetStraight, matStreetCorner, matStreetCrossing,  matRoof, matWalk, matStreetT, matWall1, matWall2]))
	scene.add mesh
	ambientLight = new THREE.AmbientLight(0xcccccc)
	scene.add ambientLight
	directionalLight = new THREE.DirectionalLight(0xffffff, 0.5)
	directionalLight.position.set(1, 1, 0.5).normalize()
	scene.add directionalLight
	renderer = new THREE.WebGLRenderer(clearColor: 0xffffff)
	renderer.setSize $(container).width(), $(container).height()
	container.appendChild renderer.domElement
	renderer.domElement.style.position = "absolute"
	renderer.domElement.style.bottom = "0px"
	renderer.domElement.style.right = "0px"
	stats = new Stats()
	stats.domElement.style.position = "absolute"
	stats.domElement.style.bottom = "0px"
	stats.domElement.style.right = "0px"
	container.appendChild stats.domElement
	$(window).resize ->
		camera.aspect = window.innerWidth / window.innerHeight
		camera.updateProjectionMatrix()
		renderer.setSize $(container).width(), $(container).height()
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

# crash stuff
formatDollar = (num) ->
	p = num.toFixed(2).split(".")
	chars = p[0].split("").reverse()
	newstr = ""
	count = 0
	for x of chars
		count++
		if count % 3 is 1 and count isnt 1
			newstr = chars[x] + "," + newstr
		else
			newstr = chars[x] + newstr
	newstr + "." + p[1]

#TODO: replace with proper code.
cash = 0
setInterval(->
	cash += 1000
	$('#cash').text(formatDollar(cash))
, 500)
	
#
animate = ->
	requestAnimationFrame animate
	render()
	stats.update()
render = ->
	playerCar.update clock.getDelta(), controls
	camera.position.x = playerCar.root.position.x
	camera.position.z = playerCar.root.position.z
	camera.lookAt playerCar.root.position

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


