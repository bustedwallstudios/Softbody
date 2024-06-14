class_name Constraint extends Node

# words this project has ruined: edge, normal

"""
Mostly created with help from Ten Minute Physics: https://www.youtube.com/watch?v=uCaHXkS2cUg
"""

# Compliance
var α:float

var vertices:Array = []

var restValue:float # Will either represent the rest length or rest volume
var currentValue:float:
	get:
		return getCurrentValue()

var constraintType:C_Type

enum C_Type {
	EDGE,
	FACE
}

# points is an array of Node2Ds
func _construct(points:Array, restVal:float, compliance:float, type:C_Type):
	self.vertices       = points
	self.restValue      = restVal
	self.currentValue   = restVal
	self.α              = compliance
	self.constraintType = type

func solve(Δt:float):
	# Edge constraint
	if self.constraintType == C_Type.EDGE:
		α = 1 # The edges have wayyy more compliance than the area
		
		var p1:RigidBody2D = vertices[0]
		var p2:RigidBody2D = vertices[1]
		
		# The length and rest length of this edge constraint
		var l  = self.currentValue
		var l0 = self.restValue
		
		# For all particles in this constraint (only 2, cuz it's an edge),
		# get their inverse masses
		var w1 = 1.0/p1.mass # inverse mass (same for all particles, just because i don't have the option to change that per particle)
		var w2 = 1.0/p2.mass
		var w = w1 + w2
		
		# The constraint function is the function that is 0 when the constraint
		# is satisfied, and will be negative/positive based on which way the 
		# constraint is deformed.
		var C:float = l - l0
		
		# The gradient of the constraint function is the direction to move which
		# results in a maximal decrease of C. Essentially, this is the direction
		# that the points would have to move with magnitude C in order to 
		# completely satisfy the constraint.
		# The two point's gradients are just negative the other point's gradient
		var gradient:Vector2 = getDirVec(p2.tPos, p1.tPos)
		
		var dir1:Vector2 = gradient # gradient (should be squared, but it's length 1, so don't waste clock cycles)
		var dir2:Vector2 = -gradient
		
		# This value will be the following:
		# The constraint function (pointing towards the rest size), divided by:
		# the inverse mass of both points combined, plus the compliance (higher compliance -> smaller λ)
		# This IS:
		# A value representing how much each point should move towards
		# the desired (resting) tPos of the constraint.
		# It is that because it's the amount fully towards the end, decreased
		# inversely proportionally to how heavy all the points are, and
		# proportionally to the compliance.
		var λ:float = -C / (w + α/pow(Δt, 2))
		
		var correctionVec1:Vector2 = (λ * w1) * dir1
		var correctionVec2:Vector2 = (λ * w2) * dir2
		
		self.vertices[0].tPos += correctionVec1
		self.vertices[1].tPos += correctionVec2
		
		# Just to display the force vectors
		return [correctionVec1, correctionVec2]
	
	# Triangle constraint
	else:
		var p1:RigidBody2D = vertices[0]
		var p2:RigidBody2D = vertices[1]
		var p3:RigidBody2D = vertices[2]
		
		# Just to save a couple characters down the line
		var p1p:Vector2 = p1.tPos
		var p2p:Vector2 = p2.tPos
		var p3p:Vector2 = p3.tPos
		
		# Rest value of this triangle constraint
		var area0 = self.restValue
		
		# For all particles in this constraint (3 for a triangle),
		# get their inverse masses
		var w1 = 1.0 / p1.mass
		var w2 = 1.0 / p2.mass
		var w3 = 1.0 / p3.mass
		var w = w1 + w2 + w3
		
		# Calculate current area of the triangle formed by the particles
		var area = self.getCurrentValue()
		
		# The constraint function is the deviation from the rest area.
		# Includes negative areas.
		var m:float = 1
		var C:float = m * (area - area0)
		
		# Calculate λ (Lagrange multiplier)
		var denom = (w + α / pow(Δt, 2))
		var λ: float = (-C) / denom
		
#		if not is_nan(λ):
#			print("-C:    ", -C)
#			print("denom: ", denom)
		
		# Calculate individual gradient vectors for each particle.
		# A vector purpendicular to the opposide side from this point.
		var dir1:Vector2 = (p3p - p2p).rotated(PI/2).normalized()
		var dir2:Vector2 = (p1p - p3p).rotated(PI/2).normalized()
		var dir3:Vector2 = (p2p - p1p).rotated(PI/2).normalized()
		
		# Calculate correction vectors for each particle
		var correctionVec1:Vector2 = (λ * w1) * dir1
		var correctionVec2:Vector2 = (λ * w2) * dir2
		var correctionVec3:Vector2 = (λ * w3) * dir3
		
		# Debugging
#		if not is_nan(λ):
#			print("λ:    ", λ)
#			print("w1:   ", w1)
#			print("dir1: ", dir1)
#			print("cvec1: ", correctionVec1)
#			print("cvec2: ", correctionVec2)
#			print("cvec3: ", correctionVec3)
#			print()
		
		self.vertices[0].tPos += correctionVec1*0.0001
		self.vertices[1].tPos += correctionVec2*0.0001
		self.vertices[2].tPos += correctionVec3*0.0001
		
		# Just to display the force vectors
		return [correctionVec1, correctionVec2, correctionVec3]

# The normalized direction vector (the gradient of a distance constraint) between two points
func getDirVec(p1:Vector2, p2:Vector2):
	return (p2-p1).normalized()

# Helper functions to calculate the current values of this constraint

func getCurrentValue():
	# If this constraint is an edge, then its current value (length) is the
	# distance between the two points.
	match self.constraintType:
		
		C_Type.EDGE:
			return currentLength()
	
		C_Type.FACE:
			return currentArea()
		
		_:
			print("ERROR! Constraint has no C_Type associated with it!")

func currentLength():
	return vertices[0].tPos.distance_to(vertices[1].tPos)

# Written by ChatGPT 4
func currentArea() -> float:
	var point1 = vertices[0]
	var point2 = vertices[1]
	var point3 = vertices[2]
	
	var area = 0.5 * ((point1.tPos.x * point2.tPos.y + point2.tPos.x * point3.tPos.y + point3.tPos.x * point1.tPos.y) -
					  (point1.tPos.y * point2.tPos.x + point2.tPos.y * point3.tPos.x + point3.tPos.y * point1.tPos.x))
	
	# Return the area - takes into account winding direction, and therefore
	# will return negative values for inverted triangles.
	return area

# Written by ChatGPT 3
func calculateTriangleNormal(p1:Vector2, p2:Vector2, p3:Vector2) -> float:
	# Calculate two vectors representing edges of the triangle
	var edge1: Vector2 = p2 - p1
	var edge2: Vector2 = p3 - p1
	
	# Calculate the cross product of the two edges to obtain the normal
	var normal:float = edge1.cross(edge2)
	
	# Normalize the normal, then return the normal normal vector
	normal = normal / abs(normal)
	print("normal: ", normal)
	return normal
