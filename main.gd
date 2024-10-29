extends Control

const MINUTES := "minutes"
const DISPLAY_SECONDS := "display_seconds"
const NUM_TASKS := "num_tasks"

const FONT_PATH := "font_path"
const FONT_SIZE := "font_size"
const FONT_COLOR := "font_color"
const FONT_OUTLINE_SIZE := "font_outline_size"
const FONT_OUTLINE_COLOR := "font_outline_color"
const FONT_SHADOW_SIZE := "font_shadow_size"
const FONT_SHADOW_COLOR := "font_shadow_color"
const FONT_SHADOW_OFFSET_X := "font_shadow_offset_x"
const FONT_SHADOW_OFFSET_Y := "font_shadow_offset_y"
const KEY_MENU := "key_menu"
const KEY_PAUSE := "key_pause"
const KEY_INCREMENT := "key_increment"
const KEY_DECREMENT := "key_decrement"

const SOUND_VOLUME := "sound_volume"
const SOUND_TIME_UP := "sound_time_up"
const SOUND_CHANGE_TASK := "sound_change_task"
const SOUND_PAUSE := "sound_pause"

const BACKGROUND_COLOR := "background_color"

### should be const but functions aren't
var DEFAULT_CONFIG := {
	MINUTES: 25.0,
	DISPLAY_SECONDS: true,
	NUM_TASKS: 8.0,
	
	FONT_PATH: "res://Lato-Light.ttf",
	FONT_SIZE: 64.0,
	FONT_COLOR: Color(1, 1, 1, 1),
	FONT_OUTLINE_SIZE: 0.0,
	FONT_OUTLINE_COLOR: Color(0, 0, 0, 1),
	FONT_SHADOW_SIZE: 4.0,
	FONT_SHADOW_COLOR: Color(0, 0, 0, 0),
	FONT_SHADOW_OFFSET_X: 1.0,
	FONT_SHADOW_OFFSET_Y: 1.0,
	
	KEY_MENU: OS.get_keycode_string(KEY_ESCAPE),
	KEY_PAUSE: OS.get_keycode_string(KEY_DELETE),
	KEY_DECREMENT: OS.get_keycode_string(KEY_KP_SUBTRACT),
	KEY_INCREMENT: OS.get_keycode_string(KEY_KP_ADD),
	
	SOUND_VOLUME: 0.0,
	SOUND_TIME_UP: "res://timeup.ogg",
	SOUND_CHANGE_TASK: "res://change_task.ogg",
	SOUND_PAUSE: "res://pause.ogg",
	
	BACKGROUND_COLOR: Color(0, 0, 0, 1)
}

var config := {}

const CONFIG_FILE := "res://MementoTimer.config"

var current_font : FontFile = null

func set_dictionary(c: Dictionary, default: Dictionary):
	if c == null:
		c = default.duplicate(true)
	else:
		for option in default:
			if !c.has(option) or typeof(default[option]) != typeof(c[option]):
				c[option] = default[option]
	return c

func load_config():
	var f := FileAccess.open(CONFIG_FILE, FileAccess.READ)
	
	if f != null:
		config = str_to_var(f.get_as_text())
		f.close()
	
	if config.is_empty():
		config = DEFAULT_CONFIG.duplicate(true)
	else:
		for option in DEFAULT_CONFIG:
			if !config.has(option) or typeof(DEFAULT_CONFIG[option]) != typeof(config[option]):
				config[option] = DEFAULT_CONFIG[option]
	
	update()

func save_config():
	var f := FileAccess.open(CONFIG_FILE, FileAccess.WRITE)
	if f != null:
		f.store_string(var_to_str(config))
		f.close()

func set_config(c: String, v):
	config[c] = v
	update()
	save_config()




func key_name(code: Key) -> String:
	var k := InputEventKey.new()
	k.physical_keycode = code
	return k.as_text().replace(" (Physical)", "")

func update_file(cfg: String, text_object, resource):
	if resource == null or resource.resource_path != config[cfg].get_file():
		text_object.text = config[cfg].get_file()
		return true
	return false

func update_sound(cfg: String, text_object, sound: AudioStreamPlayer):
	if update_file(cfg, text_object, sound.stream):
		var n : String = config[cfg]
		if n.ends_with(".ogg"):
			sound.stream = AudioStreamOggVorbis.load_from_file(n)
		else:
			print("File wasn't .ogg, thus couldn't be loaded")



