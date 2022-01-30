extends Node2D


# This allows us to create the rigidbodies whenever we need to
export (PackedScene) var PhysicsPoint

# This allows us to create the SPRINGS whenever we need to
export (PackedScene) var PhysicsSpring

# The amount of balls sideways and vertically 
export (int) var width  = 10
export (int) var height = 10

# This lets us control the "density" of the points
export (int) var pxBetweenPoints = 20

export (float) var pointRadius = 10

# Stores all the points in a 2d array
var bodyPoints = []

func _ready():
	# Create all the points that can fall and stuff for physics
	initiatePoints()
	initiateSprings()

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
			
			add_child(newPoint)
			
			# And add it to the array so we can easily remember which are which
			bodyPoints[y].append(newPoint.get_path())

func initiateSprings():
	var diagPxBetweenPoints = sqrt((pxBetweenPoints * pxBetweenPoints) + (pxBetweenPoints * pxBetweenPoints))
	
	for y in height:
		for x in width:
			var currentPoint = bodyPoints[y][x]
		
			# These if statements only allow the springs to be created
			# that will fit in the world, for example it will only create a spring
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
	var spring = PhysicsSpring.instance()
	spring.PointA = bodyPoints[y][x]
	spring.PointB = bodyPoints[targetY][targetX]
	spring.restLength = length
	spring.springName = springName + "("+str(x)+","+str(y)+")"
	add_child(spring)
	print("added " + springName)
	
