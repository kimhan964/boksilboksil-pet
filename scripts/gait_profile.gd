extends RefCounted
# Two foot contacts per cycle. Short-legged pets take smaller, quicker steps.
const PERIOD=[1.55,1.94,1.40,2.02,1.87,1.69,2.38,1.98,1.66,1.51,1.30,2.41,1.69,1.87,2.30,2.09]
const LIFT=[1.5,.65,1.1,.35,.65,.85,.45,.55,.7,.9,.45,.4,.75,.7,.35,.5]
const SWAY=[.008,.012,.008,.012,.015,.008,.018,.025,.006,.012,.012,.022,.012,.012,.018,.035]
static func pose(species: int, phase: float, strength: float) -> Vector3:
	var step=phase*TAU
	# Compress during weight transfer; rise between foot contacts.
	return Vector3(-LIFT[species]*(1.0-cos(step*2.0))*.5,
		SWAY[species]*sin(step),-.009*cos(step*2.0))*strength
