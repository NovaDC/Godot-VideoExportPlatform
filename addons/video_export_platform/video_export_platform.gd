@tool
class_name VideoEditorExportPlatform
extends ToolEditorExportPlatform

## VideoEditorExportPlatform
## 
## A simple godot export plugin that connects godot's video export mode to the export menu.
## Requires the NovaTools plugin as a dependency.

## The command line flag used with godot to export a movie.
const GODOT_VIDEO_EXPORT_FLAG := "--write-movie"
## The command line flag used with godot to specify the project file to open.
const GODOT_PROJECT_PATH_FLAG := "--path"
## The command line flag used with godot when exporting a movie of how many seconds to quit after.
const GODOT_QUIT_AFTER_FLAG := "--quit-after"

## Exports the godot project file located at [param from_project] (defaulting to the currently
## opened project in the editor) to a given movie located at [param to_path].[br]
## When [param quit_after] is larger than 0, godot will quit filming after the
## set amount of seconds. If this is negative, it will film until the window doing
## the filming is closed by the user.[br]
## Note: Godot determines what format of video to export
## based on [param to_path]'s file extention. See [MovieWriter] for more information.
static func export_video(to_path:String,
						 quit_after:int = -1,
						 from_project := ProjectSettings.globalize_path("res://"),
						 stay_open := false
						) -> Error:
	var args := [GODOT_VIDEO_EXPORT_FLAG,
				 ProjectSettings.globalize_path(to_path),
				 GODOT_PROJECT_PATH_FLAG,
				 from_project,
				]
	if quit_after > 0:
		args.append(GODOT_QUIT_AFTER_FLAG)
		args.append(str(quit_after))
	
	return await NovaTools.launch_editor_instance_async(args, "", stay_open)

func _get_name():
	return "Video"

func _get_logo():
	var size = Vector2i.ONE * floori(32 * EditorInterface.get_editor_scale())
	return NovaTools.get_editor_icon_named("Animation", size)

func _get_platform_features():
	return super._get_platform_features() + PackedStringArray(["video"])

func _get_export_options():
	return [
		{
			"name": "quit_after",
			"type": TYPE_INT,
			"default_value": -1
		},
		{
			"name": "keep_open",
			"type": TYPE_BOOL,
			"default_value": true
		},
	] + super._get_export_options()

func _export_hook(preset: EditorExportPreset, path: String):
	return await export_video(path,
							  preset.get_or_env("quit_after", ""),
							  ProjectSettings.globalize_path("res://"),
							  preset.get_or_env("keep_open", "")
							 )

func _get_binary_extensions(preset: EditorExportPreset):
	return PackedStringArray(["avi", "png", "*"])
