extends Node

signal time_passed

onready var ten_timer := Timer.new()

func _ready():
	ten_timer.wait_time = 10
	ten_timer.one_shot = false
	ten_timer.start()


func _process(delta):
	pass
