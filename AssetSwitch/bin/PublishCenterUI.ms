--*****************************************************
--Aaron Dabelow, theonlyaaron@gmail.com
--*****************************************************
-- HISTORY:
--- version 1.0 : 08.05.2014  	>> Created by Aaron Dabelow
--- version 1.1 : 08.05.2014  	>> Improved Publish settings
--- version 1.4 : 01.16.2015  	>> Naming version of objects now made easier
--					 >> Save globalNode properties, if present
--- version 1.6 : 06.26.2025  	>> Script modernization and features improvements
--*****************************************************

try (destroydialog ASSET_PublishCenterRollout) catch()

struct ASSET_PublishOptions
(	
	function FN_GetPrefixList =
	(
		curFile = assetFile
		curFileParts = (filterString curFile @"\")
		str = ""

		-- Get the project folder
		for i in 1 to curFileParts.count do
		(
			if curFileParts[i] == "Projects" or curFileParts[i] == "Pitches"
			then
			(

				for j in 1 to i do
				(
					str = str + curFileParts[j] + @"\"
				)
				
				str = str + curFileParts[ ( i + 1 ) ] + @"\Data\"
				exit
			)
			else ( str = "" )
		)

		dataFile = (str + @"assetSwitch.ini")

		classesArr = execute (getinisetting dataFile "classes" "classesArr")
		return classesArr
	),

	function FN_SetPrefixList arg_classes  =
	(
		curFile = maxFilePath
		curFileParts = (filterString curFile @"\")
		str = ""

		-- Get the project folder
		for i in 1 to curFileParts.count do
		(
			if curFileParts[i] == "Projects" or curFileParts[i] == "Pitches"
			then
			(

				for j in 1 to i do
				(
					str = str + curFileParts[j] + @"\"
				)
				
				str = str + curFileParts[ ( i + 1 ) ] + @"\Data\"
				exit
			)
			else ( str = "" )
		)
		dataFile = (str + @"assetSwitch.ini")
		setinisetting dataFile "classes" "classesArr" (arg_classes as string)
	),
/*
	fn FN_classNamePreset_Dialog =
	(
		try (destroydialog classNamePreset_Dialog) catch()
		
		rollout classNamePreset_Dialog  "Add Preset Class Name" width:350 height:200
		(
			multilistbox mlb_Classes -- items:curClasses 
			editText edt_add "" text:"New" align:#left offset:[-4,0] width: (classNamePreset_Dialog.width - 58 )
			button btn_add "Add" align:#left offset:[(classNamePreset_Dialog.width - 60 ),-25]
			button btn_save "Save" align:#left offset:[(classNamePreset_Dialog.width - 115 ),0]
			button btn_cancel "Cancel" align:#left offset:[(classNamePreset_Dialog.width - 73 ),-26]
			
			on btn_add pressed do
			(
				list = (mlb_Classes.items + #(edt_add.text))
				mlb_Classes.items = list				
			)
			
			on btn_save pressed do
			(
				ASSET_PublishOptions.FN_SetPrefixList mlb_Classes.items
				destroydialog classNamePreset_Dialog
				destroydialog ASSET_PublishCenterRollout
				FN_PublishCenter()
			)
			
			on btn_cancel pressed do
			(
				destroydialog classNamePreset_Dialog
			)
			
			on classNamePreset_Dialog open do
			(
				curClasses = ASSET_PublishOptions.FN_GetPrefixList() -- #("a","B") --
				mlb_Classes.items = curClasses
			)
		)
		createDialog classNamePreset_Dialog
	),
*/
	-- Max File Options Rollout
	fn maxfile =
	(
		rollout ASSET_Options_MaxFile  "Publish Center Options" width:350 height:90
		(
			groupbox grp "3ds Max File Options" width:(ASSET_Options_MaxFile.width - 25) height:(ASSET_Options_MaxFile.height - 40)
			dropdownlist ddl_Contents "" items:#("Publish asset only (reccomended)","Publish entire scene") offset:[10,((grp.height * -1) + 15)] width:(ASSET_Options_MaxFile.width - 45)
			button buttonOK "OK" pos:[(ASSET_Options_MaxFile.width - 92),(ASSET_Options_MaxFile.height - 30)]
			button buttonCancel "Cancel" align:#right offset:[0,-26]

			on ASSET_Options_MaxFile open do
			(
				try( ddl_Contents.selection = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "MaxFile" "PublishMode")) )catch()
			)
			on buttonOK pressed do
			(
				setinisetting (ASSET_PublishFunctions.INIget()) "MaxFile" "PublishMode" (ddl_Contents.selection as string)
				destroydialog ASSET_Options_MaxFile
			)
			on buttonCancel pressed do( destroydialog ASSET_Options_MaxFile )
		)
		createDialog ASSET_Options_MaxFile
	),
	-- Function to test if tylibMtl is chosen as export option
	function tylibMtl_test =
	(
		getinisetting (ASSET_PublishFunctions.INIget()) "MaterialFile" "tyLibMtl"
	),
	-- Material File Options Rollout
	fn materialfile tyLibMatExists =
	(
		rollout ASSET_Options_MaterialFile  "Publish Center Options" width:350 height:185
		(
			group "Material File Options" --width:(ASSET_Options_MaterialFile.width - 25) height:(ASSET_Options_MaterialFile.height - 75)
			(
				checkbox TyLibMaterialCheckbox "Also save tyLibMtl material" enabled:tyLibMatExists tooltip:"Enables Publishing a tyLib Material alongside the Material Library" 
			)
			group "Material Conflict Options" --offset:[0,15] width:(ASSET_Options_MaterialFile.width - 25) height:(ASSET_Options_MaterialFile.height - 75)
			(
				label GlobalChildrenConflict_Label "Global and Children conflict:" offset:[-5,0] tooltip:"Default option when a conflict is detected between the Global and its children"  across:2
				label ChildrenConflict_Label "Children conflict:" offset:[-11,0] tooltip:"Default option when a conflict is detected between the children"
				radiobuttons GlobalChildren_Radiobutton "" labels:#("Save Global only", "Save Global and Children", "Ask per case") tooltip:#("Publish the Global's material only","Publish the Global and its children's materials","Prompt user when a conflict is detected") offsets:#([0,0], [0,5], [0,10]) default:3 across:2
				radiobuttons Children_Radiobutton "" labels:#("Save all Children", "Ask per case")  tooltip:#("Publish all of children's materials","Prompt user when a conflict is detected") offsets:#([0,0], [0,5]) default:2
			)
			button buttonOK "OK" pos:[(ASSET_Options_MaterialFile.width - 92),(ASSET_Options_MaterialFile.height - 30)]
			button buttonCancel "Cancel" align:#right offset:[0,-26]
			on buttonOK pressed do
			(
				setinisetting (ASSET_PublishFunctions.INIget()) "MaterialFile" "GlobalChildrenConflict" (GlobalChildren_Radiobutton.state as string)
				setinisetting (ASSET_PublishFunctions.INIget()) "MaterialFile" "ChildrenConflict" (Children_Radiobutton.state as string)
				setinisetting (ASSET_PublishFunctions.INIget()) "MaterialFile" "tyLibMtl" (TyLibMaterialCheckbox.checked as string)
				destroydialog ASSET_Options_MaterialFile
			)
			on ASSET_Options_MaterialFile open do
			(
				try( GlobalChildren_Radiobutton.state = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "MaterialFile" "GlobalChildrenConflict" )) )catch()
				try( Children_Radiobutton.state = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "MaterialFile" "ChildrenConflict" )) )catch()
				try( TyLibMaterialCheckbox.checked = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "MaterialFile" "tyLibMtl" )) )catch()
			)
			on buttonCancel pressed do ( destroydialog ASSET_Options_MaterialFile )
		)
		createDialog ASSET_Options_MaterialFile
	),

	-- VRMESH File Options Rollout
	fn vrmeshfile =
	(
		rollout ASSET_Options_vrmeshFile  "Publish Center Options" width:350 height:105
		(
			group  "VRMESH File Options" --width:(ASSET_Options_vrmeshFile.width - 25) height:(ASSET_Options_vrmeshFile.height - 40)
			(
				checkbox chk_exportAnimation "Export Animation" across:3 tooltip:"Enables Publishing a VRay animated proxy"  
				spinner spn_from "from" range:[-9999,9999,((animationrange.start / TicksPerFrame ) as integer )] type:#integer width:70 align:#left offset:[51,1]  tooltip:"Start frame to Publish animation"
				spinner spn_to "to" range:[-9999,9999,((animationrange.end / TicksPerFrame ) as integer )] type:#integer width:70 align:#left offset:[20,1]  tooltip:"End frame to Publish animation"
				
				spinner spn_facecount "Number of faces in preview mesh: " align:#left range:[1,50000,1000] type:#integer offset:[15,0] width:100
			)
			button buttonOK "OK" pos:[(ASSET_Options_vrmeshFile.width - 92),(ASSET_Options_vrmeshFile.height - 30)]
			button buttonCancel "Cancel" align:#right offset:[0,-26]
			
			on chk_exportAnimation changed state do
			(
				spn_from.enabled = spn_to.enabled = ASSET_PublishCenterRollout.lab_vrmeshAnimFrames.enabled = state
			)
			on spn_from changed state do (if state >= spn_to.value then (spn_to.value = state)else())
			on spn_to changed state do (if state <= spn_from.value then (spn_from.value = state)else())
			
			on ASSET_Options_vrmeshFile open do
			(
				try
				(
					chk_exportAnimation.checked = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "vrmeshFile" "ExportAnimation" ))
					spn_from.enabled = spn_to.enabled = chk_exportAnimation.checked
				)
				catch ()
				try( spn_from.value = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "vrmeshFile" "FrameStart" )) )catch()
				try( spn_to.value = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "vrmeshFile" "FrameEnd" )) )catch()
				try( spn_facecount.value = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "vrmeshFile" "Facecount" )) )catch()
			)
				
			on buttonOK pressed do
			(
				setinisetting (ASSET_PublishFunctions.INIget()) "vrmeshFile" "ExportAnimation" (chk_exportAnimation.checked as string)
				setinisetting (ASSET_PublishFunctions.INIget()) "vrmeshFile" "FrameStart" (spn_from.value as string)
				setinisetting (ASSET_PublishFunctions.INIget()) "vrmeshFile" "FrameEnd" (spn_to.value as string)
				setinisetting (ASSET_PublishFunctions.INIget()) "vrmeshFile" "Facecount" (spn_facecount.value as string)
				destroydialog ASSET_Options_vrmeshFile
					
				ASSET_PublishCenterRollout.FN_UpdateFrameRange ASSET_PublishCenterRollout.lab_vrmeshAnimFrames "vrmeshFile" "ExportAnimation"
			)
			on buttonCancel pressed do( destroydialog ASSET_Options_vrmeshFile )
		)
		createDialog ASSET_Options_vrmeshFile
	),
	fn AnimationFile =
	(
		rollout ASSET_Options_Animation "Publish Center Options" width:350 height:105
		(
			group  "Publish Animation Options"
			(
				checkbox SetRange_CheckBox "Set Range" checked:false tooltip:"Enables Animation Publish on a specific range" across:3
				spinner StartRange_Spinner "from" range:[-9999,9999,animationrange.start] type:#integer width:70 align:#left offset:[51,1] tooltip:"Start frame to Publish animation"
				spinner EndRange_Spinner "to" range:[-9999,9999,animationrange.end] type:#integer width:70 align:#left offset:[20,1] tooltip:"End frame to Publish animation"
				checkbox LoadSavedNames_CheckBox "Load saved names before transferring animation" checked:false  tooltip:"Load saved names inside User Properties on the object before doing a Publish"
			)
			button buttonOK "OK" pos:[258, 75]
			button buttonCancel "Cancel" align:#right offset:[0,-26]

			on SetRange_CheckBox changed state do
			(
				StartRange_Spinner.enabled = EndRange_Spinner.enabled = ASSET_PublishCenterRollout.lab_AnimationAnimFrames.enabled = state
			)
			on StartRange_Spinner changed state do (if state >= EndRange_Spinner.value then (EndRange_Spinner.value = state)else())
			on EndRange_Spinner changed state do (if state <= StartRange_Spinner.value then (StartRange_Spinner.value = state)else())


			on ASSET_Options_Animation open do
			(
				try
				(
					SetRange_CheckBox.checked = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "AnimationPublish" "SetRange" ))
					StartRange_Spinner.enabled = EndRange_Spinner.enabled = SetRange_CheckBox.checked
					StartRange_Spinner.value = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "AnimationPublish" "FrameStart" ))
					EndRange_Spinner.value = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "AnimationPublish" "FrameEnd" ))
					LoadSavedNames_CheckBox.checked = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "AnimationPublish" "LoadSavedNames" ))
				)
				catch()
			)
			on buttonOK pressed do
			(
				setinisetting (ASSET_PublishFunctions.INIget()) "AnimationPublish" "SetRange" (SetRange_CheckBox.checked as string)
				setinisetting (ASSET_PublishFunctions.INIget()) "AnimationPublish" "FrameStart" (StartRange_Spinner.value as string)
				setinisetting (ASSET_PublishFunctions.INIget()) "AnimationPublish" "FrameEnd" (EndRange_Spinner.value as string)
				setinisetting (ASSET_PublishFunctions.INIget()) "AnimationPublish" "LoadSavedNames" (LoadSavedNames_CheckBox.checked as string)
				destroydialog ASSET_Options_Animation
				ASSET_PublishCenterRollout.FN_UpdateFrameRange ASSET_PublishCenterRollout.lab_AnimationAnimFrames "AnimationPublish" "OutputEnabled"
			)
			on buttonCancel pressed do( destroydialog ASSET_Options_Animation )
		)
		createDialog ASSET_Options_Animation
	)
)

