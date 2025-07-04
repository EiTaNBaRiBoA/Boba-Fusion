extends Node2D


signal menu_pressed

signal score_updated(score: int, color: Color)
signal multiplicator_updated(multiplicator: int)

signal ended


const TOP_SCREEN_MARIN := 350 #px
const BOTTOM_SCREEN_MARGIN := 50 #px
const CLAW_BOX_MARING := 105

const MULTIPLICATOR_MAX := 8

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
@onready var claw := $Claw
@onready var claw_magazine := $Claw/ClawManagazine
@onready var cup := $Cup
@onready var bubbles_pool := $BubblesPool
@onready var camera := $Camera2D


func _ready():
	var tint: Tint = tints_list.get_random_tint()
	background.color = tint.background_color
	cup.tint = tint


func _on_menu_button_pressed() -> void:
	menu_pressed.emit()


func start():
	claw_magazine.attach()


func _on_claw_managazine_loaded(bubble: TapiocaBubble) -> void:
	bubble.fusionned.connect(_on_bubble_fusionned)
	bubble.poped.connect(_on_bubble_poped.bind(bubble))


func _on_bubble_fusionned(bubble_a: TapiocaBubble, bubble_b: TapiocaBubble):
	var next_variation := bubble_a.get_evolution()
	
	claw_magazine.unlock_bubble(next_variation)
	score_color = next_variation.color
	
	multiplicator = min(MULTIPLICATOR_MAX, multiplicator + 1)
	score += (2*bubble_b.points) * multiplicator
	multiplicator_timer.start()


func _on_bubble_poped(p_bubble: TapiocaBubble):
	score += p_bubble.points


func _on_multiplicator_timer_timeout() -> void:
	multiplicator = 0


func _on_cup_overflowed() -> void:
	end()


func end():
	claw.unarm()
	claw_magazine.detach()
	await bubbles_pool.pop_bubbles()
	ended.emit()


func reset():
	score = 0
	cup.reset()
	claw.unarm()
	claw_magazine.reset()
	bubbles_pool.clean()
