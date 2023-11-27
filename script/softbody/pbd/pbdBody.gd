extends Polygon2D

@export var physicsPointScene:PackedScene
@export var physicsSpringScene:PackedScene

@export_range(1, 10) var substeps:int = 5

@export_range(-100, 100) var gravity:float = 1

@export_range(0, 100) var stiffness:float = 10

# If plasticity is 1, it will competely deform to any squishing that happens.
# The lower it is, the less it will conform, and the more it will bounce back.
@export_range(0, 0.2) var plasticity:float = 0

# This will gradually return the rest length of the spring to the original length,
# if it is decreased by the plasticity of the object (think memory foam pillow).
@export_range(0, 1, 0.01) var memory: float

@export_range(1, 1000) var pointRadius = 100

# Show the lines representing the spring constraints
@export var showLines = true

@export var displayBoundingBox:bool = false

var allParticles:Array = []

var constraintsList:Array = []

func _ready():
	var triangulation = await delaunayTriangulation(self.polygon)
	var edges         = getAllEdgesFrom(triangulation)
	var points        = self.polygon
	
	for pos in points:
		var physicsPoint = physicsPointScene.instantiate()
		
		physicsPoint.gravity_scale = gravity
		
		
		# Scale the point size and marker size appropriately
		physicsPoint.get_node("Hitbox").shape.radius = pointRadius
		physicsPoint.get_node("Marker").scale = Vector2(pointRadius/10, pointRadius/10) # /10 because it is already 10 pixels across
		
		
		physicsPoint.position = pos
		
		allParticles.append(physicsPoint)
		self.add_child(physicsPoint)
	
	# After creating all the points, add their collision exceptions.
	addPointExceptions()
	
	for edge in edges:
		var p1 = getParticleNodeAt(edge[0])
		var p2 = getParticleNodeAt(edge[1])
		createSpring(p1, p2)
	
	if not displayBoundingBox:
		$BoundingBoxLine.clear_points()
		$BoundingBoxLine.hide()
		
		$SuperTriangleLine.clear_points()
		$SuperTriangleLine.hide()

func addPointExceptions():
	for point in allParticles:
		for point2 in allParticles:
			point.add_collision_exception_with(point2)

func getParticleNodeAt(pos:Vector2):
	for pointNode in allParticles:
		if pointNode.position == pos:
			return pointNode
	
	print("ERROR: Could not find point node at position ", pos)
	return null

func createSpring(pA, pB):
	
	# Create a new spring and add it as a child
	var spring = physicsSpringScene.instantiate()
	
	# Connect the spring to this node and the target node, so that it keeps them apart.
	spring.PointA = pA.get_path()
	spring.PointB = pB.get_path()
	
	var thisSpringLength = (pA.position - pB.position).length()
	
	# Set the physical properties of the spring
	spring.restLength         = thisSpringLength
	spring.originalRestLength = thisSpringLength
	spring.stiffness          = stiffness
	spring.dampingFactor      = stiffness
	spring.plasticity         = plasticity
	spring.memory             = memory
	
	# This will not display the lines connecting the points where the springs are.
	spring.hideLine = !showLines
	
	add_child(spring)

#func _physics_process(Δt):
#
#	var Δts = Δt/substeps
#
#	# Calculate for each substep
#	for n in range(0, substeps):
#
#		for particle in allParticles:
#			particle.linear_velocity.y += Δts * gravity
#			particle.prevPos     = particle.position
#			particle.position   += Δts * particle.linear_velocity
#
#		for 

