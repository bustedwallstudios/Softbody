extends Node2D

# basically i can only have NodePaths as the export variable, and i have 
# to literally just call get_node() on them IMMEDIATELY when the thing
# starts, TO CONVERT THEM TO AN ACTUAL NODE.
var hasConvertedStupidNodePaths = false

export (NodePath) var PointA
export (NodePath) var PointB

export (float) var stiffness = 1

# We multiply the velocity by this each frame, to slow it down over time
export (float) var dampingFactor = 0.95

# The force applied due to "gravity"
export (Vector2) var gravityForce = Vector2(0, 50)

var springName = "unknown"

# This is determined during the creation by the body, it's just how long the
# spring would be if there were no external forces acting upon it
var restLength = 0

# How much force will be applied to the points, based on a bunch of spring things
var forceProduced

func convertStupidNodePaths():
	PointA = get_node(PointA)
	PointB = get_node(PointB)

func _process(delta):
	if not hasConvertedStupidNodePaths: # check line 3
		convertStupidNodePaths()
		hasConvertedStupidNodePaths = true
	
	var springForce  = hookesLawToFindForce()
	var dampingForce = findDampingForce()
	
	var totalForce:float = springForce + dampingForce
	
	# Used for finding the force to apply to PointA and PointB, respectively
	var aMinusB = PointA.position - PointB.position
	var bMinusA = PointB.position - PointA.position
	
	var aTowardsB = aMinusB.normalized()
	var bTowardsA = bMinusA.normalized()
	
	# This is the force magnitude, multiplied by the
	# normal vector between A and B
	var forceOnPointA = totalForce * (aTowardsB)
	var forceOnPointB = totalForce * (bTowardsA)

	forceOnPointA = fixVector(forceOnPointA)
	forceOnPointB = fixVector(forceOnPointB)
	
	PointA.linear_velocity = forceOnPointA
	PointB.linear_velocity = forceOnPointB
	
	updateLine()
	print(springName, " sf:", springForce, " dpf:", dampingForce, " Af: ", forceOnPointA, " Bf: ", forceOnPointB, " Av: ", PointA.linear_velocity, " Bv: ", PointB.linear_velocity)
	var foo = 23

func fixVector( vec: Vector2 ) -> Vector2:
	var x = round( vec.x * 1000 ) / 1000
	if x == -0: x = 0
	
	var y = round( vec.y * 1000 ) / 1000
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
	forceProduced = stiffness * differenceToRestLength
	
	return forceProduced

func findDampingForce() -> float:
	# The difference in position
	var bMinusA = PointB.position - PointA.position
	
	# The direction from A to B with a length of 1
	var normalizedDirectionVector = bMinusA.normalized()
	
	# Just the differnce in linear velocity between A and B
	var velocityDifference = PointA.linear_velocity - PointB.linear_velocity
	
	# The dot product of the two vectors; if this is positive it will move the 
	# points closer together, otherwise it will move them apart
	var dotProduct = normalizedDirectionVector.dot(velocityDifference)
	
	return (dotProduct * dampingFactor)

# Update the line graphic for each frame, to point from point A to B
func updateLine():
	$Line2D.clear_points()
	$Line2D.add_point(PointA.position)
	$Line2D.add_point(PointB.position)
