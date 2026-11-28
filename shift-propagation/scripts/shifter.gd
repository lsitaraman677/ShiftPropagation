@tool
class_name Shifter
extends Node2D

const constt = 1e5
const maxtime = 1.0
var curt = 0.0
var fact = 1.0

@export var width: float = 100.0:
	set(value):
		width = value
		_update_visuals()

@export var height: float = 20.0:
	set(value):
		height = value
		_update_visuals()

@export var pivdist: float = 80.0:
	set(value):
		pivdist = value
		_update_visuals()

@export var pivthick: float = 10.0:
	set(value):
		pivthick = value
		_update_visuals()

var platform: RigidBody2D
var hitbox: CollisionShape2D
var colorrect: ColorRect
var colorrect2: ColorRect

func _ready():
	var dummystatic = StaticBody2D.new()
	platform = RigidBody2D.new()
	platform.mass = 100
	
	hitbox = CollisionShape2D.new()
	hitbox.shape = RectangleShape2D.new()
	
	colorrect = ColorRect.new()
	colorrect2 = ColorRect.new()
	
	var pivot = PinJoint2D.new()
	pivot.position = Vector2.ZERO
	
	platform.position = Vector2(0, -pivdist)
	hitbox.shape.size = Vector2(width, height)
	
	colorrect.size = Vector2(width, height)
	colorrect.position = -0.5 * Vector2(width, height)
	
	colorrect2.size = Vector2(pivthick, pivdist + pivthick * 0.5)
	colorrect2.position = Vector2(-pivthick * 0.5, 0)
	
	add_child(dummystatic)
	add_child(pivot)
	add_child(platform)
	platform.add_child(hitbox)
	platform.add_child(colorrect)
	platform.add_child(colorrect2)
	
	pivot.node_a = dummystatic.get_path()
	pivot.node_b = platform.get_path()
	
	if Engine.is_editor_hint():
		set_physics_process(false)
		set_process_input(false)
		set_process(false)
	else:
		set_physics_process(true)
		set_process_input(true)
		set_process(true)
	
	_update_visuals()

func _update_visuals():
	if not is_node_ready():
		return
		
	platform.position = Vector2(0, -pivdist)
	hitbox.shape.size = Vector2(width, height)
	
	colorrect.size = Vector2(width, height)
	colorrect.position = -0.5 * Vector2(width, height)
	
	colorrect2.size = Vector2(pivthick, pivdist + pivthick * 0.5)
	colorrect2.position = Vector2(-pivthick * 0.5, 0)

func torquefunc(t):
	const startt = 5e7
	const endt = 1e8
	return (endt - startt) * t / maxtime

func _physics_process(dt):
		
	if Engine.is_editor_hint():
		set_physics_process(false)
		set_process_input(false)
		set_process(false)
		
	if curt > maxtime:
		platform.apply_torque(constt * fact)
	else:
		platform.apply_torque(torquefunc(curt) * fact)
	if Input.is_action_just_pressed("spacepressed"):
		shift()
	curt += dt

func shift():
	fact *= -1
	curt = 0.0
