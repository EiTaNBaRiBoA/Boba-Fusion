extends Node2D


@export var poping_interval_min := 0.1
@export var poping_interval_max := 0.35

var poping_center: Vector2


func pop_bubbles():
	var bubbles_sorted := get_children()
	
	for bubble in bubbles_sorted:
		if bubble.in_danger:
			poping_center = bubble.global_position
			break
	
	bubbles_sorted.sort_custom(_comp_bubble_heigth)
	
	var i := 0
	for bubble in bubbles_sorted:
		if not is_instance_valid(bubble):
			continue
		
		bubble.pop()
	
		var time = lerp(poping_interval_max, poping_interval_min, float(i/5.0))
		i += 1
		
		await get_tree().create_timer(time).timeout
	
	await get_tree().create_timer(1.0).timeout


func _comp_bubble_heigth(bubble_a: TapiocaBubble, bubble_b: TapiocaBubble):
	var distance_a := bubble_a.global_position.distance_squared_to(poping_center)
	var distance_b := bubble_b.global_position.distance_squared_to(poping_center)
	
	return distance_a < distance_b


func clean():
	for bubble in get_children():
		bubble.delete()
