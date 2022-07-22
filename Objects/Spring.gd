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
var stiffness
var dampingFactor # We multiply the velocity by this each frame, to prevent it from flying off to infinity

var springName = "unknown" # We'll set this to something later on to identify which spring it is

# This is determined during the creation by the body, it's just how long the
# spring would be if there were no external forces acting upon it
var restLength

# How much force will be applied to the points, based on the stiffness, distance apart, etc
var hookesForceProduced

func convertStupidNodePaths():
	# Change the |path to the node| to the node itself
	PointA = get_node(PointA)
	PointB = get_node(PointB)
	
	#print("Node paths converted to point nodes.")

# warning-ignore:unused_argument
func _process(delta):
	if doneSetup:
		if not hasConvertedStupidNodePaths: # check line 3
			convertStupidNodePaths()
			hasConvertedStupidNodePaths = true
		
		var springForce  = hookesLawToFindForce()
		var dampingForce = findDampingForce()
		
		var totalForce:float = springForce + dampingForce
		
		# Get the force vectors to apply to each point
		var forceOnPointA = aimForceToOtherPoint(totalForce, PointA.position, PointB.position)
		var forceOnPointB = aimForceToOtherPoint(totalForce, PointB.position, PointA.position)
		
		# Set the spring force applied to each point to the force we calculated
		PointA.integrateForceFromOneSpring(forceOnPointA)
		PointB.integrateForceFromOneSpring(forceOnPointB)
		
		updateLine()

# Takes the amount of force as an argument and aims it towards
# the points, from each other. This results in the points receiving 
# the correct force, *in the correct direction*.
func aimForceToOtherPoint(force:float, thisPointPos:Vector2, otherPointPos:Vector2):
	# The vector pointing from this point to the other point
	var fromThisToOther = (thisPointPos - otherPointPos).normalized()
	
	# The force we should apply, in the direction and with the power it should have
	var forceToApply = force * fromThisToOther
	
	# Repair the weird ass vector nonsense that sometimes happens
	var fixedForce:Vector2 = fixVector(forceToApply)
	
	# Limit the force so it at least waits a few seconds before exploding
	if fixedForce.length() > 10:
		fixedForce = fixedForce.normalized() * 10
	
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
	
	# The distance between them
	var distBetweenPoints = (PointB.position - PointA.position).length()
	
	# The difference between its current length and its resting length
	# If this is negative, it will push the points apart
	var differenceToRestLength = restLength - distBetweenPoints
	
	# The force it produces increases if the stiffness does, and also if
	# it's proximity to it's resting length increases
	hookesForceProduced = differenceToRestLength * stiffness
	
	return hookesForceProduced

func findDampingForce() -> float:
	# The vector pointing towards A from B with length 1
	var normalizedDirection = (PointB.position - PointA.position).normalized()
	
	# Just the differnce in linear velocity between A and B
	var velocityDifference = PointB.linear_velocity - PointA.linear_velocity
	
	# The dot product of the two vectors; if this is positive it will move the 
	# points closer together, otherwise it will move them apart
	var dotProduct = normalizedDirection.dot(velocityDifference)
	
	dotProduct /= 50
	
	return -(dotProduct * dampingFactor)

# Update the line graphic for each frame, to point from point A to B
func updateLine():
	$Line2D.clear_points()
	$Line2D.add_point(PointA.position)
	$Line2D.add_point(PointB.position)
