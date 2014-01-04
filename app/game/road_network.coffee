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

module.exports = class Graph
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
		return new Graph nodes, edges
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
