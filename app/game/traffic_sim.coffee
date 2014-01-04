Car = require './car'
b2Vec2 = Box2D.Common.Math.b2Vec2
b2Transform = Box2D.Common.Math.b2Transform
b2Mat22 = Box2D.Common.Math.b2Mat22

class Node
	constructor: (@x, @y, @type, @children = []) ->
		@fromEdges = []
		@toEdges = []
		@occupiedBy = null
	
	distanceTo: (position) =>
		return Math.sqrt(Math.pow(@x - position.x, 2) + Math.pow(@y - position.y, 2))
		
	randomTo: (from) =>
		if @toEdges.length > 1
			if from?
				edges = []
				for edge in @toEdges
					switch from.type
						when 16
							if not (edge.to.type is 64)
								edges.push edge
						when 32
							if not (edge.to.type is 48)
								edges.push edge
						when 48
							if not (edge.to.type is 32)
								edges.push edge
						when 64
							if not (edge.to.type is 16)
								edges.push edge
				return edges[Math.floor(Math.random() * edges.length)].to
			else
				return @toEdges[Math.floor(Math.random() * @toEdges.length)].to
		else if @toEdges.length > 0
			return @toEdges[0].to
		else
			return new Node 0, 0, 0
			
	@createSuperNode: (nodes) =>
		x = 0
		y = 0
		for node in nodes
			x += node.x
			y += node.y
		if nodes.length > 0
			return new Node(x / nodes.length, y / nodes.length, nodes[0].type, nodes)
		else
			return new Node 0, 0, 0
	
class Edge
	constructor: (@from, @to) ->

module.exports.StreetGraph = class StreetGraph
	constructor: (@nodes, @edges) ->
		for edge in @edges
			edge.to.fromEdges.push edge
			edge.from.toEdges.push edge
	
	findNodes: (position, minRadius, maxRadius) =>
		result = []
		for node in @nodes
			distance = node.distanceTo(position)
			if (distance < minRadius) or (distance > maxRadius)
				result.push node
		return result
		
	occupiedNodes: =>
		result = []
		for node in @nodes
			if node.occupiedBy?
				result.push node
		return result
		
	randomNode: (exclude) =>
		isExcluded = (node, excluded) =>
			for excludedNode in excluded
				if node is excludedNode
					return true
			return false
			
		nodes = []
		for node in @nodes
			if isExcluded node, exclude
				nodes.push node
		if nodes.length > 1
			return nodes[Math.floor(Math.random() * nodes.length)]
		else if nodes.length > 0
			return nodes[0]
		else
			#console.log 'tada'
			return @nodes[Math.floor(Math.random() * @nodes.length)]
	
	@fromMapData: (mapData) =>
		index = 0
		nodes = []
		edges = []
		for x in [0..(mapData.width - 1)]
			for y in [0..(mapData.height - 1)]
				tile = mapData.data[index]
				if tile in [16, 32, 48, 64, 224]
					if mapData.data[index + 1] is 0
						nodes.push new Node(x, y, tile)
				index += 4
		nodes = @createSuperNodes nodes
		edges = @generateEdges(nodes)
		return new StreetGraph nodes, edges
		# return
			
	@createSuperNodes: (nodes) =>
		result = []
		while nodes.length > 0
			node = nodes[0]
			if node.type is 224 # Crossing
				crossingNodes = []
				crossingNodes.push node
				nodes.splice(nodes.indexOf(node), 1)
				adjacentNodes = @findAdjacentNodes(node, nodes, 224)
				while adjacentNodes.length > 0
					newAdjacentNodes = []
					crossingNodes = crossingNodes.concat adjacentNodes
					for adjacentNode in adjacentNodes
						nodes.splice(nodes.indexOf(adjacentNode), 1)
					for adjacentNode in adjacentNodes
						newAdjacentNodes = newAdjacentNodes.concat(@findAdjacentNodes(adjacentNode, nodes, 224))
					adjacentNodes = newAdjacentNodes
				result.push Node.createSuperNode crossingNodes
			else
				result.push node
				nodes.splice(nodes.indexOf(node), 1)
		return result
	
	@findAdjacentNodes: (node, nodes, type) =>
		result = []
		newNode = @findNode node.x + 1, node.y, nodes
		if (newNode?) and (newNode.type is type)
			result.push newNode
		newNode = @findNode node.x - 1, node.y, nodes
		if (newNode?) and (newNode.type is type)
			result.push newNode
		newNode = @findNode node.x, node.y + 1, nodes
		if (newNode?) and (newNode.type is type)
			result.push newNode
		newNode = @findNode node.x, node.y - 1, nodes
		if (newNode?) and (newNode.type is type)
			result.push newNode
		return result
	
	@findNode: (x, y, nodes) =>
		for node in nodes
			if (node.x is x) and (node.y is y)
				return node
		return null

	@findNodeWithSuperNodes: (x, y, nodes) =>
		for node in nodes
			if node.children.length > 0 
				if (@findNode(x, y, node.children))?
					return node
			else
				if (node.x is x) and (node.y is y)
					return node
		return null
		
	@generateEdges: (nodes) =>
		edges = []
		
		insertEdge = (newEdge, edges) =>
			for edge in edges
				if (edge.from is newEdge.from) and (edge.to is newEdge.to)
					return
			edges.push newEdge
		
		for node in nodes
			switch node.type
				when 16
					toNode = @findNodeWithSuperNodes(node.x, node.y + 1, nodes)
					if toNode?
						insertEdge(new Edge(node, toNode), edges)
					fromNode = @findNodeWithSuperNodes(node.x, node.y - 1, nodes)
					if fromNode?
						insertEdge(new Edge(fromNode, node), edges)
				when 32
					toNode = @findNodeWithSuperNodes(node.x + 1, node.y, nodes)
					if toNode?
						insertEdge(new Edge(node, toNode), edges)
					fromNode = @findNodeWithSuperNodes(node.x - 1, node.y, nodes)
					if fromNode?
						insertEdge(new Edge(fromNode, node), edges)
				when 48
					toNode = @findNodeWithSuperNodes(node.x - 1, node.y, nodes)
					if toNode?
						insertEdge(new Edge(node, toNode), edges)
					fromNode = @findNodeWithSuperNodes(node.x + 1, node.y, nodes)
					if fromNode?
						insertEdge(new Edge(fromNode, node), edges)
				when 64
					toNode = @findNodeWithSuperNodes(node.x, node.y - 1, nodes)
					if toNode?
						insertEdge(new Edge(node, toNode), edges)
					fromNode = @findNodeWithSuperNodes(node.x, node.y + 1, nodes)
					if fromNode?
						insertEdge(new Edge(fromNode, node), edges)
		return edges
	
