extends Node2D


# This allows us to create the rigidbodies whenever we need to
export (PackedScene) var PhysicsPoint

# This allows us to create the SPRINGS whenever we need to
export (PackedScene) var PhysicsSpring

# The amount of balls sideways and vertically 
export (int, 1, 100) var pointsHoriz  = 6
export (int, 1, 100) var pointsVert = 10

export (int) var sizeInPx = 300

# This is set in _ready(), and is calculated by dividing the total size of the shape by 
# how many points there are across it.
var pxBetweenPoints:float

export (float) var pointRadius = 10

# These will be applied to each spring as they are created
# Damping factor is only really useful if it is set to exactly the same thing as stiffness,
# so I have removed the ability to control that from the node.
export (float, 0, 15) var stiffness = 8
var dampingFactor

# If plasticity is 1, it will competely deform to any squishing that happens, and
# stay there without reforming.
# The lower it is, the less it will conform, and the more it will bounce back.
export (float, 0, 0.1) var plasticity = 0

export (float) var mass = 1

export (Vector2) var gravity = Vector2(0, 3)

export (bool) var showLines   = true
export (bool) var showPoints  = false
export (bool) var showPolygon = false
export (bool) var showOutline = true

# Stores all the points in a 2d array (Currently unused I think)
var bodyPoints = []

func _ready():
	# The body works the best if they are equal.
	dampingFactor = stiffness
	
	pxBetweenPoints = sizeInPx/pointsHoriz
	
	if not showPolygon:
		$Shape.hide()
	
	# Create and initiate all the points and springs.
	initiatePoints()
	initiateSprings()

# warning-ignore:unused_argument
func _physics_process(delta):
	if showPolygon:
		$Shape.polygon = getOutlineArray()
	
	if showOutline:
		$Outline.points = getOutlineArray()


# Create the correct amount of rigidbodies for all the points,
# and put them in the correct positions
func initiatePoints():
	for y in pointsVert:
		bodyPoints.append([]) # Add another layer
		
		for x in pointsHoriz:
			# Initiate a new one in memory
			var newPoint = PhysicsPoint.instance()
			
			# Put the new point where it should be
			newPoint.position = Vector2(x*pxBetweenPoints, y*pxBetweenPoints)
			
			# Scale the point size and marker size appropriately
			newPoint.get_node("Hitbox").shape.radius = pointRadius
			newPoint.get_node("Marker").scale = Vector2(pointRadius/10, pointRadius/10)
			
			# Adjust the color to give the whole squishy body a nice rainbow across it
			newPoint.get_node("Marker").color = Color.from_hsv((x + y) / (float(pointsHoriz) + float(pointsVert)), 1, 1)
			
			# All the points need to have the same mass
			newPoint.mass = mass
			
			# All the points need to have the same gravity also
			newPoint.gravityForce = gravity
			
			add_child(newPoint)
			
			# If we are hiding the points, we hide the point.
			if not showPoints:
				newPoint.hide()
			
			# And add it to the array so we can easily remember which are which
			bodyPoints[y].append(newPoint.get_path())

func initiateSprings():
	# Thank you Pythagoras
	var diagPxBetweenPoints = sqrt((pxBetweenPoints * pxBetweenPoints) + (pxBetweenPoints * pxBetweenPoints))
	
	for y in pointsVert:
		for x in pointsHoriz:
			# These if statements only allow the springs to be created
			# that will fit in the body, for example it will only create a spring
			# that connects to a point on the right IF there is actually a point
			# on the right
			if x < pointsHoriz-1:
				# Only create this one if there's space on the right
				createSpring(x, y, x+1, y, "x ", pxBetweenPoints)
				
				if y > 0:
					# Only create this one if there's space on the right AND upward
					createSpring(x, y, x+1, y-1, "du", diagPxBetweenPoints)
			
			if y < pointsVert-1:
				# Only create this one if there's space downward
				createSpring(x, y, x, y+1, "y ", pxBetweenPoints)
				
				# Only create this one if there's space downward AND to the right
				if x < pointsHoriz-1:
					createSpring(x, y, x+1, y+1, "dd", diagPxBetweenPoints)

func createSpring(x:int, y:int, targetX:int, targetY:int, springName:String, length:float):
	# Create a new spring and add it as a child
	var spring = PhysicsSpring.instance()
	add_child(spring)
	
	# Connect the spring to this node and the target node, so that it keeps them apart.
	spring.PointA = bodyPoints[y][x]
	spring.PointB = bodyPoints[targetY][targetX]
	
	# Set the physical properties of the spring
	spring.restLength     = length
	spring.stiffness      = stiffness
	spring.dampingFactor  = dampingFactor
	spring.plasticity     = plasticity
	
	spring.springName = springName + "("+str(x)+","+str(y)+")" # Will look like "dd(3,6)".
	
	# This will not display the lines connecting the points where the springs are.
	spring.hideLine = !showLines
	
	# We're done setting it up, so it can now start processing its physics and whatnot
	spring.doneSetup = true

# Refreshes the Polygon2D or Line2D that we use to represent the shape of the softbody,
# which uses eldritch array positioning to get the right points and add them to
# the array of positions.
func getOutlineArray():
	var pointArray:PoolVector2Array = []
	var colorArray:PoolColorArray   = []
	
	var currentNode:RigidBody2D
	
	for i in range(0, pointsHoriz):
		currentNode = get_node(bodyPoints[0][i])
		pointArray.append(currentNode.position)
		colorArray.append(markerColor(currentNode))
	
	for i in range(0, pointsVert-2):
		currentNode = get_node(bodyPoints[i+1][pointsHoriz-1])
		pointArray.append(currentNode.position)
		colorArray.append(markerColor(currentNode))
	
	var backwards = []
	for i in range(0, pointsHoriz):
		backwards.insert(0, i)
	
	for i in backwards:
		currentNode = get_node(bodyPoints[pointsVert-1][i])
		pointArray.append(currentNode.position)
		colorArray.append(markerColor(currentNode))
	
	var cornerlessBackwards = []
	for i in range(1, pointsVert-1):
		cornerlessBackwards.insert(0, i)
	
	for i in cornerlessBackwards:
		currentNode = get_node(bodyPoints[i][0])
		pointArray.append(currentNode.position)
		colorArray.append(markerColor(currentNode))
	
	# Append the top right point again, to connect the outline back to itself.
	# This will fix the outline, and will have no effect on the Polygon2D.
	pointArray.append(get_node(bodyPoints[0][0]).position)
	
	return(pointArray)

func markerColor(node:RigidBody2D):
	return node.get_node("Marker").color
