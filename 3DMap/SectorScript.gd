extends MeshInstance

onready var cam = get_node("../../../CameraGimbal")

func area_input():
	#imported origin is incorrect
	cam.snappos = (get_parent().translation)/10 #because its parent galaxy is 0.1 scaled
	cam.zoom(10)
