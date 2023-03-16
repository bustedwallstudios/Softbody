extends Node2D

# This allows us to create the rigidbodies whenever we need to
@export var PhysicsPoint:PackedScene

# This allows us to create the SPRINGS whenever we need to
@export var PhysicsSpring:PackedScene

# The amount of balls sideways and vertically
@export_range(2, 100) var pointsHorz:int = 6
@export_range(2, 100) var pointsVert:int = 10

@export var distanceApart:int = 300
var sizeInPx:int

# This is set in _ready(), and is calculated by dividing the total size of the shape by 
# how many points there are across it.
var orthogSpringLength:float

@export var pointRadius:int = 10

# These will be applied to each spring as they are created
# Damping factor is only really useful if it is set to exactly the same thing as stiffness,
# so I have removed the ability to control that from the node.
@export_range(0, 15) var stiffness:float = 8
# The body works the best if dampingFactor = stiffness (if it's not it explodes basically instantly)
@onready var dampingFactor = stiffness

# If plasticity is 1, it will competely deform to any squishing that happens.
# The lower it is, the less it will conform, and the more it will bounce back.
@export_range(0, 0.2) var plasticity:float = 0

# This will gradually return the rest length of the spring to the original length,
# if it is decreased by the plasticity of the object (think memory foam pillow).
@export_range(0, 1, 0.01) var memory: float

@export var edgeBulges:float = 0

# I removed the ability to control this because having it much higher or lower than one results
# in undesirable behavior
var mass = 1

@export var gravity:Vector2 = Vector2(0, 3)

# If this is true, the corners will have supporting springs connecting them to the points
# two points diagonally inwards of the corner.
@export var includeCornerSupports = false

# If this is false, the points will be a rainbow, if it is true, they will be tinted every frame 
# based on the forces being applied to them.
@export var forceTint = false

@export var showLines   = true
@export var showPoints  = false
@export var showPolygon = false
@export var showOutline = true

# idk
var lengthForThisSpring:float

# Stores all the points in a 2d array (Currently unused I think)
var bodyPoints = []

func _ready():
	#orthogSpringLength = sizeInPx/(pointsHorz-1)
	orthogSpringLength = distanceApart
	sizeInPx = orthogSpringLength*pointsHorz # The total size of the body
	
	if not showPolygon:
		$Shape3D.hide()
	
	# Create and initiate all the points and springs.
	initiatePoints()
	initiateSprings()

# warning-ignore:unused_argument
func _physics_process(delta):
	# The position of the point closest to the center of the squishyBody.
	var centerPointPos = get_node(bodyPoints[pointsVert/2][pointsHorz/2]).position
	# Put the camera at the correct position.
	$SquishyBodyCamera.position = centerPointPos
	
	if showPolygon:
		$Shape3D.polygon = getOutlineArray()
	
	if showOutline:
		$Outline.points = getOutlineArray()

# Create the correct amount of rigidbodies for all the points,
# and put them in the correct positions
func initiatePoints():
	for y in pointsVert:
		bodyPoints.append([]) # Add another layer
		
		for x in pointsHorz:
			# Initiate a new one in memory
			var newPoint = PhysicsPoint.instantiate()
			
			# Put the new point where it should be
			newPoint.position = Vector2(x*orthogSpringLength, y*orthogSpringLength)
			
			# Scale the point size and marker size appropriately
			newPoint.get_node("Hitbox").shape.radius = pointRadius
			newPoint.get_node("Marker").scale = Vector2(pointRadius/10, pointRadius/10) # /10 because it is already 10 pixels across
			
			# Adjust the color to give the whole squishy body a nice rainbow across it
			newPoint.get_node("Marker").color = Color.from_hsv((x + y) / (float(pointsHorz) + float(pointsVert)), 1, 1)
			
			# All the points need to have the same mass
			newPoint.mass = mass
			
			# All the points need to have the same gravity also
			newPoint.gravityForce = gravity
			
			# Whether we are tinting the points based on the forces applied to them
			newPoint.doTint = forceTint
			
			add_child(newPoint)
			
			# If we are hiding the points, we hide the point.
			if not showPoints:
				newPoint.hide()
			
			# And add it to the array so we can easily remember which are which
			bodyPoints[y].append(newPoint.get_path())

