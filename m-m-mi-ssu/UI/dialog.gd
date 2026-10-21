extends Node2D
class_name DialogUI

# Signals
signal location_finished  # Emitted when the location has no more runnable events.

# UI nodes
@onready var name_label = $Name
@onready var dialog_label = $Dialog
@onready var speaker1 = $Speaker1
@onready var speaker2 = $Speaker2
@onready var background = $Background
@onready var option_button_1 = $OptionButton1
@onready var option_button_2 = $OptionButton2

# Dialog state
var location: dialogs  # The location script (e.g. adminbldg) providing events.
var characters: Dictionary = {}  # Maps speaker name -> Character resource.
var current_event_name: String = ""
var current_event: Array = []
var current_entry_index: int = 0
var waiting_for_input: bool = false  # Set true while a regular entry is on screen.

# Stored option-button callables so they can be disconnected cleanly.
var _opt1_callable: Callable
var _opt2_callable: Callable

# Map emotion strings to the speaker sprite that should display them.
var emotion_to_sprite: Dictionary = {
	"Neutral": "Neutral",
	"Happy": "Happy",
	"Sad": "Sad",
	"Angry": "Angry",
	"Embarrassed": "Embarrassed",
	"Flustered": "Flustered",
}

# Call this to start playing a location. Plays every runnable event in
# event_priority order, then emits location_finished.
func run_location(loc: dialogs, chars: Dictionary = {}):
	location = loc
	characters = chars
	option_button_1.hide()
	option_button_2.hide()
	_show()
	_play_next_event()

# Plays the next runnable event, or finishes the location if none remain.
func _play_next_event():
	var event_name = location.get_next_runnable_event()
	if event_name == "":
		_location_done()
		return
	current_event_name = event_name
	current_event = location.get_event(event_name)
	current_entry_index = 0
	_show_entry()

# Displays the entry at current_entry_index inside current_event.
# current_event[0] is the prerequisite list; real entries start at index 1.
func _show_entry():
	var entry_index = current_entry_index + 1  # skip the prerequisite list
	if entry_index >= current_event.size():
		# Event fully read through. Mark completed and move to next event.
		location.mark_event_completed(current_event_name)
		_play_next_event()
		return

	var entry = current_event[entry_index]

	# Options branch: entry starts with a string (option text).
	if typeof(entry) == TYPE_ARRAY and entry.size() > 0 and typeof(entry[0]) == TYPE_STRING:
		_show_options(entry)
		return

	# Regular dialog entry:
	# [index, speaker, in_position, dialog, emotion, trust_gain, next_dialog_index, audiofilepath]
	var speaker: String = entry[1] if entry.size() > 1 else ""
	var in_position: int = entry[2] if entry.size() > 2 else 1
	var text: String = entry[3] if entry.size() > 3 else ""
	var emotion: String = entry[4] if entry.size() > 4 else "Neutral"
	var trust_gain: float = entry[5] if entry.size() > 5 else 0.0
	var next_index: int = entry[6] if entry.size() > 6 else -1

	name_label.text = speaker
	dialog_label.text = text
	_apply_trust_gain(speaker, trust_gain)
	_set_speaker_portrait(speaker, emotion, in_position)

	# Store where to go next once the player advances.
	var pending_next: int = next_index
	if pending_next >= 0 and pending_next < current_event.size():
		pending_next = pending_next - 1  # -1 because _show_entry adds +1
	else:
		pending_next = current_entry_index + 1

	# Wait for the player to click / press a key before advancing.
	waiting_for_input = true
	# Stash the target index on a temporary var for _advance to use.
	_set_next_target(pending_next)

# Stores the index to jump to when the player advances the current entry.
var _next_target_index: int = 0
func _set_next_target(idx: int):
	_next_target_index = idx

# Called by _input when the player advances a regular entry.
func _advance_entry():
	waiting_for_input = false
	current_entry_index = _next_target_index
	_show_entry()

func _input(event: InputEvent):
	if not waiting_for_input:
		return
	if event is InputEventMouseButton or event is InputEventKey:
		if event.pressed:
			event.accept()
			_advance_entry()

# Shows the two option buttons for an options entry.
# options entry: ["opt1_text", gain1, next1, "opt2_text", gain2, next2]
func _show_options(entry: Array):
	name_label.text = ""
	dialog_label.text = ""
	waiting_for_input = false

	var opt1_text: String = entry[0] if entry.size() > 0 else "Option 1"
	var opt1_gain: float = entry[1] if entry.size() > 1 else 0.0
	var opt1_next: int = entry[2] if entry.size() > 2 else -1
	var opt2_text: String = entry[3] if entry.size() > 3 else "Option 2"
	var opt2_gain: float = entry[4] if entry.size() > 4 else 0.0
	var opt2_next: int = entry[5] if entry.size() > 5 else -1

	option_button_1.text = opt1_text
	option_button_2.text = opt2_text
	option_button_1.show()
	option_button_2.show()

	# Reconnect the option buttons with the new targets.
	if _opt1_callable:
		option_button_1.pressed.disconnect(_opt1_callable)
	if _opt2_callable:
		option_button_2.pressed.disconnect(_opt2_callable)
	_opt1_callable = Callable(self, "_on_option_picked").bind(opt1_gain, opt1_next)
	_opt2_callable = Callable(self, "_on_option_picked").bind(opt2_gain, opt2_next)
	option_button_1.pressed.connect(_opt1_callable)
	option_button_2.pressed.connect(_opt2_callable)

func _on_option_picked(trust_gain: float, next_index: int):
	option_button_1.hide()
	option_button_2.hide()
	if next_index >= 0 and next_index < current_event.size():
		current_entry_index = next_index - 1
	else:
		# No next index: finish this event and move on.
		location.mark_event_completed(current_event_name)
		_play_next_event()
		return
	_show_entry()

func _set_speaker_portrait(speaker: String, emotion: String, in_position: int):
	var character: Character = characters.get(speaker, null)
	var texture: Texture2D = character.get_portrait(emotion) if character else null

	if in_position == 1:
		speaker1.texture = texture
		speaker2.texture = null
	elif in_position == 2:
		speaker2.texture = texture
		speaker1.texture = null
	else:
		speaker1.texture = texture
		speaker2.texture = null

func _apply_trust_gain(speaker: String, gain: float):
	if gain == 0:
		return
	var character: Character = characters.get(speaker, null)
	if character:
		character.change_trust(gain)
		character.has_met = true

func _show():
	visible = true
	speaker1.hide()
	speaker2.hide()
	option_button_1.hide()
	option_button_2.hide()

func _hide():
	visible = false
	speaker1.texture = null
	speaker2.texture = null
	option_button_1.hide()
	option_button_2.hide()

func _location_done():
	_hide()
	location_finished.emit()
