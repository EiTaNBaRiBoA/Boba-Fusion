extends Node2D


signal loaded(bubble: TapiocaBubble)


@export var start_sequence: Array[BubbleVariation]
@export var bubble_variations: Array[BubbleVariation]

@export var BubbleScene: PackedScene
@export var bubbles_pool: Node2D

var bubbles_unlocked = [] # bubble autorized to be loaded, bubble of the claw list can only be loaded if already seen in the current game
#var next_variation: BubbleVariation

var attached := false

var loaded_index := 0
var is_loaded := false
var loaded_bubble: TapiocaBubble

@onready var claw := get_parent()


func _ready() -> void:
	assert(BubbleScene)
	assert(bubbles_pool)


func attach():
	attached = true
	load_new_bubble()


func detach():
	attached = false
	unload()


func roll_next_bubble() -> BubbleVariation:
	var next_variation: BubbleVariation
	if loaded_index < len(start_sequence):
		next_variation = start_sequence[loaded_index] # in this order
		loaded_index += 1
	
	else:
		next_variation = bubbles_unlocked.pick_random()
	
	unlock_bubble(next_variation)
	return next_variation


func unlock_bubble(p_variation: BubbleVariation):
	if not p_variation in bubble_variations:
		return
	
	if p_variation in bubbles_unlocked:
		return
	
	bubbles_unlocked.append(p_variation)


func load_new_bubble():
	if not attached:
		return
	
	if is_loaded:
		return
	
	is_loaded = true
	loaded_bubble = BubbleScene.instantiate()
	bubbles_pool.add_child(loaded_bubble)
	loaded_bubble.variation = roll_next_bubble()
	loaded_bubble.global_position.x = 0
	loaded_bubble.global_position.y = global_position.y
	loaded_bubble.growned.connect(_on_bubble_growned.bind(loaded_bubble))
	loaded_bubble.grow()


func _on_bubble_growned(p_bubble: TapiocaBubble):
	if p_bubble.growned.is_connected(_on_bubble_growned):
		p_bubble.growned.disconnect(_on_bubble_growned)
	
	loaded.emit(p_bubble)
	
	if not claw.is_armed:
		claw.arm(p_bubble)
		unload()


func _on_claw_dropped() -> void:
	if not attached:
		return
	
	if not is_loaded:
		return
	
	if claw.is_armed:
		return
	
	claw.arm(loaded_bubble)
	unload()


func _on_claw_armed() -> void:
	if not attached:
		return
	
	load_new_bubble()


func unload():
	is_loaded = false
	loaded_bubble = null


func reset():
	detach()
	bubbles_unlocked.clear()
	loaded_index = 0