func initiateSprings():
	# We need the diagonal length between the points for the diagonal springs
	var d = orthogSpringLength
	var diagPxBetweenPoints = pythag(d, d)
	
	for y in pointsVert:
		for x in pointsHorz:
			# Magic?? No, this is all still math
			var r = pythag(sizeInPx, sizeInPx) / 2.0
			var bulgeToCreateCircle = r - ((r * sqrt(2)) / 2)
			
			# Adding this number to the spring length results in the middle of the
			# shape bulging outwards, to make it more like a circle, based on edgeBulges.
			var bulgeVert = (sin(x * (PI/(pointsHorz-1))) * bulgeToCreateCircle) * edgeBulges
			var bulgeHorz = (sin(y * (PI/(pointsVert-1))) * bulgeToCreateCircle) * edgeBulges
			
			var diagSpringLength = pythag(orthogSpringLength, orthogSpringLength)
			
			# Because some are diagonal, the length will be the hypotenuse of the two
			# horizontal lengths the spring is associated with. Because it is sometimes going
			# to be longer (due to the edge bulges) we have to calculate the rest length with
			# the spring length (which may have been changed by bulges) as one side, and the
			# original orthogSpringLength as the other side.
			
			# The length of each spring we're creating for this point
			var upRightLength   = diagSpringLength
			var rightLength     = orthogSpringLength
			var downRightLength = diagSpringLength
			var downLength      = orthogSpringLength
			
			# The lengths of each spring, if we're bulging it out
			var orthogWithBulgeHorz = orthogSpringLength + bulgeHorz #0.8 just bcuz it looks better
			var orthogWithBulgeVert = orthogSpringLength + bulgeVert
			var diagWithBulge = pythag(orthogWithBulgeHorz, orthogSpringLength)
			
			# These are for bulges. If it's on the edge of the square, it will
			# extend the length of the springs to the amount they should be with
			# the bulges.
			if y == 0: # If we're on the TOP ROW
#				downRightLength = diagWithBulge
				downLength      = orthogWithBulgeVert
			elif y == pointsVert-2: # If we're on the SECOND BOTTOM ROW
#				downRightLength = diagWithBulge
				downLength      = orthogWithBulgeVert
#			elif y == pointsVert-1: # If we're on the BOTTOM ROW
#				upRightLength   = diagWithBulge

			if x == 0: # If we're on the LEFT COLUMN
#				upRightLength   = diagWithBulge
				rightLength     = orthogWithBulgeHorz
#				downRightLength = diagWithBulge
			elif x == pointsHorz-2: # If we're on the SECOND RIGHT COLUMN
#				upRightLength    = diagWithBulge
				rightLength      = orthogWithBulgeHorz
