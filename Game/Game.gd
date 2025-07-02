extends Node2D


signal menu_pressed

signal score_updated(score: int, color: Color)
signal multiplicator_updated(multiplicator: int)

signal ended


const TOP_SCREEN_MARIN := 350 #px
const BOTTOM_SCREEN_MARGIN := 50 #px
const CLAW_BOX_MARING := 105

const MULTIPLICATOR_MAX := 8

@export var BubbleScene: PackedScene
@export var tints_list: Resource

var score := 0:
	set(x):
		score = x
		score_updated.emit(score, score_color)

var score_color: Color
var multiplicator := 0:
	set(x):
		multiplicator = x
		multiplicator_updated.emit(multiplicator)

@onready var background := $Background/ColorRect
@onready var foreground := $Foreground #HUD

@onready var multiplicator_timer := $MultiplicatorTimer
@onready var pop_timer := $PopTimer
@onready var claw := $Claw
@onready var claw_loader := $Claw/ClawLoader
@onready var cup := $Cup
@onready var bubbles := $Bubbles
@onready var camera := $Camera2D


func _ready():
	var tint: Tint = tints_list.get_random_tint()
	background.color = tint.background_color
	cup.tint = tint


func _on_menu_button_pressed() -> void:
	menu_pressed.emit()


func start():
	#claw_loader.roll_next_bubble()
	load_claw()


func load_claw():
	claw_loader.roll_next_bubble()
	
	var bubble: TapiocaBubble = BubbleScene.instantiate()
	bubbles.add_child(bubble)
	bubble.variation = claw_loader.next_variation
	bubble.fusionned.connect(_on_bubble_fusionned)
	claw.load_bubble(bubble)
	
	print_rich(bubble.variation)
	print_stack()


func _on_Claw_armed():
	load_claw()


func _on_bubble_fusionned(bubble_a: TapiocaBubble, bubble_b: TapiocaBubble):
	var next_variation := bubble_a.get_evolution()
	
	claw_loader.unlock_bubble(next_variation)
	score_color = next_variation.color
	
	multiplicator = min(MULTIPLICATOR_MAX, multiplicator + 1)
	score += (2*bubble_b.points) * multiplicator
	multiplicator_timer.start()


func _on_MultiplicatorTimer_timeout():
	self.multiplicator = 0


func _on_cup_overflowed() -> void:
	end()


func end():
	
	claw.unload()
	
	var bubbles_sorted := bubbles.get_children()
	bubbles_sorted.sort_custom(_comp_bubble_heigth)
	
	var max_time := 0.35
	var min_time := 0.1
	
	var i := 0
	for bubble in bubbles_sorted:
		if not is_instance_valid(bubble):
			continue
		
		self.score += bubble.points
		bubble.pop()
	
		var time = lerp(max_time, min_time, float(i/5.0))
		i += 1
		
		pop_timer.start(time)
		await pop_timer.timeout
	
	pop_timer.start(1.0)
	await pop_timer.timeout
	ended.emit()


func _comp_bubble_heigth(bubble_a: TapiocaBubble, bubble_b: TapiocaBubble):
	if bubble_a.in_danger == bubble_b.in_danger:
		return bubble_a.global_position.y < bubble_b.global_position.y
	
	return bubble_a.in_danger


func reset():
	self.score = 0
	cup.reset()
	claw.unload()
	claw_loader.reset()
	
	for bubble in bubbles.get_children():
		bubble.delete()
