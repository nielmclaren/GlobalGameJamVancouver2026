class_name Game
extends Node2D

signal completed(winner_player_index: int)

var is_online_multiplayer: bool = false
var is_game_host: bool = false
var local_player_index: int = -1

var _mask_scene: PackedScene = load("res://game_objects/mask.tscn")
var _goal_scene: PackedScene = load("res://game_objects/goal.tscn")
var _player_scene: PackedScene = load("res://characters/player.tscn")

var _is_game_started: bool = false
var _players: Array[Player]
var _id_to_mask: Dictionary  # mask ID -> Mask
var _next_mask_id: AutoIncrement = AutoIncrement.new()
var _goal: Goal
var _scores: Array[int] = [0, 0]

@onready var _clip_tilemap_player0: TileMapLayer = %ClipTileMapPlayer0
@onready var _player_container0: Node2D = %ClipMaskPlayer0
@onready var _clip_tilemap_player1: TileMapLayer = %ClipTileMapPlayer1
@onready var _player_container1: Node2D = %ClipMaskPlayer1
@onready var _goal_container: Node2D = %GoalContainer
@onready var _mask_container: Node2D = %MaskContainer
@onready var _tilemap: TileMapLayer = %TileMapLayer
@onready var _hud: Hud = %Hud
@onready var _map_regen_timer: Timer = %MapRegenTimer
@onready var _score_sound: AudioStreamPlayer = %ScoreSound
@onready var _level_ready_timer: Timer = %LevelReadyTimer


func _ready() -> void:
	Tracer.trace("Game ready.")
	if is_online_multiplayer:
		MultiplayerManager.message_received.connect(_message_received)

	_map_regen_timer.timeout.connect(_map_regen_timeout)

	_init_clip_tiles()

	if !is_online_multiplayer:
		# Local game can start right away.
		start()

	elif !is_game_host:
		# For an online game, the game client sends "ready" repeatedly until game host starts the game.
		_level_ready_timer.timeout.connect(
			func _level_ready_timeout() -> void:
				MultiplayerManager.send(MultiplayerMessage.new(get_path(), "ready"))
		)


func start() -> void:
	_is_game_started = true

	var rand_seed: int = randi()
	_randomize_tiles(rand_seed)

	_spawn_player(0, _tilemap.map_to_local(Vector2i(0, 3)))
	_spawn_player(1, _tilemap.map_to_local(Vector2i(3, 0)))

	_spawn_first_masks()

	_try_spawn_goal(true)

	if !is_online_multiplayer or is_game_host:
		_map_regen_timer.start()


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


func _spawn_player(player_index: int, initial_position: Vector2) -> Player:
	var player: Player = _player_scene.instantiate()
	player.setup(self)

	player.is_online_multiplayer = is_online_multiplayer
	player.is_game_host = is_game_host
	player.is_local_player = local_player_index == player_index
	player.player_index = player_index
	player.position = initial_position

	player.masked.connect(_mask_player.bind(player))
	player.unmasked.connect(_unmask_player.bind(player))
	player.hitted.connect(_player_hitted.bind(player))

	if player_index == 0:
		_player_container0.add_child(player)
	else:
		_player_container1.add_child(player)

	player.name = "Player%d" % player_index

	if is_online_multiplayer and is_game_host:
		_game_host_send_spawn_player(player)

	_players.append(player)

	return player


func _game_host_send_spawn_player(player: Player) -> void:
	MultiplayerManager.send(
		(
			MultiplayerMessage
			. new(get_path(), "spawn_player")
			. append_int(player.player_index)
			. append_vector2(player.position)
		)
	)


func _map_regen_timeout() -> void:
	Tracer.trace("Map regen timeout.")
	var rand_seed: int = randi()
	_randomize_tiles(rand_seed)

	for player: Player in _players:
		_update_clip_tilemap(player)
		player.is_stealthed = is_in_stealth_tile(player)
		player.is_stunned = false


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


func _generate_random_tiles(rand_seed: int) -> Array[Vector2i]:
	# Build a list of tile atlas positions with an equal number of each tile.
	var tiles: Array[Vector2i]
	for i: int in range(Constants.NUM_ROWS * Constants.NUM_COLS):
		tiles.append(Vector2i(i % Constants.COLORS.size(), 0))

	seed(rand_seed)
	tiles.shuffle()
	randomize()

	return tiles


func _randomize_tiles(rand_seed: int) -> void:
	var tiles: Array[Vector2i] = _generate_random_tiles(rand_seed)

	for c: int in range(Constants.NUM_COLS):
		for r: int in range(Constants.NUM_ROWS):
			var tile: Vector2i = tiles.pop_back()
			var coord: Vector2i = Vector2i(c, r)
			_tilemap.set_cell(coord, 1, tile)

	if is_online_multiplayer and is_game_host:
		_game_host_send_randomize_tiles(rand_seed)


func _game_host_send_randomize_tiles(rand_seed: int) -> void:
	MultiplayerManager.send(
		MultiplayerMessage.new(get_path(), "randomize_tiles").append_int(rand_seed)
	)


