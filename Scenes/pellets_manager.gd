extends Node

class_name PelletsManager

var total_pellets_count 
var pellets_eaten = 0

@onready var points_manager = $"../PointsManager"
@onready var chomp_sound_player = $"../SoundPlayers/ChompSoundPlayer"
@onready var power_pellet_sound_player = $"../SoundPlayers/PowerPelletSoundPlayer"

@onready var ui = $"../UI" as UI

@export var ghost_array: Array[Ghost]

var eaten_ghost_counter = 0

func _ready():
	var pellets = self.get_children() as Array[Pellet]
	total_pellets_count = pellets.size()
	for pellet in pellets:
		pellet.pellet_eaten.connect(on_pellet_eaten)
	
	for ghost in ghost_array:
		ghost.run_away_timeout.connect(on_ghost_run_away_timeout)

func on_pellet_eaten(should_allow_eating_ghosts: bool):
	
	if !chomp_sound_player.playing:
		chomp_sound_player.play()
	pellets_eaten += 1
	
	if should_allow_eating_ghosts:
		power_pellet_sound_player.play()
		for ghost in ghost_array:
			if ghost.current_state != ghost.GhostState.STARTING_AT_HOME:
				ghost.run_away_from_pacman()
	
	if pellets_eaten == total_pellets_count:
		ui.game_won()
		
func on_ghost_run_away_timeout():
	eaten_ghost_counter += 1
	if eaten_ghost_counter == ghost_array.size():
		points_manager.reset_points_for_ghosts()
		eaten_ghost_counter = 0
		power_pellet_sound_player.stop()


