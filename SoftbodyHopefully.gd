extends Polygon2D

# The amount of substance
export (float) var amountOfSubstance_n = 1000
export (float) var idealGasConstant_R  = 8.31446261815324; # 8.31446261815324 is the real life universal gas constant

# This allows us to create the rigidbodies whenever we need to
export (PackedScene) var PhysicsPoint

# This allows us to create the SPRINGS whenever we need to
export (PackedScene) var Spring

# Lets us keep track of the physics points and springs based on an iterable value
var allPhysicsPoints = []
var allSprings = []

func _ready1():
	# Create all the points that can fall and stuff for physics
	initiatePoints()

func _process1(delta):
	# Every frame, move the corners of the polygon to the corresponding
	# rigidbodies
	updatePoints()
	
	# Create two lists of X and Y positions of the points in this polygon,
	# and then get the two arrays back
	var lists = createXYList()
	
	# Find the area of the shape, which mostly uses magic:
	# https://www.geodose.com/2021/09/how-calculate-polygon-area-unordered-coordinates-points-python.html
	var areaOfShape = shoelaceArea(lists[0], lists[1])
	
	# Find the pressure inside the shape, given the ideal gas law:
	# https://en.wikipedia.org/wiki/Ideal_gas_law
	var pressureInShape = getPressure(areaOfShape)
	
	applyIndividualForcesFromPressure(pressureInShape)

func applyIndividualForcesFromPressure(pressure):
	var avgPoint = Vector2()
	for point in self.polygon:
		avgPoint += point
	avgPoint /= len(self.polygon)
	
	for i in len(allPhysicsPoints)-1:
		
		var difference = allPhysicsPoints[i].position - avgPoint
		
		allPhysicsPoints[i].linear_velocity += difference*pressure

# Create the correct amount of rigidbodies for all the points,
# and put them in the correct positions
func initiatePoints():
	var counter = 0
	for point in self.polygon:
		# Initiate a new one in memory
		var newPoint  = PhysicsPoint.instance()
		var newSpring = Spring.instance()
		
		# Once we've instantiated it, add it to
		# the universe, as a child of self
		self.add_child(newPoint)
		
		# And add it to the array so we can easily remember which are which
		allPhysicsPoints.append(newPoint)
		allSprings.append(newSpring)
		
		# Put the new point where it should be
		newPoint.position = Vector2(point.x, point.y)
		
		# Set the CURRENT loop's spring's PointA to THIS loop's point
		newSpring.PointA = newPoint.get_path()
		
		# If there's already at least one other point that we've created
		if counter > 0:
			# Make the PREVIOUS spring's PointB THIS loop's point. In this way,
			# All points will be locked to the next one by a spring.
			allSprings[counter-1].PointB = newPoint.get_path()
			
			# Now that it has both it's points, we can add it to the universe
			self.add_child(allSprings[counter-1])
		
		# If we're on the last point
		if counter == len(self.polygon) - 1:
			# We won't have a chance to set THIS point's B to anything next
			# loop, since this IS the last loop. Therefore, we connect THIS spring's
			# PointB to the very first point.
			newSpring.PointB = allPhysicsPoints[0].get_path()
			
			# Now that it has both it's points, we can add it to the universe
			self.add_child(newSpring)
		
		#newSpring.queue_free()
		
		# Would use i, but in this loop keeping
		# the point itself is more convenient
		counter += 1

# This is called each frame; it will update the points in the polygon to match
# the positions of the rigidbodies
func updatePoints():
	for i in len(self.polygon):
		# For every item in our polygon, set the position of it to the same
		# place as the corresponding rigidbody
		self.polygon[i] = allPhysicsPoints[i].position

# Go through every point in this Node's polygon, and separate the X and Y
# values into two different arrays, just for convenience
func createXYList():
	var xList = []
	var yList = []
	
	for point in self.polygon:
		xList.append(point.x)
		yList.append(point.y)
	
	return[xList, yList]

# Find the area of the shape, magically
func shoelaceArea(xList:Array, yList:Array):
	# Keep track of... something important- don't question the code ._.
	var a1 = 0
	var a2 = 0
	
	# This makes sure that we can link our last point
	# back to the first one, because they are connected
	xList.append(xList[0])
	yList.append(yList[0])
	
	for i in range(0, len(xList)-1):
		# Criss-cross-kinda-thing multiply them, it's weird but it works
		a1 += xList[i] * yList[i+1]
		a2 += yList[i] * xList[i+1] # Fucking hell i spent an hour only to realize that this a2 was previously an a1 and that was fucking me over LMFAO
		
	var area = abs(a1-a2)/2
	
	return area

func getPressure(volume_V):
	# In real life, P = nRT/V, where:
	
	# P is the pressure force (which we're looking for)
	# n is the amount of substance, which we don't care about
	# T is the temperature, which we don't care about
	# R is the ideal gas constant, which we don't care about
	# V is the volume (which we have as an argument)
	
	# So as such, our equation for P would look like this:
	# P = nR/V
	
	var pressure = amountOfSubstance_n * idealGasConstant_R / volume_V
	return pressure