func _init_clip_tiles() -> void:
	# Enable all clip tiles.
	var atlas_coord: Vector2i = Vector2i(0, 0)
	for c: int in range(Constants.NUM_COLS):
		for r: int in range(Constants.NUM_ROWS):
			var coord: Vector2i = Vector2i(c, r)
			_clip_tilemap_player0.set_cell(coord, 0, atlas_coord)
			_clip_tilemap_player1.set_cell(coord, 0, atlas_coord)


func _mask_player(player: Player) -> void:
	_update_clip_tilemap(player)


func _unmask_player(player: Player) -> void:
	_reveal_clip_tilemap(player)


func _player_hitted(player: Player) -> void:
	_scores[player.player_index] = 0
	_scores_changed()


func _delay_spawn_goal() -> void:
	await get_tree().create_timer(Constants.GOAL_SPAWN_DELAY_S).timeout

	var success: bool = false
	while !success:
		success = _try_spawn_goal()
		await get_tree().create_timer(Constants.GOAL_SPAWN_RETRY_S).timeout


func _try_spawn_goal(is_first_spawn: bool = false) -> bool:
	var available_coords: Array[Vector2i] = _get_diagonal_coords()
	if is_first_spawn:
		available_coords = _get_diagonal_coords()
	else:
		available_coords = _get_yonder_coords()

	if available_coords.is_empty():
		return false

	var coord: Vector2i = available_coords.pick_random()
	_spawn_update_goal(coord)
	return true


func _spawn_update_goal(coord: Vector2i) -> void:
	if !_goal:
		_goal = _goal_scene.instantiate()
		_goal.picked_up.connect(_goal_picked_up)
		_goal_container.add_child(_goal)

	_goal.coord = coord
	_goal.position = _tilemap.map_to_local(coord)

	if is_online_multiplayer and is_game_host:
		_game_host_send_goal_state()


func _despawn_goal() -> void:
	if _goal:
		_goal.queue_free()
		_goal = null

	if is_online_multiplayer and is_game_host:
		_game_host_send_goal_state()


func _game_host_send_goal_state() -> void:
	var message: MultiplayerMessage = MultiplayerMessage.new(get_path(), "goal_state")
	if _goal:
		message.append_vector2(_goal.coord)
	MultiplayerManager.send(message)


func _goal_picked_up(player: Player) -> void:
	Tracer.trace("Player %d scored!" % player.player_index)
	print("Player %d scored!" % player.player_index)

	if !is_online_multiplayer or is_game_host:
		_scores[player.player_index] += 1
		_scores_changed()

		_despawn_goal()

		if _scores[player.player_index] >= Constants.MAX_SCORE:
			print("Player %d won!" % player.player_index)
			var other_player: Player = _players[1 - player.player_index]
			completed.emit(player.player_index, player.color_index, other_player.color_index)

			if is_online_multiplayer and is_game_host:
				_game_host_send_game_over(
					player.player_index, player.color_index, other_player.color_index
				)

		else:
			_delay_spawn_goal()

			# TODO: Trigger sound on game client.
			if !_score_sound.playing:
				_score_sound.play()


func _game_host_send_game_over(
	player_index: int, winner_color_index: int, loser_color_index: int
) -> void:
	MultiplayerManager.send(
		(
			MultiplayerMessage
			. new(get_path(), "game_over")
			. append_int(player_index)
			. append_int(winner_color_index)
			. append_int(loser_color_index)
		)
	)


func _scores_changed() -> void:
	_hud.set_score(0, _scores[0])
	_hud.set_score(1, _scores[1])
	if _players.size() > 1:
		_players[0].score = _scores[0]
		_players[1].score = _scores[1]

	if is_online_multiplayer and is_game_host:
		_game_host_send_score_state()


func _game_host_send_score_state() -> void:
	MultiplayerManager.send(
		MultiplayerMessage.new(get_path(), "score_state").append_int(_scores[0]).append_int(
			_scores[1]
		)
	)


func _spawn_first_masks() -> void:
	var available_mask_color_indices: Array[int] = _get_available_mask_color_indices()
	if available_mask_color_indices.is_empty():
		push_error("Available mask color indices was empty on first mask spawn!?")
	available_mask_color_indices.shuffle()

	var coord: Vector2i
	var color_index: int

	coord = [Vector2i(0, Constants.NUM_ROWS - 2), Vector2i(1, Constants.NUM_ROWS - 1)].pick_random()
	color_index = available_mask_color_indices.pop_back()
	_spawn_update_mask(_next_mask_id.value(), coord, color_index)

	coord = [Vector2i(Constants.NUM_COLS - 2, 0), Vector2i(Constants.NUM_COLS - 1, 1)].pick_random()
	color_index = available_mask_color_indices.pop_back()
	_spawn_update_mask(_next_mask_id.value(), coord, color_index)


func _delay_spawn_mask() -> void:
	await get_tree().create_timer(Constants.MASK_SPAWN_DELAY_S).timeout

	var success: bool = false
	while !success:
		success = _try_spawn_mask()
		await get_tree().create_timer(Constants.MASK_SPAWN_RETRY_S).timeout


