extends Spatial

onready var animplayer = get_node("../../../AnimationPlayer")
onready var animplayerp = get_node("../../../AnimationPlayerP")
onready var vbox = get_node("../../../VBoxContainer")

var bubblepos = {
	#y from -0.471 to 0.938
	101: Vector3(-0.029,-0.1,5.041),
	102: Vector3(-0.914,0.54,4.572),
	103: Vector3(0.947,-0.2,5.204),
	104: Vector3(-1.311,-0.462,5.962),
	105: Vector3(-0.751,0.62,3.596),
	
	201: Vector3(-5.176,0,5.89),
	202: Vector3(-4.472,0.3,5.583),
	203: Vector3(-5.682,-0.31,6.197),
	204: Vector3(-5.862,0.75,5.366),
	205: Vector3(-3.63,0.5,4.505),
	
	301: Vector3(-6.693,-0.12,7.516),
	302: Vector3(-6.169,0.92,7.859),
	303: Vector3(-5.357,-0.33,8.292),
	304: Vector3(-8.463,0.44,5.998),
	305: Vector3(-8.553,0.1,5.348),
	
	401: Vector3(-10.757,-0.21,6.233),
	402: Vector3(-10.414,0.86,5.836),
	403: Vector3(-8.138,-0.28,8.437),
	404: Vector3(-7.127,0.41,9.213),
	405: Vector3(-6.278,0.3,10.116),
	
	501: Vector3(-10.594,-0.35,2.386),
	502: Vector3(-11.01,0.874,2.838),
	503: Vector3(-11.317,-0.32,3.398),
	504: Vector3(-9.872,-0.18,1.844),
	505: Vector3(-9.005,0.47,1.7),
	
	601: Vector3(-7.145,0.64,1.284),
	602: Vector3(-6.711,0.62,1.465),
	603: Vector3(-6.458,-0.41,1.772),
	604: Vector3(-8.337,0.51,1.266),
	605: Vector3(-9.005,0.58,1.194),
	
	701: Vector3(-4.544,0,3.542),
	702: Vector3(-4.038,-0.08,3.542),
	703: Vector3(-5.754,0.91,3.181),
	704: Vector3(-3.478,0.67,3.398),
	705: Vector3(-2.936,-0.82,3.705),
	
	801: Vector3(-1.925,-0.34,9.105),
	802: Vector3(-1.383,0.51,9.502),
	803: Vector3(-2.593,0.11,9.755),
	804: Vector3(-0.932,-0.14,7.877),
	805: Vector3(-2.232,0.79,7.064),
	
	901: Vector3(0.802,0,8.13),
	902: Vector3(1.001,-0.46,8.563),
	903: Vector3(0.604,0.21,7.624),
	904: Vector3(1.38,0.92,9.069),
	905: Vector3(1.32,-0.45,6.667),
}

func window(sectorid):
	if stepify(get_node("../../../PlanetLabel").rect_scale.x,0.01) != 0:
		animplayerp.play("PlanetLabelOut")
	animplayer.play("WindowIn")
	get_node("../../../VBoxContainer").visible = true
	for i in range(5):
		vbox.get_child(i).text = "Sector "+str(sectorid)+"0"+str(i+1)
func close_window():
	animplayer.play("WindowOut")

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("escape"):
		close_window()

func _ready() -> void:
	# Create lanes between planets.
	var MAP = Database.MAP
	var ids = MAP.get_point_connections(1)
	for child in vbox.get_children():
		child.connect("pressed",self,"sector_pressed",[child])
	#var instance = load("res://MapEnv.tscn")
	#$Galaxy.add_child(instance.instance())
onready var mainui = get_node("../../../..")
func sector_pressed(button):
	close_window()
	var s = button.text.replace(" ","").replace("Sector","")
	var inspect_data
	for system in Database.GALACTIC_DATA.keys():
		for solar in Database.GALACTIC_DATA[system].keys():
			if solar == int(s):
				inspect_data = Database.GALACTIC_DATA[system][solar]
	mainui.sector_inspect_desc(s,inspect_data)

onready var planetlabel = get_node("../../../PlanetLabel/Label")
var second_anim = ""
func planet_name(planetname):
	if stepify(get_node("../../../Window").rect_scale.x,0.01) != 0:
		close_window()
	animplayerp.play("PlanetLabelIn")
	planetlabel.text = planetname

func release_console_focus():
	var inp = get_node("../../../../Console").get_node("Background/MarginContainer/SectionsContainer/InputContainer/HBoxContainer/Input")
	inp.release_focus()
	
func battle_popup(data,solar):
	var popupwindow = get_node("../../../../PopupWindow")
	popupwindow.battle_intel(data,solar)

func refresh_map():
	var battle = Database.BATTLE_QUEUE
	$CameraGimbal._ready()
	for child in get_child(0).get_children():
		if "_" in child.name:
			child.queue_free()
	for b in battle.keys():
		var bubble = preload("res://Instances/3DBattleBubble.tscn").instance()
		get_child(0).add_child(bubble)
		bubble.name = "BATTLE_"+str(b)
		bubble.scale = Vector3(0.05,0.05,0.05)
		bubble.translation = bubblepos[int(b)]
		bubble.data = Database.BATTLE_QUEUE[int(b)]
		bubble.solar = b
	for child in get_child(0).get_children():
		if "_" in child.name:
			child.refresh_colour()
