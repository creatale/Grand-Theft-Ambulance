module.exports = class VictimHint
	constructor: ->
		@root = null

	loadParts: () =>
		texture = THREE.ImageUtils.loadTexture "textures/victim_hint.png"
		material = new THREE.SpriteMaterial( { map: texture, useScreenCoordinates: false, color: 0xffffff } )
		@root = new THREE.Sprite material
		
		#material.uvScale.set( 2, 2 )
		@root.scale.set 200, 200, 200
		
	update: (victim, playerCar) =>
		victimDir = new THREE.Vector2 victim.root.position.x - playerCar.root.position.x, victim.root.position.z - playerCar.root.position.z
		if victimDir.length() > 500
			victimDir.normalize()
			@root.position.x = playerCar.root.position.x + victimDir.x * 500
			@root.position.z = playerCar.root.position.z + victimDir.y * 500
		else
			victimDir.normalize()
			@root.position.x = victim.root.position.x + -victimDir.x * 250
			@root.position.z = victim.root.position.z + -victimDir.y * 250
		
		@root.position.y = 15
		@root.rotation = Math.atan2(victimDir.x, victimDir.y)
