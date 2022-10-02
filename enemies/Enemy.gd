class_name Enemy
extends KinematicBody2D

enum STATES {
	ROAM,  # fly around until player is in reach
	ATTACK # go fuck up the player
}

export(float, 2.0, 10.0, 0.1) var attack_dist = 5.0

onready var ray := $RayCast2D

var noise_idx := 0.0
var noise := OpenSimplexNoise.new()
var state = STATES.ROAM 
var player : PlatformerController2D = null
var dir := Vector2.RIGHT

func _ready():
	# Since there are no enemies during the day,
	# we can assume this node will be instanced
	# WAY AFTER the whole scene has been loaded
	
	if owner.get("player"):
		# Gets reference to the player from the root node
		player = owner.player 
	
	# Configure noise
	noise.seed = randi()
	noise.octaves = 2
	noise.period = 20.0
	noise.persistence = 0.8


func _physics_process(delta):
	check_state()
	run_state(delta)
	
func check_state():
	state = STATES.ROAM
		
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
		STATES.ROAM:
			noise_idx += delta
			var n = noise.get_noise_1d(noise_idx)
			n = range_lerp(n, -1.0, 1.0, PI/6.0, PI/3.0)
			print(rad2deg(n))
			
			dir = Vector2.RIGHT.rotated(n * 100.0)
			$DEBUG_Dir.rotation = dir.angle()
			
			move_and_slide(dir * 30.0)
		STATES.ATTACK:
			pass
