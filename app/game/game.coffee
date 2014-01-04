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
policeCount = 0
map = undefined
Controls = require 'game/controls'
Car = require 'game/car'
PoliceCar = require 'game/policecar'
Victim = require 'game/victim'
MapHint = require 'game/maphint'
Map = require './map'
{SimulationParameters, TrafficSimulation} = require './traffic_sim'
StreetGraph = require './road_network'

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


init = (done) ->
	controls = new Controls()

	# Graphics scene.
	scene = new THREE.Scene()
	scene.fog = new THREE.FogExp2(0xffffff, 0)

	# Lights.
	ambientLight = new THREE.AmbientLight(0xcccccc)
	scene.add ambientLight
	directionalLight = new THREE.DirectionalLight(0xffffff, 0.5)
	directionalLight.position.set(1, 1, 0.5).normalize()
	scene.add directionalLight

	# Camera.
	camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 100, 5000)
	camera.position.y = 2000
	camera.rotation.z = Math.PI
	scene.add camera
	
	# Physics world.
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
	
	# Map.
	map = new Map(scene, world)
	map.load ->
		graph = StreetGraph.fromMapData(map.map)
		#traffic = new TrafficSimulation({x: 0, y: 0}, graph, new SimulationParameters(2, 15, 5, 500, 25), world, scene, {x: map.width * 250, y: map.height * 250})
		placeCar()
		placeVictim()
		done()

	container = document.getElementById("game-container")

	# Renderer.
	renderer = new THREE.WebGLRenderer
		clearColor: 0xffffff
		precision: "lowp"
	renderer.setDepthTest(false)
	container.appendChild renderer.domElement
	renderer.domElement.style.position = "absolute"
	renderer.domElement.style.bottom = "0px"
	renderer.domElement.style.right = "0px"
	resizeHandler = ->
		camera.aspect = window.innerWidth / window.innerHeight
		camera.updateProjectionMatrix()
		renderer.setSize $(container).width(), $(container).height()
		$('#touch-frame')[0].width = $(container).width()
		$('#touch-frame')[0].height = $(container).height()
	$(window).resize resizeHandler
	resizeHandler()

	# Frame statistics.
	stats = new Stats()
	stats.domElement.style.position = "absolute"
	stats.domElement.style.bottom = "0px"
	stats.domElement.style.right = "0px"
	container.appendChild stats.domElement

placeCar = () ->
	playerCar = new Car world
	playerCar.load()
	playerCar.onGrabbed = ->
		carDirection = new THREE.Vector3(-Math.cos(playerCar.root.rotation.y) * 250, 0, -Math.sin(playerCar.root.rotation.y) * 250)
		if playerCar.root.position.clone().sub(carDirection).sub(victim.root.position).length() < 500 and cargoCount < 4
			placeVictim()
			cargoCount++
			policeCount = Math.min(policeCount + 1, 9)
			document.getElementById('grab').play()
	scene.add playerCar.root

placeVictim = () ->
	if victim?
		scene.remove victim.root
		scene.remove victimHint.root
	if butcherHint?
		scene.remove butcherHint.root

	randomNode = graph.randomNode([])
	#console.log randomNode
	victim = new Victim()
	victim.load()
	scene.add victim.root
	victim.root.position.x = (randomNode.y - map.worldHalfDepth) * 500
	victim.root.position.z = (randomNode.x - map.worldHalfWidth) * 500
	
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
cargoCount = 0
 
uiLoop = ->
	# Cash
	$('#cash').text(formatDollar(cash))

	# Cargo
	for index in [0..3]
		if cargoCount > index
			$("#cargo-" + index).attr("src", "ui/heart-1.png")
		else
			$("#cargo-" + index).attr("src", "ui/heart-0.png")

	# Police
	policeFrame = $("#police-frame")
	return if policeFrame.children().length is policeCount
	policeFrame.empty()
	for index in [1..policeCount] by 1
		policeFrame.append('<img src="ui/police.png">')

	setTimeout uiLoop, 500

#
animate = ->
	requestAnimationFrame animate
	render()
	stats.update()

