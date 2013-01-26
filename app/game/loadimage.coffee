module.exports = (url, cb) ->
	img = document.createElement('img')
	img.src = url
	img.onload = () ->
		console.log img
		canvas = document.createElement('canvas')
		canvas.width = img.width
		canvas.height = img.height
		ctx = canvas.getContext('2d')
		ctx.drawImage(img, 0, 0)
		cb ctx.getImageData(0, 0, img.width, img.height)