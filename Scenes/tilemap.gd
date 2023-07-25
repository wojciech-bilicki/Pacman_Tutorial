extends TileMap

class_name MazeTileMap

var empty_cells = []

func _ready():
	var cells = get_used_cells(0)
	
	for cell in cells:
		var data = get_cell_tile_data(0, cell)
		if data.get_custom_data("isEmpty"):
			empty_cells.push_front(cell)

func get_random_empty_cell_position():
	return to_global(map_to_local(empty_cells.pick_random()))
