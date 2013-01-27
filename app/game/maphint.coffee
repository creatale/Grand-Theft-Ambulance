module.exports = class MapHint
	hintIndex = 0
	
	constructor: ->
		@root = null

	loadParts: (textureUrl) =>
		texture = THREE.ImageUtils.loadTexture textureUrl
		material = new THREE.SpriteMaterial( { map: texture, useScreenCoordinates: false, color: 0xffffff } )
		@root = new THREE.Sprite material
		
		#material.uvScale.set( 2, 2 )
		@root.scale.set 200, 200, 200
		
	update: (object, playerCar) =>
		objectDir = new THREE.Vector2 object.root.position.x - playerCar.root.position.x, object.root.position.z - playerCar.root.position.z
		if objectDir.length() > 400
			objectDir.normalize()
			@root.position.x = playerCar.root.position.x + objectDir.x * 400
			@root.position.z = playerCar.root.position.z + objectDir.y * 400
		else
			objectDir.normalize()
			@root.position.x = object.root.position.x + -objectDir.x * 250
			@root.position.z = object.root.position.z + -objectDir.y * 250
		
		@root.position.y = (hintIndex++ % 2) * 15
		@root.rotation = Math.atan2(objectDir.x, objectDir.y)
