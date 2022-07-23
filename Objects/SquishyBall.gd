extends Node2D


# This allows us to create the rigidbodies whenever we need to
export (PackedScene) var PhysicsPoint

# This allows us to create the SPRINGS whenever we need to
export (PackedScene) var PhysicsSpring

# The amount of pixels away from the center each vertex will be
export (int) var radiusInPx         = 100

# The amount of vertices around the circle (3 makes it a triangle, 4 a square, etc.)
export (int) var pointsAroundCircle = 10
var pxBetweenPoints # The amount of pixels between each point (we have to calculate this in _ready()

export (float) var pointRadius = 10

# These will be applied to each spring as they are created
# Damping factor is only really useful if it is set to exactly the same thing as stiffness,
# so I have removed the ability to control that from the node.
export (float) var stiffness = 4
var dampingFactor

export (float) var mass = 1

export (Vector2) var gravity = Vector2(0, 1)

export (bool) var showLines   = true
export (bool) var showPoints  = true
export (bool) var showPolygon = false

# Stores all the points in a 2d array (used in squishy ball, not square one)
var bodyPoints = []

# PRESSURE RELATED STUFF
var p:float # Pressure: Calculated each frame
var V:float # Volume: Calculated each frame
export (float) var n = 100  # Amount of substance: constant (This can be increased by the user to 
const R:float = 8.31446261815324 # Ideal gas constant: constant (obviously)

# The formula to calculate pressure is PV = nRT, but T is temp (we don't care
# about that), and all we actually need is pressure. Thus, we rearrange the
# formula to solve for P: P = nR/V. This makes sense; as the volume increases,
# the pressure within the shape will be lower and lower, and as the amount of
# substance increases, the pressure will go up.


func _ready():
	# The body works the best if they are equal.
	dampingFactor = stiffness
	
	# This will equal the circumference of the circle / the point count.
	pxBetweenPoints = radiusInPx*2 * PI / pointsAroundCircle
	
	if not showPolygon:
		$Shape.hide()
	
	# Create and initiate all the points and springs.
	initiatePoints()
	initiateSprings()

func _process(delta):
	if showPolygon:
		refreshShapeArray()

# Create the correct amount of rigidbodies for all the points,
# and put them in the correct positions
func initiatePoints():
	# How many radians apart each point should be
	var angleApart = 2*PI / pointsAroundCircle
	
	# The first point we create will be at 0°, and from there we will increment
	# this so that each one is further along the shape.
	var angle = 0
	
	for pointIdx in range(0, pointsAroundCircle):
		
		# Calculate the position to put it at around the circle
		var directionVector = Vector2(cos(angle), sin(angle))
		var nodePosition    = directionVector * radiusInPx
		angle += angleApart # Increase the angle that we'll create the next one at
		
		# Initiate a new point in memory
		var newPoint = PhysicsPoint.instance()
		
		# Put the new point where it should be
		newPoint.position = nodePosition
		
		# Scale the point size and marker size appropriately
		newPoint.get_node("Hitbox").shape.radius = pointRadius
		newPoint.get_node("Marker").scale = Vector2(pointRadius/10, pointRadius/10)
		
		# Adjust the color to give the whole squishy body a nice rainbow across it
		newPoint.get_node("Marker").color = Color.from_hsv(pointIdx/pointsAroundCircle, 1, 1)
		
		# All the points need to have the same mass
		newPoint.mass = mass
		
		# All the points need to have the same gravity also
		newPoint.gravityForce = gravity
		
		add_child(newPoint)
		
		# If we are hiding the points, we hide the point.
		if not showPoints:
			newPoint.hide()
		
		# And add it to the array so we can easily remember which are which
		bodyPoints.append(newPoint.get_path())

func initiateSprings():
	# Loop the same amount of times as we have points in the circle
	for i in range(0, pointsAroundCircle):
		
		# If we're on the last point, we want the spring to connect
		# to the last point and the first one, to complete the circle.
		if i == pointsAroundCircle-1:
			createSpring(i, 0, str(i), pxBetweenPoints)
		# In any other case though, we just connect
		# it to the next point in the circle.
		else:
			# Create a spring attached to the current and next points
			createSpring(i, i+1, str(i), pxBetweenPoints)

func createSpring(idx:int, targetIdx:int, springName:String, length:float):
	# Create a new spring and add it as a child
	var spring = PhysicsSpring.instance()
	add_child(spring)
	
	# Connect the spring to this node and the target node, so that it keeps them apart.
	# The only case where targetIdx won't be idx+1 is when we're on the last point,
	# and targetIdx will be 0, to connect the spring back to the first point.
	spring.PointA = bodyPoints[idx]
	spring.PointB = bodyPoints[targetIdx]
	
	# Set the physical properties of the spring
	spring.restLength    = length
	spring.stiffness     = self.stiffness
	spring.dampingFactor = self.dampingFactor
	
	# Mostly for debugging
	spring.springName = springName
	
	# This will not display the lines connecting the points where the springs are.
	spring.hideLine = !showLines
	
	# We're done setting it up, so it can now start processing its physics and whatnot
	spring.doneSetup = true

# Refreshes the Polygon2D that we use to represent the shape of the softbody,
# which uses eldritch array positioning to get the right points and add them to
# the array of positions.
func refreshShapeArray():
	var pointArray:PoolVector2Array
	
	for point in bodyPoints:
		pointArray.append(get_node(point).position)
	
	$Shape.polygon = pointArray