physicsLoop = ->
	fps = 60
	timeStep = 0.9/fps  # compensate because physics were calibrated wrongly
	window.setTimeout(physicsLoop, 1000/fps)
	
	playerCar.updatePhysics timeStep, controls
	#traffic.updatePhysics timeStep
	for policeCar in policeCars
		policeCar.updatePhysics timeStep, policeCar.controls
	world.Step timeStep, 6, 2
	world.ClearForces()

	#setTimeout(physicsLoop, 1000/fps)
	# canvas = document.getElementById("debug")
	# canvas.width = canvas.width;
	# ctx = canvas.getContext('2d')
	# ctx.translate worldHalfWidth*10 , worldHalfDepth*10
	# world.DrawDebugData()

blockedSince = null
gameOver = false
busted = false

render = ->
	deltaT = clock.getDelta()
	if not gameOver
		playerCar.update deltaT, controls
	#traffic.step deltaT, {x: playerCar.body.GetPosition().x, y: playerCar.body.GetPosition().z}
	#traffic.update deltaT
	blocked = false
	for policeCar in policeCars
		policeCar.update deltaT
		policeCar.kiUpdate deltaT
		if policeCar.root.position.clone().sub(playerCar.root.position).length() < 2000 and not gameOver
			raceSince = 0 unless 0 < raceSince < 2
			document.getElementById('sirene').play()
			if policeCar.root.position.clone().sub(playerCar.root.position).length() < 800 and playerCar.getSpeedKMH() < 5
				blocked = true
				if not blockedSince?
					blockedSince = clock.getElapsedTime()
				else if clock.getElapsedTime() - blockedSince > 5
					gameOver = true
	if not blocked
		blockedSince = null

	if gameOver
		document.getElementById('bg1').pause()
		document.getElementById('bg2').pause()
		# policeCount = 100
		
		if not busted
			gameDiv = $('#game')
			for i in [0..10]
				gameDiv.append """<div class='busted-line' style='
				-webkit-transform-origin:#{i*15}em 0em; transform-origin:#{i*15}em 0em;
				-webkit-animation: busted 0.5s #{i*0.01}s linear forwards; animation: busted 0.5s #{i*0.01}s  linear forwards;
				'></div>"""
			gameDiv.append "<p id='busted-text'>BUSTED!</p>"
			busted = true
			document.getElementById('jail').play()
		setTimeout () ->
			location.reload()
		, 10000
		return

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

	if parkingPlace? and parkingPlace.clone().sub(playerCar.root.position).length() < 300
		if cargoCount > 0
			document.getElementById('kaching').play()
			policeCount = Math.max(policeCount - 1, 0)
		cash += cargoCount * 10000
		if butcherHint?
			scene.remove butcherHint.root
		cargoCount = 0

	b2Transform = require

	if policeCars.length < policeCount < 10 and not nextPoliceSpawn?
		nextPoliceSpawn =
			time: clock.getElapsedTime() + 5
			position:
				#root: playerCar.root.position.clone()
				x: playerCar.body.GetPosition().x
				y: playerCar.body.GetPosition().y
		#console.log nextPoliceSpawn
	else if nextPoliceSpawn? and clock.getElapsedTime() > nextPoliceSpawn.time
		policeCar = new PoliceCar(world, playerCar, map.map, nextPoliceSpawn.position)
		policeCar.load()
		#policeCar.body.SetPosition(new b2Vec2(nextPoliceSpawn.position.x, nextPoliceSpawn.position.y))
		#policeCar.root.position = nextPoliceSpawn.position.root
		console.log 'Adding police', nextPoliceSpawn.position
		#policeCar.body.angle = nextPoliceSpawn.angle
		scene.add policeCar.root
		#policeCar.updatePhysics(0, {})
		policeCars.push policeCar
		nextPoliceSpawn = null
	else
		for policeCar, idx in policeCars
			continue unless policeCar?
			if policeCar.root.position.clone().sub(playerCar.root.position).length() > 10000
				console.log 'Removing remote police car'
				scene.remove policeCar.root
				world.DestroyBody policeCar.body
				policeCars.splice(idx, 1)


	camera.position.x = playerCar.root.position.x
	camera.position.z = playerCar.root.position.z
	carSpeed = playerCar.getSpeedKMH()
	camera.position.y = THREE.Math.clamp (Math.pow(Math.max(0,carSpeed - 10),1.01) - 20 + camera.position.y), 2000, 3000
	camera.lookAt playerCar.root.position
	updateHints()
	renderer.render scene, camera

# silly workaround for HTML not being added to DOM, yet.
setTimeout -> 
	init ->
		animate()
		physicsLoop()
		uiLoop()
		document.getElementById('bg0').pause()
		document.getElementById('bg1').play()
, 1

clock = new THREE.Clock()
