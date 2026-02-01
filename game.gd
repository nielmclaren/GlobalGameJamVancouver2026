class_name Game
extends Node2D

@onready var _clip_tilemap_player0: TileMapLayer = %ClipTileMapPlayer0
@onready var _player_container0: Node2D = %ClipMaskPlayer0
@onready var _clip_tilemap_player1: TileMapLayer = %ClipTileMapPlayer1
@onready var _player_container1: Node2D = %ClipMaskPlayer1
@onready var _goal_container: Node2D = %GoalContainer
@onready var _mask_container: Node2D = %MaskContainer
@onready var _tilemap: TileMapLayer = %TileMapLayer
@onready var _hud: Hud = %Hud
@onready var _map_regen_timer: Timer = %MapRegenTimer
@onready var _winner_screen: Node2D = %WinnerScreen
@onready var _winner_label0: Label = %WinnerLabel0
@onready var _winner_label1: Label = %WinnerLabel1

@onready var _winner_loser_art: Node2D = %WinnerLoserArt
@onready var _winner_animated_sprite: AnimatedSprite2D = %WinnerAnimatedSprite
@onready var _loser_animated_sprite: AnimatedSprite2D = %LoserAnimatedSprite

var _mask_scene: PackedScene = load("res://game_objects/mask.tscn")
var _goal_scene: PackedScene = load("res://game_objects/goal.tscn")
var _player_scene: PackedScene = load("res://characters/player.tscn")

var _players: Array[Player]
var _masks: Array[Mask]
var _goal: Goal
var _scores: Array[int]

# Used to discard timeouts from old timers.
var _reset_index: int = 0


func _ready() -> void:
	_map_regen_timer.timeout.connect(_map_regen_timeout)
	_winner_screen.hide()

	reset()


func _map_regen_timeout() -> void:
	_randomize_tiles()

	for player: Player in _players:
		_update_clip_tilemap(player)
		player.is_stealthed = is_in_stealth_tile(player)


func reset() -> void:
	_reset_index += 1

	clear()

	_randomize_tiles()

	_spawn_player(0, Vector2i(0, 3))
	_spawn_player(1, Vector2i(3, 0))

	_try_spawn_goal(true)

	_spawn_first_masks()

	_map_regen_timer.start()


func clear() -> void:
	for player: Player in _players:
		player.queue_free()
	_players.clear()

	if _goal:
		_goal.queue_free()
		_goal = null

	for mask: Mask in _masks:
		mask.queue_free()
	_masks.clear()

	_scores.clear()
	_scores.append(0)
	_scores.append(0)
	_scores_changed()


func is_in_stealth_tile(player: Player) -> bool:
	for c: int in range(Constants.NUM_COLS):
		for r: int in range(Constants.NUM_ROWS):
			var coord: Vector2i = Vector2i(c, r)
			var atlas_coord: Vector2i = _tilemap.get_cell_atlas_coords(coord)
			var color_index: int = Utils.atlas_coord_to_color_index(atlas_coord)
			if color_index == player.color_index:
				if _is_player_tile_overlap(player, coord):
					return true
	return false


func _is_player_tile_overlap(player: Player, coord: Vector2i) -> bool:
	var circle_pos: Vector2 = player.position  # center
	var radius: float = 10
	var square_pos: Vector2 = _tilemap.map_to_local(coord)  # center
	var half_size: float = Constants.TILE_HALF_SIZE

	var x: float = absf(circle_pos.x - square_pos.x) - half_size
	var y: float = absf(circle_pos.y - square_pos.y) - half_size
	if x > 0:
		if y > 0:
			var result: bool = x * x + y * y < radius * radius
			return result
		else:
			return x < radius
	else:
		return y < radius


func _randomize_tiles() -> void:
	# Build a list of tile atlas positions with an equal number of each tile.
	var tiles: Array[Vector2i]
	for i: int in range(Constants.NUM_ROWS * Constants.NUM_COLS):
		tiles.append(Vector2i(i % Constants.COLORS.size(), 0))
	tiles.shuffle()

	for c: int in range(Constants.NUM_COLS):
		for r: int in range(Constants.NUM_ROWS):
			var tile: Vector2i = tiles.pop_back()
			var coord: Vector2i = Vector2i(c, r)
			_tilemap.set_cell(coord, 1, tile)

	# Enable all clip tiles.
	var atlas_coord: Vector2i = Vector2i(0, 0)
	for c: int in range(Constants.NUM_COLS):
		for r: int in range(Constants.NUM_ROWS):
			var coord: Vector2i = Vector2i(c, r)
			_clip_tilemap_player0.set_cell(coord, 0, atlas_coord)
			_clip_tilemap_player1.set_cell(coord, 0, atlas_coord)


