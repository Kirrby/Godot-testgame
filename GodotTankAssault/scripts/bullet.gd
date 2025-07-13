extends Area2D

var shooter_id: int
var velocity = Vector2.ZERO
var bounces_left = 5
var lifetime_timer: Timer

func _ready():
	lifetime_timer = Timer.new()
	add_child(lifetime_timer)
	lifetime_timer.wait_time = 3.0
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(queue_free)
	lifetime_timer.start()

func init(p_shooter_id: int, p_velocity: Vector2):
	shooter_id = p_shooter_id
	velocity = p_velocity

func _physics_process(delta):
	var new_position = position + velocity * delta
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(position, new_position, 1)
	var result = space_state.intersect_ray(query)

	if result and result.normal != Vector2.ZERO:

		velocity = velocity.bounce(result.normal)
		position = result.position
		bounces_left -= 1
		if bounces_left <= 0:
			queue_free()
	else:
		position = new_position

func _on_body_entered(body):
	if not multiplayer.is_server():
		return

	if body.is_in_group("tanks") and body.name != str(shooter_id):
		# The server authoritatively tells the tank to take damage.
		body.take_damage_rpc.rpc(10, shooter_id)
		# The server authoritatively tells all peers to destroy the bullet.
		destroy_bullet_rpc.rpc()

@rpc("any_peer", "call_local", "reliable")
func destroy_bullet_rpc():
	if is_instance_valid(self):
		queue_free()
