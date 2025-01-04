@tool
extends EditorPlugin

const PLUGIN_NAME := "video_export_platform"

var _export_platform_ref:VideoEditorExportPlatform = null

func _get_plugin_name():
	return PLUGIN_NAME

func _get_plugin_icon():
	return NovaTools.get_editor_icon_named("Animation", Vector2i.ONE * 16)

func _enter_tree():
	if EditorInterface.is_plugin_enabled(PLUGIN_NAME):
		_try_init_platform()

func _enable_plugin():
	_try_init_platform()

func _disable_plugin():
	_try_deinit_platform()

func _exit_tree():
	_try_deinit_platform()

func _try_init_platform():
	if _export_platform_ref == null:
		_export_platform_ref = VideoEditorExportPlatform.new()
		add_export_platform(_export_platform_ref)

func _try_deinit_platform():
	if _export_platform_ref != null:
		remove_export_platform(_export_platform_ref)
		_export_platform_ref = null