#				downRightLength  = diagWithBulge
			
			# The following if statements only allow the springs to be created if
			# they will fit in the body, for example it will only create a spring
			# that connects to a point on the right of the current point IF there
			# is actually a point on the right
			
			# Only create this one if there's space on the right
			if x < pointsHorz-1:
				self.lengthForThisSpring = rightLength
				# Directly rightwards
				createSpring(x, y, x+1, y, "r ")
				
				# Only create this one if there's space on the right AND upward
				if y > 0:
					self.lengthForThisSpring = upRightLength
					# Diagonally up and to the right
					createSpring(x, y, x+1, y-1, "ru")
			
			# Only create this one if there's space downward
			if y < pointsVert-1:
				self.lengthForThisSpring = downLength
				# Directly downwards
				createSpring(x, y, x, y+1, "d ")
				
				# Only create this one if there's space downward AND to the right
				if x < pointsHorz-1:
					self.lengthForThisSpring = downRightLength
					createSpring(x, y, x+1, y+1, "rd")
	
	# Create springs from the corner points to the points two inwards from the corners.
	# This hopefully prevents the corners from being squished in so far.
	# We don't have to do this in the loop, because we know exactly where we want these.
	if includeCornerSupports and pointsHorz > 2 and pointsVert > 2:
		self.lengthForThisSpring = diagPxBetweenPoints*2
		
		# The length from one corner to the opposite corner. This takes into account
		# the possible difference between the length and width of the rectangle.
		# We need to subtract one spring length because it doesn't get fully to the end,
		# due to the final point being one spring length short of the "sizeInPx".
		
		var actualHorzLen = sizeInPx # The horizontal length is actually the specified size.
		var actualVertLen = sizeInPx * ((pointsVert/pointsHorz)+1) # The vertical length is not the same as the horizontal length always, so adjust for that.
		
		var fullDiagonalLength = sqrt(pow(actualHorzLen, 2) + pow(actualVertLen, 2))
		
		# Top two corners
		createSpring(0,            0, int(pointsHorz/2.0), int(pointsVert/2.0), "TL ", fullDiagonalLength/2.0)
		createSpring(pointsHorz-1, 0, int(pointsHorz/2.0), int(pointsVert/2.0), "TR ", fullDiagonalLength/2.0)
		
		# Bottom two corners
		createSpring(0,            pointsVert-1, int(pointsHorz/2.0), int(pointsVert/2.0), "TL ", fullDiagonalLength/2.0)
		createSpring(pointsHorz-1, pointsVert-1, int(pointsHorz/2.0), int(pointsVert/2.0), "TR ", fullDiagonalLength/2.0)

func createSpring(x:int, y:int, targetX:int, targetY:int, springName:String, lengthOverride:float=0):
	# Create a new spring and add it as a child
	var spring = PhysicsSpring.instantiate()
	
	# Connect the spring to this node and the target node, so that it keeps them apart.
	spring.PointA = bodyPoints[y][x]
	spring.PointB = bodyPoints[targetY][targetX]
	
	# Set the physical properties of the spring
	if lengthOverride == 0:
		spring.restLength     = lengthForThisSpring
	else:
		spring.restLength     = lengthOverride
	spring.originalRestLength = lengthForThisSpring
	spring.stiffness          = stiffness
	spring.dampingFactor      = dampingFactor
	spring.plasticity         = plasticity
	spring.memory             = memory
	
	spring.springName = springName + "("+str(x)+","+str(y)+")" # Will look like "dd(3,6)".
	
	# This will not display the lines connecting the points where the springs are.
	spring.hideLine = !showLines
	
	add_child(spring)

# Refreshes the Polygon2D or Line2D that we use to represent the shape of the softbody,
# which uses eldritch array positioning to get the right points and add them to
# the array of positions.
func getOutlineArray():
	var pointArray:PackedVector2Array = []
	var colorArray:PackedColorArray   = []
	
	var currentNode:RigidBody2D
	
	for i in range(0, pointsHorz):
		currentNode = get_node(bodyPoints[0][i])
		pointArray.append(currentNode.position)
		colorArray.append(markerColor(currentNode))
	
	for i in range(0, pointsVert-2):
		currentNode = get_node(bodyPoints[i+1][pointsHorz-1])
		pointArray.append(currentNode.position)
		colorArray.append(markerColor(currentNode))
	
	var backwards = []
	for i in range(0, pointsHorz):
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

# Do the pythagorean theorem on s1 and s2, and return the hypotenuse
func pythag(s1:float, s2:float) -> float:
	var result = sqrt((s1 * s1) + (s2 * s2))
	return result

func markerColor(node:RigidBody2D):
	return node.get_node("Marker").color

func enableThisCamera():
	$SquishyBodyCamera.make_current()
