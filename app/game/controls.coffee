_steeringAngle = THREE.Math.degToRad 45

module.exports = class Controls
	constructor: (@domElement=document) ->

		@viewHalfX = 0
		@viewHalfY = 0
		@moveForward = false
		@moveBackward = false
		@moveLeft = false
		@moveRight = false
		@grab = false
		@domElement.setAttribute "tabindex", -1  if @domElement isnt document

		@domElement.addEventListener "contextmenu", (event) ->
			event.preventDefault()
		, false
		@domElement.addEventListener "keydown", () =>
			@onKeyDown.apply @, arguments
		, false
		@domElement.addEventListener "keyup", () =>
			@onKeyUp.apply @, arguments
		, false
		@handleResize()

	handleResize: =>
		if @domElement is document
			@viewHalfX = window.innerWidth / 2
			@viewHalfY = window.innerHeight / 2
		else
			@viewHalfX = @domElement.offsetWidth / 2
			@viewHalfY = @domElement.offsetHeight / 2

	onKeyDown: (event) =>
		switch event.keyCode
			when 37, 65
				@moveLeft = true
			when 39, 68
				@moveRight = true
			when 38, 87
				@moveForward = true
			when 40, 83
				@moveBackward = true
			when 32
				@grab = true

	onKeyUp: (event) =>
		switch event.keyCode
			when 37, 65
				@moveLeft = false
			when 39, 68
				@moveRight = false
			when 38, 87
				@moveForward = false
			when 40, 83
				@moveBackward = false
			when 32
				@grab = false
			