-- Function that calls the publish center, and its constituents
function FN_PublishCenter = -- asset: the current asset definition
(	
	
	-- The main rollout
	rollout	ASSET_PublishCenterRollout ("Publish Center v" + (versionNumber as string)) width:380 height:505
	(
		label lab_AssetName assetName
/*
		groupbox grp_PrefixGang "Class Name" width:(ASSET_PublishCenterRollout.width - 15) align:#left offset:[-5,0] height:65
			dropdownlist  ddl_className items:#("Error loading presets") width:(ASSET_PublishCenterRollout.width - 80) align:#left offset:[-1,(grp_PrefixGang.height * -1 + 10)]
			button btn_PrefixGang_Preset "Presets" align:#left offset:[(ASSET_PublishCenterRollout.width - 80),-28]
			edittext edt_PrefixGang_Custom text:"Layout" width:(ASSET_PublishCenterRollout.width - 25) align:#left offset:[-3,0] enabled:true
*/
		groupbox grp_MaterialFile "" width:(ASSET_PublishCenterRollout.width - 15) align:#left offset:[-5,5] height:65
			checkbox chk_MaterialFile "Material" align:#left offset:[0,((grp_MaterialFile.height * -1) - 5)] tooltip:"Enable Material Publish"
				dropdownlist ddl_MaterialFile_Name "" items:#("name","none") width:60 align:#left offset:[-1,0]  visible:false
				edittext edt_MaterialFile_Prefex "" text: "ver" width:60 align:#left offset:[0,-25] tooltip:"Version name prefix"
				spinner spinner_MaterialFile_Number "" range:[1,999,1] type:#integer width:40 align:#left offset:[60,-21] tooltip:"Version number"
				button button_MaterialFile_Options "Options" offset:[0,-25] align:#right tooltip:"Material Publishing Options"
				label lab_MaterialFile " error" style_sunkenedge:true height:16 width:(ASSET_PublishCenterRollout.width - 25) align:#left offset:[0,0]
		
		groupbox grp_MaxFile "" width:(ASSET_PublishCenterRollout.width - 15) align:#left offset:[-5,5] height:65
			checkbox chk_MaxFile "3ds Max File" align:#left offset:[0,((grp_MaxFile.height * -1) - 5)] checked:true tooltip:"Enable 3dsMax file Publish"
				dropdownlist ddl_MaxFile_Name "" items:#("name","none") width:60 align:#left offset:[-1,0]  visible:false
				edittext edt_MaxFile_Prefex "" text: "ver" width:60 align:#left offset:[0,-25] tooltip:"Version name prefix"
				spinner spinner_MaxFile_Number "" range:[1,999,1] type:#integer width:40 align:#left offset:[60,-21] tooltip:"Version number"
				button button_MaxFile_Options "Options" offset:[0,-25] align:#right tooltip:"3dsMax Publishing Options"
				label lab_MaxFile " error" style_sunkenedge:true height:16 width:(ASSET_PublishCenterRollout.width - 25) align:#left offset:[0,0]
			
		groupbox grp_vrmeshFile "" width:(ASSET_PublishCenterRollout.width - 15) align:#left offset:[-5,5] height:65
			checkbox chk_vrmeshFile ".vrmesh" align:#left offset:[0,((grp_vrmeshFile.height * -1) - 5)] tooltip:"Enable Vraymesh file Publish"
				dropdownlist ddl_vrmeshFile_Name "" items:#("name","none") width:60 align:#left offset:[-1,0]  visible:false
				edittext edt_vrmeshFile_Prefex "" text: "ver" width:60 align:#left offset:[0,-25] tooltip:"Version name prefix"
				spinner spinner_vrmeshFile_Number "" range:[1,999,1] type:#integer width:40 align:#left offset:[60,-21] tooltip:"Version number"
				button button_vrmeshFile_Options "Options" offset:[0,-25] align:#right tooltip:"VRay Publishing Options"
				label lab_vrmeshAnimFrames "frames:0" enabled:false align:#left offset:[125,-20]
				button button_vrmeshFileRefresh "R" align:#left offset:[105,-21] width:18 height:18 tooltip:"Reset frame range to current scene time range and enables Export Animation under Options menu"
				label lab_vrmeshFile " error" style_sunkenedge:true height:16 width:(ASSET_PublishCenterRollout.width - 25) align:#left offset:[0,0]

		groupbox grp_vrmeshPartsFile "" width:(ASSET_PublishCenterRollout.width - 15) align:#left offset:[-5,5] height:65
			checkbox chk_vrmeshPartsFile ".vrmesh Parts" align:#left offset:[0,((grp_vrmeshFile.height * -1) - 5)] tooltip:"Enable Vraymesh file parts Publish"
				dropdownlist ddl_vrmeshPartsFile_Name "" items:#("name","none") width:60 align:#left offset:[-1,0] visible:false
				edittext edt_vrmeshPartsFile_Prefex "" text: "ver" width:60 align:#left offset:[0,-25] tooltip:"Version name prefix"
				spinner spinner_vrmeshPartsFile_Number "" range:[1,999,1] type:#integer width:40 align:#left offset:[60,-21] tooltip:"Version number"
				label lab_vrmeshPartsFile " error" style_sunkenedge:true height:16 width:(ASSET_PublishCenterRollout.width - 25) align:#left offset:[0,0]

		groupbox grp_AnimationFile "" width:(ASSET_PublishCenterRollout.width - 15) align:#left offset:[-5,5] height:65
			checkbox chk_AnimationFile "Animation .xaf File" align:#left offset:[0,((grp_AnimationFile.height * -1) - 5)] tooltip:"Enable Animation file Publish"
				dropdownlist ddl_AnimationFile_Name "" items:#("name","none") width:60 align:#left offset:[-1,0]  visible:false
				edittext edt_AnimationFile_Prefex "" text: "ver" width:60 align:#left offset:[0,-25] tooltip:"Version name prefix"
				spinner spinner_AnimationFile_Number "" range:[1,999,1] type:#integer width:40 align:#left offset:[60,-21] tooltip:"Version number"
				button button_AnimationFile_Options "Options" offset:[0,-25] align:#right tooltip:"Animation Publishing Options"
				label lab_AnimationAnimFrames "frames:0" enabled:false align:#left offset:[125,-20]
				button button_AnimationFileRefresh "R" align:#left offset:[105,-21] width:18 height:18 tooltip:"Reset frame range to current scene time range and enables Set Range under Options menu"
				label lab_AnimationFile " error" style_sunkenedge:true height:16 width:(ASSET_PublishCenterRollout.width - 25) align:#left offset:[0,0]

		groupbox grp_PublishAsset "Publish Asset" width:(ASSET_PublishCenterRollout.width - 15) align:#left offset:[-5,5] height:120
			label lab_PublishAssetDir  "" style_sunkenedge:true align:#left width:(ASSET_PublishCenterRollout.width - 68) height:16 offset:[0,((grp_PublishAsset.height * -1) + 10)]
				button btn_copyAssetDir "C" width:18 height:18 align:#left offset:[(ASSET_PublishCenterRollout.width - 65),-23] tooltip:"Copy the path to the clipboard"
				button btn_openAssetDir "..." width:18 height:18 align:#left offset:[(ASSET_PublishCenterRollout.width - 45),-23] tooltip:"Open explorer on the current path"
				button btn_PublishAsset " Publish Asset " height:40 width:(ASSET_PublishCenterRollout.width - 25) tooltip:"Publish Assets"
				progressbar prog_totalprogress height:10 width:(ASSET_PublishCenterRollout.width - 25)
				label lab_Status " Status: ready" style_sunkenedge:true height:16 width:(ASSET_PublishCenterRollout.width - 65) align:#left
				button btn_logOpen "log" height:20 width:40 align:#left offset:[(ASSET_PublishCenterRollout.width - 65),-23] tooltip:"Open the publishing log"
		

		-- Bakes on ALL children their name as a User Properties.
		fn FN_ChildrenName_Bake =
		(
			ChildrenArray = ASSET_PublishFunctions.CollectAllChildren nodeAsset includeParent:false
			if ChildrenArray.count > 1 do
			(
				Global_Asset_Name = (getINISetting assetFile "Global" "name")
				for child in ChildrenArray do
				(
					if (doesUserPropExist child "AssetName") do
					(
						deleteUserProp child "AssetName"
					)
					setUserProp child "MAKE_NodeName" child.name
				)
			)
		)
		-- Returns the filename of the desired output, with the passed variables included
		function FN_UpdateLocalPath target curClass arg1 arg2 arg3 = -- target:target label | curClass:class of publish | edittext arg1: name | arg2: prefix | arg3:version
		(
			nameVer = arg2 + "_" + (substring ((arg3 + 1000)as string) 2 4) 
			case arg1 of
			(
				1:(curAssetName = (assetName + "_" ))
				2:(curAssetName = "")
			)
			
			case curClass of
			(
				1: -- 3dsMaxFile
				(
					curClassName = "Max"
					curClassExtension = ".max"
				)
				2: -- AnimationFile
				(
					curClassName = "Animation"
					curClassExtension = ".xaf"
					comboString = (@"\" + curClassName + @"\" + curAssetName + nameVer + curClassExtension )
					target.text = comboString
					return comboString
				)
				3: -- MaterialFile
				(
					curClassName = "Material"
					curClassExtension = ".mat"
					
					comboString = (@"\" + curClassName + @"\" + curAssetName + nameVer + curClassExtension )
					target.text = comboString
					tyLibSave = ((ASSET_PublishOptions()).tylibMtl_test())
					if tyLibSave == "true" then
					(
						tylib_comboString = (@"\" + curClassName + @"\" + curAssetName + nameVer + "_tyLibMtl" + curClassExtension )
						return #(comboString, tylib_comboString)
					)
					else
					(
						return #(comboString)
					)
				)
				4: -- vrmeshFile
				(
					curClassName = "Vrmesh"
					curClassExtension = ".vrmesh"
				)
				5: -- vrmesh Parts
				(
					curClassName = "VrmeshParts"     -- TODO: Reevaluate the naming (maybe rename to VrayRig - Rigid objects only)
					curClassExtension = ".vrmesh"
				)
			)			
			
			comboString = (@"\" + curClassName + @"\" + nameVer + @"\" + curAssetName + nameVer + curClassExtension )
			target.text = comboString
			
			return comboString
		)
		
		-- Sets the publish asset preview path, truncating if necessary
		function FN_PublishAssetDirPreview = 
		(
			maxStringLength = 50
			
			if assetDir.count > maxStringLength
			then(lab_PublishAssetDir.text = ( " ..." + ( substring assetDir (assetDir.count - maxStringLength ) 5000)))
			else(lab_PublishAssetDir.text = ( " " + assetDir ))
		)
		
		-- Sets passed publish class to animation enabled, and sets its export frame range to the current time line
		function FN_RefreshFrameRange arg_label arg_iniKey ar_variable = -- arg_iniKey: where to read out of the .ini file | arg_label: the label to update
		(
			startFrame = ((animationrange.start as integer / ticksperframe) as string)
			endFrame = ((animationrange.end as integer / ticksperframe) as string)
			
			setinisetting (ASSET_PublishFunctions.INIget()) arg_iniKey ar_variable "true"
			setinisetting (ASSET_PublishFunctions.INIget()) arg_iniKey "FrameStart" (startFrame as string)
			setinisetting (ASSET_PublishFunctions.INIget()) arg_iniKey "FrameEnd" (endFrame as string)
				
			arg_label.text = ("frames: " + startFrame + " to " + endFrame)
		)
		
		-- Function for reading and sorting the frame range for an asset publish, and updates the UI for it
		function FN_UpdateFrameRange arg_label arg_iniKey ar_variable =  -- arg_label: the UI element to update |arg_iniKey: where to read out of the ini file
		(
			-- Get if animation is enabled
			if ( hasinisetting (ASSET_PublishFunctions.INIget()) arg_iniKey ar_variable ) then
			(
				export_animation = ( execute ( getinisetting (ASSET_PublishFunctions.INIget()) arg_iniKey ar_variable ))
			)
			else
			(
				setinisetting (ASSET_PublishFunctions.INIget()) arg_iniKey ar_variable "false"
				export_animation = false
			)
			
			-- Set the approprite frame or frame range to the .ini and ui
			if export_animation then
			(
				startFrame = ( getinisetting (ASSET_PublishFunctions.INIget()) arg_iniKey "FrameStart" )
				endFrame = ( getinisetting (ASSET_PublishFunctions.INIget()) arg_iniKey "FrameEnd" )
				arg_label.text = ("frames: " + startFrame + " to " + endFrame)
			)
			else
			(	
				StartFrame = ((animationrange.start as integer / ticksperframe) as string)
				EndFrame = ((animationrange.end as integer / ticksperframe) as string)
				setinisetting (ASSET_PublishFunctions.INIget()) arg_iniKey "FrameStart" StartFrame
				setinisetting (ASSET_PublishFunctions.INIget()) arg_iniKey "FrameEnd" EndFrame
				arg_label.text = ("frames: " + StartFrame + " to " + EndFrame)
			)
		)
		
		-- Functions that update the filename and path for the desired asset class
		function FN_Update_3dsMaxFile =				(FN_UpdateLocalPath lab_MaxFile 1 ddl_MaxFile_Name.selection edt_MaxFile_Prefex.text spinner_MaxFile_Number.value)
		function FN_Update_Material_Lib_File =		(FN_UpdateLocalPath lab_MaterialFile 3 ddl_MaterialFile_Name.selection edt_MaterialFile_Prefex.text spinner_MaterialFile_Number.value)
		function FN_Update_vrmeshFile =				(FN_UpdateLocalPath lab_vrmeshFile 4 ddl_vrmeshFile_Name.selection edt_vrmeshFile_Prefex.text spinner_vrmeshFile_Number.value)
		function FN_Update_vrmeshPartsFile =		(FN_UpdateLocalPath lab_vrmeshPartsFile 5 ddl_vrmeshPartsFile_Name.selection edt_vrmeshPartsFile_Prefex.text spinner_vrmeshPartsFile_Number.value)
		function FN_Update_AnimationFile = 			(FN_UpdateLocalPath lab_AnimationFile 2 ddl_AnimationFile_Name.selection edt_AnimationFile_Prefex.text spinner_AnimationFile_Number.value)


		function FN_ReportResult arg_result arg_timestart_minor = -- arg_result : the string returned from the publisher  | arg_timestart : the start time of the operation
		(
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": [   TASK RESULT   ] : " + arg_result )
			timeend_minor = timestamp()
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": [  TASK DURATION  ] : " + (((timeend_minor - arg_timestart_minor) * .001 ) as string) + " seconds")
			
			if arg_result == "Success!"	then (return 0) else (return 1)
		)
		function FN_ReportEnd arg_errors arg_timestart = -- arg_errors : the number of errors during the publish | arg_timestart : the start time of the operation
		(
			
			timeend = timestamp()
			lab_Status.text = (" Status: Publsihing took " + (((timeend - arg_timestart) * .001 ) as string) + " seconds, with " + (arg_errors as string) + " errors")
			
			ASSET_PublishFunctions.LOGwrite "---------------------------------RESULT----------------------------------"
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": [  TASK DURATION  ] : " + (((timeend - arg_timestart) * .001 ) as string) + " seconds")
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": [   ERROR COUNT   ] : Task contained " + (arg_errors as string ) + " error(s)")
			ASSET_PublishFunctions.LOGwrite "-------------------------------------------------------------------------"
		)
		
		-- Publisher for the 3dsMaxFile class
		function FN_Publish_MaxFile =
		(
			local publish_filepath = ( assetDir + @"Publish" + (FN_Update_3dsMaxFile())) -- ASK_AARON - Maybe add @ on this string?
			
			-- Prepare to publish
			timestart_minor = timestamp()
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": <<< Publishing 3dsMax File >>>")
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": [ ASSET DIRECTORY ] : " + publish_filepath )
			lab_Status.text = " Status: Publishing 3dsMax File"
			
			-- Call the publish function
			result = ASSET_PublishFunctions.pub_3dsMaxFile "asset" publish_filepath
				
			-- Report result of the Publish
			FN_ReportResult result timestart_minor
		)
		
		-- Publisher for the MaterialFile class
		function FN_Publish_MaterialFile =
		(
			
			-- checks if the user has also set to save a tyLibMtl
			tyLibSave = ((ASSET_PublishOptions()).tylibMtl_test())
			-- Updates the Material Libraries Names
			Material_Libraries = (FN_Update_Material_Lib_File())

			--Collect the paths for the Material Libraries to be created

			local publish_filepath =
			(
				for i = 1 to Material_Libraries.count collect
				(
					assetDir + "Publish" + Material_Libraries[i]
				)
			)
			-- Prepare to publish
			timestart_minor = timestamp()
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": <<< Publishing Material File >>>")

			ASSET_PublishFunctions.LOGwrite (LocalTime + ": [ ASSET DIRECTORY ] : " + publish_filepath[1] ) -- TODO: publish_filepath[1] currently accounts for
																											-- the first material name only, and not the tyLibMatl
			lab_Status.text = " Status: Publishing Material File"

			-- Call the publish function
			result = ASSET_PublishFunctions.pub_MaterialFile "asset" publish_filepath tyLibSave
				
			-- Report result of the Publish
			FN_ReportResult result timestart_minor
		)
		
		-- Publisher for the vrmeshFile class
		function FN_Publish_vrmeshFile =
		(
			publish_filepath = ( assetDir + "Publish" + (FN_Update_vrmeshFile())) -- ASK_AARON - Maybe add @ on this string?
			
			-- Prepare to publish
			timestart_minor = timestamp()
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": <<< Publishing vrmesh File >>>")
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": [ ASSET DIRECTORY ] : " + publish_filepath)
			lab_Status.text = " Status: Publishing vrmesh File"
			result = ASSET_PublishFunctions.pub_vrmeshFile "asset" publish_filepath true
		
			-- Report result of the Publish
			FN_ReportResult result timestart_minor
		)

		function FN_Publish_vrmeshPartsFile =
		(
			publish_filepath = ( assetDir + "Publish" + (FN_Update_vrmeshPartsFile()))

			-- Prepare to publish
			timestart_minor = timestamp()
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": <<< Publishing vrmesh Parts File >>>")
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": [ ASSET DIRECTORY ] : " + publish_filepath)
			lab_Status.text = " Status: Publishing vrmesh Parts File"

			result = ASSET_PublishFunctions.pub_vrmeshFile "asset" publish_filepath false
			FN_ReportResult result timestart_minor
		)
		
		function FN_Publish_AnimationFile =
		(
			publish_filepath = ( assetDir + "Publish" + (FN_Update_AnimationFile()))

			-- Prepare to publish
			timestart_minor = timestamp()
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": <<< Publishing Animation File >>>")
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": [ ASSET DIRECTORY ] : " + publish_filepath)
			lab_Status.text = " Status: Publishing Animation File"

			result = ASSET_PublishFunctions.pub_AnimationFile "asset" publish_filepath
			FN_ReportResult result timestart_minor


		)
		
		function FN_PUBhistSave =
		(
			setUserProp nodeAsset "MAKE_Asset_Material_Prefix" edt_MaterialFile_Prefex.text
 			setUserProp nodeAsset "MAKE_Asset_Material_Versions" spinner_MaterialFile_Number.value
 			setUserProp nodeAsset "MAKE_Asset_Max_Prefix" edt_MaxFile_Prefex.text
 			setUserProp nodeAsset "MAKE_Asset_Max_Versions" spinner_MaxFile_Number.value
 			setUserProp nodeAsset "MAKE_Asset_Vrmesh_Prefix" edt_vrmeshFile_Prefex.text
 			setUserProp nodeAsset "MAKE_Asset_Vrmesh_Versions" spinner_vrmeshFile_Number.value
 			setUserProp nodeAsset "MAKE_Asset_VrmeshParts_Prefix" edt_vrmeshPartsFile_Prefex.text
 			setUserProp nodeAsset "MAKE_Asset_VrmeshParts_Versions" spinner_vrmeshPartsFile_Number.value
 			setUserProp nodeAsset "MAKE_Asset_Animation_Prefix" edt_AnimationFile_Prefex.text
 			setUserProp nodeAsset "MAKE_Asset_Animation_Versions" spinner_AnimationFile_Number.value
 			setUserProp nodeAsset "MAKE_Asset_TimeStamp" localTime
 			setUserProp nodeAsset "MAKE_Asset_Author" sysInfo.username
 			setUserProp nodeAsset "MAKE_Asset_Computer" sysInfo.computername 
		)
		
		-- Enables / Disables UI items if that section is enabled
		function FN_UpdateUiSubItems =
		(
			-- 3dsMaxFile
			bool = chk_MaxFile.checked
			lab_MaxFile.enabled = bool
			spinner_MaxFile_Number.enabled = bool
			edt_MaxFile_Prefex.enabled = bool
			ddl_MaxFile_Name.enabled = bool
			button_MaxFile_Options.enabled = bool
			
			-- MaterialFile
			bool = chk_MaterialFile.checked
			lab_MaterialFile.enabled = bool
			spinner_MaterialFile_Number.enabled = bool
			edt_MaterialFile_Prefex.enabled = bool
			ddl_MaterialFile_Name.enabled = bool
			button_MaterialFile_Options.enabled = bool
			
			-- vrmeshFile
			bool = chk_vrmeshFile.checked
			lab_vrmeshFile.enabled = bool
			spinner_vrmeshFile_Number.enabled = bool
			edt_vrmeshFile_Prefex.enabled = bool
			button_vrmeshFileRefresh.enabled = bool
			ddl_vrmeshFile_Name.enabled = bool
			button_vrmeshFile_Options.enabled = bool
			if bool then
			(
				lab_vrmeshAnimFrames.enabled = (execute ( getinisetting (ASSET_PublishFunctions.INIget()) "vrmeshFile" "ExportAnimation" ))
			)
			else
			(
				lab_vrmeshAnimFrames.enabled = bool
			)

			-- vrmeshPartsFile
			bool = chk_vrmeshPartsFile.checked
			lab_vrmeshPartsFile.enabled = bool
			spinner_vrmeshPartsFile_Number.enabled = bool
			edt_vrmeshPartsFile_Prefex.enabled = bool
			ddl_vrmeshPartsFile_Name.enabled = bool

			-- AnimationFile
			bool = chk_AnimationFile.checked
			lab_AnimationFile.enabled = bool
			spinner_AnimationFile_Number.enabled = bool
			edt_AnimationFile_Prefex.enabled = bool
			button_AnimationFileRefresh.enabled = bool
			ddl_AnimationFile_Name.enabled = bool
			button_AnimationFile_Options.enabled = bool
			if bool then
			(
				lab_AnimationAnimFrames.enabled = (execute ( getinisetting (ASSET_PublishFunctions.INIget()) "AnimationPublish" "SetRange" ))
			)
			else
			(
				lab_AnimationAnimFrames.enabled = bool
			)
		)
		
		function FN_CountEnabled =
		(
			count = 0
			if chk_MaxFile.checked then 			(count += 1)
			if chk_MaterialFile.checked then 		(count += 1)
			if chk_vrmeshFile.checked then 			(count += 1)
			if chk_vrmeshPartsFile.checked then 	(count += 1)
			if chk_AnimationFile.checked then 		(count += 1)
			return count
		)
		
		-- Prepares the Publish button to read the number of assets to publish
		function FN_CategoryToggle =
		(
			btn_PublishAsset.text = ("Publish ( " + (FN_CountEnabled() as string) + " ) Assets")
			FN_UpdateUiSubItems()
		)

		function updateAllPrefixes arg_str =
		(
			-- All of the edit texts
			editArray = #(edt_MaxFile_Prefex, edt_MaxOptimizedFile_Prefex, edt_MaterialFile_Prefex, edt_xmeshFile_Prefex, edt_vrmeshFile_Prefex, edt_xmeshAsMaxFile_Prefex, edt_vrmeshAsMaxFile_Prefex )
			for i in editArray do
			(
				i.text = arg_str
			)
			FN_Update_3dsMaxFile()
			FN_Update_Material_Lib_File()
			FN_Update_vrmeshFile()
			FN_Update_vrmeshPartsFile()
			FN_Update_AnimationFile()
		)
		--------------------
		-- Event Handlers --
		--------------------
		/*
		on btn_PrefixGang_Preset pressed do
		(
			ASSET_PublishOptions.FN_classNamePreset_Dialog()
		)	
		on ddl_className selected arg do
		(
			if arg != ddl_className.items.count 
			then
			(
				edt_PrefixGang_Custom.enabled = true
				updateAllPrefixes ddl_className.items[arg]

				edt_PrefixGang_Custom.text = ddl_className.items[arg]
			)
			else
			(
				edt_PrefixGang_Custom.enabled = true
				updateAllPrefixes edt_PrefixGang_Custom.text

				edt_PrefixGang_Custom.text = ddl_className.items[arg]
			)
		)

		on edt_PrefixGang_Custom changed state do updateAllPrefixes state

*/
		-- MaterialFile
		on chk_MaterialFile changed state do
		(
			setinisetting (ASSET_PublishFunctions.INIget()) "MaterialFile" "OutputEnabled" (chk_MaterialFile.checked as string)
			FN_CategoryToggle()
		)
		on ddl_MaterialFile_Name selected state do (FN_Update_Material_Lib_File())
		on edt_MaterialFile_Prefex changed state do (FN_Update_Material_Lib_File())
		on spinner_MaterialFile_Number changed state do	(FN_Update_Material_Lib_File())
		on button_MaterialFile_Options pressed do
		(
			tyLibMatExists = true
			if FindItem material.classes tyLibMtl == 0 do
			(
				tyLibMatExists = false
				setinisetting (ASSET_PublishFunctions.INIget()) "MaterialFile" "tyLibMtl" "false"

			)
			ASSET_PublishOptions.materialfile tyLibMatExists
		)
		-- 3dsMaxFile
		on chk_MaxFile changed state do 
		(
			setinisetting (ASSET_PublishFunctions.INIget()) "MaxFile" "OutputEnabled" (chk_MaxFile.checked as string)
			FN_CategoryToggle() 
		)
		on ddl_MaxFile_Name selected state do FN_Update_3dsMaxFile()
		on edt_MaxFile_Prefex changed state do FN_Update_3dsMaxFile()
		on spinner_MaxFile_Number changed state do FN_Update_3dsMaxFile()
		on button_MaxFile_Options pressed do (ASSET_PublishOptions.maxfile())
		-- vrmeshFile
		on chk_vrmeshFile changed state do
		(
			setinisetting (ASSET_PublishFunctions.INIget()) "vrmeshFile" "OutputEnabled" (chk_vrmeshFile.checked as string)
			FN_CategoryToggle() 
		)
		on ddl_vrmeshFile_Name selected state do FN_Update_vrmeshFile()
		on edt_vrmeshFile_Prefex changed state do FN_Update_vrmeshFile()
		on spinner_vrmeshFile_Number changed state do FN_Update_vrmeshFile()
		on button_vrmeshFile_Options pressed do (ASSET_PublishOptions.vrmeshfile())
		on button_vrmeshFileRefresh pressed do
		(
			FN_RefreshFrameRange lab_vrmeshAnimFrames "vrmeshFile" "ExportAnimation"
			lab_vrmeshAnimFrames.enabled = true
		)
		-- vrmeshPartsFile
		on chk_vrmeshPartsFile changed state do
		(
			setinisetting (ASSET_PublishFunctions.INIget()) "vrmeshPartsFile" "OutputEnabled" (chk_vrmeshPartsFile.checked as string)
			FN_CategoryToggle() 
		)
		on ddl_vrmeshPartsFile_Name selected state do FN_Update_vrmeshPartsFile()
		on edt_vrmeshPartsFile_Prefex changed state do FN_Update_vrmeshPartsFile()
		on spinner_vrmeshPartsFile_Number changed state do FN_Update_vrmeshPartsFile()
		-- AnimationFile
		on chk_AnimationFile changed state do
		(
			setinisetting (ASSET_PublishFunctions.INIget()) "AnimationPublish" "OutputEnabled" (chk_AnimationFile.checked as string)
			FN_CategoryToggle() 
		)
		on ddl_AnimationFile_Name changed state do FN_Update_AnimationFile() --TODO: Create this function
		on edt_AnimationFile_Prefex changed state do FN_Update_AnimationFile()
		on spinner_AnimationFile_Number changed state do FN_Update_AnimationFile()
		on button_AnimationFile_Options pressed do (ASSET_PublishOptions.AnimationFile())
		on button_AnimationFileRefresh pressed do
		(
			FN_RefreshFrameRange lab_AnimationAnimFrames "AnimationPublish" "SetRange"
			lab_AnimationAnimFrames.enabled = true
		)		
		-- UI Update triggers for when the main rollout first opens
		on ASSET_PublishCenterRollout open do
		(
			-- Loads previous settings, if settings had been set
			try( chk_MaxFile.checked = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "MaxFile" "OutputEnabled")) )catch()
			try( chk_MaterialFile.checked = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "MaterialFile" "OutputEnabled")) )catch()
			try( chk_vrmeshFile.checked = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "vrmeshFile" "OutputEnabled")) )catch()
			try( chk_vrmeshPartsFile.checked = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "vrmeshPartsFile" "OutputEnabled")) )catch()
			try( chk_AnimationFile.checked = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "AnimationPublish" "OutputEnabled")) )catch()

			-- Update stored names 
			curStr = "undefined"

			curStr = ((getUserProp nodeAsset "MAKE_Asset_Material_Prefix") as string ) 
			if curStr == "undefined" do ( curStr = "ver" )
			edt_MaterialFile_Prefex.text = curStr

			curStr = ((getUserProp nodeAsset "MAKE_Asset_Max_Prefix") as string )
			if curStr == "undefined" do ( curStr = "ver" )
			edt_MaxFile_Prefex.text = curStr

			curStr = ((getUserProp nodeAsset "MAKE_Asset_Vrmesh_Prefix") as string )
			if curStr == "undefined" do ( curStr = "ver" )
			edt_vrmeshFile_Prefex.text = curStr

			curStr = ((getUserProp nodeAsset "MAKE_Asset_VrmeshParts_Prefix") as string )
			if curStr == "undefined" do ( curStr = "ver" )
			edt_vrmeshPartsFile_Prefex.text = curStr
			
			curStr = ((getUserProp nodeAsset "MAKE_Asset_Animation_Prefix") as string )
			if curStr == "undefined" do ( curStr = "ver" )
			edt_AnimationFile_Prefex.text = curStr

			-- Update stored interations
			try( spinner_MaterialFile_Number.value 		= ( ( getUserProp nodeAsset "MAKE_Asset_Material_Versions" ) 	as integer ) ) catch ( spinner_MaterialFile_Number.value 		= 001 )
			try( spinner_MaxFile_Number.value 			= ( ( getUserProp nodeAsset "MAKE_Asset_Max_Versions" ) 		as integer ) ) catch ( spinner_MaxFile_Number.value 			= 001 )
			try( spinner_vrmeshFile_Number.value 		= ( ( getUserProp nodeAsset "MAKE_Asset_Vrmesh_Versions" ) 		as integer ) ) catch ( spinner_vrmeshFile_Number.value 			= 001 )
			try( spinner_vrmeshPartsFile_Number.value 	= ( ( getUserProp nodeAsset "MAKE_Asset_VrmeshParts_Versions" ) as integer ) ) catch ( spinner_vrmeshPartsFile_Number.value 	= 001 )
			try( spinner_AnimationFile_Number.value 	= ( ( getUserProp nodeAsset "MAKE_Asset_Animation_Versions" ) 	as integer ) ) catch ( spinner_AnimationFile_Number.value 		= 001 )
			
			-- Update individual paths for each asset
			FN_Update_3dsMaxFile()
			FN_Update_Material_Lib_File()
			FN_Update_vrmeshFile()
			FN_Update_vrmeshPartsFile()
			FN_Update_AnimationFile()
			--arg_enabled: if animation is enabled | arg_source: either scene or predefined range | arg_label: the UI element to update
			FN_UpdateFrameRange lab_vrmeshAnimFrames "vrmeshFile" "ExportAnimation"
			FN_UpdateFrameRange lab_AnimationAnimFrames "AnimationPublish" "OutputEnabled"
			-- Update Ui Items
			FN_PublishAssetDirPreview()
			FN_CategoryToggle()
		)
		
		-- Main publish Action
		on btn_PublishAsset pressed do
		(
			-- prepare for publishing

			timestart = timestamp()
			errorcount = 0
			ASSET_PublishFunctions.LOGclear()
			prog_totalprogress.value = 0
			countCurrent = 0
			countTotal = FN_CountEnabled()

			FN_PUBhistSave()
			FN_ChildrenName_Bake()

			try( setinisetting AssetFile "Global" "radius" 		(nodeAsset.radius as string)	) catch ()
			try( setinisetting AssetFile "Global" "wirecolor" 	(nodeAsset.wirecolor as string)	) catch ()
			try( setinisetting AssetFile "Global" "steps" 		(nodeAsset.steps as string)		) catch ()
			-- individual publish operations, and progressbar updates
			if chk_MaxFile.checked then 
			(
				errorcount += FN_Publish_MaxFile() -- ASK_AARON - How is the error count updated by this function?? Ask Aaron about this!
				countCurrent += 1
				prog_totalprogress.value = ((( countCurrent / countTotal as float) * 100))
			)

			if chk_MaterialFile.checked then
			(
				errorcount += FN_Publish_MaterialFile()
				countCurrent += 1
				prog_totalprogress.value = ((( countCurrent / countTotal as float) * 100))
			)
			if chk_vrmeshFile.checked then
			(
				errorcount += FN_Publish_vrmeshFile()
				countCurrent += 1
				prog_totalprogress.value = ((( countCurrent / countTotal as float) * 100))
			)
			if chk_vrmeshPartsFile.checked then
			(
				errorcount += FN_Publish_vrmeshPartsFile()
				countCurrent += 1
				prog_totalprogress.value = ((( countCurrent / countTotal as float) * 100))
			)
			if chk_AnimationFile.checked then
			(
				errorcount += FN_Publish_AnimationFile()
				countCurrent += 1
				prog_totalprogress.value = ((( countCurrent / countTotal as float) * 100))
			)
			-- report the results of the publishing operations
			FN_ReportEnd errorcount timestart
			if errorcount > 0 then(ASSET_PublishFunctions.LOGopen()) else(destroydialog ASSET_PublishCenterRollout)
			FN_Callback_SelectionChange() -- call this callback function to update the AssetSwitch UI to populate newly published assets
		)
		
		on btn_copyAssetDir pressed do
		(
			setclipboardtext assetDir
			messagebox assetDir beep:false
		)
		
		on btn_openAssetDir pressed do
		(
			shelllaunch assetDir "explorer.exe"
		)
		
		on btn_logOpen pressed do
		(
			ASSET_PublishFunctions.LOGopen()
		)
	)
	createDialog ASSET_PublishCenterRollout 380 510 --modal:true -- added a fixed size for this dialog
)

FN_PublishCenter()