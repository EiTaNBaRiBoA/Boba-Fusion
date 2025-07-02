class_name BubbleVariation extends Resource

@export var points: int = 0
@export var texture: Texture2D
@export var color: Color
@export var radius: float


func _to_string() -> String:
	return """BubbleVariation with :
	- points: {points}
	- radius: {radius}
	- texture: [img={image_size}]{image}[/img]
	- color: [color=#{color}]{color}[/color]
	""".format({
		"points": points,
		"radius": radius,
		"image": texture.resource_path,
		"image_size": 3000/radius,
		"color": color.to_html(false),
	})
