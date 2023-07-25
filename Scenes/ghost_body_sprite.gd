extends Sprite2D
class_name BodySprite

@onready var animation_player = $"../AnimationPlayer"
var starting_texture: Texture2D

func _ready():
	move()

func move():
	texture = starting_texture
	self.modulate = (get_parent() as Ghost).color
	animation_player.play("moving")
	
func run_away():
	self.modulate = Color.WHITE
	animation_player.play("running_away")

func start_blinking():
	animation_player.play("blinking")

