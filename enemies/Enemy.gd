class_name Enemy
extends KinematicBody2D

enum STATES {
	SPAWN,
	ROAM,  # fly around until player is in reach
	AGGRO, # get mad because you saw the player
	CHARGE, #RUN to the player
	ATTACK #fuck up the player if the sucker didnt run away
}

export(float, 2.0, 150.0, 0.1) var attack_dist = 150.0
export(float, 1.0, 500.0, 0.1) var roam_max_speed = 100.0
export(float, 1.0, 200.0, 0.1) var attack_speed_mul = 10.0
export(float, 0.01, 1.0, 0.01) var roam_acceleration = 0.4
export(float, 0.01, 5.0, 0.01) var aggro_timer_len = 2.0

onready var ray := $RayCast2D
onready var anim_sprite := $AnimatedSprite

var aggro_timer := Timer.new()
var noise_idx := 0.0
var noise := OpenSimplexNoise.new()
var state = STATES.SPAWN 
var player : PlatformerController2D = null
var velocity := Vector2.ZERO
var dir := Vector2.RIGHT
var charge_target := Vector2.ZERO
var charge_collision : KinematicCollision2D = null
var charge_done := false
var spawn_done := false

func _ready():
	add_child(aggro_timer)
	aggro_timer.one_shot = true
	aggro_timer.wait_time = aggro_timer_len
	
	anim_sprite.animation = "spawning"
	anim_sprite.playing = true
	
	# Configure noise
	randomize()
	noise.seed = randi()
	noise.octaves = 2
	noise.period = 20.0
	noise.persistence = 0.8

#	yield(get_tree(), "idle_frame")
	# Gets reference to the player from the root node
	player = owner.get_meta("player") 


func _physics_process(delta):
	var new_s = check_state()
	
	if state != new_s:
		state = new_s
		init_state()
	
	run_state(delta)
	
func check_state():
	if not player:
		return STATES.ROAM
	
	match state:
		STATES.SPAWN:
			if spawn_done:
				return STATES.ROAM
		STATES.ROAM:
			var p_pos = player.global_position
			# let's be efficient and use the squared distance
			var dist = global_position.distance_squared_to(p_pos)
			
			if dist <= pow(attack_dist, 2):
				# it's in range
				ray.cast_to = ray.to_local(p_pos)
				ray.force_raycast_update()
				
				var coll = ray.get_collider()
				if coll and coll == player:
					# LADIES N GENTLEMEN WE GOT HIM
					return STATES.AGGRO
		STATES.AGGRO:
			if aggro_timer.time_left <= 0.0:
				return STATES.CHARGE
		STATES.CHARGE:
			charge_done = charge_collision and charge_collision.collider == player
			if charge_done:
				return STATES.ATTACK
		STATES.ATTACK:
			return state
			if dist_to_player() > 20.0:
				return STATES.ROAM
					
	return state
	
func init_state():
	# Things to do when the state changes
	match state:
		STATES.SPAWN:
			# nothing to do
			pass
		STATES.ROAM:
			anim_sprite.modulate = Color.white
			velocity *= 0.0
			dir = Vector2.RIGHT
			anim_sprite.animation = "roaming"
			anim_sprite.playing = true
		STATES.AGGRO:
			velocity *= 0.0
			dir = Vector2.RIGHT
			aggro_timer.start()
			charge_target = player.position
		STATES.CHARGE:
			charge_done = false
			anim_sprite.offset *= 0.0
		STATES.ATTACK:
			## TEMP
			velocity *= 0.0
			anim_sprite.modulate = Color.red
	
func run_state(delta):
	match state:
		STATES.SPAWN:
			# nothing to do
			pass
		STATES.ROAM:
			noise_idx += delta * 100
			var _n = noise.get_noise_1d(noise_idx)
			var n = range_lerp(_n, -1.0, 1.0, -TAU/4.0, TAU/4.0)
			
			dir = dir.linear_interpolate(dir.rotated(n * 0.1), 0.5)
			
			velocity = velocity.linear_interpolate(dir * roam_max_speed, roam_acceleration)
			
			var coll = move_and_collide(velocity * delta)
			
			var coll_horizontal := false
			if coll:
				var norm = coll.normal
				if norm.y == 0:
					# vertical wall
					dir.x *= -1
					velocity.x *= -1
				else:
					dir.y *= -1
					velocity.y *= -1
					
			anim_sprite.flip_h = (velocity.x > 0)
		STATES.AGGRO:
			var r = 2.0
			anim_sprite.offset = Vector2(rand_range(-r, r), rand_range(-r, r))
		STATES.CHARGE:
			var target_dist = position.distance_squared_to(charge_target)
			var target_dir = position.direction_to(charge_target)
			var speed = roam_max_speed * attack_speed_mul
			var fac = target_dist/pow(attack_dist, 2)
			
			velocity = velocity.linear_interpolate(target_dir * speed, fac)
			
			move_and_slide(velocity)
			
			if get_slide_count() > 0:
				charge_collision = get_slide_collision(0)
		STATES.ATTACK:
			pass

func dist_to_player():
	return position.distance_to(player.position)

func _on_AnimatedSprite_animation_finished():
	if anim_sprite.animation == "spawning":
		spawn_done = true
