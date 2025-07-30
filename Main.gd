extends Control

var dialogue_index: int = 0
var dialogues: Array = []

var typing: bool = false
var typing_timer: Timer
var current_text: String = ""
var current_char_index: int = 0

@onready var character_name: Label = $DialogueBox/CharacterName
@onready var dialogue_text: Label = $DialogueBox/DialogueText
@onready var next_button: Button = $DialogueBox/NextButton
@onready var talk_sound: AudioStreamPlayer2D = $DialogueBox/TalkSound

func _ready() -> void:
	next_button.pressed.connect(_on_next_button_pressed)
	load_dialogues()
	show_dialogue()

func load_dialogues() -> void:
	var file_path: String = "res://dialogues.json"
	if not FileAccess.file_exists(file_path):
		push_error("Archivo no encontrado: " + file_path)
		return
	
	var file := FileAccess.open(file_path, FileAccess.READ)
	var content := file.get_as_text()
	file.close()

	var json := JSON.new()
	var result := json.parse(content)
	if result != OK:
		push_error("Error al parsear JSON")
		return
	
	dialogues = json.data
	if typeof(dialogues) != TYPE_ARRAY:
		push_error("El JSON no contiene un array de diálogos")
		dialogues = []

func show_dialogue() -> void:
	if dialogue_index >= dialogues.size():
		character_name.text = ""
		dialogue_text.text = "Fin del diálogo."
		next_button.disabled = true
		typing = false
		return

	var d = dialogues[dialogue_index]
	if typeof(d) != TYPE_DICTIONARY or not d.has("speaker") or not d.has("text"):
		push_error("Formato inválido en diálogo " + str(dialogue_index))
		return

	character_name.text = d["speaker"]
	start_typing(d["text"])

func start_typing(text_to_type: String) -> void:
	if typing_timer:
		typing_timer.stop()
		typing_timer.queue_free()

	current_text = text_to_type
	current_char_index = 0
	dialogue_text.text = ""
	typing = true

	typing_timer = Timer.new()
	typing_timer.wait_time = 0.03
	typing_timer.one_shot = false
	add_child(typing_timer)
	typing_timer.timeout.connect(_on_typing_timeout)
	typing_timer.start()

func _on_typing_timeout() -> void:
	if current_char_index < current_text.length():
		dialogue_text.text += current_text[current_char_index]
		current_char_index += 1
		
		if current_char_index % 2 == 0 and talk_sound.stream:
			talk_sound.play()
	else:
		typing = false
		typing_timer.stop()
		typing_timer.queue_free()
		typing_timer = null

func _on_next_button_pressed() -> void:
	if typing:
		typing = false
		typing_timer.stop()
		typing_timer.queue_free()
		typing_timer = null
		dialogue_text.text = current_text
	else:
		dialogue_index += 1
		show_dialogue()
