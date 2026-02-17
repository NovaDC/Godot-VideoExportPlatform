@tool
class_name VideoEditorExportPlatform
extends ToolEditorExportPlatform

## VideoEditorExportPlatform
##
## A simple [EditorExportPlatformExtension] that provides a interface for video rendering
## in the editor's export menu.
## Requires the [NovaTools] plugin as a dependency. [NovaTools] does not need to be enabled.

## Preset verbosity setting to use for the editor instance launched when exporting a video.
enum Verbosity{
	## Suppresses most console output. Uses the [code]--quiet[/code] flag.
	QUIET = -1,
	## Sets no flags. The default value.
	UNSET = 0,
	## Prints additional fps counts to the console. Uses the [code]--print-fps[/code] flag.
	VERBOSE_FPS = 1,
	## Includes everything used by [const Verbosity.VERBOSE_FPS],
	## as well as printing additional information to the console.
	## Uses all flags used by [const Verbosity.VERBOSE_FPS]
	## as well the [code]--verbose[/code] flag.
	VERBOSE_ALL = 2,
}

## The command line flag used with godot to export a movie.
const GODOT_VIDEO_EXPORT_FLAG := "--write-movie"
## The command line flag used with godot to specify the project file to open.
const GODOT_PROJECT_PATH_FLAG := "--path"
## The command line flag used with godot to set the fixed amount of frames
## that ideally should be processed in a second.
const GODOT_FIXED_FPS_FLAG := "--fixed-fps"
## The command line flag used with godot to request a specified resolution be used.
const GODOT_RESOLUTION_FLAG := "--resolution"
## The command line flag used with godot to print fps information to the console.
const GODOT_PRINT_FPS_FLAG := "--print-fps"
## The command line flag used with godot to print additional information to the console.
const GODOT_VERBOSE_FLAG := "--verbose"
## The command line flag used with godot to print less information to the console.
const GODOT_QUIET_FLAG := "--quiet"

## Exports the godot project file located at [param from_project] (defaulting to the currently
## opened project in the editor) to a given movie located at [param to_path],
## Returning the relevant [enum Error] code as a result.[br]
## Godot determines what format of video to export
## based on [param to_path]'s file extention.
## There is currently no other option that allows for the specific
## selection of what [MovieWriter] should be used.
## See [MovieWriter] and
## [url]https://docs.godotengine.org/en/stable/tutorials/animation/creating_movies.html[/url]
## for more information.
## [br]
## [br]
## When [param fps] is larger than 0, Godot will attempt to render the movie as close as possible to
## that given frame rate.[br]
## [br]
## When both [param resolution_override]'s axis are larger than 0,
## the movie will attempt to render at that given resolution.
## Having only a single axis greater than 0 will result in an error.[br]
## [br]
## [param verbosity] specifies various presets of verbosity for the console
## output to use. See [enum Verbosity] for more information about each option.[br]
## [br]
## [param additional_args] allows for further customization of
## video rendering by supplying the provided arguments to the
## rendering editor's cli when launched.[br]
## These arguments are passed directly,
## so duplicate arguments already supplied by other parts of the method
## or characters/patterns that allow for cli command escaping are not filtered.[br]
## It is the responsibility of the user to ensure these arguments are well formed and safe.
## [br]
## [b]NOTE[/b]: The console and editor instance opened when rendering
## should always be closed [b]properly[/b]
## (ex. using the window's close button,
## having a script in the project that exits the program automatically,
## etc...).[br]
## Failing to do so will [b]abort the video rendering[/b] and possibly
## [b]loose or corrupt[/b] the rendered video.[br]
## [param additional_args] may be used to supply arguments
## that allow for video rendering to automatically finish without the use of a script.[br]
static func export_video(to_path:String,
							from_project := "res://",
							fps:int = 0,
							resolution_override := Vector2i.ZERO,
							verbosity:Verbosity = Verbosity.UNSET,
							additional_args := PackedStringArray(),
							stay_open := false,
							) -> int:

	to_path = NovaTools.normalize_path_absolute(to_path, false)
	from_project = NovaTools.normalize_path_absolute(from_project, false)
	if not DirAccess.dir_exists_absolute(from_project) and from_project.get_file() == "project.godot":
		from_project = from_project.get_base_dir()

	if not DirAccess.dir_exists_absolute(from_project):
		return ERR_FILE_NOT_FOUND

	if DirAccess.dir_exists_absolute(to_path):
		return ERR_ALREADY_EXISTS

	var args := PackedStringArray([GODOT_VIDEO_EXPORT_FLAG,
							to_path,
							GODOT_PROJECT_PATH_FLAG,
							from_project,
							])
	args += additional_args

	if resolution_override.x > 0 and resolution_override.y > 0:
		args.append(GODOT_RESOLUTION_FLAG)
		args.append("%dx%d" % [resolution_override.x, resolution_override.y])
	elif not (resolution_override.x <= 0 and resolution_override.y <= 0):
		return ERR_PARAMETER_RANGE_ERROR

	if verbosity < 0:
		args.append(GODOT_QUIET_FLAG)
	elif verbosity > 0:
		args.append(GODOT_PRINT_FPS_FLAG)
		if verbosity >= Verbosity.VERBOSE_ALL:
			args.append(GODOT_VERBOSE_FLAG)

	if fps > 0:
		args.append(GODOT_FIXED_FPS_FLAG)
		args.append(str(fps))

	return await NovaTools.launch_editor_instance_async(args, "", stay_open)

