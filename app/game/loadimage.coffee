module.exports = (url, cb) ->
	canvas = document.createElement 'canvas'
	context = canvas.getContext '2d'
	image = document.createElement 'img'
	image.src = url
	image.onload = ->
		canvas.width = image.width
		canvas.height = image.height
		context.drawImage image, 0, 0
		cb context.getImageData(0, 0, canvas.width, canvas.height)
	image.onerror = ->
		canvas.width = 32
		canvas.height = 32
		context.font = '12px monospace'
		context.fillStyle = '#f00'
		context.fillText 'ERROR', 0, 8
		cb context.getImageData(0, 0, canvas.width, canvas.height)
		