func _spawn_player(player_num: int, coord: Vector2i) -> void:
	var player: Player = _player_scene.instantiate()
	player.setup(self)
	player.player_num = player_num
	player.position = _tilemap.map_to_local(coord)

	player.masked.connect(_mask_player.bind(player))
	player.unmasked.connect(_unmask_player.bind(player))
	player.hitted.connect(_player_hitted.bind(player))

	if player_num == 0:
		_player_container0.add_child(player)
	else:
		_player_container1.add_child(player)

	_players.append(player)


func _mask_player(player: Player) -> void:
	_update_clip_tilemap(player)


func _unmask_player(player: Player) -> void:
	_reveal_clip_tilemap(player)


func _player_hitted(player: Player) -> void:
	_scores[player.player_num] = 0
	_scores_changed()


func _delay_spawn_goal() -> void:
	var reset_index: int = _reset_index
	await get_tree().create_timer(Constants.GOAL_SPAWN_DELAY_S).timeout

	if _reset_index != reset_index:
		return

	var success: bool = false
	while !success:
		success = _try_spawn_goal()
		await get_tree().create_timer(Constants.GOAL_SPAWN_RETRY_S).timeout

		if _reset_index != reset_index:
			return


func _try_spawn_goal(is_first_spawn: bool = false) -> bool:
	var available_coords: Array[Vector2i] = _get_diagonal_coords()
	if is_first_spawn:
		available_coords = _get_diagonal_coords()
	else:
		available_coords = _get_yonder_coords()

	if available_coords.is_empty():
		return false

	var coord: Vector2i = available_coords.pick_random()

	var goal: Goal = _goal_scene.instantiate()
	goal.scored.connect(_goal_scored)
	goal.position = _tilemap.map_to_local(coord)
	_goal_container.add_child(goal)
	_goal = goal

	return true


func _goal_scored(player: Player) -> void:
	print("Player %d scored!" % player.player_num)
	_scores[player.player_num] += 1
	_scores_changed()

	_goal = null

	if _scores[player.player_num] >= Constants.MAX_SCORE:
		var other_player: Player = _players[1 - player.player_num]
		_show_winner(player, other_player)

	else:
		_delay_spawn_goal()


func _show_winner(winner: Player, loser: Player) -> void:
	_winner_label0.visible = winner.player_num == 0
	_winner_label1.visible = winner.player_num == 1

	_winner_loser_art.scale.x = -1 if winner.player_num == 0 else 1

	var winner_form: String = "base"
	if winner.color_index >= 0:
		winner_form = Constants.PLAYER_FORMS[winner.color_index]
	_winner_animated_sprite.play(winner_form)

	var loser_form: String = "base"
	if loser.color_index >= 0:
		loser_form = Constants.PLAYER_FORMS[loser.color_index]
	_loser_animated_sprite.play(loser_form)

	_winner_screen.show()


func _scores_changed() -> void:
	_hud.set_score(0, _scores[0])
	_hud.set_score(1, _scores[1])
	if _players.size() > 1:
		_players[0].score = _scores[0]
		_players[1].score = _scores[1]


func _spawn_first_masks() -> void:
	var available_mask_color_indices: Array[int] = _get_available_mask_color_indices()
	if available_mask_color_indices.is_empty():
		push_error("Available mask color indices was empty on first mask spawn!?")
	available_mask_color_indices.shuffle()

	var coord: Vector2i
	var color_index: int

	coord = [Vector2i(0, Constants.NUM_ROWS - 2), Vector2i(1, Constants.NUM_ROWS - 1)].pick_random()
	color_index = available_mask_color_indices.pop_back()
	_spawn_mask_at(coord, color_index)

	coord = [Vector2i(Constants.NUM_COLS - 2, 0), Vector2i(Constants.NUM_COLS - 1, 1)].pick_random()
	color_index = available_mask_color_indices.pop_back()
	_spawn_mask_at(coord, color_index)


func _delay_spawn_mask() -> void:
	var reset_index: int = _reset_index
	await get_tree().create_timer(Constants.MASK_SPAWN_DELAY_S).timeout

	if _reset_index != reset_index:
		return

	var success: bool = false
	while !success:
		success = _try_spawn_mask()
		await get_tree().create_timer(Constants.MASK_SPAWN_RETRY_S).timeout

		if _reset_index != reset_index:
			return


func _try_spawn_mask() -> bool:
	var available_coords: Array[Vector2i] = _get_yonder_coords()
	if available_coords.is_empty():
		return false

	var available_mask_color_indices: Array[int] = _get_available_mask_color_indices()
	if available_mask_color_indices.is_empty():
		return false

	var coord: Vector2i = available_coords.pick_random()
	var color_index: int = available_mask_color_indices.pick_random()

	_spawn_mask_at(coord, color_index)

	return true


