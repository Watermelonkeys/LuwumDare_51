extends Node

var rng = RandomNumberGenerator.new()

func _ready():
	$ColorRect.color = Color(1,1,1,1)
	$Timer10.start()


func _on_Timer_timeout():
	if has_node("ColorRect"):
		$ColorRect.color = Color(0,0,0,1)
		$Shock.wait_time = rng.randi_range(1, 5)
		$Shock.start()


func _on_Shock_timeout():
	$Shock.stop()
	$ColorRect.color = Color(1,1,1,1)
