extends Control


onready var animplayer := $"AnimationPlayer"
onready var lst = $"InspectPanel/DataWindow/ScrollContainer/VBoxContainer"

var isolar = 0
var cache = {}

onready var console = $"../Console"

var on = false
var shift = false
func _on_Button_pressed() -> void:
	if on:
		on=false
		animplayer.play("in")
	else:
		on=true
		animplayer.play("out")

func listpress(button):
	if button.selected:
		button.selected = false
	else:
		button.selected = true
	if not shift:
		for c in lst.get_children():
			if c.name != button.name:
				c.selected = false

	for c in lst.get_children():
		if c.selected:
			if not c.solar in cache.keys(): cache[c.solar] = {}
			if c.planetdata: #is a planet
				if not c.planetdata[0] in cache[c.solar].keys():
					var data = Database.GALACTIC_DATA[int(round(float(c.solar)/100))][c.solar][c.planetdata[0]]
					cache[c.solar][c.planetdata[0]] = data
			elif c.shipdata: #is a ship
				if not c.shipdata[4] in cache[c.solar].keys():
					var data = Database.GALACTIC_DATA[int(round(float(c.solar)/100))][c.solar][c.shipdata[4]]
					cache[c.solar][c.shipdata[4]] = data
		else:
			if c.solar in cache.keys():
				if c.planetdata:
					if c.planetdata[0] in cache[c.solar].keys():
						cache[c.solar].erase(c.planetdata[0])
				if c.shipdata:
					if c.shipdata[4] in cache[c.solar].keys():
						cache[c.solar].erase(c.shipdata[0])
func _process(delta: float) -> void:
	if Input.is_action_pressed("shift"):
		print("shift")
		shift = true
	else: shift = false
	for button in lst.get_children():
		if button.selected:
			button.modulate = lerp(button.modulate,Color(2,2,2,1.0),15*delta)
		else:
			button.modulate = lerp(button.modulate,Color(1.0,1.0,1.0,1.0),15*delta)

### BUTTONS ###
func _on_Dispatch_pressed():
	var selected_solar = isolar
	var input = "Dispatch Ships to SECTOR "+str(selected_solar)
	for solar in cache.keys():
		for object in cache[solar].keys():
			var object_tags = object.split("-")
			if object_tags[0] == "SHIP":
				# This section determines the distance between the solars, the path, etc.
				var ship_speed = cache[solar][object]["SPEED"]
				var destination = [] #[system,0,solar spec]
				var start = []
				for i in selected_solar:
					destination.append(int(i))
				for i in str(solar):
					start.append(int(i))
				#Simpler option. Is the destination in the same solar? If so, its easy to calculate:
				var solar_range = []
				if destination[0] == start[0]: #same system
					if abs(destination[2]-start[2]) <= ship_speed:
						if start[2] > destination[2]:
							var s = range(int(selected_solar),solar)
							var i = s.size() - 1
							while i >= 0:
								solar_range.append(int(s[i]))
								i -= 1
						if destination[2] > start[2]:
							solar_range = range(solar,int(selected_solar))
							solar_range.remove(0)
							solar_range.append(int(selected_solar))
					else:
						console.command_response(input,"Solar is out of reach for "+object+"!")
						return
				else: #not same system
					if destination[0] in Database.SYSTEM_SIBLINGS[start[0]]: #neighbouring system
						#calculates the destinations distance to the border and the starts, adds them and sees if its a short enough distance
						if (abs(destination[2]-5)+abs(start[2]-5))+1 <= ship_speed:
							for s in range(solar,int(str(start[0])+"05")):
								solar_range.append(int(s))
							solar_range.append(int(str(start[0])+"05"))
							solar_range.append(int(str(destination[0])+"05"))
							var r = range(int(selected_solar),int(str(destination[0])+"05"))
							var i = r.size() - 1
							while i >= 0:
								solar_range.append(int(r[i]))
								i -= 1
						else:
							console.command_response(input,"Solar is out of reach for "+object+"!")
							return
					else:
						console.command_response(input,"Solar is out of reach for "+object+"!")
						cache = {}
						return
				Network.move_ship_along_path(solar,solar_range,int(selected_solar),object,input)
			else:
				console.command_response(input,"Some of the selected objects are not moveable and remain in their original sector.")
				cache = {}
				return
	cache = {}
	return
	
func _on_Invade_pressed():
	var input = "INVASION ORDER"
	var contested_planet = ""
	for s in cache.keys():
		for obj in cache[s].keys():
			if not "-" in obj:
				if contested_planet == "": contested_planet = obj
				else:
					cache = {}
					console.command_response(input,"There are multiple target planets selected, so the order did not carry out.")
	for system in Database.GALACTIC_DATA.keys():
		for solar in Database.GALACTIC_DATA[system].keys():
			for object in Database.GALACTIC_DATA[system][solar].keys():
				if contested_planet == object: #this is the planet we're invading
					if Database.GALACTIC_DATA[system][solar][contested_planet]["Owner"] != Database.PLAYERS[Network.active_id][0]: #we own this planet already
						if solar in cache.keys(): #if there's selected ships where the planet is
							if Database.GALACTIC_DATA[system][solar][contested_planet]["Owner"] == "":
								console.command_response(input,"Colonized "+contested_planet+". Buildings can now be constructed here.")
								Network.packets.append("STAT-"+str(contested_planet)+"-Owner-"+str(Database.PLAYERS[Network.active_id][0])+"-str")
								Database.GALACTIC_DATA[system][solar][contested_planet]["Owner"] = Database.PLAYERS[Network.active_id][0]
								return
							var invading_shipsIDs = []
							for ship in cache[solar]:
								invading_shipsIDs.append(ship)
							if contested_planet in Database.LAND_QUEUE.keys(): #there's already an invasion happening
								Network.join_land_battle(solar,contested_planet,invading_shipsIDs)
								cache = {}
								console.command_response(input,"Reinforcements joining The Siege of "+contested_planet+".")
							else:
								Network.start_land_battle(solar,contested_planet,invading_shipsIDs)
								cache = {}
								console.command_response(input,"The Siege of "+contested_planet+" has begun.")
								Network.client.send_match_state({"SENDER_ID":Database.LOCAL_ID,"MESSAGE":contested_planet+" is being invaded."},7)
						else:
							emit_signal("com_response",input,"Selected ships are not in the area!")
							return
					else:
						emit_signal("com_response",input,"You already control this planet!")
						return
