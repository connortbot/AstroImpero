extends Node #AUTOLOADED ON START as "Database"

############### SPACE TERMINALS v0.9.5 ###############
## Created by Connor T. Loi ##

## Design Recipe for all functions ##

## (function) function purpose
# @param - param name: param value
# => USER: host or client, or both
# => RESULT: result or returned value of the function


############### MAIN AGENDA ###############
# Continue Map reform update
# Fix all game states for new GALACTIC_DATA structure
# Change movement and supply to astar pathing
############### MAIN AGENDA ###############


############### SPACE TERMINALS ###############



## Player Client-Specific Variables ##
var LOCAL_USERNAME = ""
var LOCAL_ID = 0

## Lobby Usernames ##
var USERNAMES = ["",""]

## PLANETS ##
var PLANETS = {
	"Botra": "",
	"Anaxes": ""
}

## PLAYERS ##
#ID: [username,metal,fuel,energy,active]
var PLAYERS = {
	0: ["",0,0,0,false],
	1: ["",0,0,0,false]
}

#Tracks movement and building queues (if it takes multiple turns)
#type, what turn it was started on
var PLAYER_QUEUE = {
	0: {},
	1: {}
}

#SOLAR ID: SIDE 1: {SHIPS:SHIPINFO}, SIDE 2: {SHIPS:SHIPINFO}
var BATTLE_QUEUE = {}
var evasion_rands = []

#PLANET ID: [all participating ship ids, [all garrison ids], TURN_STARTED
var LAND_QUEUE = {}

var global_id_counter = 0
var global_turn_counter = 0


var PRODUCTION_QUEUE = {
	0: {
		"slots": 0,
		"production": [], #[ship type, amount,spawn_solar]
		"active_production": [] #[ship type, turn started,spawn_solar,amount]
	},
	1: {
		"slots": 0,
		"production": [],
		"active_production": []
	}
}

var SUPPLY_SYSTEM = {
	0: {
		"QUOTA": 0,
		"SUPPLIER_SCORE": 0,
		"SUPPLY_LOSS": 0.0
	},
	1: {
		"QUOTA": 0,
		"SUPPLIER_SCORE": 0,
		"SUPPLY_LOSS": 0.0
	}
}

var GALACTIC_DATA = {
	"Anaxes": {
		"Anenia": {
			"Owner": "",
			"building_slots": 10
		}
	},
	"Agumuun": {
		"Ichiza": {
			"Owner": "",
			"building_slots": 6
		}
	},
	"Isaac": {
		"Las Elfar": {
			"Owner": "",
			"building_slots": 2
		}
	},
	"Riga": {
		"Taxalis": {
			"Owner": "",
			"building_slots": 3
		}
	},
	"Botra": {
		"Boshaa": {
			"Owner": "",
			"building_slots": 10
		}
	},
	"Autumn": {
		"Caesar": {
			"Owner": "",
			"building_slots": 2
		}
	}
}

var MAP = AStar.new()
func map():
	MAP.add_point(1,Vector3(-5,1,50)) #Anaxes
	MAP.add_point(2,Vector3(-45,6,34)) #Agumuun
	MAP.add_point(3,Vector3(42,-9,9)) #Isaac
	MAP.add_point(4,Vector3(-25,2,100)) #Riga
	MAP.add_point(5,Vector3(-105,-15,67)) #Botra
	MAP.add_point(6,Vector3(63,15,-25)) #Autumn

	### AGUMUUN CONNECTIONS ###
	MAP.connect_points(2, 1, true)
	MAP.connect_points(2, 4, true)
	MAP.connect_points(2, 5, true)
	MAP.connect_points(2, 6, true)

	MAP.connect_points(3,1,true)
	MAP.connect_points(5,4,true)
	var path = MAP.get_id_path(1,6)
	print(path)
	#MISSING: Edavellir, Sol, Fol, Pol, Ustoh, Naivoh, Yaowei, Hestea, Hosharri

# generating a lane -> midpoint = (-25,3.5,42)
# midheight -> (40,5,16) -> sqr(40^2+5^2+16^2)
# angle calc on chatgpt

func _ready() -> void:
	map()
	return