func delaunayTriangulation(points:PackedVector2Array) -> Array:
	# The list of current triangles that are inside the polygon. Starts at zero,
	# and triangles are added and removed over the course of this algorithm.
	var triangles:Array = []
	
	# The bounding box of the polygon
	var boundingBox:Rect2 = getBoundingBox(points)
	
	# The smallest (but not with my algorithm) triangle that encompasses the
	# entire triangle.
	var superTriangle:Array = getSuperTriangle(boundingBox)
	triangles.append(superTriangle)
	
	# One at a time, integrate all the points into the triangulation.
	for point in points:
		var badTriangles:Array = []
		
		for thisTriangle in triangles:
			# If the point is inside the circumcircle of this triangle, then it
			# is not a valid Delaunay Triangulation. Thus, this triangle is bad.
			if inCircumcircleOf(thisTriangle, point):
				
				#print("Bad triangle with vertices ", thisTriangle)
				badTriangles.append(thisTriangle)
		
		# The edges of the polygon that delineates the hole that will be created
		# by removing the bad triangles.
		var polygonEdges:Array = []
		
		# All of the edges in the bad triangles
		var allEdges:Array
		
		# Loop over all the bad triangles, and add each of their edges to the list.
		# This will contain all edges, and whichever ones are NOT duplicates 
		# are going to be added to the polygonEdges.
		for badTriangle in badTriangles:
			for edgeIdx in range(0, 3):
				var edge:Array = []
				
				edge.append(badTriangle[edgeIdx])
				edge.append(badTriangle[(edgeIdx+1)%3]) # For the last edge, use vertex 0 again.
				
				allEdges.append(edge)
			
			#print("Bad triangle with vertices ", badTriangle, " ERASED")
			
			removeArrayFromAnotherArray(badTriangle, triangles)
		
		# Add all non-duplicate edges to the polygonEdges array.
		
		for wrongEdge in allEdges:
			# Count the number of time this edge shows up in the list. 
			var totalCount = 0
			totalCount += allEdges.count(wrongEdge)
			totalCount += allEdges.count([wrongEdge[1], wrongEdge[0]]) # VERY IMPORTANT! ALSO COUNT THE CASES WHERE THE EDGE IS "BACKWARDS" - THE ORDER MAY BE FLIPPED, BUT THE EDGE IS THE SAME!
			
			if totalCount == 1:
				polygonEdges.append(wrongEdge)
		
		for edge in polygonEdges:
			var newTriangle:Array = edge.duplicate()
			newTriangle.append(point)
			
			triangles.append(newTriangle)
		
	# Using the other one directly gets fucky, and doesn't finish iterating.
	var finalTrianglesArray = triangles.duplicate()
	
	# Loop over every triangle, and see if it shares any points with the super
	# triangle - if it does, remove it.
	for triangle in triangles:
		for vertex in superTriangle:
			if vertex in triangle:
				finalTrianglesArray.erase(triangle)
	
#	print("Final triangles array: ")
#	for i in finalTrianglesArray:
#		print(i)
	
	return finalTrianglesArray

# This function checks whether an array is present within another array,
# REGARDLESS OF ARRAY ORDER.‎
func arrayIsInAnotherArray(insideArray:Array, outsideArray:Array) -> bool:
	var requiredMatches = len(insideArray)
	var matchesSeen = 0
	
	# Loop over all the triangles in the outside array
	for subArray in outsideArray:
		matchesSeen = 0
		
		# For each vector2 in the triangle, 
		for ov in subArray:
			# go over each vector2 in the OTHER triangle,
			for iv in insideArray:
				# and check if they're equal.
				if ov == iv:
					# If they are equal, then that's one match closer to being
					# in the outside array. If all of them are equal, it's there.
					matchesSeen += 1
					break # Stop checking this inside vector2. Further matches mean less than nothing.
		
		# If, after looping over every value in both sub arrays, all of them were
		# matches, they were the same!
		if matchesSeen == requiredMatches:
			return true
	
	return false

func removeArrayFromAnotherArray(insideArray:Array, outsideArray:Array):
	var requiredMatches = len(insideArray)
	var matchesSeen = 0
	
	# Loop over all the triangles in the outside array
	for subArray in outsideArray:
		matchesSeen = 0
		
		# For each vector2 in the triangle, 
		for ov in subArray:
			# go over each vector2 in the OTHER triangle,
			for iv in insideArray:
				# and check if they're equal.
				if ov == iv:
					# If they are equal, then that's one match closer to being
					# in the outside array. If all of them are equal, it's there.
					matchesSeen += 1
					break # Stop checking this inside vector2. Further matches mean less than nothing.
		
		# If, after looping over every value in both sub arrays, all of them were
		# matches, they were the same!
		if matchesSeen == requiredMatches:
			outsideArray.erase(subArray)
			return

