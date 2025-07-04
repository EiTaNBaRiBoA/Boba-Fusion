extends CharacterBody2D

signal armed
signal dropped

const SPEED := 700
const BUBBLE_DROP_IMPULSE := 800
const ARM_DURATION := 0.5 # sec

var is_armed := false

var drop_position_x := 0.0 # global
var user_dropped := false

var current_bubble: TapiocaBubble

@onready var timer := $Timer
@onready var next_bubble_position: Vector2 = $Marker2D.position
@onready var collision_shape := $CollisionShape2D


func arm(p_bubble: TapiocaBubble):
	if is_armed:
		return
	
	is_armed = true
	drop_position_x = 0.0
	position.x = 0.0
	
	var tween := get_tree().create_tween()
	tween.tween_property(p_bubble, "global_position", global_position, ARM_DURATION
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	
	await tween.finished
	
	if not is_instance_valid(p_bubble): # bubble has been freed while tweening
		return
	
	current_bubble = p_bubble
	collision_shape.shape = current_bubble.get_collision_shape()
	armed.emit()


func unarm():
	is_armed = false
	user_dropped = false
	current_bubble = null


func _physics_process(delta):
	if not is_armed:
		return
		
	var target := Vector2(drop_position_x, global_position.y)
	
	if SPEED*0.1 < position.distance_squared_to(target):
		var movement := position.direction_to(target)* SPEED
		var collision := move_and_collide(movement * delta)
		
		if is_instance_valid(current_bubble):
			current_bubble.global_position = global_position
		
		if collision:
			drop()
	
	elif user_dropped:
		drop()


func _on_user_inputs_controller_bubble_dropped(pos_x: float) -> void:
	if not is_armed:
		return
	
	if user_dropped:
		return
	
	drop_position_x = pos_x
	user_dropped = true


func drop():
	if not is_instance_valid(current_bubble):
		return
	
	current_bubble.fall(BUBBLE_DROP_IMPULSE)
	
	is_armed = false
	current_bubble = null
	
	user_dropped = false
	drop_position_x = 0.0
	dropped.emit()