## Returns a [PackedStringArray] that specifies the builtin video export formats
## supported.[br]
## [b]NOTE[/b]: This cannot return any supported formats provided by addons,
## as there is currently no features in Godot that could provide such an interface.
static func get_builtin_video_export_extensions() -> PackedStringArray:
	var exts := PackedStringArray(["avi", "png"])

	var ver_info := Engine.get_version_info()
	if ver_info.major > 4 or (ver_info.major == 4 and ver_info.minor >= 5):
		exts.append("ogv")

	return exts

func _get_name() -> String:
	return "Video"

func _get_logo() -> Texture2D:
	var size = Vector2i.ONE * roundi(32 * EditorInterface.get_editor_scale())
	return NovaTools.get_editor_icon_named("Animation", size)

func _has_valid_export_configuration(preset:EditorExportPreset, _debug:bool) -> bool:
	# forcefully ignore not allowing tool exports to be run as debug
	# as debug video renders may be of genuine use
	return super(preset, false)

func _get_export_options() -> Array:
	return [
		{
			"name": "fps",
			"type": TYPE_INT,
			"default_value": 0,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,1024,1,or_greater,suffix:s"
		},
		{
			"name": "resolution_override",
			"type": TYPE_VECTOR2I,
			"default_value": Vector2i.ZERO,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,1024,1,or_greater,suffix:px"
		},
		{
			"name": "additional_arguments",
			"type": TYPE_PACKED_STRING_ARRAY,
			"default_value": PackedStringArray()
		},
		{
			"name": "verbosity",
			"type": TYPE_INT,
			"default_value": Verbosity.UNSET,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": NovaTools.make_int_enum_hint_string([Verbosity])
		},
		{
			"name": "keep_open",
			"type": TYPE_BOOL,
			"default_value": true
		},
	] + super._get_export_options()

func _export_hook(preset: EditorExportPreset, path: String) -> int:
	var add_args = preset.get_or_env("additional_arguments", "")
	if not typeof(add_args) == TYPE_NIL:
		add_args = PackedStringArray(add_args)
	else:
		add_args = PackedStringArray()

	if not add_args.is_empty():
		push_warning("Exporting video with custom arguments: '%s'." % ["' and '".join(add_args)])

	return await export_video(path,
								"res://",
								preset.get_or_env("fps", ""),
								preset.get_or_env("resolution_override", ""),
								preset.get_or_env("verbosity", ""),
								add_args,
								preset.get_or_env("keep_open", "")
								)

func _get_binary_extensions(_preset:EditorExportPreset) -> PackedStringArray:
	return get_builtin_video_export_extensions() + PackedStringArray(["*"])
