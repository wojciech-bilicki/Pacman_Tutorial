extends Node

@onready var player = $"../Player" as Player


func _ready():
	player.player_died.connect(reset_ghosts)
	

func reset_ghosts(lifes):	
	var ghosts = get_children() as Array[Ghost]
	if lifes == 0:
		for ghost in ghosts:
			ghost.scatter_timer.stop()
			ghost.scatter_timer.wait_time = 10000
			ghost.scatter_timer.start()
			ghost.current_state = Ghost.GhostState.SCATTER
	else:		
		for ghost in ghosts:
			ghost.setup()
	

