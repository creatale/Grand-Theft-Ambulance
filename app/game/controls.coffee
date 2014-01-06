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
		@move = new THREE.Vector2()
		@grab = false
		@moveKeys = [false, false, false, false]
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

	keyMove: =>
		# Left/Right
		@move.x = 0
		if @moveKeys[1]
			@move.x += -1
		if @moveKeys[3]
			@move.x += 1
		# Gas/Brake
		@move.y = 0
		if @moveKeys[0]
			@move.y += 1
		if @moveKeys[2]
			@move.y += -1
		return false
		
	keyDown: (event) =>
		switch event.keyCode
			when 37, 65 # Left, A
				@moveKeys[1] = true
			when 39, 68 # Right, D
				@moveKeys[3] = true
			when 38, 87 # Up, W
				@moveKeys[0] = true
			when 40, 83 # Down, S
				@moveKeys[2] = true
			when 32 # Space
				@grab = true
		@keyMove()
		return false

	keyUp: (event) =>
		switch event.keyCode
			when 37, 65 # Left, A
				@moveKeys[1] = false
			when 39, 68 # Right, D
				@moveKeys[3] = false
			when 38, 87 # Up, W
				@moveKeys[0] = false
			when 40, 83 # Down, S
				@moveKeys[2] = false
			when 32  # Space
				@grab = false
		@keyMove()
		return false
	
	touchStart: (event) =>
		event.preventDefault()
		for touch in event.changedTouches
			if not @analogTouch? and touch.pageX >= 3 * window.innerWidth / 5
				@analogTouch = cloneTouch touch
			if not @grabTouch? and touch.pageX < 2 * window.innerWidth / 5
				@grab = true
				@grabTouch = cloneTouch touch
		return false

	touchEnd: (event) =>
		event.preventDefault()
		if @analogTouch? and findTouch(event.changedTouches, @analogTouch.identifier)?
			@analogTouch = null
			@move.x = 0
			@move.y = 0
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
				fingerSize = 25
				stickSize = fingerSize * 3
				dX =  @analogTouch.pageX - touch.pageX
				dY =  @analogTouch.pageY - touch.pageY
				distance = Math.max(Math.sqrt(dX * dX + dY * dY), 1)
				nX = dX / distance
				nY = dY / distance
				if fingerSize < distance
					@move.x = -dX
					@move.y = dY
					@move.setLength(Math.min(distance / stickSize, stickSize))
				else
					@move.x = 0
					@move.y = 0
				# Clear.
				@touchContext.clearRect 0, 0, @touchFrame.width(), @touchFrame.height()
				@touchContext.strokeStyle = '#ff0000'
				@touchContext.lineWidth = 1
				# Draw indicator for analog stick.
				@touchContext.beginPath()
				@touchContext.arc @analogTouch.pageX, @analogTouch.pageY, fingerSize, 0, 2 * Math.PI, true
				@touchContext.stroke()
				@touchContext.beginPath()
				@touchContext.arc @analogTouch.pageX, @analogTouch.pageY, stickSize, 0, 2 * Math.PI, true
				@touchContext.stroke()
				# Draw direction indicator.
				if fingerSize < distance
					@touchContext.beginPath()
					@touchContext.moveTo @analogTouch.pageX - nX * fingerSize, @analogTouch.pageY - nY * fingerSize
					@touchContext.lineTo touch.pageX, touch.pageY
					@touchContext.stroke()
		return false

