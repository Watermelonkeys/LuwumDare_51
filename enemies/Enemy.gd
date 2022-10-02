class_name Enemy
extends KinematicBody2D

enum STATES {
	SPAWN,
	ROAM,  # fly around until player is in reach
	ATTACK # go fuck up the player
}

export(float, 2.0, 10.0, 0.1) var attack_dist = 5.0
export(float, 1.0, 500.0, 0.1) var roam_max_speed = 100.0
export(float, 0.01, 1.0, 0.01) var roam_acceleration = 0.4

onready var ray := $RayCast2D
onready var anim_sprite := $AnimatedSprite

var noise_idx := 0.0
var noise := OpenSimplexNoise.new()
var state = STATES.ROAM 
var player : PlatformerController2D = null
var velocity := Vector2.ZERO
var dir := Vector2.RIGHT

func _ready():
	anim_sprite.animation = "spawning"
	anim_sprite.playing = true
	# Since there are no enemies during the day,
	# we can assume this node will be instanced
	# WAY AFTER the whole scene has been loaded
	
	if owner.get("player"):
		# Gets reference to the player from the root node
		player = owner.player 
	
	# Configure noise
	randomize()
	noise.seed = randi()
	noise.octaves = 2
	noise.period = 20.0
	noise.persistence = 0.8


func _physics_process(delta):
	state = STATES.ROAM
	
	check_state()
	run_state(delta)
	
func check_state():
	if anim_sprite.animation == "spawning":
		state = STATES.SPAWN
		return 
		
	if not player:
		return
	
	var p_pos = player.position
	# let's be efficient and use the squared distance
	var dist = position.distance_squared_to(p_pos)
	
	if dist <= pow(attack_dist, 2):
		# it's in range
		ray.cast_to = p_pos
		ray.force_raycast_update()
		
		var coll = ray.get_collider()
		if coll and coll == player:
			# LADIES N GENTLEMEN WE GOT HIM
			state = STATES.ATTACK
	
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
			
			#print("noise: %s | angle: %s | dir: %s " % [_n, rad2deg(n), dir])
			
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
		STATES.ATTACK:
			pass


func _on_AnimatedSprite_animation_finished():
	if anim_sprite.animation == "spawning":
		anim_sprite.animation = "roaming"
		anim_sprite.playing = true
