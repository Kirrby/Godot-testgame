extends Area2D

var shooter_id: int
var velocity = Vector2.ZERO
var bounces_left = 5
var lifetime_timer: Timer

func _ready():
	# This timer is created on all peers to act as a failsafe.
	# Every bullet will be removed after a few seconds, preventing ghosts.
	lifetime_timer = Timer.new()
	add_child(lifetime_timer)
	lifetime_timer.wait_time = 3.0
	lifetime_timer.one_shot = true
	# When the timer ends, just free the bullet locally.
	lifetime_timer.timeout.connect(queue_free)
	lifetime_timer.start()

func init(p_shooter_id: int, p_velocity: Vector2):
	shooter_id = p_shooter_id
	velocity = p_velocity

func _physics_process(delta):
	# All peers simulate the bullet's movement for immediate feedback.
	var new_position = position + velocity * delta
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(position, new_position, 1)
	var result = space_state.intersect_ray(query)

	if result:
		velocity = velocity.bounce(result.normal)
		position = result.position
		bounces_left -= 1
		
		# If the bullet runs out of bounces, remove it locally.
		# The server will also do this and send an authoritative destroy RPC,
		# but this prevents visual glitches on the client.
		if bounces_left <= 0:
			queue_free()
	else:
		position = new_position

func _on_body_entered(body):
	# Only the server has authority to deal damage and destroy bullets on impact.
	if not multiplayer.is_server():
		return

	if body.is_in_group("tanks") and body.name != str(shooter_id):
		if body.has_method("take_damage_rpc"):
			body.take_damage_rpc(10)
		# The server authoritatively tells all peers to destroy the bullet.
		destroy_bullet_rpc.rpc()

# This RPC is called by the server to ensure critical destructions are synced.
@rpc("any_peer", "call_local", "reliable")
func destroy_bullet_rpc():
	# Check if the node is still valid before trying to free it,
	# as it might have been freed locally by the timer or bounce limit.
	if is_instance_valid(self):
		queue_free()
