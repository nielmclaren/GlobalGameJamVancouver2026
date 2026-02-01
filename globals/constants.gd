extends Node

# Order must match the tileset left-to-right.
var COLORS: Array[Color] = [
	Color.from_string("#6ab2e4", Color.RED),
	Color.from_string("#ca6ae4", Color.RED),
	Color.from_string("#6ae4a7", Color.RED),
	Color.from_string("#e4bf6a", Color.RED),
]

const NUM_COLS: int = 4
const NUM_ROWS: int = 4

const NUM_MASKS: int = 2

# How long to wait after a mask is picked up.
const MASK_SPAWN_DELAY_S: float = 1.

# How long to wait after spawning a mask failed (due to no available spaces).
const MASK_SPAWN_RETRY_S: float = 0.2

# How long to wait after a goal is picked up.
const GOAL_SPAWN_DELAY_S: float = 3.

# How long to wait after spawning a goal failed (due to no available spaces).
const GOAL_SPAWN_RETRY_S: float = 0.2

const TILE_SIZE: int = 128
const TILE_HALF_SIZE: int = 64

const COLLISION_LAYER: int = 1
const PICKUP_LAYER: int = 2
const ATTACK_LAYER: int = 3
