Car = require './car'

class Node
	constructor: (@x, @y, @type, @children = []) ->
		@fromEdges = []
		@toEdges = []
		@occupiedBy = null
	
	distanceTo: (position) =>
		return Math.sqrt(Math.pow(@x - position.x, 2) + Math.pow(@y - position.y, 2))
		
	randomTo: =>
		if @toEdges.length > 1
			return @toEdges[Math.floor(Math.random() * toEdges.length)].to
		else
			# TODO: will die if no toEdge is present
			return @toEdges[0].to
			
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
	
	findNodes: (position, radius) =>
		result = []
		for node in @nodes
			if node.distanceTo(position) < radius
				result.push node
		return result
	
	randomNode: (exclude) =>
		nodes = []
		for node in @nodes
			if not (node in exclude)
				nodes.push node
		if nodes.length > 1
			return nodes[Math.floor(Math.random() * nodes.length)]
		else if nodes.length > 0
			return nodes[0]
		else
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
	constructor: (@spawnRadius, @numCars, @tileSize, @despawnRadius) ->
	
class SimulationCar extends Car
	constructor: (@type, @from, @to, @nextNode, @tileSize) ->
		super
		@position =
			x: @from.x
			y: @from.y
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

	# loadPartsJSON: (bodyURL) =>
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

	inRange: (playerPosition, maxDistance) =>
		return Math.sqrt(Math.pow(playerPosition.x - @position.x, 2) + Math.pow(playerPosition.y - @position.y, 2)) < maxDistance
		
	move: (deltaT, globalOffset) =>
		# break if @nextNode is occupied and ||nextNode.car.velocity|| < ||@velocity||
		# break completely if crossing is occupied
		# if @nextNode.occupiedBy?
		speed = 0
		switch @type
			when 0
				speed = 0.05
		direction =
			x: (@to.x - @position.x)
			y: (@to.y - @position.y)
		# console.log direction
		length = Math.sqrt(Math.pow(direction.x, 2) + Math.pow(direction.y, 2))
		@position =
			x: (@position.x + direction.x * speed / length)
			y: (@position.y + direction.y * speed / length)
		# console.log @root.position
		@root.position.x = @position.x * @tileSize - globalOffset.x
		@root.position.z = @position.y * @tileSize - globalOffset.y
		# console.log @root.position
		return
		
	atDestination: =>
		# console.log @to.distanceTo(@position)
		return @to.distanceTo(@position) < 1 # @tileSize
		# return false
		
	findNewDestination: =>
		@from.occupiedBy = null
		@to.occupiedBy = @
		@from = @to
		@to = @nextNode
		@nextNode = @nextNode.randomTo()

#
# drive
# random turns at crossings
# avoid collision
# - look ahead, break if car
# - waiting at crossing: at max one car per crossing
# - max capacity per street piece
# map virtual to real position

		
module.exports.TrafficSimulation = class TrafficSimulation
	constructor: (playerPosition, @streetGraph, @simulationParameters, @scene, @globalOffset) ->
		@cars = []
		@spawn playerPosition
		@oldPlayerPostion = playerPosition
	
	step: (deltaT, playerPosition) =>
		# console.log playerPosition
		# span
		@spawn
			x: playerPosition.x / @simulationParameters.tileSize
			y: playerPosition.y / @simulationParameters.tileSize
		# move
		@move deltaT
		# despawn
		@despawn
			x: playerPosition.x / @simulationParameters.tileSize
			y: playerPosition.y / @simulationParameters.tileSize
		# console.log @cars
		
	spawn: (playerPosition) =>
		while @cars.length < @simulationParameters.numCars
			nodes = @streetGraph.findNodes(playerPosition, @simulationParameters.spawnRadius)
			from = @streetGraph.randomNode nodes
			to = from.randomTo()
			car = new SimulationCar(0, from, to, to.randomTo(), @simulationParameters.tileSize)
			car.loadPartsJSON 'textures/Male02_dds.js', 'textures/Male02_dds.js'
			@scene.add car.root
			@cars.push car
			
	move: (deltaT) =>
		for car in @cars
			car.move deltaT, @globalOffset
			if car.atDestination()
				# console.log 'tada'
				car.findNewDestination @streetGraph
			# console.log car.position.x, car.position.y
			
	despawn: (playerPosition) =>
		index = 0
		while index < @cars.length
			car = @cars[index]
			if not(car.inRange(playerPosition, @simulationParameters.despawnRadius))
				@scene.remove car.root
				@cars.splice(index, 1)
			else
				index++
				