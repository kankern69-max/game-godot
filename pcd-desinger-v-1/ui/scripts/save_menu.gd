extends Control

@onready var save1_name: Label = $CenterContainer/ScrollContainer/VBoxContainer/Savegame/ContainsSave/SaveName
@onready var save1_time: Label = $CenterContainer/ScrollContainer/VBoxContainer/Savegame/ContainsSave/SaveTime
@onready var save1_gameMode: Label = $CenterContainer/ScrollContainer/VBoxContainer/Savegame/ContainsSave/GameMode
@onready var save1_money: Label = $CenterContainer/ScrollContainer/VBoxContainer/Savegame/ContainsSave/MoneyInSave
@onready var save1_has: Control = $CenterContainer/ScrollContainer/VBoxContainer/Savegame/ContainsSave
@onready var save1_new: Control = $CenterContainer/ScrollContainer/VBoxContainer/Savegame/CreateNew

var save1_hasSave: bool = false

@onready var save2_name: Label = $CenterContainer/ScrollContainer/VBoxContainer/Savegame2/ContainsSave/SaveName
@onready var save2_time: Label = $CenterContainer/ScrollContainer/VBoxContainer/Savegame2/ContainsSave/SaveTime
@onready var save2_gameMode: Label = $CenterContainer/ScrollContainer/VBoxContainer/Savegame2/ContainsSave/GameMode
@onready var save2_money: Label = $CenterContainer/ScrollContainer/VBoxContainer/Savegame2/ContainsSave/MoneyInSave
@onready var save2_has: Control = $CenterContainer/ScrollContainer/VBoxContainer/Savegame2/ContainsSave
@onready var save2_new: Control = $CenterContainer/ScrollContainer/VBoxContainer/Savegame2/CreateNew

var save2_hasSave: bool = false

@onready var save3_name: Label = $CenterContainer/ScrollContainer/VBoxContainer/Savegame3/ContainsSave/SaveName
@onready var save3_time: Label = $CenterContainer/ScrollContainer/VBoxContainer/Savegame3/ContainsSave/SaveTime
@onready var save3_gameMode: Label = $CenterContainer/ScrollContainer/VBoxContainer/Savegame3/ContainsSave/GameMode
@onready var save3_money: Label = $CenterContainer/ScrollContainer/VBoxContainer/Savegame3/ContainsSave/MoneyInSave
@onready var save3_has: Control = $CenterContainer/ScrollContainer/VBoxContainer/Savegame3/ContainsSave
@onready var save3_new: Control = $CenterContainer/ScrollContainer/VBoxContainer/Savegame3/CreateNew

var save3_hasSave: bool = false

@onready var save4_name: Label = $CenterContainer/ScrollContainer/VBoxContainer/Savegame4/ContainsSave/SaveName
@onready var save4_time: Label = $CenterContainer/ScrollContainer/VBoxContainer/Savegame4/ContainsSave/SaveTime
@onready var save4_gameMode: Label = $CenterContainer/ScrollContainer/VBoxContainer/Savegame4/ContainsSave/GameMode
@onready var save4_money: Label = $CenterContainer/ScrollContainer/VBoxContainer/Savegame4/ContainsSave/MoneyInSave
@onready var save4_has: Control = $CenterContainer/ScrollContainer/VBoxContainer/Savegame4/ContainsSave
@onready var save4_new: Control = $CenterContainer/ScrollContainer/VBoxContainer/Savegame4/CreateNew

var save4_hasSave: bool = false

@onready var save5_name: Label = $CenterContainer/ScrollContainer/VBoxContainer/Savegame5/ContainsSave/SaveName
@onready var save5_time: Label = $CenterContainer/ScrollContainer/VBoxContainer/Savegame5/ContainsSave/SaveTime
@onready var save5_gameMode: Label = $CenterContainer/ScrollContainer/VBoxContainer/Savegame5/ContainsSave/GameMode
@onready var save5_money: Label = $CenterContainer/ScrollContainer/VBoxContainer/Savegame5/ContainsSave/MoneyInSave
@onready var save5_has: Control = $CenterContainer/ScrollContainer/VBoxContainer/Savegame5/ContainsSave
@onready var save5_new: Control = $CenterContainer/ScrollContainer/VBoxContainer/Savegame5/CreateNew

var save5_hasSave: bool = false

func _ready():
	Savegame.refresh_slots()
	_populate_slot(0, save1_has, save1_new, save1_name, save1_time, save1_money, save1_gameMode)
	_populate_slot(1, save2_has, save2_new, save2_name, save2_time, save2_money, save2_gameMode)
	_populate_slot(2, save3_has, save3_new, save3_name, save3_time, save3_money, save3_gameMode)
	_populate_slot(3, save4_has, save4_new, save4_name, save4_time, save4_money, save4_gameMode)
	_populate_slot(4, save5_has, save5_new, save5_name, save5_time, save5_money, save5_gameMode)

func _populate_slot(slot: int, has_box: Control, new_box: Control, name_l: Label, date_l: Label, money_l: Label, mode_l: Label) -> void:
	var info: Dictionary = Global.save_games[slot]
	var has_save: bool = info.get("exists", false)
	has_box.visible = has_save
	new_box.visible = not has_save
	if not has_save:
		return
	name_l.text = info.get("name", "Slot %d" % (slot + 1))
	date_l.text = _format_real_date(info.get("timestamp", 0))
	money_l.text = "$%.0f" % info.get("money", 0.0)
	mode_l.text = "Gamemode: " + str(info.get("mode"))


func _handle_slot_click(event: InputEvent, slot: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Global.save_games[slot].get("exists", false):
			Savegame.load_game(slot)
		else:
			Savegame.start_new_game(slot)

func _format_real_date(unix_time: int) -> String:
	var bias_minutes: int = Time.get_time_zone_from_system().get("bias", 0)
	var dt: Dictionary = Time.get_datetime_dict_from_unix_time(unix_time + bias_minutes * 60)
	return "%02d-%02d-%04d  %02d:%02d" % [dt.day, dt.month, dt.year, dt.hour, dt.minute]


func _on_savegame_gui_input(event):
	_handle_slot_click(event, 0)

func _on_savegame_2_gui_input(event):
	_handle_slot_click(event, 1)

func _on_savegame_3_gui_input(event):
	_handle_slot_click(event, 2)

func _on_savegame_4_gui_input(event):
	_handle_slot_click(event, 3)

func _on_savegame_5_gui_input(event):
	_handle_slot_click(event, 4)