# Gets just the edges from a given list of triangles - this is used to create
# the spring constraints.
func getAllEdgesFrom(triangulation:Array) -> Array:
	var allEdges = []
	
	for triangle in triangulation:
		for edgeIdx in range(0, 3):
				var edge:Array = []
				
				edge.append(triangle[edgeIdx])
				edge.append(triangle[(edgeIdx+1)%3]) # For the last edge, use vertex 0 again.
				
				# Only add the edge to the list of edges if it has not been counted yet
				if not edge in allEdges:
					allEdges.append(edge)
	
	return allEdges

# Written by ChatGPT4
func inCircumcircleOf(triangle:Array, P:Vector2):
	
	var A:Vector2 = triangle[0]
	var B:Vector2 = triangle[1]
	var C:Vector2 = triangle[2]
	
	# Construct the matrix
	var matrix:Array = [
		[A.x, A.y, A.x * A.x + A.y * A.y, 1],
		[B.x, B.y, B.x * B.x + B.y * B.y, 1],
		[C.x, C.y, C.x * C.x + C.y * C.y, 1],
		[P.x, P.y, P.x * P.x + P.y * P.y, 1]
	]
	
	# Calculate the determinant
	var det = determinant_4x4(matrix)
	
	# Interpret the determinant
	# SO LONG AS THE TRIANGLE IS ORDERED COUNTERCLOCKWISE:
	# If determinant is positive, P is inside the circumcircle
	# If determinant is zero, P is on the circumcircle
	# If determinant is negative, P is outside the circumcircle
	if verifyCCW(triangle):
		return det > 0
	else:
		return det < 0

# Function to calculate the determinant of a 4x4 matrix
# Written by ChatGPT 4
func determinant_4x4(mat:Array):
	# Initialize the determinant to 0
	var det:float = 0.0
	
	# Loop over the first row
	for i in range(4):
		
		# Create a sub-matrix for the minor
		var sub_mat = []
		
		for j in range(1, 4):
			var row = []
			
			for k in range(4):
				if k != i:
					row.append(mat[j][k])
			
			sub_mat.append(row)
		
		# Calculate the minor
		var minor = determinant_3x3(sub_mat)
		
		# Calculate cofactor
		var cofactor = (-1 if i % 2 else 1) * minor
		
		# Add to the total determinant
		det += mat[0][i] * cofactor
	
	return det

# Function to calculate the determinant of a 3x3 matrix (helper function for the 4x4 version)
# Written by ChatGPT 4
func determinant_3x3(mat:Array) -> float:
	return mat[0][0] * (mat[1][1] * mat[2][2] - mat[1][2] * mat[2][1]) \
		 - mat[0][1] * (mat[1][0] * mat[2][2] - mat[1][2] * mat[2][0]) \
		 + mat[0][2] * (mat[1][0] * mat[2][1] - mat[1][1] * mat[2][0])

# Adjusted means that it will extend the bounding box by 10px in all directions,
# to add a little bit of wiggle room.
func getBoundingBox(points, adjusted:bool=true) -> Rect2:
	# Can't just initialize these as zero, in case the actual min/max is on
	# the wrong side of zero, and it would never find the actual extreme, and
	# would think that 0 is the extreme, where it could have been constrained more.
	var minX:float = points[0].x
	var minY:float = points[0].y
	var maxX:float = points[0].x
	var maxY:float = points[0].y
	
	# For each point, if any of its coordinates are outside the extremes of the
	# current bounding box, then move the bounding box to be that size.
	for point in points:
		minX = point.x if point.x < minX else minX
		minY = point.y if point.y < minY else minY
		
		maxX = point.x if point.x > maxX else maxX
		maxY = point.y if point.y > maxY else maxY
	
	# The width and height are equal to the difference between the end and the
	# beginning of the box.
	var w:float = maxX - minX
	var h:float = maxY - minY
	
	
	# Add a little bit to the size of the box, in pixels
	var tolerance:float = 5
	if adjusted:
		minX -= tolerance
		minY -= tolerance
		
		# Times two because it has to account for the -10 on the min side, and
		# also add 10 on the max side.
		w += tolerance*2
		h += tolerance*2
	
	var boundingBox:Rect2 = Rect2(minX, minY, w, h)
	
	if displayBoundingBox: showBoundingBox(boundingBox)
	
	#print("Area of bounding box: ", w*h)
	
	return boundingBox

