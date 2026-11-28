extends Node2D

var stuff = []
var clicked = false
var justclicked = false
var justreleased = false

var holding = null

func _ready():
	stuff.append(get_children()[0])
	stuff.append(get_children()[1])
	
func _process(dt):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if not clicked:
			clicked = true
			justclicked = true
		else:
			justclicked = false
		justreleased = false
	else:
		if clicked:
			clicked = false
			justreleased = true
		else:
			justreleased = false
		justclicked = false
		
	if justreleased:
		if holding != null:
			holding.release()
			holding = null
	if justclicked:
		for thing in stuff:
			if thing.has_method("process_click"):
				if thing.process_click(get_global_mouse_position()):
					holding = thing
					break
	else:
		if holding != null:
			holding.mouseupdate(get_global_mouse_position())
		
			
