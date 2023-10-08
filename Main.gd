extends Control

var log_update = load("res://Instances/log_update.tscn")
var log_instance = load("res://Instances/Log_Instance.tscn")

onready var ResourcesPanel = $"Resources Panel"

var query_data

var client: Node
signal log_update(text)

var datamodule_MODE = "PLANETS"

onready var terminal = $Console/Background/MarginContainer/SectionsContainer/InputContainer/HBoxContainer/Input
onready var consolelog = $Console/Background/MarginContainer/SectionsContainer/History/ScrollContainer/VBoxHistory
onready var titlelabel = $"Side Panel/InspectPanel/TitleLabel"
onready var metalLabel = $"Resources Panel/InspectPanel/ResourcesButton/MetalsButton/MetalsAmount"
onready var fuelLabel = $"Resources Panel/InspectPanel/ResourcesButton/MetalsButton/FuelAmount"
onready var energyLabel = $"Resources Panel/InspectPanel/ResourcesButton/MetalsButton/EnergyAmount"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	client = get_tree().get_root().get_child(3).get_child(1)
	client.connect("log_update",self,"log_update")
	Network.connect("start_game_org", self, "_start_game_org")
	Network.connect("start_loaded_game",self,"_start_loaded_game")
	Network.connect("log_update",self,"log_update")
	Network.connect("activate_console",self,"activate_console")
	Network.connect("deactivate_console",self,"deactivate_console")
	Network.connect("refresh_ui",self,"refresh_ui")
	Network.connect("refresh_map",self,"refresh_map")
	Network.connect("win_screen",self,"win_screen")
	
	#For all UI buttons
	for first_child in get_children():
		for second_child in first_child.get_children():
			if "Button" in second_child.name:
				if "-" in second_child.name:
					second_child.connect("button_down",self,"button_pressed",[second_child])
					second_child.connect("button_up",self,"button_released",[second_child])
				second_child.connect("mouse_entered",self,"mouse_entered",[second_child])
				second_child.connect("mouse_exited",self,"mouse_exited",[second_child])
			for third_child in second_child.get_children():
				if "Button" in third_child.name:
					if "-" in second_child.name:
						third_child.connect("button_down",self,"button_pressed",[third_child])
						third_child.connect("button_up",self,"button_released",[third_child])
					third_child.connect("mouse_entered",self,"mouse_entered",[third_child])
					third_child.connect("mouse_exited",self,"mouse_exited",[third_child])
func refresh_map():
	get_node("3DMap/ViewportContainer/Viewport/3DMap").refresh_map()


var fadedin = false
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("mouse"):
		$AudioStreamPlayer.play()
	if Database.global_turn_counter == 0:
		if not $Music.playing:
			$Music.stream = load("res://OST/War Music 1.wav")
			$Music.playing = true
	elif Database.global_turn_counter >= 10 and Database.global_turn_counter < 20:
		if not $Music.playing:
			$Music.stream = load("res://OST/War Music 2.wav")
			$Music.playing = true
	elif Database.global_turn_counter >= 30:
		if not $Music.playing:
			$Music.stream = load("res://OST/War Music 3.wav")
			$Music.playing = true
func _on_AudioStreamPlayer_finished() -> void:
	$AudioStreamPlayer.playing = false

func refresh_ui(aID):
	$PopupWindow.visible = false
	titlelabel.text = ""
	for child in dataList.get_children():
		child.queue_free()
	ships_list = []
	planets_list = []
	get_node("3DMap/ViewportContainer/Viewport/3DMap").refresh_map()
	ResourcesPanel.update_panel()
	ResourcesPanel.update_cell(Database.PLAYERS[aID][1],"metals")
	ResourcesPanel.update_cell(Database.PLAYERS[aID][2],"fuel")
	ResourcesPanel.update_cell(Database.PLAYERS[aID][3],"energy")
	get_node("3DMap/ViewportContainer/Viewport/3DMap").refresh_map()
	

