extends Node2D

# P = NRT / V, F = P * A // 3D
# P = NRT / A, F = P * L // 2D

# This allows us to create the rigidbodies whenever we need to
export (PackedScene) var PhysicsPoint

# This allows us to create the SPRINGS whenever we need to
export (PackedScene) var PhysicsSpring

# The amount of pixels away from the center each vertex will be
export (int) var radiusInPx = 100

# The amount of vertices around the circle (3 makes it a triangle, 4 a square, etc.)
export (int, 3, 100) var pointsAroundCircle = 10
var pxBetweenPoints # The amount of pixels between each point (we have to calculate this in _ready()

export (float) var pointRadius = 10

# These will be applied to each spring as they are created
# Damping factor is only really useful if it is set to exactly the same thing as stiffness,
# so I have removed the ability to control that from the node.
export (float, 0, 15) var stiffness = 10
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

var n # Amount of substance within the ball: constant (calculated in _ready()
const R:float = 8.31446261815324 # Ideal gas constant: constant (obviously)

# The pressure is literally just multiplied by this during the calculation
export (float) var pressureFactor = 1

# The formula to calculate pressure is PV = nRT, but T is temp (we don't care
# about that), and all we actually need is pressure. Thus, we rearrange the
# formula to solve for P: P = nR/V. This makes sense; as the volume increases,
# the pressure within the shape will be lower and lower, and as the amount of
# substance increases, the pressure will go up.


func _ready():
	# The ball works best if it's a little more dampened (since there are only 
	# 2 springs on each point)
	dampingFactor = stiffness * 1.5
	
	# n is the area of the shape in pixels
	n = radiusInPx * 10000
	
	# This will equal the circumference of the circle / the point count.
	pxBetweenPoints = radiusInPx*2 * PI / pointsAroundCircle
	
	if not showPolygon:
		$Shape.hide()
	
	# Create and initiate all the points and springs.
	initiatePoints()
	initiateSprings()

func _physics_process(delta):
	if showPolygon:
		refreshShapeArray()
	
	# Calculate the area (volume) of the shape this frame
	V = calculateArea()
	
	# Calculate the pressure using a simplified version of the Ideal Gas Law:
	# https://en.wikipedia.org/wiki/Ideal_gas_law
	p = n*R/V

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
		# We have to multiply it by 1.0 to prevent it from rounding to 0 no matter what -_-
		newPoint.get_node("Marker").color = Color.from_hsv((pointIdx*1.0)/(pointsAroundCircle *1.0), 1, 1)
		
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
		# to the last point and the first one, to complete the circle. (2nd argument)
		if i == pointsAroundCircle-1:
			# Create a spring attached to the current and FIRST points
			createSpring(i, 0, str(i), pxBetweenPoints)
		# In any other case though, we just connect
		# it to the next point in the circle. (2nd argument)
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
	spring.pressureFactor = pressureFactor
	
	# This is the squishy ball, so the spring has to adjust the forces according to that
	spring.isBall = true
	
	# Mostly for debugging
	spring.springName = springName
	
	# This will not display the lines connecting the points where the springs are.
	spring.hideLine = !showLines
	
	# We're done setting it up, so it can now start processing its physics and whatnot
	spring.doneSetup = true

func calculateArea():
	# The running total of all our calculations
	var total = 0
	
	# The index of the first and second points
	var p1
	var p2
	
	# For every point in the body
	for i in range(0, pointsAroundCircle):
		# We get the index of point 1 and point 2
		p1 = i
		p2 = p1 + 1
		
		# If p1 is the LAST point, the index of the second point should be 0
		# This reconnects the polygon at the end
		if p1 == pointsAroundCircle-1:
			p2 = 0
		
		# Get the x and y positions of the points in question
		var x1 = get_node(bodyPoints[p1]).position.x
		var y1 = get_node(bodyPoints[p1]).position.y
		
		var x2 = get_node(bodyPoints[p2]).position.x
		var y2 = get_node(bodyPoints[p2]).position.y
		
		var result = x1*y2 - y1*x2
		
		total += result
	
	# Divide the absolute value of the total by 2, and we have our area.
	total = abs(total/2)
	
	return total

# Refreshes the Polygon2D that we use to represent the shape of the softbody.
# This simply iterates through each point and adds it to the polygon in order.
# Very convenient to have that bodyPoints[] array.
func refreshShapeArray():
	var pointArray:PoolVector2Array
	
	for point in bodyPoints:
		pointArray.append(get_node(point).position)
	
	$Shape.polygon = pointArray