module.exports.SimulationParameters = class SimulationParameters
	constructor: (@minSpawnRadius, @maxSpawnRadius, @numCars, @tileSize, @despawnRadius) ->
	
class SimulationCar extends Car
	constructor: (world, @type, @from, @to, @nextNode, @tileSize) ->
		super world, 
			position:
				x: @from.x * @tileSize / 100
				y: @from.y * @tileSize / 100
		#@modelScale = 2.5
		# mat = new b2Mat22()
		# mat.Set(Math.atan2(@to.x - @from.x, @to.y - @from.y))
		# @body.SetTransform(new b2Transform(new b2Vec2(@from.x * @tileSize / 100, @from.y * @tileSize / 100), mat))

		@texture = "textures/limousine_#{ Math.round(Math.random() * 8 + 0.5) }.png"
		@controls =
			moveLeft: false
			moveRight: false
			moveForward: false

	load: () =>
		@bodyGeometry = new THREE.PlaneGeometry 128 * 1.8, 256 * 1.8
		matrix = new THREE.Matrix4()
		@bodyGeometry.applyMatrix matrix.makeRotationX -Math.PI / 2
		@bodyGeometry.applyMatrix matrix.makeRotationY Math.PI
		#@updateSprite(0)
		map = THREE.ImageUtils.loadTexture(@texture)
		map.wrapS = map.wrapT = THREE.RepeatWrapping
		@bodyMaterials = [
			new THREE.MeshLambertMaterial( { ambient: 0xbbbbbb, map: map, transparent: true, side: THREE.DoubleSide } ),
		]
		@wheelGeometry = new THREE.SphereGeometry 5, 5, 4
		@createCar()
		# @modelScale = 1
		# @root = new THREE.Object3D()
		# @bodyMesh = null
		# @bodyGeometry = null
		# @bodyMaterials = null
		# @loaded = false
		# @meshes = []

	# setVisible: (enable) =>
		# for mesh in @meshes
			# mesh.visible = enable

	# load: () =>
		# @bodyGeometry = new THREE.CubeGeometry 40, 80, 80
		# @createCar()

	# createBody: (geometry, materials) =>
		# @bodyGeometry = geometry
		# @bodyMaterials = materials
		# @createCar()
		
	# createCar: =>
		# if @bodyGeometry and @wheelGeometry
			
			# # rig the car
			# s = @modelScale
			# delta = new THREE.Vector3()
			# bodyFaceMaterial = new THREE.MeshFaceMaterial(@bodyMaterials)
			
			# # body
			# @bodyMesh = new THREE.Mesh @bodyGeometry #, bodyFaceMaterial)
			# @bodyMesh.scale.set s, s, s
			# @root.add @bodyMesh
			
			# # cache meshes
			# @meshes = [@bodyMesh]
			
			# # callback
			# @loaded = true
			# @callback if @callback

	inRange: (playerPosition, maxDistance, tileSize) =>
		return Math.sqrt(Math.pow(playerPosition.x - @body.GetPosition().y * 100 / tileSize, 2) + Math.pow(playerPosition.y - @body.GetPosition().x * 100 / tileSize, 2)) < maxDistance
		
	# move: (deltaT, globalOffset) =>
		# # break if @nextNode is occupied and ||nextNode.car.velocity|| < ||@velocity||
		# # break completely if crossing is occupied
		# speed = 0
		# switch @type
			# when 0
				# speed = 0.025
		# if @to.occupiedBy?
			# speed = speed / 2
		# if @nextNode.occupiedBy?
			# speed = speed / 4
		# direction =
			# x: (@to.x - @position.x)
			# y: (@to.y - @position.y)

		# @root.rotation.y = Math.atan2(direction.y, direction.x)

		# # console.log direction
		# length = Math.sqrt(Math.pow(direction.x, 2) + Math.pow(direction.y, 2))
		# @position =
			# x: (@position.x + direction.x * speed / length)
			# y: (@position.y + direction.y * speed / length)
		# # console.log @root.position
		# @root.position.x = @position.y * @tileSize - globalOffset.y
		# @root.position.z = @position.x * @tileSize - globalOffset.x
		# # console.log @root.position
		# return
		
	calculateControls: =>
		forward = false
		left = false
		right = false
		if (not @to.occupiedBy?) and (not @nextNode.occupiedBy?)
			forward = true
			
		currentAngle = @body.GetAngle()
		newAngle = Math.atan2(@to.x, @to.y)
		
		angleDiff = newAngle - currentAngle
		
		if Math.abs(angleDiff) > 0.35 # approx. 10 degrees
			if angleDiff > 0
				left = true
			else
				right = true
			
		@controls =
			moveLeft: left
			moveRight: right
			moveForward: true
		
	atDestination: (tileSize) =>
		# console.log @to.distanceTo(@position)
		return @to.distanceTo({x: @body.GetPosition().y * 100 / tileSize, y: @body.GetPosition().x * 100 / tileSize}) < 2 # @tileSize
		# return false
		
	findNewDestination: =>
		@from.occupiedBy = null
		@to.occupiedBy = @
		@from = @to
		@to = @nextNode
		@nextNode = @nextNode.randomTo(@from)