#system,username,id,quadrant,core
func starting_inventory(username,id,system_name):
	InventoryManager.add_ship(id,"DESTROYER",system_name)
	InventoryManager.add_ship(id,"DESTROYER",system_name)
	InventoryManager.add_supplier(id,"FREIGHTER",system_name)
	if system_name == "Botra": #Botra Player
		Database.GALACTIC_DATA["Botra"]["Boshaa"]["Owner"] = username
		InventoryManager.add_building(id,"FUEL_MINE","Boshaa")
		InventoryManager.add_building(id,"METALS_MINE","Boshaa")
		InventoryManager.add_building(id,"ENERGY_MINE","Boshaa")
		InventoryManager.add_building(id,"GARRISON","Boshaa")
	if system_name == "Anaxes": #Anaxes Player
		Database.GALACTIC_DATA["Anaxes"]["Anenia"]["Owner"] = username
		InventoryManager.add_building(id,"GARRISON","Anenia")
		InventoryManager.add_building(id,"FUEL_MINE","Anenia")
		InventoryManager.add_building(id,"METALS_MINE","Anenia")
		InventoryManager.add_building(id,"ENERGY_MINE","Anenia")
	for i in range(5):
		InventoryManager.add_building(id,"MILITARY_STATION",system_name)
	ResourcesPanel.update_metals(100,id)
	ResourcesPanel.update_fuel(5000,id)
	ResourcesPanel.update_energy(500,id)

## FOR LOADING GAMES
#func _start_loaded_game():
#	Network.next_turn(Network.active_id,Database.PLAYERS[Network.active_id][0])


## (_start_game_org) Adds the starting buildings, ships, and resources for all players.
# => USER: host/client
# => RESULT: Calls start_turn_system.
func _start_game_org():
	log_update("Organizing Game Data before Start")
	for planet in Database.PLANETS.keys():
		var username = Database.PLANETS[planet]
		for id in Database.PLAYERS.keys(): #0 or 1
			if Database.PLAYERS[id][0] == username:
				starting_inventory(username,id,planet)
	if Database.LOCAL_ID == 0:
		Network.next_player(1)

func log_update(text):
	var log_up = log_update.instance()
	log_up.log_update(text)
	consolelog.add_child(log_up)


#### MAP ####
signal refresh_map(galactic,battle,land)

#Any of the map system buttons pressed
onready var sidepanel_title = $"Side Panel/InspectPanel/TitleLabel"
func _on_SystemButton_pressed(system_name):
	var inspect_data
	for system in Database.GALACTIC_DATA.keys():
		for solar in Database.GALACTIC_DATA[system].keys():
			if solar == int(system_name):
				inspect_data = Database.GALACTIC_DATA[system][solar]
	sector_inspect_desc(system_name,inspect_data)

var ships_list = []
var planets_list = []
func sector_inspect_desc(system_name,inspect_data):
	sidepanel_title.text = "SECTOR "+system_name
	$"Side Panel".solar = int(system_name)
	ships_list = []
	planets_list = []
	for object in inspect_data.keys():
		if "-" in object: #not a planet
			var template = [object,false,inspect_data[object]["CLASS"],int(system_name)] #name, owned, class
			var object_tags = object.split("-")
			if inspect_data[object]["OWNER"] == Network.active_id:
				template[1] = true
			ships_list.append(template)
		else:
			var template = [object,"",0,0,0,0,0,int(system_name)] #planetname,owner,#m-mines,#f-mines,#e-mines,factories,garrisons
			if inspect_data[object]["Owner"] != "":
				for id in Database.PLAYERS.keys():
					if Database.PLAYERS[id][0] == inspect_data[object]["Owner"] and id == Network.active_id: #we own this
						template[1] = inspect_data[object]["Owner"]
			for building in inspect_data[object]:
				var tags = building.split("-")
				if tags[0] == "BUILDING":
					if tags[1] == "METALS_MINE":
						template[2] += 1
					elif tags[1] == "FUEL_MINE":
						template[3] += 1
					elif tags[1] == "ENERGY_MINE":
						template[4] += 1
					elif tags[1] == "MILITARY_STATION":
						template[5] += 1
					elif tags[1] == "GARRISON":
						template[6] += 1
			planets_list.append(template)
	show_acquired_data()
#### TURN SYSTEM ####
func deactivate_console():
	terminal.editable = false
func activate_console():
	terminal.editable = true

