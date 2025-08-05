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

@onready var backlog_panel: PanelContainer = $BacklogPanel
@onready var backlog_list: VBoxContainer = $BacklogPanel/ScrollContainer/BacklogList
@onready var toggle_backlog_button: Button = $ToggleBacklogButton
@onready var scroll_container: ScrollContainer = $BacklogPanel/ScrollContainer

func _ready() -> void:
	# Conectar señales
	next_button.pressed.connect(_on_next_button_pressed)
	toggle_backlog_button.pressed.connect(_on_toggle_backlog_pressed)
	
	# Configuración inicial
	load_dialogues()
	show_dialogue()
	backlog_panel.visible = false
	
	# Configurar panel de backlog
	backlog_panel.custom_minimum_size = Vector2(600, 300)
	backlog_panel.size = Vector2(600, 300)
	scroll_container.custom_minimum_size = Vector2(580, 280)
	
	# Estilo para mejor visibilidad
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_color = Color(0.5, 0.5, 0.5)
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	backlog_panel.add_theme_stylebox_override("panel", style)

func load_dialogues() -> void:
	var file_path: String = "res://dialogues.json"
	if not FileAccess.file_exists(file_path):
		push_error("Archivo no encontrado: " + file_path)
		return
	
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Error al abrir el archivo: " + file_path)
		return
	
	var content := file.get_as_text()
	file.close()

	var json := JSON.new()
	var result := json.parse(content)
	if result != OK:
		push_error("Error al parsear JSON: " + json.get_error_message())
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
		finish_typing()

func finish_typing() -> void:
	typing = false
	if typing_timer:
		typing_timer.stop()
		typing_timer.queue_free()
		typing_timer = null

func _on_next_button_pressed() -> void:
	if typing:
		# Saltar al final del texto actual
		finish_typing()
		dialogue_text.text = current_text
	else:
		# Avanzar al siguiente diálogo
		dialogue_index += 1
		show_dialogue()

func update_backlog() -> void:
	# Limpiar backlog existente
	for child in backlog_list.get_children():
		child.queue_free()
	
	# Añadir solo los diálogos mostrados hasta ahora
	for i in range(dialogue_index + 1):
		if i >= dialogues.size():
			continue
			
		var entry = dialogues[i]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if not entry.has("speaker") or not entry.has("text"):
			continue
		
		# Crear contenedor para cada entrada del backlog
		var entry_container = HBoxContainer.new()
		entry_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entry_container.custom_minimum_size = Vector2(0, 40)
		
		# Etiqueta del nombre del personaje
		var name_label = Label.new()
		name_label.text = entry["speaker"] + ":"
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		name_label.custom_minimum_size = Vector2(150, 0)
		name_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
		
		# Etiqueta del texto del diálogo
		var text_label = Label.new()
		text_label.text = entry["text"]
		text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		text_label.custom_minimum_size = Vector2(400, 0)
		
		# Resaltar el diálogo actual
		if i == dialogue_index:
			var highlight = StyleBoxFlat.new()
			highlight.bg_color = Color(0.2, 0.2, 0.3, 0.5)
			entry_container.add_theme_stylebox_override("panel", highlight)
		
		# Añadir elementos al contenedor
		entry_container.add_child(name_label)
		entry_container.add_child(text_label)
		
		# Añadir separador si no es el primer elemento
		if i > 0:
			var separator = HSeparator.new()
			backlog_list.add_child(separator)
		
		# Añadir entrada al backlog
		backlog_list.add_child(entry_container)
	
	# Ajustar el scroll al final después de actualizar
	call_deferred("_scroll_to_bottom")

func _scroll_to_bottom() -> void:
	await get_tree().process_frame
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value

func _on_toggle_backlog_pressed() -> void:
	backlog_panel.visible = !backlog_panel.visible
	if backlog_panel.visible:
		update_backlog()
		# Mover el panel al frente
		var parent = backlog_panel.get_parent()
		parent.move_child(backlog_panel, parent.get_child_count() - 1)
		_scroll_to_bottom()
