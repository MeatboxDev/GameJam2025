## Takes in a vector, and returns only it's x and z coordinates
static func xyz_to_xz(vec: Vector3) -> Vector2:
	return Vector2(vec.x, vec.z)


## Gives the length of the vector composed of the x, z components
static func xz_length(vec: Vector3) -> float:
	return xyz_to_xz(vec).length()


## Takes in a vector, and normalizes ONLY the x and z coordinates
static func normalize_xz(vec: Vector3, magnitude: float = 1.0) -> Vector3:
	var v: Vector2 = xyz_to_xz(vec).normalized()
	return Vector3(v.x * magnitude, vec.y, v.y * magnitude)


## Makes the XZ coordinates move towards a point at a speed
static func move_toward_xz(vec: Vector3, to: Vector3, speed: float) -> Vector3:
	return vec.move_toward(Vector3(to.x, vec.y, to.z), speed)
