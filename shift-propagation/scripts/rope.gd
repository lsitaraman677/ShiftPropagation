@tool
class_name Rope
extends Node2D

var curpoints = PackedVector2Array()
var prevpoints = PackedVector2Array()
var paused = false

var holding
var anchoridx
var startclickloc
var startpos

@export var length: float = 200:
	set(value):
		length = value
		_rebuild_preview()

@export var numpoints: int = 20:
	set(value):
		numpoints = max(2, value)
		_rebuild_preview()

var iters: int = 40
var forcefact: float = 1e3
var dampfact: float = 1e3
var maxforce: float = 1e4
var colcheckfreq = 10

var ropewidth: float = 10:
	set(value):
		ropewidth = value
		if query and query.shape:
			query.shape.radius = ropewidth * 0.5
		queue_redraw()

var damping: float = 0.98
var pullcheckportion: float = 1.0

var endpointrad: float = 10:
	set(value):
		endpointrad = value
		queue_redraw()

var g

var anchor1
var anchor2

var object1 = null:
	set(newval):
		object1 = newval
		updateexcludes()
var object2 = null:
	set(newval):
		object2 = newval
		updateexcludes()

var query

func _ready():
	g = ProjectSettings.get_setting("physics/2d/default_gravity")
	
	anchor1 = Node2D.new()
	anchor2 = Node2D.new()
	
	_init_points()
	
	var circ = CircleShape2D.new()
	circ.radius = ropewidth * 0.5
	query = PhysicsShapeQueryParameters2D.new()
	query.shape = circ
	
	updateexcludes()
	queue_redraw()
	
	if Engine.is_editor_hint():
		set_physics_process(false)
		set_process_input(false)
		set_process(false)

func _init_points():
	curpoints.clear()
	prevpoints.clear()
	var loc = global_position
	var seglen = length / (numpoints - 1)
	var lastang = 0.0
	for i in range(numpoints):
		curpoints.append(loc)
		prevpoints.append(loc)
		var ang = lastang + 2 * (randf() - 0.5) * 0.5 * PI
		loc += Vector2(cos(ang), sin(ang)) * seglen
		lastang = ang
		
	anchor1.global_position = curpoints[0]
	anchor2.global_position = curpoints[len(curpoints) - 1]

func _rebuild_preview():
	if not is_node_ready():
		return
	_init_points()
	queue_redraw()
	
func unpause():
	paused = false
	
func pause():
	paused = true

