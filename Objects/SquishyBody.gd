extends Node2D


# This allows us to create the rigidbodies whenever we need to
export (PackedScene) var PhysicsPoint

# This allows us to create the SPRINGS whenever we need to
export (PackedScene) var PhysicsSpring

# The amount of balls sideways and vertically 
export (int) var width  = 10
export (int) var height = 6

# This lets us control the "density" of the points within the shape
export (int) var pxBetweenPoints = 40

export (float) var pointRadius = 10

# These will be applied to each spring as they are created
export (float) var stiffness     = 4
export (float) var dampingFactor = 4

export (float) var mass = 1

# Stores all the points in a 2d array
var bodyPoints = []

var perimeter # The amount of points around the perimeter of the shape

func _ready():
	# Create all the points that can fall and stuff for physics
	initiatePoints()
	initiateSprings()
	
	# This is the length of the perimeter of the shape, in points.
	# It counts two sides, and then so as to not count the corner points twice, 
	# subtracts two from the other two sides.
	perimeter = (width * 2) + ((width-2) * 2)

#func _process(delta):
#	updateShape()

# Create the correct amount of rigidbodies for all the points,
# and put them in the correct positions
func initiatePoints():
	for y in height:
		bodyPoints.append([]) # Add another layer
		
		for x in width:
			# Initiate a new one in memory
			var newPoint = PhysicsPoint.instance()
			
			# Put the new point where it should be
			newPoint.position = Vector2(x*pxBetweenPoints, y*pxBetweenPoints)
			
			# Scale the point size and marker size appropriately
			newPoint.get_node("Hitbox").shape.radius = pointRadius
			newPoint.get_node("Marker").scale = Vector2(pointRadius/10, pointRadius/10)
			
			# Adjust the color to give the whole squishy body a nice rainbow across it
			newPoint.get_node("Marker").color = Color.from_hsv((x + y) / (float(width) + float(height)), 1, 1)
			
			# These all need to be the same
			newPoint.mass = mass
			
			add_child(newPoint)
			
			# And add it to the array so we can easily remember which are which
			bodyPoints[y].append(newPoint.get_path())

func initiateSprings():
	# Thank you Pythagoras
	var diagPxBetweenPoints = sqrt((pxBetweenPoints * pxBetweenPoints) + (pxBetweenPoints * pxBetweenPoints))
	
	for y in height:
		for x in width:
			var currentPoint = bodyPoints[y][x]
		
			# These if statements only allow the springs to be created
			# that will fit in the body, for example it will only create a spring
			# that connects to a point on the right IF there is actually a point
			# on the right
			if x < width-1:
				# Only create this one if there's space on the right
				createSpring(x, y, x+1, y, "x ", pxBetweenPoints)
				
				if y > 0:
					# Only create this one if there's space on the right AND upward
					createSpring(x, y, x+1, y-1, "du", diagPxBetweenPoints)
			
			if y < height-1:
				# Only create this one if there's space downward
				createSpring(x, y, x, y+1, "y ", pxBetweenPoints)
				
				# Only create this one if there's space downward AND to the right
				if x < width-1:
					createSpring(x, y, x+1, y+1, "dd", diagPxBetweenPoints)

func createSpring(x:int, y:int, targetX:int, targetY:int, springName:String, length:float):
	
	# Create a new spring and add it as a child
	var spring = PhysicsSpring.instance()
	add_child(spring)
	
	# Connect the spring to this node and the target node, so that it keeps them apart.
	spring.PointA = bodyPoints[y][x]
	spring.PointB = bodyPoints[targetY][targetX]
	
	# Set the physical properties of the spring
	spring.restLength    = length
	spring.stiffness     = self.stiffness
	spring.dampingFactor = self.dampingFactor
	
	spring.springName = springName + "("+str(x)+","+str(y)+")" # Will look like "dd(3,6)".
	
	# We're done setting it up, so it can now start processing its physics and whatnot
	spring.doneSetup = true
