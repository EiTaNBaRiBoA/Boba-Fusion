extends RigidBody2D
class_name TapiocaBubble


signal growned
signal fusionned(bubble_a: TapiocaBubble, bubble_b: TapiocaBubble)
signal poped


const BASE_RADIUS := 108.0

const FALL_FUSION_IMPULSE := 500
const GROW_DURATION: float = 0.25 # sec
const FUSION_SPEED := 1000

const FALLING_VELOCITY_THRESHOLD: float = 200.0
const CRUSHED_CONTACT_THRESHOLD: int = 4
const ROLLING_VOLOCITY_THRESHOLD: float = 1.5


@export var variation: BubbleVariation:
	set(x):
		variation = x
		
		if not is_instance_valid(variation):
			return
		
		radius = variation.radius
		color = variation.color
		
		if not is_inside_tree():
			return
		
		sprite.texture = variation.texture
		size = 0.0

@export var variations_collection: Resource
@export var faces_collection: Array[SpriteFrames]

var points: int:
	get:
		if is_instance_valid(variation):
			return variation.points
		
		return 1
	
var radius: float = 20.0:
	set(x):
		radius = x
		face_ratio = float(radius/BASE_RADIUS)
		mass = float(radius)
		
		if not is_inside_tree():
			return
		
		scaler.scale = face_ratio * Vector2.ONE
		
		var shape := CircleShape2D.new()
		shape.radius = radius
		collision_shape.set_deferred("shape", shape)
		
		particules.scale_amount_min = face_ratio
		particules.scale_amount_max = face_ratio


var color: Color = Color.REBECCA_PURPLE:
	set(x):
		color = x
		
		if not is_inside_tree():
			return
		
		particules.modulate = color


var face_ratio := 1.0
var size := 0.0:
	set(x):
		sprite.scale = x * Vector2.ONE
		scaler.scale = x * face_ratio * Vector2.ONE
		collision_shape.shape.radius = radius * x


var fluid_density: float = 0.0
var physic_activated := false:
	set(x):
		physic_activated = x
		if x:
			max_contacts_reported = 4
			contact_monitor = true
			set_collision_layer_value(1, true)
			set_collision_mask_value(1, true)
			freeze = false
		
		else:
			max_contacts_reported = 0
			contact_monitor = false
			set_collision_layer_value(1, false)
			set_collision_mask_value(1, false)
			freeze = true

var is_fusionned := false
var invincible := true:
	set(x):
		invincible = x
		set_collision_layer_value(2, not invincible)

var falling := false
var rolling := false
var crushed := false
var in_danger := false

@onready var animation_player := $AnimationPlayer
@onready var invincibility_timer := $Timer
@onready var scaler := $Scaler
@onready var sprite := $Sprite2D
@onready var animated_face := $Scaler/Face
@onready var collision_shape := $CollisionShape2D

@onready var particules := $Particles2D
@onready var audio_player_a := $AudioStreamPlayer2DA
@onready var audio_player_b := $AudioStreamPlayer2DB


func _ready():
	#variation = variation
	physic_activated = false
	animation_player.play("RESET")
	animated_face.frames = faces_collection.pick_random()


func get_collision_shape() -> Shape2D:
	return collision_shape.shape


func grow(from_fusion := false):
	if from_fusion:
		audio_player_a.pitch_scale = randf_range(0.95, 1.05)
		audio_player_b.pitch_scale = randf_range(0.98, 1.02)
		animation_player.play("fusion")
	
	var tween := get_tree().create_tween()
	tween.tween_property(self, "size", 1.0, GROW_DURATION
		).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	growned.emit()


func fall(impulse: int = 1):
	set_deferred("physic_activated", true)
	apply_central_impulse(mass * impulse * Vector2.DOWN) # small impulse to feel gravity again
	invincibility_timer.start()


func _on_invincibility_timeout():
	invincible = false


func pop():
	set_deferred("physic_activated", false)
	audio_player_a.pitch_scale = randf_range(0.95, 1.05)
	animation_player.play("pop")
	poped.emit()
	await animation_player.animation_finished


func delete(pos: Vector2 = global_position):
	set_deferred("physic_activated", false)
	
	var distance := global_position.distance_to(pos)
	var time := distance/FUSION_SPEED
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", pos, time)
	await tween.finished
	queue_free()


func get_evolution() -> BubbleVariation:
	return variations_collection.get_evolution(variation)


func evolve(pos: Vector2 = global_position):
	set_deferred("physic_activated", false)
	
	var distance := global_position.distance_to(pos)
	var time := distance/FUSION_SPEED
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", pos, time)
	await tween.finished
	
	variation = get_evolution()
	set_deferred("physic_activated", true)
	is_fusionned = false
	
	fall(FALL_FUSION_IMPULSE)
	await grow(true)


func _process(_delta):
	if falling:
		animated_face.play("falling")
	
	elif rolling:
		animated_face.play("rolling")
	
	elif crushed:
		animated_face.play("crushed")
	
	elif in_danger:
		animated_face.play("in_danger")
	
	else:
		animated_face.play("idle")


func _integrate_forces(state: PhysicsDirectBodyState2D):
	falling = bool(state.linear_velocity.y > FALLING_VELOCITY_THRESHOLD)
	crushed = bool(state.get_contact_count() >= CRUSHED_CONTACT_THRESHOLD)
	rolling = bool(abs(state.angular_velocity) > ROLLING_VOLOCITY_THRESHOLD)
	
	var A = radius*2.0
	var Cd = 0.01
	var drag = -0.5*fluid_density*state.linear_velocity*abs(state.linear_velocity)*A*Cd
	state.apply_central_force(drag)
	
	var angular_drag = -0.5*fluid_density*state.angular_velocity*abs(state.angular_velocity)*A*Cd
	state.apply_torque(angular_drag)


func _on_body_entered(body):
	
	if not body is TapiocaBubble:
		return
	
	if body.variation != variation: # same type of bubbles
		return
	
	if body.name > name: # only one body raise the collision
		return
	
	if is_fusionned: # don't fusion with another in the mean time
		return
	
	fusion_with_other(body)


func fusion_with_other(other: TapiocaBubble):
	is_fusionned = true
	other.is_fusionned = true
	fusionned.emit(self, other)
	
	var pos: Vector2 = (global_position + other.global_position) * 0.5 # center betwen two points
	
	other.delete(pos)
	await evolve(pos)