func update():
	### Minutes
	$Menu/ScrollContainer/VBoxContainer/Time/VBoxContainer/Minutes/Label.text = "Minutes: " + str(config[MINUTES])
	$Menu/ScrollContainer/VBoxContainer/Time/VBoxContainer/Minutes/HSlider.value = config[MINUTES]
	
	var m : int = config[MINUTES] * 60
	var diff : int = m - $Timer.wait_time
	if diff != 0:
		var paused : bool = $Timer.paused
		if paused:
			start_timer(m)
			pause_timer()
		else:
			start_timer(maxf(0.0, $Timer.time_left + diff))
		
		$Timer.wait_time = m
	
	### Tasks
	$Menu/ScrollContainer/VBoxContainer/Time/VBoxContainer/Tasks/Label.text = "Tasks: " + str(config[NUM_TASKS])
	$Menu/ScrollContainer/VBoxContainer/Time/VBoxContainer/Tasks/HSlider.value = config[NUM_TASKS]
	count = mini(count, config[NUM_TASKS])
	update_count()
	
	### Display seconds
	$Menu/ScrollContainer/VBoxContainer/Time/VBoxContainer/Seconds.button_pressed = config[DISPLAY_SECONDS]
	
	### Font path
	if update_file(FONT_PATH, $Menu/ScrollContainer/VBoxContainer/Font/VBoxContainer/Font, $Display/Label.label_settings.font):
		$Display/Label.label_settings.font = FontFile.new()
		$Display/Label.label_settings.font.load_dynamic_font(config[FONT_PATH])
	
	### Font size/color
	$Menu/ScrollContainer/VBoxContainer/Font/VBoxContainer/FontSize/Label.text = "Size: " + str(config[FONT_SIZE])
	$Menu/ScrollContainer/VBoxContainer/Font/VBoxContainer/FontSize/HSlider.value = config[FONT_SIZE]
	$Menu/ScrollContainer/VBoxContainer/Font/VBoxContainer/FontColor.color = config[FONT_COLOR]
	
	$Display/Label.label_settings.font_size = config[FONT_SIZE]
	$Display/Label.label_settings.font_color = config[FONT_COLOR]
	### Font outline size/color
	$Menu/ScrollContainer/VBoxContainer/Font/VBoxContainer/OutlineSize/Label.text = "Outline size: " + str(config[FONT_OUTLINE_SIZE])
	$Menu/ScrollContainer/VBoxContainer/Font/VBoxContainer/OutlineSize/HSlider.value = config[FONT_OUTLINE_SIZE]
	$Menu/ScrollContainer/VBoxContainer/Font/VBoxContainer/OutlineColor.color = config[FONT_OUTLINE_COLOR]
	
	$Display/Label.label_settings.outline_size = config[FONT_OUTLINE_SIZE]
	$Display/Label.label_settings.outline_color = config[FONT_OUTLINE_COLOR]
	### Font shadow size/color/offset
	$Menu/ScrollContainer/VBoxContainer/Font/VBoxContainer/ShadowSize/Label.text = "Shadow size: " + str(config[FONT_SHADOW_SIZE])
	$Menu/ScrollContainer/VBoxContainer/Font/VBoxContainer/ShadowSize/HSlider.value = config[FONT_SHADOW_SIZE]
	$Menu/ScrollContainer/VBoxContainer/Font/VBoxContainer/ShadowColor.color = config[FONT_SHADOW_COLOR]
	$Menu/ScrollContainer/VBoxContainer/Font/VBoxContainer/ShadowOffset/Label.text = "Shadow offset: (" + str(config[FONT_SHADOW_OFFSET_X]) + ", " + str(config[FONT_SHADOW_OFFSET_Y]) + ")"
	$Menu/ScrollContainer/VBoxContainer/Font/VBoxContainer/ShadowOffset/HSliderX.value = config[FONT_SHADOW_OFFSET_X]
	$Menu/ScrollContainer/VBoxContainer/Font/VBoxContainer/ShadowOffset/HSliderY.value = config[FONT_SHADOW_OFFSET_Y]
	
	$Display/Label.label_settings.shadow_size = config[FONT_SHADOW_SIZE]
	$Display/Label.label_settings.shadow_color = config[FONT_SHADOW_COLOR]
	$Display/Label.label_settings.shadow_offset = Vector2(config[FONT_SHADOW_OFFSET_X], config[FONT_SHADOW_OFFSET_Y])
	### Keybinds
	$Menu/ScrollContainer/VBoxContainer/Keybinds/VBoxContainer/ShowMenu.text = "Show menu: " + config[KEY_MENU]
	$Menu/ScrollContainer/VBoxContainer/Keybinds/VBoxContainer/PauseTimer.text = "Pause/Reset Timer: " + config[KEY_PAUSE]
	$Menu/ScrollContainer/VBoxContainer/Keybinds/VBoxContainer/CompleteTask.text = "Complete task: " + config[KEY_INCREMENT]
	$Menu/ScrollContainer/VBoxContainer/Keybinds/VBoxContainer/RemoveTask.text = "Remove task: " + config[KEY_DECREMENT]
	
	### Sounds
	AudioServer.set_bus_volume_db(0, config[SOUND_VOLUME])
	$Menu/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/Volume/HSlider.value = config[SOUND_VOLUME]
	
	update_sound(SOUND_TIME_UP, $Menu/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/TimeUp/Button, $Display/TimeUp)
	update_sound(SOUND_CHANGE_TASK, $Menu/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/ChangeTask/Button, $Display/ChangeTask)
	update_sound(SOUND_PAUSE, $Menu/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/Pause/Button, $Display/Pause)
	
	### Background color
	$Menu/ScrollContainer/VBoxContainer/Background.color = config[BACKGROUND_COLOR]
	$Display/Background.modulate = config[BACKGROUND_COLOR]




