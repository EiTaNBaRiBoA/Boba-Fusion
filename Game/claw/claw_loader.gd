extends Node


@export var start_sequence: Array[BubbleVariation]
@export var bubble_variations: Array[BubbleVariation]

var loaded_index := 0
var bubbles_unlocked = [] # bubble autorized to be loaded, bubble of the claw list can only be loaded if already seen in the current game
var next_variation: BubbleVariation


func roll_next_bubble():
	if loaded_index < len(start_sequence):
		next_variation = start_sequence[loaded_index] # in this order
		loaded_index += 1
	
	else:
		next_variation = bubbles_unlocked.pick_random()
	
	unlock_bubble(next_variation)


func unlock_bubble(p_variation: BubbleVariation):
	if not p_variation in bubble_variations:
		return
	
	if p_variation in bubbles_unlocked:
		return
	
	bubbles_unlocked.append(p_variation)


func reset():
	bubbles_unlocked.clear()
	loaded_index = 0
