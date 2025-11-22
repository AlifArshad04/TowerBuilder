extends Node
class_name ScoreManager

# Very simple scoring: height only
const HEIGHT_SCORE_RATE: float = 1.0    # 1 point per pixel of height

var elapsed_time: float = 0.0
var max_height: float = 0.0       # in pixels above some baseline


func reset() -> void:
	elapsed_time = 0.0
	max_height = 0.0


func get_height_score() -> int:
	return int(round(max_height * HEIGHT_SCORE_RATE))


func get_total_score() -> int:
	# For now: just height, no time penalty
	return max(get_height_score(), 0)