func checkbox_update(obj: CheckBox, cfg: String):
	obj.toggled.connect(func(b: bool): set_config(cfg, b))

func slider_update(obj: Slider, cfg: String):
	obj.value_changed.connect(func(v: float): set_config(cfg, v))

var expected_key := ""
func set_key(cfg: String):
	expected_key = cfg
	$Menu/PressKey.show()

func key_button(btn: Button, cfg: String):
	btn.pressed.connect(set_key.bind(cfg))

func color_enable(btn: ColorPickerButton, b: bool):
	$Menu.modulate.a = 1.0 if b else 0.0
	$Menu.process_mode = Node.PROCESS_MODE_INHERIT if b else Node.PROCESS_MODE_DISABLED
	btn.process_mode = Node.PROCESS_MODE_INHERIT if b else Node.PROCESS_MODE_ALWAYS

func color_button(btn: ColorPickerButton, cfg: String):
	btn.color_changed.connect(func(c: Color): set_config(cfg, c))
	btn.popup_closed.connect(color_enable.bind(btn, true))
	btn.pressed.connect(color_enable.bind(btn, false))

func file_button(btn: Button, cfg: String, dialog: FileDialog):
	dialog.hide()
	dialog.file_selected.connect(func(s: String): set_config(cfg, s))
	btn.pressed.connect(dialog.show)




func _ready() -> void:
	for k in [KEY_MENU, KEY_PAUSE, KEY_DECREMENT, KEY_INCREMENT]:
		pressed_time[k] = -1
		held_key[k] = false
	
	$Menu.hide()
	$Menu/PressKey.hide()
	
	load_config()
	
	slider_update($Menu/ScrollContainer/VBoxContainer/Time/VBoxContainer/Minutes/HSlider, MINUTES)
	slider_update($Menu/ScrollContainer/VBoxContainer/Time/VBoxContainer/Tasks/HSlider, NUM_TASKS)
	slider_update($Menu/ScrollContainer/VBoxContainer/Font/VBoxContainer/FontSize/HSlider, FONT_SIZE)
	slider_update($Menu/ScrollContainer/VBoxContainer/Font/VBoxContainer/OutlineSize/HSlider, FONT_OUTLINE_SIZE)
	slider_update($Menu/ScrollContainer/VBoxContainer/Font/VBoxContainer/ShadowSize/HSlider, FONT_SHADOW_SIZE)
	slider_update($Menu/ScrollContainer/VBoxContainer/Font/VBoxContainer/ShadowOffset/HSliderX, FONT_SHADOW_OFFSET_X)
	slider_update($Menu/ScrollContainer/VBoxContainer/Font/VBoxContainer/ShadowOffset/HSliderY, FONT_SHADOW_OFFSET_Y)
	slider_update($Menu/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/Volume/HSlider, SOUND_VOLUME)
	
	checkbox_update($Menu/ScrollContainer/VBoxContainer/Time/VBoxContainer/Seconds, DISPLAY_SECONDS)
	key_button($Menu/ScrollContainer/VBoxContainer/Keybinds/VBoxContainer/ShowMenu, KEY_MENU)
	key_button($Menu/ScrollContainer/VBoxContainer/Keybinds/VBoxContainer/PauseTimer, KEY_PAUSE)
	key_button($Menu/ScrollContainer/VBoxContainer/Keybinds/VBoxContainer/CompleteTask, KEY_INCREMENT)
	key_button($Menu/ScrollContainer/VBoxContainer/Keybinds/VBoxContainer/RemoveTask, KEY_DECREMENT)
	
	color_button($Menu/ScrollContainer/VBoxContainer/Font/VBoxContainer/FontColor, FONT_COLOR)
	color_button($Menu/ScrollContainer/VBoxContainer/Font/VBoxContainer/OutlineColor, FONT_OUTLINE_COLOR)
	color_button($Menu/ScrollContainer/VBoxContainer/Font/VBoxContainer/ShadowColor, FONT_SHADOW_COLOR)
	color_button($Menu/ScrollContainer/VBoxContainer/Background, BACKGROUND_COLOR)
	
	file_button($Menu/ScrollContainer/VBoxContainer/Font/VBoxContainer/Font, FONT_PATH, $Menu/FontDialog)
	file_button($Menu/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/TimeUp/Button, SOUND_TIME_UP, $Menu/TimeUpDialog)
	file_button($Menu/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/ChangeTask/Button, SOUND_CHANGE_TASK, $Menu/ChangeTaskDialog)
	file_button($Menu/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/Pause/Button, SOUND_PAUSE, $Menu/PauseDialog)
	
	$Timer.timeout.connect($Display/TimeUp.play)
	$Menu/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/TimeUp/Test.pressed.connect($Display/TimeUp.play)
	$Menu/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/ChangeTask/Test.pressed.connect($Display/ChangeTask.play)
	$Menu/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/Pause/Test.pressed.connect($Display/Pause.play)
	
	clear_timer()


