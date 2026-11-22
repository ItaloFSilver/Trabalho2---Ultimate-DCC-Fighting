extends TileMap 

@export var first_frame: Texture2D
@export var second_frame: Texture2D
@export var third_frame: Texture2D
@export var frame_time: float

var _frames: Array[Texture2D] = []
var _current_index: int = 0
var _time: float = 0.0
var _atlas_source: TileSetAtlasSource


func _ready() -> void:
	_frames = [first_frame, second_frame, third_frame, second_frame]

	if tile_set and tile_set.get_source_count() > 0:
		var source_id := tile_set.get_source_id(0)
		_atlas_source = tile_set.get_source(source_id) as TileSetAtlasSource


func _process(delta: float) -> void:
	if not _atlas_source or _frames.is_empty():
		return

	_time += delta
	if _time >= frame_time:
		_time = 0.0
		_current_index = (_current_index + 1) % _frames.size()
		if _frames[_current_index]:
			_atlas_source.texture = _frames[_current_index]
