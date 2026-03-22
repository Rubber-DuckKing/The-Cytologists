extends Node2D

signal camera_reset


func _on_camera_reset_button_pressed() -> void:
	camera_reset.emit()
	$CameraResetButton.button_pressed = false