var shipreading = preload("res://Instances/ShipReading.tscn")
var planetreading = preload("res://Instances/PlanetReading.tscn")
onready var dataList = $"Side Panel/InspectPanel/DataWindow/ScrollContainer/VBoxContainer"
func show_acquired_data():
	for child in dataList.get_children():
		child.queue_free()
	if datamodule_MODE == "SHIPS":
		for entry in ships_list:
			var newreading = shipreading.instance()
			newreading.shipdata = entry.duplicate()
			newreading.solar = entry[3]
			var ship_tags = entry[0].split("-")
			var ship_type = ship_tags[1]
			ship_type = ship_type.replace("_"," ")
			newreading.get_node("ShipTypeLabel").text = entry[2]+" "+ship_type
			newreading.get_node("HBoxContainer/ID").text = ship_tags[2]
			if entry[1]: #we own it
				newreading.get_node("HBoxContainer/Body").texture_normal = load("res://GUI_Assets/Friendly.png")
				newreading.get_node("HBoxContainer/End").texture = load("res://GUI_Assets/FriendlyEnd.png")
			else:
				newreading.get_node("HBoxContainer/Body").texture_normal = load("res://GUI_Assets/Enemy.png")
				newreading.get_node("HBoxContainer/End").texture = load("res://GUI_Assets/EnemyEnd.png")
			if entry[2] == "ESS":
				newreading.get_node("Icon").texture = load("res://GUI_Assets/SupplyIcon.png")
			else:
				newreading.get_node("Icon").texture = load("res://GUI_Assets/CombatShipIcon.png")
			dataList.add_child(newreading)
			newreading.get_child(0).get_child(0).connect("pressed",$"Side Panel","listpress",[newreading])
			
	elif datamodule_MODE == "PLANETS":
		for entry in planets_list:
			var newreading = planetreading.instance()
			newreading.planetdata = entry.duplicate()
			newreading.solar = entry[7]
			newreading.get_node("PlanetName").text = entry[0]
			if entry[1] != "": #we own it
				newreading.get_node("HBoxContainer/Planet").texture_normal = load("res://GUI_Assets/FriendlyPlanet.png")
				newreading.get_node("HBoxContainer/PlanetEnd").texture = load("res://GUI_Assets/FriendlyPlanet End.png")
			else:
				newreading.get_node("HBoxContainer/Planet").texture_normal = load("res://GUI_Assets/EnemyPlanet.png")
				newreading.get_node("HBoxContainer/PlanetEnd").texture = load("res://GUI_Assets/EnemyPlanet End.png")
			dataList.add_child(newreading)
			newreading.get_child(0).get_child(0).connect("pressed",$"Side Panel","listpress",[newreading])

func _on_ShipsButton_pressed() -> void:
	datamodule_MODE = "SHIPS"
	show_acquired_data()


func _on_PlanetsButton_pressed() -> void:
	datamodule_MODE = "PLANETS"
	show_acquired_data()


func _on_StationAmount_pressed() -> void:
	#Show popup
	$PopupWindow.visible = true
	for child in $PopupWindow.get_children():
		if child.name != "Textures":
			child.visible = false
	$PopupWindow/TextMode.visible = true
	var text = ""
	$PopupWindow/TextMode/Data.text = text
	var total_slots = Database.PRODUCTION_QUEUE[Network.active_id]["slots"]
	var available_slots = total_slots
	for product in Database.PRODUCTION_QUEUE[Network.active_id]["production"]:
		available_slots -= Database.SHIPS[product[0]]["REQUIRED_STATIONS"]*product[1]
	text += str(available_slots)+" available military stations."
	if Database.PRODUCTION_QUEUE[Network.active_id]["production"].size() > 0:
		for product in Database.PRODUCTION_QUEUE[Network.active_id]["active_production"]:
			var used_slots = Database.SHIPS[product[0]]["REQUIRED_STATIONS"]*product[3]
			text += "\n"+"-"+str(used_slots)+" (x"+str(product[3])+" "+product[0]+")"
	$PopupWindow/TextMode/Data.text = text

var p = false

### GLOW ###
var obj = {} #[button,pressed,glow]
func _physics_process(delta: float) -> void:
	if obj != null:
		for button in obj.keys():
			if obj[button][1]:
				button.modulate = lerp(button.modulate,Color(2,2,2,1.0),15*delta)
			else:
				button.modulate = lerp(button.modulate,Color(1.0,1.0,1.0,1.0),15*delta)
			if obj[button][0]:
				button.rect_scale = lerp(button.rect_scale,Vector2(0.8,0.8),10*delta)
			else:
				button.rect_scale = lerp(button.rect_scale,Vector2(1.0,1.0),10*delta)
func button_pressed(button):
	if not button in obj.keys():
		obj[button] = [true,false]
	else:
		obj[button][0] = true
func button_released(button):
	if button in obj.keys():
		obj[button][0] = false
func mouse_entered(button):
	if not button in obj.keys():
		obj[button] = [false,true]
	else:
		obj[button][1] = true
func mouse_exited(button):
	if button in obj.keys():
		obj[button][1] = false


func _on_SettingsButton_pressed() -> void:
	$"Side Panel/Settings".visible = true


func _on_PanSensSlider_value_changed(value: float) -> void:
	print(value)
	get_node("3DMap/ViewportContainer/Viewport/3DMap/CameraGimbal").panspeed = value


func _on_ZoomSensSlider_value_changed(value: float) -> void:
	print(value)
	get_node("3DMap/ViewportContainer/Viewport/3DMap/CameraGimbal").zoomspeed = value