func _physics_process(dt):
	
	if Engine.is_editor_hint():
		set_physics_process(false)
		set_process_input(false)
		set_process(false)
		
	if not paused:
		var seglen = length / (numpoints - 1)
		var before_update = curpoints.duplicate()
		
		for i in range(len(curpoints)):
			curpoints[i] += (curpoints[i] - prevpoints[i]) * damping + Vector2(0, 1) * g * dt * dt
		
		var a1_pos = anchor1.global_position
		var a2_pos = anchor2.global_position
		curpoints[0] = a1_pos
		curpoints[len(curpoints) - 1] = a2_pos
		
		var space_state = get_world_2d().direct_space_state
		
		for i in range(iters):
			for j in range(len(curpoints) - 1):
				var i1
				var i2
				if i % 2 == 0:
					i1 = j
					i2 = i1 + 1
				else:
					i1 = len(curpoints) - j - 1
					i2 = i1 - 1
				var p1 = curpoints[i1]
				var p2 = curpoints[i2]
				var diff = p2 - p1
				var l = diff.length()
				if l > seglen:
					var nudge = (l - seglen) * 0.5
					var unit = diff / l
					curpoints[i1] = p1 + unit * nudge
					curpoints[i2] = p2 - unit * nudge
			curpoints[0] = a1_pos
			curpoints[len(curpoints) - 1] = a2_pos
			if (i % colcheckfreq == 0) or (i == iters - 1):
				for j in range(1, len(curpoints) - 1):
					query.transform.origin = curpoints[j]
					var contacts = space_state.collide_shape(query, 1)
					if contacts.size() >= 2:
						curpoints[j] += contacts[1] - contacts[0]
		
		if object1 != null and object1 is RigidBody2D:
			var curlength = 0
			var numsegs = int((len(curpoints) - 1) * pullcheckportion)
			if numsegs == 0:
				numsegs = 1
			for i in range(numsegs):
				curlength += (curpoints[i + 1] - curpoints[i]).length()
			var stretch = (curlength - numsegs * seglen) / (numsegs * seglen)
			if stretch > 0:
				var unit = (curpoints[1] - curpoints[0]).normalized()
				var dot = unit.dot(get_point_vel(object1, curpoints[0]))
				var force = forcefact * stretch - dampfact * dot
				#if force > 0:
				if abs(force) > maxforce:
					force = sign(force) * maxforce
				var forcevec = unit * force 
				object1.apply_force(forcevec, curpoints[0] - object1.global_position)
		
		if object2 != null and object2 is RigidBody2D:
			var curlength = 0
			var numsegs = int((len(curpoints) - 1) * pullcheckportion)
			if numsegs == 0:
				numsegs = 1
			for i in range(len(curpoints) - numsegs - 1, len(curpoints) - 1):
				curlength += (curpoints[i + 1] - curpoints[i]).length()
			var stretch = (curlength - numsegs * seglen) / (numsegs * seglen)
			if stretch > 0:
				var unit = (curpoints[len(curpoints) - 2] - curpoints[len(curpoints) - 1]).normalized()
				var dot = unit.dot(get_point_vel(object2, curpoints[len(curpoints) - 1]))
				var force = forcefact * stretch - dampfact * dot
				#if force > 0:
				if abs(force) > maxforce:
					force = sign(force) * maxforce
				var forcevec = unit * force 
				object2.apply_force(forcevec, curpoints[len(curpoints) - 1] - object2.global_position)
			
		prevpoints = before_update
	
	queue_redraw()

func _draw():
	if curpoints.size() < 2:
		return
		
	var localposes = PackedVector2Array()
	for p in curpoints:
		localposes.append(to_local(p))

	draw_circle(localposes[0], endpointrad, Color.WHITE)
	draw_circle(localposes[len(curpoints) - 1], endpointrad, Color.WHITE)
	
	draw_polyline(localposes, Color.WHITE, ropewidth, true)
	
func updateexcludes():
	if query == null:
		return
	var arr: Array[RID] = []
	if object1 != null:
		arr.append(object1.get_rid())
	if object2 != null:
		arr.append(object2.get_rid())
	query.exclude = arr

func get_point_vel(obj, pt):
	var linvel = obj.linear_velocity
	var angvel = obj.angular_velocity
	var offset = pt - obj.global_position
	return linvel + angvel * Vector2(-offset.y, offset.x)
	
func process_click(clickloc):
	if (clickloc - anchor1.global_position).length() < endpointrad:
		holding = anchor1
		startpos = anchor1.global_position
		var parent = anchor1.get_parent()
		if parent != null:
			parent.remove_child(anchor1)
		object1 = null
		anchor1.global_position = startpos
		startclickloc = clickloc
		anchoridx = 1
		return true
	elif (clickloc - anchor2.global_position).length() < endpointrad:
		holding = anchor2
		startpos = anchor2.global_position
		var parent = anchor2.get_parent()
		if parent != null:
			parent.remove_child(anchor2)
		object2 = null
		anchor2.global_position = startpos
		startclickloc = clickloc
		anchoridx = 2
		return true
	return false
	
func mouseupdate(loc):
	if holding != null:
		holding.global_position = startpos + loc - startclickloc
		
func release():
	var space_state = get_world_2d().direct_space_state
	query.shape.radius = endpointrad
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.transform.origin = holding.global_position
	query.exclude = []
	var results = space_state.intersect_shape(query)
	if len(results) > 0:
		var result = results[0].collider
		var globalpos = holding.global_position
		result.add_child(holding)
		holding.global_position = globalpos
		if anchoridx == 1:
			object1 = result
		else:
			object2 = result
	else:
		if anchoridx == 1:
			object1 = null
		if anchoridx == 2:
			object2 = null
	holding = null
	query.shape.radius = ropewidth * 0.5
	updateexcludes()
