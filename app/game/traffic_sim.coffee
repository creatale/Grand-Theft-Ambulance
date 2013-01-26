class Node:
	constructor: (@x, @y) ->
		@fromEdges = []
		@toEdges = []
		@occupiedBy = null
	
	distanceTo: (position) =>
		return Math.sqrt(Math.pow(@x - position.x, 2) + Math.pow(@y - position.y, 2))
		
	randomTo: =>
		if @toEdges.length > 1
			return toEdges[Math.floor(Math.random() * toEdges.length)].to
		else
			# TODO: will die if no toEdge is present
			return toEdges[0].to
	
class Edge:
	constructor: (@from, @to) ->

class StreetGraph
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
			if not exclude.contains node
				nodes.push node
		if nodes.length > 1
			return nodes[Math.floor(Math.random() * nodes.length)]
		else if nodes.length > 0
			return nodes[0]
		else
			return @nodes[Math.floor(Math.random() * @nodes.length)]
	
class SimulationParameters
	constructor: (@spawnRadius, @numCars) ->
	
class SimulationCar
	constructor: (@type, @from, @to, @nextNode, @tileSize) ->
	
	inRange: (playerPosition, maxDistance) =>
		return true
		
	move: (deltaT) =>
		# break if @nextNode is occupied and ||nextNode.car.velocity|| < ||@velocity||
		# break completely if crossing is occupied
		# if @nextNode.occupiedBy?
			
		return
		
	atDestination: =>
		return @to.distanceTo({x: 0, y: 0}) < @tileSize
		
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

		
class TrafficSimulation
	constructor: (playerPosition, @streetGraph, @simulationParameters) ->
		@cars = []
		spawn playerPosition
		@oldPlayerPostion = playerPosition
	
	step: (deltaT, playerPosition) =>
		# span
		@spawn playerPosition
		# move
		@move deltaT
		# despawn
		@despawn playerPosition
		
	spawn: (playerPosition) =>
		while @cars.length < @simulationParameters.numCars
			nodes = @streetGraph.findNodes playerPosition, @simulationParameters.spawnRadius
			from = @streetGraph.randomNode nodes
			to = from.randomTo()
			@cars.push new Car 0, from, to, to.randomTo()
			
	move: (deltaT) =>
		for car in @cars
			car.move deltaT
			if car.atDestination()
				car.findNewDestination @streetGraph
			
	despawn: (playerPosition) =>
		for car, index in @cars
			if not car.inRange(playerPosition, @simulationParameters.spawnRadius)
				@cars.splice(index, 1)