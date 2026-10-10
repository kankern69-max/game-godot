extends Node

const SAVE_DIR: String = "user://saves"
const SAVE_PASS: String = "TismTeamMetZimZim"
const GAME_SCENE: String = "res://mainSystems/game.tscn"

const SLOT_COUNT: int = 5
const AUTOSAVE_INTERVAL: float = 180.0
var autosave_enabled: bool = false
var _autosave_timer: float = 0.0

func _process(delta) -> void:
	if not autosave_enabled:
		return
	_autosave_timer += delta
	if _autosave_timer >= AUTOSAVE_INTERVAL:
		_autosave_timer == 0.0
		save()

func _slot_path(slot: int) -> String:
	return "%s/slot_%d.save" % [SAVE_DIR, slot]

func _slot_key(slot: int) -> String:
	return "savegame_%d" % slot

func _ready():
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	refresh_slots()

func save(slot: int = -1) -> void:
	if slot < 0:
		slot = Global.loaded_save_index
	var data: Dictionary = {
		"save_name": "Slot %d" % (slot + 1),
		"money": Global.money,
		"mode": Global.current_mode,
		"state": _collect_state(),
	}
	var f := FileAccess.open_encrypted_with_pass(_slot_path(slot), FileAccess.WRITE, SAVE_PASS)
	if f == null:
		push_error("Failed to open save slot %d for writing" % slot)
		return
	f.store_var(data)
	f.close()
	Global.loaded_save_index = slot
	refresh_slots()

func load_game(slot: int = 0) -> void:
	var data = recover(slot)
	
	if data.is_empty():
		print("No save file found in slot %d" % slot)
		return
	Global.loaded_save_index = slot
	autosave_enabled = true
	_reset_runtime_state()
	Global.pending_load = data.get("state", {})
	get_tree().change_scene_to_file(GAME_SCENE)

func recover(slot: int = 0) -> Dictionary:
	if not FileAccess.file_exists(_slot_path(slot)):
		return {}
	var f := FileAccess.open_encrypted_with_pass(_slot_path(slot), FileAccess.READ, SAVE_PASS)
	if f == null:
		push_error("Failed to open save slot %d (wrong password or corrupt file)" % slot)
		return {}
	var data = f.get_var()
	f.close()
	return data

func refresh_slots() -> void:
	Global.save_games.clear()
	for slot in SLOT_COUNT:
		var data = recover(slot)
		var info: Dictionary = {"slot": slot, "exists": false}
		if data is Dictionary and not data.is_empty():
			info["exists"] = true
			info["name"] = data.get("save_name", "Slot %d" % (slot + 1))
			info["money"] = data.get("money", 0.0)
			info["mode"] = data.get("mode", Global.MODE.CARRER)
		Global.save_games.append(info)

func delete_slot(slot: int) -> void:
	if OS.get_name() == "Web":
		Engine.get_singleton("javaScript").eval("localStorage.removeItem('" + _slot_key(slot) + "'); sessionStorage.removeItem('" + _slot_key(slot) + "');")
	elif FileAccess.file_exists(_slot_path(slot)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_slot_path(slot)))
	refresh_slots()

func _collect_state() -> Dictionary:
	return {
		"unlocked_techs": Global.unlocked_techs,
		"unlocked_components": Global.unlocked_components
	}

func _reset_runtime_state() -> void:
	Global.unlocked_components.clear()
	Global.unlocked_techs.clear()
	

func apply_pending_load() -> void:
	var s: Dictionary = Global.pending_load
	if s.is_empty():
		return
	Global.pending_load = {}
	
	Global.money = s.get("money", 0.0)
	Global.current_mode = s.get("mode")
	Global.unlocked_techs = s.get("unlocked_techs", [])
	Global.unlocked_components = s.get("unlocked_components", [])
