extends Control
class_name Map

# Preload class_name scripts so their types are registered before anything
# tries to use them (map.gd is the main scene, so it loads first).
var _character_script = preload("res://Characters/character.gd")
var _dialog_ui_script = preload("res://UI/dialog.gd")

# The map screen. Shows one button per location. Clicking a location runs its
# dialog sequence; when the sequence finishes the player returns here.

@onready var admin_bldg_button = $AdminBldgButton

# Reference to the shared dialog UI (instanced from res://UI/dialog.tscn).
var dialog_ui

# Player characters keyed by speaker name, used to apply trust / has_met.
var characters: Dictionary = {}

func _ready():
	# Create the sample character (matches the "Nicoe" speaker used in
	# adminbldg.gd) via the preloaded Character script so it doesn't depend on
	# .tres type-name resolution at load time.
	var nicoe = _character_script.new()
	nicoe.name = "Nicoe"
	nicoe.current_trust = 0.0
	nicoe.has_met = false
	characters["Nicoe"] = nicoe

	# Instance the dialog UI once and keep it hidden until a location is entered.
	var dialog_scene = load("res://UI/dialog.tscn")
	dialog_ui = dialog_scene.instantiate()
	add_child(dialog_ui)
	dialog_ui.visible = false
	dialog_ui.location_finished.connect(_on_location_finished)

	admin_bldg_button.visible = true
	admin_bldg_button.grab_focus()

func _on_admin_bldg_pressed():
	admin_bldg_button.visible = false
	# Instance the admin building location script (extends dialogs -> Node).
	var location = load("res://Events/adminbldg.gd").instantiate()
	dialog_ui.run_location(location, characters)

func _on_location_finished():
	dialog_ui.visible = false
	admin_bldg_button.visible = true
	admin_bldg_button.grab_focus()
