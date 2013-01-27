fogExp2 = true
container = undefined
stats = undefined
camera = undefined
controls = undefined
playerCar = undefined
traffic = undefined
policeCars = []
scene = undefined
world = undefined
renderer = undefined
mesh = undefined
mat = undefined
raceSince = undefined
victim = undefined
victimHint = undefined
victimTimeleft = undefined
butcherHint = undefined
parkingPlace = undefined
graph = undefined
nextPoliceSpawn = undefined
cash = 0
worldWidth = 32
worldDepth = 32
worldHalfWidth = worldWidth / 2
worldHalfDepth = worldDepth / 2
Controls = require 'game/controls'
Car = require 'game/car'
PoliceCar = require 'game/policecar'
Victim = require 'game/victim'
MapHint = require 'game/maphint'
{tiles, palette} = require './palette'
{StreetGraph, SimulationParameters, TrafficSimulation} = require './traffic_sim'

updateHints = null

b2Vec2 = Box2D.Common.Math.b2Vec2
b2BodyDef = Box2D.Dynamics.b2BodyDef
b2Body = Box2D.Dynamics.b2Body
b2FixtureDef = Box2D.Dynamics.b2FixtureDef
b2Fixture = Box2D.Dynamics.b2Fixture
b2World = Box2D.Dynamics.b2World
# b2MassData = Box2D.Collision.Shapes.b2MassData
b2PolygonShape = Box2D.Collision.Shapes.b2PolygonShape
# b2CircleShape = Box2D.Collision.Shapes.b2CircleShape
b2DebugDraw = Box2D.Dynamics.b2DebugDraw

init = ->
	container = document.getElementById("container")
	camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 100, 5000)
	camera.position.y = 2000
	scene = new THREE.Scene()
	scene.fog = new THREE.FogExp2(0xffffff, 0) # 0.00015 );
		
	world = new b2World new b2Vec2(0,0), true
	# debugDraw = new b2DebugDraw()
	# ctx = document.getElementById("debug").getContext("2d")
	# debugDraw.SetSprite ctx
	# debugDraw.SetDrawScale(30)
	# ctx.translate worldHalfWidth*10 , worldHalfDepth*10
	# debugDraw.SetFillAlpha(0.5)
	# debugDraw.SetLineThickness(1.0)
	# debugDraw.SetFlags(b2DebugDraw.e_shapeBit | b2DebugDraw.e_jointBit)
	# world.SetDebugDraw(debugDraw)
	playerCar = new Car world


	playerCar.loadPartsJSON 'textures/Male02_dds.js', 'textures/Male02_dds.js'

	playerCar.onGrabbed = ->
		if playerCar.root.position.clone().sub(victim.root.position).length() < 500 and cargoCount < 4
			placeVictim()
			cargoCount++
			policeCount++
			document.getElementById('grab').play()

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

	# tile physics
	bodyDef = new b2BodyDef()
	bodyDef.type = b2Body.b2_staticBody
	fixDef = new b2FixtureDef()
	fixDef.density = 1.0
	fixDef.friction = 0.05
	fixDef.restitution = 0.0
	fixDef.shape = new b2PolygonShape()
	fixDef.shape.SetAsBox 2.5, 2.5

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
			else if tile is 0x0101
				parkingPlace = new THREE.Vector3(x * 500  - worldHalfWidth * 500, 0, z * 500  - worldHalfDepth * 500)

			stack = palette[tile] or []
			for item, h in stack
				continue unless tiles[item]?
				dummy.position.x = x * 500  - worldHalfWidth * 500
				dummy.position.y = h * 500
				dummy.position.z = z * 500  - worldHalfDepth * 500
				dummy.geometry = tiles[item]
				#dummy.geometry = pxGeometry
				THREE.GeometryUtils.merge geometry, dummy

				# physics
				if tile in [0x8080, 0x7f7f, 0xffff, 0xfffe, 0x0000]
					bodyDef.position.x = x * 5 - worldHalfWidth * 5
					bodyDef.position.y = z * 5 - worldHalfDepth * 5
					world.CreateBody(bodyDef).CreateFixture(fixDef)

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

	graph = StreetGraph.fromMapData(map)
	console.log graph

	placeVictim()
	
	traffic = new TrafficSimulation({x: 0, y: 0}, graph, new SimulationParameters(2, 4, 5, 500, 50), world, scene, {x: map.width * 250, y: map.height * 250})
	
	#
	$(window).resize ->
		camera.aspect = window.innerWidth / window.innerHeight
		camera.updateProjectionMatrix()
		renderer.setSize $(container).width(), $(container).height()
		controls.handleResize()

placeVictim = () ->
	if victim?
		scene.remove victim.root
		scene.remove victimHint.root
	if butcherHint?
		scene.remove butcherHint.root

	randomNode = graph.randomNode([])
	console.log randomNode
	victim = new Victim()
	victim.loadPartsJSON 'textures/Male02_dds.js', 'textures/Male02_dds.js'
	scene.add victim.root
	victim.root.position.x = (randomNode.y - worldHalfDepth) * 500
	victim.root.position.z = (randomNode.x - worldHalfWidth) * 500
	
	victimHint = new MapHint()
	victimHint.loadParts("ui/victim_hint.png")
	scene.add victimHint.root
	
	initialDistance = new THREE.Vector2(victim.root.position.x - playerCar.root.position.x, 
		victim.root.position.z - playerCar.root.position.z).length()
	
	victimTimeleftLast = victimTimeleft
	victimTimeleft = (5 + (initialDistance / 500) * 2.5) | 0
	victimBleedTicker = () ->
		victimTimeleft--
		$("#victim-timeleft").text('Time left for ambulance ' + ((victimTimeleft / 60) | 0) + ':' + (victimTimeleft % 60))
		if victimTimeleft > 0
			setTimeout(victimBleedTicker, 1000)
		else
			placeVictim()
	if not victimTimeleftLast? or victimTimeleftLast <= 0
		victimBleedTicker()
	
	if cargoCount > 0
		butcherHint = new MapHint()
		butcherHint.loadParts("ui/butcher_hint.png")
		scene.add butcherHint.root
	
	updateHints = ->
		victimHint.update victim, playerCar
		if butcherHint?
			butcherHint.update {root: position: parkingPlace}, playerCar