var SHIPS = {
	"DESTROYER": {
		"OWNER": 0,
		"CLASS": "ECC",
		
		"FUEL_USAGE": 60,
		"ENERGY_USAGE": 50,
		"REPAIR_METAL_USAGE": 10,
		
		"ATTACK": 10,
		"EVASION": 0.4,
		"ARMOR": 0.05,
		"HEALTH": 20,
		"MAX_HEALTH": 20,
		
		"RECENT_DAMAGE_OUTPUT": 0,
		"RECENT_TAKEN_DAMAGE": 0,
		
		"BATTALIONS": 3,
		"LEGIONS": 0,
		
		"PRESENCE": 5,
		
		"SPEED": 5,
		"MOVEABLE": true,
		
		"REQUIRED_STATIONS": 4,
		"REQUIRED_TURNS": 2,
	},
	"CRUISER": {
		"OWNER": 0,
		"CLASS": "ECC",
		
		"FUEL_USAGE": 100,
		"ENERGY_USAGE": 80,
		"REPAIR_METAL_USAGE": 15,
		
		"ATTACK": 10,
		"EVASION": 0.2,
		"ARMOR": 0.25,
		"HEALTH": 35,
		"MAX_HEALTH": 35,
		
		"RECENT_DAMAGE_OUTPUT": 0,
		"RECENT_TAKEN_DAMAGE": 0,
		
		"BATTALIONS": 5,
		"LEGIONS": 0,
		
		"PRESENCE": 8,
		
		"SPEED": 4,
		"MOVEABLE": true,
		
		"REQUIRED_STATIONS": 6,
		"REQUIRED_TURNS": 4,
	},
	"BATTLESHIP": {
		"OWNER": 0,
		"CLASS": "ECC",
		
		"FUEL_USAGE": 300,
		"ENERGY_USAGE": 220,
		"REPAIR_METAL_USAGE": 50,
		
		"ATTACK": 30,
		"EVASION": 0.05,
		"ARMOR": 0.4,
		"HEALTH": 150,
		"MAX_HEALTH": 150,
		
		"RECENT_DAMAGE_OUTPUT": 0,
		"RECENT_TAKEN_DAMAGE": 0,
		
		"BATTALIONS": 10,
		"LEGIONS": 1,
		
		"PRESENCE": 20,
		
		"SPEED": 3,
		"MOVEABLE": true,
		
		"REQUIRED_STATIONS": 12,
		"REQUIRED_TURNS": 6,
	},
	"DREADNOUGHT": {
		"OWNER": 0,
		"CLASS": "ECC",
		
		"FUEL_USAGE": 500,
		"ENERGY_USAGE": 325,
		"REPAIR_METAL_USAGE": 100,
		
		"ATTACK": 40,
		"EVASION": 0.0,
		"ARMOR": 0.7,
		"HEALTH": 200,
		"MAX_HEALTH": 200,
		
		"RECENT_DAMAGE_OUTPUT": 0,
		"RECENT_TAKEN_DAMAGE": 0,
		
		"BATTALIONS": 15,
		"LEGIONS": 2,
		
		"PRESENCE": 40,
		
		"SPEED": 2,
		"MOVEABLE": true,
		
		"REQUIRED_STATIONS": 15,
		"REQUIRED_TURNS": 8,
	}
}
var SUPPLIERS = {
	"FREIGHTER": {
		"OWNER": 0,
		"CLASS": "ESS",
		"REQUIRED_STATIONS": 1,
		"REQUIRED_TURNS": 3,
		
		"SUPPLIER_SCORE": 1000,
		"SUPPLY_LOSS_NEGATION": 0.0,
		"DEFENDER": false
	},
	"CONVOY": {
		"OWNER": 0,
		"CLASS": "ESS",
		"REQUIRED_STATIONS": 1,
		"REQUIRED_TURNS": 1,
		
		"SUPPLIER_SCORE": 200,
		"SUPPLY_LOSS_NEGATION": 0.0,
		"DEFENDER": false
	},
	"CORVETTE": {
		"OWNER": 0,
		"CLASS": "ESS",
		"REQUIRED_STATIONS": 2,
		"REQUIRED_TURNS": 3,
		
		"SUPPLIER_SCORE": 0,
		"SUPPLY_LOSS_NEGATION": 0.01,
		"DEFENDER": true
	},
	"FRIGATE": {
		"OWNER": 0,
		"CLASS": "ESS",
		"REQUIRED_STATIONS": 4,
		"REQUIRED_TURNS": 4,
		
		"SUPPLIER_SCORE": 0,
		"SUPPLY_LOSS_NEGATION": 0.025,
		"DEFENDER": true
	},
}

var BUILDINGS = {
	"FUEL_MINE": {
		"OWNER": 0,
		"PRODUCTION": 1200,
		"BUILD_TIME": 2
	},
	"METALS_MINE": {
		"OWNER": 0,
		"PRODUCTION": 100,
		"BUILD_TIME": 3
	},
	"ENERGY_MINE": {
		"OWNER": 0,
		"PRODUCTION": 800,
		"BUILD_TIME": 2
	},
	"GARRISON": {
		"OWNER": 0,
		"BATTALIONS": 5,
		"BUILD_TIME": 3
	},
	"MILITARY_STATION": {
		"OWNER": 0,
		"BUILD_TIME": 3
	}
}


func save(savenum):
	var save_game = File.new()
	save_game.open("user://savegame"+str(savenum)+".save",File.WRITE)
	
	var save_data = {
		"PLAYERS": PLAYERS,
		"PLAYER_QUEUE": PLAYER_QUEUE,
		"BATTLE_QUEUE": BATTLE_QUEUE,
		"LAND_QUEUE": LAND_QUEUE,
		"global_id_counter": global_id_counter,
		"global_turn_counter": global_turn_counter,
		"PRODUCTION_QUEUE": PRODUCTION_QUEUE,
		"SUPPLY_SYSTEM": SUPPLY_SYSTEM,
		"GALACTIC_DATA": GALACTIC_DATA,
		"active_id": Network.active_id
	}
	print(Network.active_id)
	save_game.store_var(save_data)
	save_game.close()
func load_save(savenum):
	var save_game = File.new()
	if not save_game.file_exists("user://savegame"+str(savenum)+".save"):
		return
	save_game.open("user://savegame"+str(savenum)+".save",File.READ)
	var save_data = save_game.get_var()
	for property in save_data.keys():
		if property != "active_id":
			set(property,save_data[property])
		else:
			Network.active_id = save_data[property]
	save_game.close()
func delete_save(savenum):
	var dir = Directory.new()
	dir.remove("user://savegame"+str(savenum)+".save")

func reset():
	pass #replace with resetting everything to default values
