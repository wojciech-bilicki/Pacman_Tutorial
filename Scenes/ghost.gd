extends Area2D

class_name Ghost

enum GhostState {
	SCATTER,
	CHASE,
	RUN_AWAY,
	EATEN,
	STARTING_AT_HOME
}

signal direction_change(current_direction: String)
signal run_away_timeout

var current_scatter_index = 0
var current_at_home_index = 0
var direction = null
var current_state: GhostState
var is_blinking = false

@export var scatter_wait_time = 8
@export var eaten_speed = 240
@export var speed = 120
@export var movement_targets: Resource 
@export var tile_map: MazeTileMap
@export var color: Color
@export var chasing_target: Node2D
@export var points_manager: PointsManager
@export var is_starting_at_home = false
@export var starting_position: Node2D
@export var ghost_eaten_sound_player: AudioStreamPlayer2D
@export var starting_texture: Texture2D

@onready var at_home_timer = $AtHomeTimer
@onready var eyes_sprite = $EyesSprite as EyesSprite
@onready var body_sprite = $BodySprite as BodySprite
@onready var navigation_agent_2d = $NavigationAgent2D
@onready var scatter_timer = $ScatterTimer
@onready var update_chasing_target_position_timer = $UpdateChasingTargetPositionTimer
@onready var run_away_timer = $RunAwayTimer
@onready var points_label = $PointsLabel

func _ready():
	
	scatter_timer.wait_time = scatter_wait_time
	at_home_timer.timeout.connect(scatter)
	
	navigation_agent_2d.path_desired_distance = 4.0
	navigation_agent_2d.target_desired_distance = 4.0
	navigation_agent_2d.target_reached.connect(on_position_reached)
	body_sprite.starting_texture = starting_texture

	call_deferred("setup")

func _process(delta):
	if !run_away_timer.is_stopped() && run_away_timer.time_left < run_away_timer.wait_time / 2 && !is_blinking:
		start_blinking()
	move_ghost(navigation_agent_2d.get_next_path_position(), delta)

	

func move_ghost(next_position: Vector2, delta: float):
	
	var current_ghost_position = global_position
	var current_speed = eaten_speed if current_state == GhostState.EATEN else speed
	var new_velocity = (next_position - current_ghost_position).normalized() * current_speed * delta
	
	calculate_direction(new_velocity)
	
	position += new_velocity

func calculate_direction(new_velocity: Vector2):
	
	var current_direction
	
	if new_velocity.x > 1:
		current_direction = "right"
	elif new_velocity.x < -1:
		current_direction = "left"
	elif new_velocity.y > 1:
		current_direction = "down"
	elif new_velocity.y < -1:
		current_direction = "up"
		
	if current_direction != direction:	
		direction = current_direction
		direction_change.emit(direction)

func setup():
	print("SETUP")
	set_collision_mask_value(1, true)
	position = starting_position.position
	navigation_agent_2d.set_navigation_map(tile_map.get_navigation_map(0))
	NavigationServer2D.agent_set_map(navigation_agent_2d.get_rid(), tile_map.get_navigation_map(0))
	eyes_sprite.show_eyes()
	body_sprite.move()
	if is_starting_at_home:
		start_at_home()
	else:
		scatter()

func start_at_home():
	current_state = GhostState.STARTING_AT_HOME
	at_home_timer.start()
	navigation_agent_2d.target_position = movement_targets.at_home_targets[current_at_home_index].position

func scatter():
	scatter_timer.start()
	current_state = GhostState.SCATTER
	navigation_agent_2d.target_position = movement_targets.scatter_targets[current_scatter_index].position


func on_position_reached():
	if current_state == GhostState.SCATTER:
		scatter_position_reached()
	elif current_state == GhostState.CHASE:
		chase_position_reached()
	elif current_state == GhostState.RUN_AWAY:
		run_away_from_pacman()
	elif current_state == GhostState.EATEN:
		start_chasing_pacman_after_being_eaten()
	elif current_state == GhostState.STARTING_AT_HOME:
		move_to_next_home_position()

func move_to_next_home_position():
	
	current_at_home_index = 1 if current_at_home_index == 0 else 0 
	navigation_agent_2d.target_position = movement_targets.at_home_targets[current_at_home_index].position

func chase_position_reached():
	print("KILL PACMAN")

func scatter_position_reached():
	print(current_scatter_index)
	if current_scatter_index < 3:
		current_scatter_index += 1
	else:
		current_scatter_index = 0
	print(current_scatter_index)
		
	navigation_agent_2d.target_position = movement_targets.scatter_targets[current_scatter_index].position

func _on_scatter_timer_timeout():
	start_chasing_pacman()

func start_chasing_pacman():
	if chasing_target == null:
		print("NO CHASING TARGET. CHASING WILL NOT WORK!!!")
	current_state = GhostState.CHASE
	update_chasing_target_position_timer.start()
	navigation_agent_2d.target_position = chasing_target.position


func _on_update_chasing_target_position_timer_timeout():
	navigation_agent_2d.target_position = chasing_target.position
	
func start_chasing_pacman_after_being_eaten():
	start_chasing_pacman()
	body_sprite.show()
	body_sprite.move()

func run_away_from_pacman():
	if run_away_timer.is_stopped():
		body_sprite.run_away()
		eyes_sprite.hide_eyes()
		run_away_timer.start()
		
		
	current_state = GhostState.RUN_AWAY
	
	# stop timers
	update_chasing_target_position_timer.stop()
	scatter_timer.stop()
	
	var empty_cell_position = tile_map.get_random_empty_cell_position()
	navigation_agent_2d.target_position = empty_cell_position
	
func start_blinking():
	body_sprite.start_blinking()

func _on_run_away_timer_timeout():
	run_away_timeout.emit()
	is_blinking = false
	eyes_sprite.show_eyes()
	body_sprite.move()
	start_chasing_pacman()

func get_eaten():
	ghost_eaten_sound_player.play()
	body_sprite.hide()
	eyes_sprite.show_eyes()
	points_label.show()
	points_label.text = "%d" % points_manager.points_for_ghost_eaten 
	await points_manager.pause_on_ghost_eaten()
	points_label.hide()
	run_away_timer.stop()
	run_away_timeout.emit()
	current_state = GhostState.EATEN
	navigation_agent_2d.target_position = movement_targets.at_home_targets[0].position
	
	
func _on_body_entered(body):
	var player = body as Player
	if current_state == GhostState.RUN_AWAY:
		get_eaten()
	elif current_state == GhostState.CHASE || current_state == GhostState.SCATTER:
		set_collision_mask_value(1, false)
		update_chasing_target_position_timer.stop()
		player.die()
		scatter_timer.wait_time = 600
		scatter()
	
