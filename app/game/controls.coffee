findTouch = (touchList, identifier) ->
	for touch in touchList
		if touch.identifier is identifier
			return touch
	return null

cloneTouch = (touch) ->
	return {
		identifier: touch.identifier
		pageX: touch.pageX
		pageY: touch.pageY
	}

module.exports = class Controls
	constructor: (@domElement=document) ->
		@moveForward = false
		@moveBackward = false
		@moveLeft = false
		@moveRight = false
		@grab = false
		@analogTouch = null
		@grabTouch = null

		@domElement.setAttribute 'tabindex', -1	if @domElement isnt document
		@domElement.addEventListener 'keydown', @keyDown, false
		@domElement.addEventListener 'keyup', @keyUp, false
		@domElement.addEventListener 'touchstart', @touchStart, false
		@domElement.addEventListener 'touchend', @touchEnd, false
		@domElement.addEventListener 'touchleave', @touchEnd, false
		@domElement.addEventListener 'touchcancel', @touchEnd, false
		@domElement.addEventListener 'touchmove', @touchMove, false

		@touchFrame = $('#touch-frame')
		@touchContext = @touchFrame[0].getContext('2d')

	keyDown: (event) =>
		switch event.keyCode
			when 37, 65 # Left, A
				@moveLeft = true
			when 39, 68 # Right, D
				@moveRight = true
			when 38, 87 # Up, W
				@moveForward = true
			when 40, 83 # Down, S
				@moveBackward = true
			when 32 # Space
				@grab = true
		return false

	keyUp: (event) =>
		switch event.keyCode
			when 37, 65 # Left, A
				@moveLeft = false
			when 39, 68 # Right, D
				@moveRight = false
			when 38, 87 # Up, W
				@moveForward = false
			when 40, 83 # Down, S
				@moveBackward = false
			when 32  # Space
				@grab = false
		return false
	
	touchStart: (event) =>
		event.preventDefault()
		for touch in event.changedTouches
			if not @analogTouch? and touch.pageX >= window.innerWidth / 2
				@analogTouch = cloneTouch touch
			if not @grabTouch? and touch.pageX < window.innerWidth / 2
				@grab = true
				@grabTouch = cloneTouch touch
		return false

	touchEnd: (event) =>
		event.preventDefault()
		if @analogTouch? and findTouch(event.changedTouches, @analogTouch.identifier)?
			@analogTouch = null
			@moveLeft = false
			@moveRight = false
			@moveForward = false
			@moveBackward = false
		if @grabTouch? and findTouch(event.changedTouches, @grabTouch.identifier)?
			@grab = false
			@grabTouch = null
		@touchContext.clearRect 0, 0, @touchFrame.width(), @touchFrame.height()
		return false

	touchMove: (event) =>
		event.preventDefault()
		if @analogTouch
			touch = findTouch event.changedTouches, @analogTouch.identifier
			if touch?
				dX =  @analogTouch.pageX - touch.pageX
				dY =  @analogTouch.pageY - touch.pageY
				angle = Math.atan2 dY, dX
				distance = Math.sqrt dX * dX + dY * dY
				# Forward on the upper part of the circle.
				if angle > 0 and distance > 20
					@moveForward = true
					@moveBackward = false
				# Backward on the lower part of the circle.
				else if angle < 0 and distance > 20
					@moveForward = false
					@moveBackward = true
				else
					@moveForward = false
					@moveBackward = false
				# Right on the right sector of the circle.
				if Math.abs(angle) > (2 * Math.PI / 3) and distance > 60
					@moveRight = true
				else
					@moveRight = false
				# Left on the left sector of the circle.
				if Math.abs(angle) < (Math.PI / 3) and distance > 60
					@moveLeft = true
				else
					@moveLeft = false
				# Draw indicator for analog stick.
				@touchContext.clearRect 0, 0, @touchFrame.width(), @touchFrame.height()
				@touchContext.beginPath()
				@touchContext.moveTo @analogTouch.pageX, @analogTouch.pageY
				@touchContext.lineTo touch.pageX, touch.pageY
				@touchContext.strokeStyle = '#ff0000'
				@touchContext.lineWidth = 2
				@touchContext.stroke()
		return false

