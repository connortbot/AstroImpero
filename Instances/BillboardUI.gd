extends Control

var solar = 0
var data = {}

func setsol(s):
	solar = s
	var l = Database.LOCAL_ID
	for sys in Database.GALACTIC_DATA.keys():
		for sol in Database.GALACTIC_DATA[sys].keys():
			if sol == solar:
				data = Database.GALACTIC_DATA[sys][sol].duplicate()
				break
	$"VBoxContainer/Friendly/pname".text = Database.PLAYERS[0][0]
	$"VBoxContainer/Enemy/pname".text = Database.PLAYERS[1][0]
	var f = 0
	var e = 0
	for obj in data.keys():
		if "-" in obj: #is a ship
			if data[obj]["OWNER"] == Database.PLAYERS[0][0] and not "SUPPLIER" in obj:
				f += 1
			elif data[obj]["OWNER"] == Database.PLAYERS[1][0] and not "SUPPLIER" in obj:
				e += 1
	$"VBoxContainer/Friendly/pname".text = str(f)
	$"VBoxContainer/Enemy/HBoxContainer/ID".text = str(e)


func _on_Button_pressed() -> void:
	#inspect the solar
	pass