func start_timer(time : float):
	$Timer.start(time)
	$Timer.paused = false
	$Display/Label.modulate.a = 1.0

func pause_timer():
	var p : bool = !$Timer.paused
	$Timer.paused = p
	$Display/Label.modulate.a = 0.5 if p else 1.0
	$Display/Paused.visible = p

func clear_timer():
	start_timer(config[MINUTES] * 60)
	pause_timer()

var count := 0
func update_count():
	$Display/Count.visible = config[NUM_TASKS] > 0
	$Display/Count.text = str(count) + "/" + str(config[NUM_TASKS])

func add_count(i : int):
	count = clampi(count + i, 0, config[NUM_TASKS])
	$Display/ChangeTask.play()
	$Display/Bounce.stop()
	$Display/BounceCount.play("bounce_count")
	update_count()


var pressed_time := {}
var held_key := {}

func pressed(event: InputEvent, key: String) -> bool:
	var b : bool = event.is_pressed() and event is InputEventKey and event.keycode == OS.find_keycode_from_string(config[key])
	if b:
		if pressed_time[key] == -1:
			pressed_time[key] = Engine.get_physics_frames()
			return true
	else:
		pressed_time[key] = -1
	return false

func held(key: String):
	var b : bool = pressed_time[key] != -1 and (Engine.get_physics_frames() - pressed_time[key]) > 3
	var is_held : bool = b and !held_key[key]
	held_key[key] = b
	return is_held

func _input(event: InputEvent):
	if $Menu/PressKey.visible and event.is_pressed() and event is InputEventKey:
		set_config(expected_key, event.as_text_keycode())
		$Menu/PressKey.hide()
		return
	
	if pressed(event, KEY_MENU): $Menu.visible = !$Menu.visible
	if pressed(event, KEY_PAUSE):
		pause_timer()
		if $Timer.paused:
			$Display/Pause.play()
	
	if pressed(event, KEY_DECREMENT): add_count(-1)
	if pressed(event, KEY_INCREMENT): add_count(+1)
	
	if held(KEY_PAUSE): clear_timer()


var old_time := -1
func _process(_delta: float):
	var t := 0 if $Timer.is_stopped() else int($Timer.time_left)
	var m := t / 60
	$Display/Label.text = str(m)
	
	if m != (old_time / 60) and !$Timer.paused:
		$Display/Bounce.play("bounce")
	
	if config[DISPLAY_SECONDS]:
		var s := (t % 60)
		$Display/Label.text += ":"
		if s == 0:
			$Display/Label.text += "00"
		else:
			if s < 10:
				$Display/Label.text += "0"
			$Display/Label.text += str(s)
	
	old_time = t
