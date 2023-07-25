extends Area2D

class_name Pellet

signal pellet_eaten(should_allow_eating_ghosts: bool)

@export var should_allow_eating_ghosts = false

func _on_body_entered(body):
	
	if body is Player:
		pellet_eaten.emit(should_allow_eating_ghosts)
		queue_free()
		