# A right triangle that starts at the top left corner of the bounding box, and
# extends twice the length and width.
func getSuperTriangle(box:Rect2):
	
	var p1:Vector2 = box.position - Vector2(box.size.x*0.5, 0)
	var p2:Vector2 = box.position + Vector2(box.size.x*1.5, 0)
	var p3:Vector2 = box.position + Vector2(box.size.x*0.5, box.size.y*2)
	
	var superTriangle:Array = [p1, p2, p3]
	
	if displayBoundingBox: showSuperTriangle(superTriangle)
	
	#print("Area of super triangle: ", calculateTriangleArea(p1, p2, p3))
	
	return superTriangle

# Written by ChatGPT 4
func calculateTriangleArea(point1:Vector2, point2:Vector2, point3:Vector2) -> float:
	var area = 0.5 * abs((point1.x * point2.y + point2.x * point3.y + point3.x * point1.y) -
						 (point1.y * point2.x + point2.y * point3.x + point3.y * point1.x))
	return area

# Returns true if a triangle's points are (correctly) arranged in
# counterclockwise order.
func verifyCCW(triangle:Array) -> bool:
	var a = triangle[0]
	var b = triangle[1]
	var c = triangle[2]
	
	return (b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y) > 0

func showBoundingBox(box:Rect2):
	$BoundingBoxLine.clear_points()
	
	$BoundingBoxLine.add_point(box.position)
	$BoundingBoxLine.add_point(box.position + Vector2(box.size.x, 0))
	$BoundingBoxLine.add_point(box.end)
	$BoundingBoxLine.add_point(box.position + Vector2(0, box.size.y))
	$BoundingBoxLine.add_point(box.position)

func showSuperTriangle(tri:Array):
	$SuperTriangleLine.clear_points()
	
	$SuperTriangleLine.add_point(tri[0])
	$SuperTriangleLine.add_point(tri[1])
	$SuperTriangleLine.add_point(tri[2])
	$SuperTriangleLine.add_point(tri[0])

func showCircumcircle(tri:Array):
	for child in self.get_children():
		if child is Polygon2D and child.name != "Polygon2D":
			child.queue_free()
	
	for i in range(0, 50):
		for j in range(0, 50):
			var d = $Polygon2D.duplicate()
			d.position = Vector2(i*10-250, j*10-250)
			
			
			if inCircumcircleOf(tri, d.position):
				d.color = Color(0, 1, 0, 0.1)
			else:
				d.color = Color(1, 0, 0, 0.1)
			
			self.add_child(d)

func drawTriangle(tri:Array):
	var line = Line2D.new()
	
	line.default_color = Color(randf(), randf(), randf())
	line.width = 2
	
	line.add_point(tri[0])
	line.add_point(tri[1])
	line.add_point(tri[2])
	line.add_point(tri[0])
	
	self.add_child(line)

func drawEdge(edge:Array, col=Color(randf(), randf(), randf())):
	var line = Line2D.new()
	
	line.default_color = col
	line.width = 2
	
	line.add_point(edge[0])
	line.add_point(edge[1])
	
	if col.r == 1:
		line.z_index = 99
	
	self.add_child(line)

func rmLines():
	for child in self.get_children():
		if child.name != "BoundingBoxLine" and child.name != "SuperTriangleLine":
			if child is Line2D:
				child.queue_free()

func _input(event):
	if Input.is_action_pressed("enterKey"):
		Events.wait_confirmation.emit()
