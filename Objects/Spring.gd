extends Node2D

# basically the export variable can only be a NodePath type instead of 
# a Node itself, so I have to literally just call get_node() on them
# IMMEDIATELY when the thing starts, TO CONVERT THEM TO AN ACTUAL NODE.
var hasConvertedStupidNodePaths = false

# This ensures that _process() will only start to do stuff
# once we're done setting up the spring with points and stuff
var doneSetup = false

export (NodePath) var PointA
export (NodePath) var PointB

# stiffness and dampingFactor are both set by the squishyBody itself.
var stiffness:float
var dampingFactor:float # We multiply the velocity by this each frame, to prevent it from flying off to infinity

var springName = "unknown" # We'll set this to something later on to identify which spring it is

# This is determined during the creation by the body, it's just how long the
# spring would be if there were no external forces acting upon it
var restLength:float

# If this is true, we won't show the line
var hideLine:bool

# How much force will be applied to the points, based on the stiffness, distance apart, etc
var hookesForceProduced:float

# The current length of this spring (the distance between the two points that it connects)
var currentLength

# If this is true, it will add on an extra calculation: pressure force.
# This is set to true in the SquishyBall code only, and will take the pressure
# (calculated by the SquishyBall) and apply it to each point.
var isBall = false
var pressureFactor:float

func _ready():
	if hideLine:
		$Line2D.clear_points()
		$Line2D.hide()

func convertStupidNodePaths():
	# Change the |path to the node| to the node itself
	PointA = get_node(PointA)
	PointB = get_node(PointB)

# warning-ignore:unused_argument
func _physics_process(delta):
	if doneSetup:
		if not hasConvertedStupidNodePaths: # check line 3
			convertStupidNodePaths()
			hasConvertedStupidNodePaths = true
		
		# Set the global variable for the distance between point A and B
		# This is used in hookesLawToFindForce() and findPressureForceVector()
		currentLength = (PointB.global_position - PointA.global_position).length()
		
		var springForce  = hookesLawToFindForce()
		var dampingForce = findDampingForce()
		
		var totalForce:float = springForce + dampingForce
		
		# Get the force vectors to apply to each point
		# They are just opposites, so we can calculate it once and then set the
		# force on the other point to the inverse of the force on the first one.
		var forceOnPointA = aimForceToOtherPoint(totalForce, PointA.global_position, PointB.global_position)
		var forceOnPointB = -forceOnPointA
		
		# If this is a ball body, instead of a mesh-like square one
		if isBall:
			var pressureForce = findPressureForceVector()
			
			forceOnPointA += pressureForce * pressureFactor
			forceOnPointB += pressureForce * pressureFactor
		
		# Set the spring force applied to each point to the force we calculated
		# This will be set by all the springs affecting the point, and THEN
		# integrated into the point itself
		PointA.totalSpringForce += forceOnPointA
		PointB.totalSpringForce += forceOnPointB
		
		# If we are showing the lines, update them
		if not hideLine:
			updateLine()

# Takes the amount of force as an argument and aims it towards
# the points, from each other. This results in the points receiving 
# the correct force, *in the correct direction*.
func aimForceToOtherPoint(force:float, thisPointPos:Vector2, otherPointPos:Vector2) -> Vector2:
	# The vector pointing from this point to the other point
	var fromThisToOther = (thisPointPos - otherPointPos).normalized()
	
	# The force we should apply, in the direction and with the power it should have
	var forceToApply = force * fromThisToOther
	
	# Repair the weird ass vector nonsense that sometimes happens
	var fixedForce:Vector2 = fixVector(forceToApply)
	
	return fixedForce

# Makes the vectors more normal, and rounds them to the nearest 1/1000th.
# They would sometimes return strange values like -0, so this was made to fix that.
func fixVector( vector: Vector2 ) -> Vector2:
	var x = round( vector.x * 1000 ) / 1000
	if x == -0: x = 0
	
	var y = round( vector.y * 1000 ) / 1000
	if y == -0: y = 0
	
	return Vector2(x,y)

# Find the force that the spring is applying, based on things like stiffness and position
func hookesLawToFindForce() -> float:
	# The difference between its current length and its resting length
	# If this is negative, it will push the points apart
	var differenceToRestLength = restLength - currentLength
	
	# The force it produces increases if the stiffness does, and also if
	# it's proximity to it's resting length increases
	hookesForceProduced = differenceToRestLength * stiffness
	
	return hookesForceProduced

# Calculates the force applied to the points in the opposite 
# direction from the spring's force, to prevent the shape
# from perpetually bouncing in place.
func findDampingForce() -> float:
	# The vector pointing towards A from B with length 1
	var normalizedDirection = (PointA.global_position - PointB.global_position).normalized()
	
	# Just the difference in linear velocity between A and B
	var velocityDifference = PointB.linear_velocity - PointA.linear_velocity
	
	# The dot product of the two vectors; if this is positive it will move the 
	# points closer together, otherwise it will move them apart
	var dotProduct = normalizedDirection.dot(velocityDifference)
	
	# It's WAY too big normally, so we shrink it to a reasonable amount.
	# (50 is completely arbitrary)
	dotProduct /= 50
	
	return dotProduct * dampingFactor

func findPressureForceVector():
	# Get the pressure from the squishyball
	var pressure:float = PointA.get_parent().p
	
	# Get the vector pointing from A to B
	var vectorBetweenPoints:Vector2 = PointB.global_position - PointA.global_position
	
	# Force = P * L, where P is the pressure and L is the length of the spring.
	var force:float = pressure * (vectorBetweenPoints.length())
	
	# This is the force that we apply to the points in 2D.
	# It is the force * the normalized distance between the points,
	# rotated to points outwards.
	var forceVector = vectorBetweenPoints.rotated(-PI/2) * force
	
	return forceVector

# Update the line graphic for each frame, to go from point A to B
func updateLine():
	$Line2D.clear_points()
	$Line2D.add_point(PointA.position)
	$Line2D.add_point(PointB.position)
	
