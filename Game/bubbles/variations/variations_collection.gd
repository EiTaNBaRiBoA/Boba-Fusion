extends Resource


@export var collection: Array[BubbleVariation]

var indexes: Dictionary[BubbleVariation, int] = {}


func get_evolution(p_variation: BubbleVariation) -> BubbleVariation:
	var new_index := 0
	if p_variation in indexes:
		new_index = indexes[p_variation]
	
	else:
		new_index = (collection.find(p_variation) + 1) % len(collection)
	
	return collection[new_index]
