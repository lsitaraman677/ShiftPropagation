extends Node2D

class_name Shifter

const constt = 1e5
const maxtime = 1.0
var curt = 0.0
var fact = 1.0

@export var width: float
@export var height: float
@export var pivdist: float
@export var pivthick: float

var platform

func _ready():
	var dummystatic = StaticBody2D.new()
	platform = RigidBody2D.new()
	platform.position = Vector2(0, -pivdist)
	platform.mass = 100
	var hitbox = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(width, height)
	hitbox.shape = rect
	hitbox.position = Vector2.ZERO
	var colorrect = ColorRect.new()
	colorrect.size = Vector2(width, height)
	colorrect.position = -0.5 * Vector2(width, height)
	var colorrect2 = ColorRect.new()
	colorrect2.size = Vector2(pivthick, pivdist + pivthick*0.5)
	colorrect2.position = Vector2(-pivthick*0.5, 0)
	var pivot = PinJoint2D.new()
	pivot.position = Vector2.ZERO
	add_child(dummystatic)
	add_child(pivot)
	add_child(platform)
	platform.add_child(hitbox)
	platform.add_child(colorrect)
	platform.add_child(colorrect2)
	pivot.node_a = dummystatic.get_path()
	pivot.node_b = platform.get_path()
	
func torquefunc(t):
	const startt = 5e7
	const endt = 1e8
	return (endt - startt) * t / maxtime
	
func _physics_process(dt):
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
