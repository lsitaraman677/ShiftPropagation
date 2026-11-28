extends Node2D

var startpos = null
var startclick = null

func process_click(clickloc):
	if is_point_in_collision_shape(clickloc, $RigidBody2D/CollisionShape2D):
		startclick = clickloc
		startpos = global_position
		$RigidBody2D.freeze = true
		return true
	return false
	
func mouseupdate(loc):
	if startpos != null:
		global_position = startpos + loc - startclick
	
func release():
	startpos = null
	startclick = null
	$RigidBody2D.freeze = false
	
func is_point_in_collision_shape(global_pt: Vector2, col_shape: CollisionShape2D) -> bool:
	if col_shape.disabled or col_shape.shape == null:
		return false

	var parent := col_shape.get_parent()
	if not (parent is CollisionObject2D):
		return false

	var space_state := col_shape.get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = global_pt
	query.collide_with_bodies = parent is PhysicsBody2D
	query.collide_with_areas = parent is Area2D
	query.collision_mask = parent.collision_layer

	var hits := space_state.intersect_point(query)
	for hit in hits:
		if hit.collider == parent and hit.shape == col_shape.get_index():
			return true
	return false