loadTexture = (path, callback) ->
	image = new Image()
	image.onload = ->
		callback()

	image.src = path
	image


# crash ui
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

cash = 0
#TODO: replace with proper code.
setInterval(->
#	cash += 1000
	$('#cash').text(formatDollar(cash))
, 500)

# cargo ui
cargoCount = 0

#TODO: replace with proper code.
setInterval(->
#	cargoCount = (cargoCount + 1) % 5
	for index in [0..3]
		if cargoCount > index
			$("#cargo-" + index).attr("src", "ui/heart-1.png")
		else
			$("#cargo-" + index).attr("src", "ui/heart-0.png")
, 500)

# police ui
policeCount = 0
#TODO: replace with proper code.
setInterval(->
	#policeCount = (policeCount + 1) % 4
	policeFrame = $("#police-frame")
	policeFrame.empty()
	for index in [1..policeCount]
		policeFrame.append('<img src="ui/police.png">')
, 500)

#
animate = ->
	requestAnimationFrame animate
	render()
	stats.update()

physicsLoop = ->
	fps = 60
	timeStep = 1.0/fps
	
	playerCar.updatePhysics timeStep, controls
	traffic.updatePhysics timeStep
	for policeCar in policeCars
		policeCar.updatePhysics timeStep, policeCar.controls
	world.Step timeStep, 6, 2
	world.ClearForces()

	setTimeout(physicsLoop, 1000/fps)
	# canvas = document.getElementById("debug")
	# canvas.width = canvas.width;
	# ctx = canvas.getContext('2d')
	# ctx.translate worldHalfWidth*10 , worldHalfDepth*10
	# world.DrawDebugData()

render = ->
	deltaT = clock.getDelta()
	playerCar.update deltaT, controls
	traffic.step deltaT, {x: playerCar.body.GetPosition().x, y: playerCar.body.GetPosition().z}
	traffic.update deltaT
	for policeCar in policeCars
		policeCar.update deltaT
		policeCar.kiUpdate deltaT
		if policeCar.root.position.clone().sub(playerCar.root.position).length() < 2000
			raceSince = 0 unless 0 < raceSince < 2
			document.getElementById('sirene').play()

	raceSince += deltaT

	if 0 < raceSince < 1
		document.getElementById('bg1').volume = (1 - raceSince)
		document.getElementById('bg2').play()
		document.getElementById('bg2').volume = 1
	else if 1 < raceSince < 15
		document.getElementById('bg1').pause()
	else if 15 < raceSince < 20
		document.getElementById('bg2').volume = Math.min(Math.max((20 - raceSince) / 5, 0), 1)
		document.getElementById('bg1').play()
		document.getElementById('bg1').volume = Math.min(Math.max(raceSince - 19, 0), 0.9)
	else if raceSince > 20
		document.getElementById('bg2').pause()
		document.getElementById('bg1').play()
		document.getElementById('bg1').volume = 0.9
		raceSince = undefined

	if parkingPlace.clone().sub(playerCar.root.position).length() < 300
		if cargoCount > 0
			document.getElementById('kaching').play()
		cash += cargoCount * 10000
		if butcherHint?
			scene.remove butcherHint.root
		cargoCount = 0
		policeCount = Math.max(policeCount - 1, 0)

	b2Transform = require

#	policeCount = 3

	if policeCars.length < policeCount and not nextPoliceSpawn?
		nextPoliceSpawn =
			time: clock.getElapsedTime() + 3
			position: playerCar.body.GetPosition().Copy()
		console.log nextPoliceSpawn
	else if nextPoliceSpawn? and clock.getElapsedTime() > nextPoliceSpawn.time
		policeCar = new PoliceCar(world, playerCar, map)
		policeCar.loadPartsJSON 'textures/Male02_dds.js', 'textures/Male02_dds.js'
		policeCar.body.SetPosition(nextPoliceSpawn.position)
		console.log 'Adding police', nextPoliceSpawn.position
		#policeCar.body.angle = nextPoliceSpawn.angle
		scene.add policeCar.root
		policeCars.push policeCar
		nextPoliceSpawn = null
	else
		for policeCar, idx in policeCars
			if policeCar.root.position.clone().sub(playerCar.root.position).length() > 10000
				console.log 'Removing remote police car'
				scene.remove policeCar.root
				policeCars.splice(idx, 1)


	camera.position.x = playerCar.root.position.x
	camera.position.z = playerCar.root.position.z
	carSpeed = playerCar.getSpeedKMH()
	camera.position.y = THREE.Math.clamp (Math.pow(Math.max(0,carSpeed - 10),1.01) - 20 + camera.position.y), 2000, 3000
	camera.lookAt playerCar.root.position
	updateHints()
	renderer.render scene, camera
unless Detector.webgl
	Detector.addGetWebGLMessage()
	document.getElementById("container").innerHTML = ""

loadImage = require 'game/loadimage'

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
	physicsLoop()
	document.getElementById('bg0').pause()
	document.getElementById('bg1').play()

clock = new THREE.Clock()
