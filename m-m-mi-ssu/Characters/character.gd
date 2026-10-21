extends Resource
class_name Character

# A dateable character.
#
# - name: display name used in the dialog box.
# - portraits: one Texture2D per emotion, matched by the emotion strings used in
#   the dialog format ("Neutral", "Happy", "Sad", "Angry", "Embarrassed", "Flustered").
# - current_trust: 0 to 10, stored in 0.5 intervals.
# - has_met: whether the player has met this character yet.

@export var name: String = ""

@export var neutral_portrait: Texture2D
@export var happy_portrait: Texture2D
@export var sad_portrait: Texture2D
@export var angry_portrait: Texture2D
@export var embarrassed_portrait: Texture2D
@export var flustered_portrait: Texture2D

@export_range(0.0, 10.0, 0.5)
var current_trust: float = 0.0

@export var has_met: bool = false

# Returns the portrait texture for the given emotion. Falls back to neutral if
# the emotion is unknown or the portrait is missing.
func get_portrait(emotion: String) -> Texture2D:
	match emotion:
		"Neutral":
			return neutral_portrait
		"Happy":
			return happy_portrait
		"Sad":
			return sad_portrait
		"Angry":
			return angry_portrait
		"Embarrassed":
			return embarrassed_portrait
		"Flustered":
			return flustered_portrait
		_:
			return neutral_portrait

# Changes trust by `delta`, snapping to 0.5 intervals and clamping to [0, 10].
# Returns the new trust value.
func change_trust(delta: float) -> float:
	current_trust = clamp(round((current_trust + delta) * 2.0) / 2.0, 0.0, 10.0)
	return current_trust

# Sets trust directly, snapping to 0.5 intervals and clamping to [0, 10].
func set_trust(value: float) -> float:
	current_trust = clamp(round(value * 2.0) / 2.0, 0.0, 10.0)
	return current_trust