func _try_spawn_mask() -> bool:
	var available_coords: Array[Vector2i] = _get_yonder_coords()
	if available_coords.is_empty():
		return false

	var available_mask_color_indices: Array[int] = _get_available_mask_color_indices()
	if available_mask_color_indices.is_empty():
		return false

	var coord: Vector2i = available_coords.pick_random()
	var color_index: int = available_mask_color_indices.pick_random()

	_spawn_update_mask(_next_mask_id.value(), coord, color_index)

	return true


# If a mask with the given ID exists, it is updated instead.
func _spawn_update_mask(id: int, coord: Vector2i, color_index: int) -> Mask:
	var mask: Mask
	if id in _id_to_mask:
		mask = _id_to_mask[id]
	else:
		mask = _mask_scene.instantiate()
		mask.picked_up.connect(_mask_picked_up.bind(mask))
		_mask_container.add_child(mask)
		_id_to_mask[id] = mask

	mask.id = id
	mask.coord = coord
	mask.color_index = color_index
	mask.position = _tilemap.map_to_local(coord)

	if is_online_multiplayer and is_game_host:
		_game_host_send_mask_state()

	return mask


func _despawn_mask(id: int) -> void:
	var mask: Mask = _id_to_mask[id]
	mask.queue_free()
	_id_to_mask.erase(id)

	if is_online_multiplayer and is_game_host:
		_game_host_send_mask_state()


func _get_available_mask_color_indices() -> Array[int]:
	var result: Array[int]
	for color_index: int in range(Constants.COLORS.size()):
		if _id_to_mask.values().any(
			func(mask: Mask) -> bool: return mask.color_index == color_index
		):
			continue
		if _players.any(func(player: Player) -> bool: return player.color_index == color_index):
			continue
		result.append(color_index)
	return result


func _mask_picked_up(player: Player, mask: Mask) -> void:
	if !is_online_multiplayer or is_game_host:
		player.color_index = mask.color_index

		_despawn_mask(mask.id)

		_delay_spawn_mask()

		_update_clip_tilemap(player)

	if is_online_multiplayer and is_game_host:
		_game_host_send_player_mask_state()
		_game_host_send_mask_state()


func _game_host_send_player_mask_state() -> void:
	var message: MultiplayerMessage = MultiplayerMessage.new(get_path(), "player_mask_state")
	for player: Player in _players:
		message.append_int(player.color_index)
	MultiplayerManager.send(message)


func _game_host_send_mask_state() -> void:
	var message: MultiplayerMessage = MultiplayerMessage.new(get_path(), "mask_state")
	message.append_int(_id_to_mask.size())
	for mask: Mask in _id_to_mask.values():
		message.append_int(mask.id).append_vector2i(mask.coord).append_int(mask.color_index)
	MultiplayerManager.send(message)


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

	for mask: Mask in _id_to_mask.values():
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
	if player.player_index == 0:
		return _clip_tilemap_player0
	return _clip_tilemap_player1


func _get_coord_color_index(coord: Vector2i) -> int:
	var atlas_coord: Vector2i = _tilemap.get_cell_atlas_coords(coord)
	return atlas_coord.x


func _get_coord_color(coord: Vector2i) -> Color:
	var atlas_coord: Vector2i = _tilemap.get_cell_atlas_coords(coord)
	return Constants.COLORS[atlas_coord.x]


func _message_received(message: MultiplayerMessage) -> void:
	if !message.matches_path(get_path()):
		return

	match message.name:
		"ready":
			if is_game_host and !_is_game_started:
				start()

		"randomize_tiles":
			_randomize_tiles(message.get_int(0))

		"spawn_player":
			_level_ready_timer.stop()
			_spawn_player(message.get_int(0), message.get_vector2(1))

		"mask_state":
			_sync_mask_state(message)

		"player_mask_state":
			_players[0].color_index = message.get_int(0)
			_players[1].color_index = message.get_int(1)

		"goal_state":
			if message.arg_size() == 0:
				_despawn_goal()
			else:
				_spawn_update_goal(message.get_vector2(0))

		"score_state":
			_scores[0] = message.get_int(0)
			_scores[1] = message.get_int(1)
			_scores_changed()

		"game_over":
			completed.emit(message.get_int(0), message.get_int(1), message.get_int(2))


func _sync_mask_state(message: MultiplayerMessage) -> void:
	var doomed_mask_ids: Array[int]
	doomed_mask_ids.assign(_id_to_mask.keys())

	var num_masks: int = message.get_int(0)
	for i: int in range(num_masks):
		var id: int = message.get_int(3 * i + 1)
		var coord: Vector2i = message.get_vector2i(3 * i + 2)
		var color_index: int = message.get_int(3 * i + 3)
		_spawn_update_mask(id, coord, color_index)
		doomed_mask_ids.erase(id)

	for id: int in doomed_mask_ids:
		_despawn_mask(id)