#
# drive
# random turns at crossings
# avoid collision
# - look ahead, break if car
# - waiting at crossing: at max one car per crossing
# - max capacity per street piece
# map virtual to real position

		
module.exports.TrafficSimulation = class TrafficSimulation
	constructor: (playerPosition, @streetGraph, @simulationParameters, @world, @scene, @globalOffset) ->
		@cars = []
		@spawn playerPosition
		@last = 0
	
	step: (deltaT, playerPosition) =>
		@last += deltaT
		# console.log @last
		if @last > 1
			# console.log playerPosition
			# span
			@spawn
				x: playerPosition.y / @simulationParameters.tileSize
				y: playerPosition.x / @simulationParameters.tileSize
			# move
			@move deltaT
			# despawn
			# console.log @cars
			# @despawn
				# x: playerPosition.y / @simulationParameters.tileSize
				# y: playerPosition.x / @simulationParameters.tileSize
			# console.log @cars
			@last = 0
		
	spawn: (playerPosition) =>
		while @cars.length < @simulationParameters.numCars
			nodes = @streetGraph.findNodes(playerPosition, @simulationParameters.minSpawnRadius, @simulationParameters.maxSpawnRadius)
			nodes = nodes.concat @streetGraph.occupiedNodes()
			from = @streetGraph.randomNode nodes
			to = from.randomTo()
			car = new SimulationCar(@world, 0, from, to, to.randomTo(from), @simulationParameters.tileSize)
			car.load()
			@scene.add car.root
			@cars.push car
			
	move: (deltaT) =>
		for car in @cars
			if car.atDestination(@simulationParameters.tileSize)
				car.findNewDestination @streetGraph
			car.calculateControls()
			
	despawn: (playerPosition) =>
		cars = []
		for car in @cars
			if not(car.inRange(playerPosition, @simulationParameters.despawnRadius, @simulationParameters.tileSize))
				@scene.remove car.root
				car.from.occupiedBy = null
			else
				cars.push car
		@cars = cars
		
	updatePhysics: (timeStep) =>
		for car in @cars
			car.updatePhysics timeStep, car.controls
			# console.log car.body.GetPosition()
		return
		
	update: (deltaT) =>
		for car in @cars
			car.update deltaT, car.controls
		return
				