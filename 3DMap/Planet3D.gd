extends MeshInstance

onready var cam = get_node("../../CameraGimbal")

func area_input():
	cam.snappos = translation/10
	cam.zoom(5)
