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
