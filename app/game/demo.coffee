fogExp2 = true
container = undefined
stats = undefined
camera = undefined
controls = undefined
scene = undefined
renderer = undefined
mesh = undefined
mat = undefined
worldWidth = 200
worldDepth = 50
worldHalfWidth = worldWidth / 2
worldHalfDepth = worldDepth / 2

init = ->
  container = document.getElementById("container")
  camera = new THREE.PerspectiveCamera(50, window.innerWidth / window.innerHeight, 1, 20000)
  camera.position.y = getY(worldHalfWidth, worldHalfDepth) * 100 + 100
  controls = new THREE.FirstPersonControls(camera)
  controls.movementSpeed = 1000
  controls.lookSpeed = 0.125
  controls.lookVertical = true
  controls.constrainVertical = true
  controls.verticalMin = 1.1
  controls.verticalMax = 2.2
  scene = new THREE.Scene()
  scene.fog = new THREE.FogExp2(0xffffff, 0) # 0.00015 );
  
  # sides
  light = new THREE.Color(0xeeeeee)
  shadow = new THREE.Color(0x505050)
  
  # sides
  matrix = new THREE.Matrix4()
  pxGeometry = new THREE.SphereGeometry(150, 8, 4)
  
  #
  geometry = new THREE.Geometry()
  dummy = new THREE.Mesh()
  z = 0

  while z < worldDepth
    x = 0

    while x < worldWidth
      h = getY(x, z)
      dummy.position.x = x * 100 + Math.random() * 50 - worldHalfWidth * 100
      dummy.position.y = h * 100 + Math.random() * 50
      dummy.position.z = z * 100 + Math.random() * 50 - worldHalfDepth * 100
      px = getY(x + 1, z)
      nx = getY(x - 1, z)
      pz = getY(x, z + 1)
      nz = getY(x, z - 1)
      dummy.geometry = pxGeometry
      THREE.GeometryUtils.merge geometry, dummy
      x++
    z++
  textureGrass = THREE.ImageUtils.loadTexture("textures/minecraft/grass.png")
  textureGrass.magFilter = THREE.NearestFilter
  textureGrass.minFilter = THREE.LinearMipMapLinearFilter
  textureGrassDirt = THREE.ImageUtils.loadTexture("textures/minecraft/grass_dirt.png")
  textureGrassDirt.magFilter = THREE.NearestFilter
  textureGrassDirt.minFilter = THREE.LinearMipMapLinearFilter
  material1 = new THREE.MeshLambertMaterial(
    map: textureGrass
    ambient: 0xbbbbbb
    vertexColors: THREE.VertexColors
  )
  material2 = new THREE.MeshLambertMaterial(
    map: textureGrassDirt
    ambient: 0xbbbbbb
    vertexColors: THREE.VertexColors
  )
  mesh = new THREE.Mesh(geometry, new THREE.MeshFaceMaterial([material1, material2]))
  scene.add mesh
  ambientLight = new THREE.AmbientLight(0xcccccc)
  scene.add ambientLight
  directionalLight = new THREE.DirectionalLight(0xffffff, 0.5)
  directionalLight.position.set(1, 1, 0.5).normalize()
  scene.add directionalLight
  renderer = new THREE.WebGLRenderer(clearColor: 0xffffff)
  renderer.setSize window.innerWidth, window.innerHeight
  container.innerHTML = ""
  container.appendChild renderer.domElement
  stats = new Stats()
  stats.domElement.style.position = "absolute"
  stats.domElement.style.top = "0px"
  container.appendChild stats.domElement
  
  #
  window.addEventListener "resize", onWindowResize, false
onWindowResize = ->
  camera.aspect = window.innerWidth / window.innerHeight
  camera.updateProjectionMatrix()
  renderer.setSize window.innerWidth, window.innerHeight
  controls.handleResize()
loadTexture = (path, callback) ->
  image = new Image()
  image.onload = ->
    callback()

  image.src = path
  image
generateHeight = (width, height) ->
  data = []
  perlin = new ImprovedNoise()
  size = width * height
  quality = 2
  z = Math.random() * 100
  j = 0

  while j < 4
    if j is 0
      i = 0

      while i < size
        data[i] = 0
        i++
    i = 0

    while i < size
      x = i % width
      y = (i / width) | 0
      data[i] += perlin.noise(x / quality, y / quality, z) * quality
      i++
    quality *= 4
    j++
  data
getY = (x, z) ->
  (data[x + z * worldWidth] * 0.2) | 0

#
animate = ->
  requestAnimationFrame animate
  render()
  stats.update()
render = ->
  controls.update clock.getDelta()
  renderer.render scene, camera
unless Detector.webgl
  Detector.addGetWebGLMessage()
  document.getElementById("container").innerHTML = ""
  
data = generateHeight(worldWidth, worldDepth)
clock = new THREE.Clock()
init()
animate()
