module.exports = class Controls
	constructor: (@camera, @player, @domElement=document) ->
		@player.add camera
		@target = new THREE.Vector3(0, 0, 0)
		@movementSpeed = 1.0
		@lookSpeed = 0.005
		@lookVertical = true
		@autoForward = false
		@activeLook = true
		@heightSpeed = false
		@heightCoef = 1.0
		@heightMin = 0.0
		@heightMax = 1.0
		@constrainVertical = false
		@verticalMin = 0
		@verticalMax = Math.PI
		@autoSpeedFactor = 0.0
		@lat = 0
		@lon = 0
		@phi = 0
		@theta = 0
		@moveForward = false
		@moveBackward = false
		@moveLeft = false
		@moveRight = false
		@freeze = false
		@viewHalfX = 0
		@viewHalfY = 0
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
				@moveUp = true
			when 40, 83
				@moveDown = true
			when 81
				@freeze = not @freeze

	onKeyUp: (event) =>
		switch event.keyCode
			when 37, 65
				@moveLeft = false
			when 39, 68
				@moveRight = false
			when 38, 87
				@moveUp = false
			when 40, 83
				@moveDown = false

	update: (delta) =>
		return if @freeze
		if @heightSpeed
			y = THREE.Math.clamp(@player.position.y, @heightMin, @heightMax)
			heightDelta = y - @heightMin
			@autoSpeedFactor = delta * (heightDelta * @heightCoef)
		else
			@autoSpeedFactor = 0.0
		actualMoveSpeed = delta * @movementSpeed
		@player.translateX -(actualMoveSpeed + @autoSpeedFactor)  if @moveForward or (@autoForward and not @moveBackward)
		@player.translateX actualMoveSpeed  if @moveBackward
		@player.translateZ actualMoveSpeed  if @moveLeft
		@player.translateZ -actualMoveSpeed  if @moveRight
		@player.translateX -actualMoveSpeed  if @moveUp
		@player.translateX actualMoveSpeed  if @moveDown
		actualLookSpeed = delta * @lookSpeed
		actualLookSpeed = 0  unless @activeLook
		verticalLookRatio = 1
		verticalLookRatio = Math.PI / (@verticalMax - @verticalMin)  if @constrainVertical
		@lon += @mouseX * actualLookSpeed
		@lat -= @mouseY * actualLookSpeed * verticalLookRatio  if @lookVertical
		@lat = Math.max(-85, Math.min(85, @lat))
		@phi = THREE.Math.degToRad(90 - @lat)
		@theta = THREE.Math.degToRad(@lon)
		@phi = THREE.Math.mapLinear(@phi, 0, Math.PI, @verticalMin, @verticalMax)  if @constrainVertical
		targetPosition = @target
		position = @player.position
		targetPosition.x = position.x + 100 * Math.sin(@phi) * Math.cos(@theta)
		targetPosition.y = position.y + 100 * Math.cos(@phi)
		targetPosition.z = position.z + 100 * Math.sin(@phi) * Math.sin(@theta)