func _spawn_mask_at(coord: Vector2i, color_index: int) -> void:
	var mask: Mask = _mask_scene.instantiate()
	mask.color_index = color_index
	mask.picked_up.connect(_mask_picked_up.bind(mask))
	mask.position = _tilemap.map_to_local(coord)
	_mask_container.add_child(mask)
	_masks.append(mask)


func _get_available_mask_color_indices() -> Array[int]:
	var result: Array[int]
	for color_index: int in range(Constants.COLORS.size()):
		if _masks.any(func(mask: Mask) -> bool: return mask.color_index == color_index):
			continue
		if _players.any(func(player: Player) -> bool: return player.color_index == color_index):
			continue
		result.append(color_index)
	return result


func _mask_picked_up(player: Player, mask: Mask) -> void:
	_masks.erase(mask)

	_delay_spawn_mask()

	_update_clip_tilemap(player)


func _get_diagonal_coords() -> Array[Vector2i]:
	var result: Array[Vector2i]
	for i: int in range(min(Constants.NUM_COLS, Constants.NUM_ROWS)):
		result.append(Vector2i(i, i))
	return result


# Return empty coords that aren't too close to either player.
func _get_yonder_coords() -> Array[Vector2i]:
	var result: Array[Vector2i]
	for c: int in range(Constants.NUM_COLS):
		for r: int in range(Constants.NUM_ROWS):
			var coord: Vector2i = Vector2i(c, r)
			if !_is_coord_empty(coord):
				continue
			if _is_coord_near_player(coord):
				continue
			result.append(coord)
	return result


func _is_coord_near_player(coord: Vector2i) -> bool:
	var neighbors: Array[TileSet.CellNeighbor] = [
		TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_SIDE,
		TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
		TileSet.CellNeighbor.CELL_NEIGHBOR_RIGHT_SIDE,
		TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
		TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_SIDE,
		TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
		TileSet.CellNeighbor.CELL_NEIGHBOR_LEFT_SIDE,
		TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_CORNER,
	]

	for player: Player in _players:
		var player_coord: Vector2i = _tilemap.local_to_map(player.position)
		for neighbor: TileSet.CellNeighbor in neighbors:
			if _tilemap.get_neighbor_cell(player_coord, neighbor) == coord:
				return true
	return false


func _get_empty_coord() -> Vector2i:
	var result: Vector2i = _get_random_coord()
	while !_is_coord_empty(result):
		result = _get_random_coord()
	return result


func _is_coord_empty(coord: Vector2i) -> bool:
	for player: Player in _players:
		if _tilemap.local_to_map(player.position) == coord:
			return false

	for mask: Mask in _masks:
		if _tilemap.local_to_map(mask.position) == coord:
			return false

	if _goal and _tilemap.local_to_map(_goal.position) == coord:
		return false

	return true


func _get_random_coord() -> Vector2i:
	return Vector2i(randi() % Constants.NUM_COLS, randi() % Constants.NUM_ROWS)


func _reveal_clip_tilemap(player: Player) -> void:
	var clip_tilemap: TileMapLayer = _get_clip_tilemap(player)
	for c: int in range(Constants.NUM_COLS):
		for r: int in range(Constants.NUM_ROWS):
			var coord: Vector2i = Vector2i(c, r)
			clip_tilemap.set_cell(coord, 0, Vector2i(0, 0))


func _update_clip_tilemap(player: Player) -> void:
	var clip_tilemap: TileMapLayer = _get_clip_tilemap(player)
	for c: int in range(Constants.NUM_COLS):
		for r: int in range(Constants.NUM_ROWS):
			var coord: Vector2i = Vector2i(c, r)
			if _get_coord_color_index(coord) == player.color_index:
				# Erase the cell.
				clip_tilemap.set_cell(coord, -1)
			else:
				clip_tilemap.set_cell(coord, 0, Vector2i(0, 0))


func _get_clip_tilemap(player: Player) -> TileMapLayer:
	if player.player_num == 0:
		return _clip_tilemap_player0
	return _clip_tilemap_player1


func _get_coord_color_index(coord: Vector2i) -> int:
	var atlas_coord: Vector2i = _tilemap.get_cell_atlas_coords(coord)
	return atlas_coord.x


func _get_coord_color(coord: Vector2i) -> Color:
	var atlas_coord: Vector2i = _tilemap.get_cell_atlas_coords(coord)
	return Constants.COLORS[atlas_coord.x]


func _input(event: InputEvent) -> void:
	if !OS.has_feature("template") and event.is_action_pressed("reset"):
		reset()

	if _winner_screen.visible and event.is_action_pressed("proceed"):
		_winner_screen.hide()
		reset()

	# Quickly quit if this is the root scene. Normally this scene would have Main as a parent.
	if (
		get_parent() == get_tree().root
		and event.is_action_pressed("ui_cancel")
		and !event.is_echo()
	):
		get_tree().quit()
