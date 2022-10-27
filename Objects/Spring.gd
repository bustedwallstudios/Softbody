extends Node2D

# basically the export variable can only be a NodePath type instead of 
# a Node itself, so I have to literally just call get_node() on them
# IMMEDIATELY when the thing starts, TO CONVERT THEM TO AN ACTUAL NODE.
var hasConvertedStupidNodePaths = false

export (NodePath) var PointA
export (NodePath) var PointB

# stiffness and dampingFactor are both set by the squishyBody itself.
var stiffness:float
var dampingFactor:float # We multiply the velocity by this each frame, to prevent it from flying off to infinity

# The deformity of the springs. The higher this value is, the less the spring will spring back, and
# the more it will permanently conform to the forces applied.
# Set by the squishybody itself.
var plasticity:float

# The higher this value is, the more quickly it will return to it's original shape
# after being deformed by plasticity.
var memory:float

# This is determined during the creation by the body, it's just how long the
# spring would be if there were no external forces acting upon it
var restLength:float
# This is set to the same thing as restLength in the softbody. It is used to figure out the memory
# that should be applied, to stretch the springs back to the length they started at.
var originalRestLength:float

# The current length of this spring (the distance between the two points that it connects)
var currentLength

# How much force will be applied to the points, based on the stiffness, distance apart, etc
var hookesForceProduced:float

# If this is true, we won't show the line
var hideLine:bool

# We'll set this to something later on to identify which spring it is
var springName = "unknown" 

# If this is true, it will add on an extra calculation: pressure force.
# This is set to true in the SquishyBall code only, and will take the pressure
# (calculated by the SquishyBall) and apply it to each point.
var isBall = false
var pressureFactor:float

func _ready():
	if hideLine:
		$Line2D.clear_points()
		$Line2D.hide()
	
	convertStupidNodePaths()

func convertStupidNodePaths():
	# Change the |path to the node| to the node itself
	PointA = get_node(PointA)
	PointB = get_node(PointB)

var t = 0
# warning-ignore:unused_argument
func _physics_process(delta):
	
	# fuck you
	if t <10:
		self.originalRestLength = self.restLength
		t+=1
	
	# Set the global variable for the distance between point A and B
	# This is used in hookesLawToFindForce() and findPressureForce()
	currentLength = (PointB.global_position - PointA.global_position).length()
	
	var springForce:float  = hookesLawToFindForce()
	var dampingForce:float = findDampingForce()
	
	var totalForce:float = springForce + dampingForce
	
	# Get the force vectors to apply to each point
	# They are just opposites, so we can calculate it once and then set the
	# force on the other point to the inverse of the force on the first one.
	var forceOnPointA = aimForceToOtherPoint(totalForce, PointA.global_position, PointB.global_position)
	var forceOnPointB = -forceOnPointA
	
	# If this is a ball body, instead of a mesh-like square one, we'll do the calculations
	# to figure out the pressure-based forces.
	if false:
		# The AMOUNT of pressure that we will apply to the points
		var pressureForce:float = findPressureForce() * pressureFactor
		
		# The direction we are to apply the force in is perpendicular to the spring,
		# pointing outwards. This will push them both away from the center of the ball,
		# forcing it to keep its shape.
		# This should be normalized, so that we can multiply it by the pressureForceOnX
		# variables to get it to point in the right direction AND have the right magnitude,
		# and we ensure that it is of length 1 by passing in 1 to the function.
		var forceDirection:Vector2 = aimForceToOtherPoint(1, PointA.global_position, PointB.global_position).rotated(PI/2)
		
		# Add the pressure force vector to the force that we will ultimately apply to
		# each point.
		forceOnPointA += (forceDirection * pressureForce)
		forceOnPointB += (forceDirection * pressureForce)
	
	# Set the spring force applied to each point to the force we calculated
	# This will be set by all the springs affecting the point, and THEN
	# integrated into the point itself
	PointA.applySpringForce(forceOnPointA)
	PointB.applySpringForce(forceOnPointB)
	
	# If the springs are plastic, it will deform slightly to the amount it has been
	# squished.
	# We only bother doing the math if it is at least a little bit plastic. The
	# result of the calculation will always be 0 if the plasticity is 0.
	if plasticity > 0:
		self.restLength -= findPlasticityEffect()
	
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

# Returns the new length of the spring after we do plasticity.
# The more plastic the shape is, the more it will permanently deform to any forces
# that occur to it.
func findPlasticityEffect() -> float:
	# The difference between its current and desired lengths.
	var currentDeformity:float = self.restLength - currentLength
	
	# The amount of deformity currently, scaled to the amount of plasticity.
	# 1 plasticity will result in the new length of the spring being changed
	# to exactly the length it has been squished to.
	# Keep in mind that it can be stretched, and result in the spring becoming
	# longer than it started.
	var deformAmount:float
	
	# If it wasn't going to deform much, slowly return to the original length.
	# This prevents it from being constantly squished from gravity, and
	# only really lets it be squished by heavy objects or falling.
	if abs(currentDeformity) < 10:
		# The difference between how long it was when it started and the current rest length.
		var restLengthDifference = restLength - originalRestLength
		
		# We are essentially un-deforming, slowly squishing back to the original rest length.
		deformAmount = restLengthDifference * (memory / 100.0)
	
	# However, if it was going to deform a significant amount, deform.
	else:
		deformAmount = currentDeformity * plasticity
	
	return deformAmount

# Calculates the force applied to the points in the opposite 
# direction from the spring's force, to prevent the shape
# from perpetually bouncing in place.
func findDampingForce() -> float:
	# The vector pointing towards A from B with length 1
	var normalizedDirection:Vector2 = (PointA.global_position - PointB.global_position).normalized()
	
	# Just the difference in linear velocity between A and B
	var velocityDifference:Vector2 = PointB.linear_velocity - PointA.linear_velocity
	
	# The dot product of the two vectors; if this is positive it will move the 
	# points closer together, otherwise it will move them apart
	var dotProduct = normalizedDirection.dot(velocityDifference)
	
	# It's WAY too big normally, so we shrink it to a reasonable amount.
	# (50 is completely arbitrary)
	dotProduct /= 50
	
	return dotProduct * dampingFactor

func findPressureForce() -> float:
	# Get the pressure from the squishyball
	var pressure:float = PointA.get_parent().p
	
	# Get the vector pointing from A to B
	var vectorBetweenPoints:Vector2 = PointB.global_position - PointA.global_position
	
	# Force = P * L, where P is the pressure and L is the length of the spring.
	var force:float = pressure * (vectorBetweenPoints.length())
	
	return force

# Update the line graphic for each frame, to go from point A to B
func updateLine():
	$Line2D.clear_points()
	$Line2D.add_point(PointA.position)
	$Line2D.add_point(PointB.position)
	
