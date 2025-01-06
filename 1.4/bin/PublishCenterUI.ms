--*****************************************************
--Aaron Dabelow, theonlyaaron@gmail.com
--*****************************************************
-- HISTORY:
--- version 1.0 : 08.05.2014  	>> Created by Aaron Dabelow
--- version 1.1 : 08.05.2014  	>> Improved Publish settings
--- version 1.4 : 01.16.2015  	>> Naming version of objects now made easier
--					 >> Save globalNode properties, if present
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

	-- Max File Options Rollout
	fn maxfile =
	(
		rollout ASSET_Options_MaxFile  "Publish Center Options" width:350 height:90
		(
			groupbox grp "3DS Max File Options" width:(ASSET_Options_MaxFile.width - 25) height:(ASSET_Options_MaxFile.height - 40)
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

	-- Max Optimized File Options Rollout
	fn maxoptimizedfile =
	(
		rollout ASSET_Options_MaxOptimizedFile  "Publish Center Options" width:350 height:120
		(
			groupbox grp "Optimzed 3DS Max File Options" width:(ASSET_Options_MaxOptimizedFile.width - 25) height:(ASSET_Options_MaxOptimizedFile.height - 40)
				checkbox chk_attachAll "attach all elements" pos:[25,25]
				radiobuttons radio_type labels:#("vertex %","vertex count") columns:1 align:#left offset:[10,0]
				spinner spinner_Percent "" align:#left width:60 range:[10.0,100.0,30.0] offset:[100,-35] type:#float
				spinner spinner_Count "" align:#left width:60 range:[3,10000,1000] offset:[100,-5] type:#integer
				
			button buttonOK "OK" pos:[(ASSET_Options_MaxOptimizedFile.width - 92),(ASSET_Options_MaxOptimizedFile.height - 30)]
			button buttonCancel "Cancel" align:#right offset:[0,-26]

			on ASSET_Options_MaxOptimizedFile open do
			(
				try( chk_attachAll.checked = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "MaxOptimizedFile" "AttachAllElements" )) )catch()
				try( radio_type.state = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "MaxOptimizedFile" "VertexCapType" )) )catch()
				try( spinner_Percent.value = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "MaxOptimizedFile" "VertexCapPercent" )) )catch()
				try( spinner_Count.value = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "MaxOptimizedFile" "VertexCapCount" )) )catch()
			)
			
			on buttonOK pressed do
			(
				setinisetting (ASSET_PublishFunctions.INIget()) "MaxOptimizedFile" "AttachAllElements" (chk_attachAll.checked as string)
				setinisetting (ASSET_PublishFunctions.INIget()) "MaxOptimizedFile" "VertexCapType" (radio_type.state as string)
				setinisetting (ASSET_PublishFunctions.INIget()) "MaxOptimizedFile" "VertexCapPercent" (spinner_Percent.value as string)
				setinisetting (ASSET_PublishFunctions.INIget()) "MaxOptimizedFile" "VertexCapCount" (spinner_Count.value as string)
				destroydialog ASSET_Options_MaxOptimizedFile
			)
			on buttonCancel pressed do( destroydialog ASSET_Options_MaxOptimizedFile )
		)
		createDialog ASSET_Options_MaxOptimizedFile
	),
	
	-- Material File Options Rollout
	fn materialfile =
	(
		rollout ASSET_Options_MaterialFile  "Publish Center Options" width:350 height:85
		(
			groupbox grp "Material File Options" width:(ASSET_Options_MaterialFile.width - 25) height:(ASSET_Options_MaterialFile.height - 40)
				label lab_nope "No options available to configure." pos:[25,25]
			button buttonOK "OK" pos:[(ASSET_Options_MaterialFile.width - 92),(ASSET_Options_MaterialFile.height - 30)]
			button buttonCancel "Cancel" align:#right offset:[0,-26]
				
			on buttonOK pressed do( destroydialog ASSET_Options_MaterialFile )
			on buttonCancel pressed do( destroydialog ASSET_Options_MaterialFile )
		)
		createDialog ASSET_Options_MaterialFile
	),

	-- VRMESH File Options Rollout
	fn vrmeshfile =
	(
		rollout ASSET_Options_vrmeshFile  "Publish Center Options" width:350 height:105
		(
			groupbox grp "VRMESH File Options" width:(ASSET_Options_vrmeshFile.width - 25) height:(ASSET_Options_vrmeshFile.height - 40)
				checkbox chk_exportAnimation "Export Animation" pos:[25,25]
				spinner spn_from "from" range:[-9999,9999,((animationrange.start / TicksPerFrame ) as integer )] type:#integer width:70 align:#left offset:[150,-19]
				spinner spn_to "to" range:[-9999,9999,((animationrange.end / TicksPerFrame ) as integer )] type:#integer width:70 align:#left offset:[240,-20]
				
				spinner spn_facecount "Number of faces in preview mesh: " align:#left range:[1,50000,1000] type:#integer offset:[15,0] width:105
				
			button buttonOK "OK" pos:[(ASSET_Options_vrmeshFile.width - 92),(ASSET_Options_vrmeshFile.height - 30)]
			button buttonCancel "Cancel" align:#right offset:[0,-26]
				
			on spn_from changed state do (if state >= spn_to.value then (spn_to.value = state)else())
			on spn_to changed state do (if state <= spn_from.value then (spn_from.value = state)else())
			
			on ASSET_Options_vrmeshFile open do
			(
				try( chk_exportAnimation.checked = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "vrmeshFile" "ExportAnimation" )) )catch()
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
					
				ASSET_PublishCenterRollout.FN_UpdateFrameRange ASSET_PublishCenterRollout.lab_vrmeshAnimFrames "vrmeshFile"
			)
			on buttonCancel pressed do( destroydialog ASSET_Options_vrmeshFile )
		)
		createDialog ASSET_Options_vrmeshFile
	),

	-- VRMESH as Max File Options Rollout
	fn vrmeshasmaxfile =
	(
		rollout ASSET_Options_vrmeshAsMaxFile  "Publish Center Options" width:350 height:105
		(
			groupbox grp "VRMESH as 3dsMax File Options" width:(ASSET_Options_vrmeshAsMaxFile.width - 25) height:(ASSET_Options_vrmeshAsMaxFile.height - 40)
				checkbox chk_exportAnimation "Export Animation" pos:[25,25]
				spinner spn_from "from" range:[-9999,9999,((animationrange.start / TicksPerFrame ) as integer )] type:#integer width:70 align:#left offset:[150,-19]
				spinner spn_to "to" range:[-9999,9999,((animationrange.end / TicksPerFrame ) as integer )] type:#integer width:70 align:#left offset:[240,-20]
				
				spinner spn_facecount "Number of faces in preview mesh: " align:#left range:[1,50000,1000] type:#integer offset:[15,0] width:105
				
			button buttonOK "OK" pos:[(ASSET_Options_vrmeshAsMaxFile.width - 92),(ASSET_Options_vrmeshAsMaxFile.height - 30)]
			button buttonCancel "Cancel" align:#right offset:[0,-26]
				
			on spn_from changed state do (if state >= spn_to.value then (spn_to.value = state)else())
			on spn_to changed state do (if state <= spn_from.value then (spn_from.value = state)else())
			
			on ASSET_Options_vrmeshAsMaxFile open do
			(
				try( chk_exportAnimation.checked = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "vrmeshAsMaxFile" "ExportAnimation" )) )catch()
				try( spn_from.value = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "vrmeshAsMaxFile" "FrameStart" )) )catch()
				try( spn_to.value = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "vrmeshAsMaxFile" "FrameEnd" )) )catch()
				try( spn_facecount.value = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "vrmeshAsMaxFile" "Facecount" )) )catch()
			)
				
			on buttonOK pressed do
			(
				setinisetting (ASSET_PublishFunctions.INIget()) "vrmeshAsMaxFile" "ExportAnimation" (chk_exportAnimation.checked as string)
				setinisetting (ASSET_PublishFunctions.INIget()) "vrmeshAsMaxFile" "FrameStart" (spn_from.value as string)
				setinisetting (ASSET_PublishFunctions.INIget()) "vrmeshAsMaxFile" "FrameEnd" (spn_to.value as string)
				setinisetting (ASSET_PublishFunctions.INIget()) "vrmeshAsMaxFile" "Facecount" (spn_facecount.value as string)	
				destroydialog ASSET_Options_vrmeshAsMaxFile
					
				ASSET_PublishCenterRollout.FN_UpdateFrameRange ASSET_PublishCenterRollout.lab_vrmeshAsMaxAnimFrames "vrmeshAsMaxFile"
			)
			on buttonCancel pressed do( destroydialog ASSET_Options_vrmeshAsMaxFile )
		)
		createDialog ASSET_Options_vrmeshAsMaxFile
	),

	-- xmesh File Options Rollout
	fn xmeshfile =
	(
		rollout ASSET_Options_xmeshFile  "Publish Center Options" width:350 height:115
		(
			groupbox grp "XMESH File" width:(ASSET_Options_xmeshFile.width - 25) height:(ASSET_Options_xmeshFile.height - 40)
				checkbox chk_exportAnimation "Export Animation" pos:[25,25]
				spinner spn_from "from" range:[-9999,9999,((animationrange.start / TicksPerFrame ) as integer )] type:#integer width:70 align:#left offset:[150,-19]
				spinner spn_to "to" range:[-9999,9999,((animationrange.end / TicksPerFrame ) as integer )] type:#integer width:70 align:#left offset:[240,-20]
				dropdownlist ddl_samples align:#left offset:[11,0] width:(ASSET_Options_xmeshFile.width - 43) items:#("1 sample per frame","2 sample per frame","4 sample per frame","5 samples per frame","8 samples per frame","10 samples per frame")
				
			button buttonOK "OK" pos:[(ASSET_Options_xmeshFile.width - 92),(ASSET_Options_xmeshFile.height - 30)]
			button buttonCancel "Cancel" align:#right offset:[0,-26]
				
			on spn_from changed state do (if state >= spn_to.value then (spn_to.value = state)else())
			on spn_to changed state do (if state <= spn_from.value then (spn_from.value = state)else())
			
			on ASSET_Options_xmeshFile open do
			(
				try( chk_exportAnimation.checked = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "xmeshFile" "ExportAnimation" )) )catch()
				try( spn_from.value = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "xmeshFile" "FrameStart" )) )catch()
				try( spn_to.value = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "xmeshFile" "FrameEnd" )) )catch()
				try( ddl_samples.selection = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "xmeshFile" "SampleMode" )) )catch()
			)
				
			on buttonOK pressed do
			(
				setinisetting (ASSET_PublishFunctions.INIget()) "xmeshFile" "ExportAnimation" (chk_exportAnimation.checked as string)
				setinisetting (ASSET_PublishFunctions.INIget()) "xmeshFile" "FrameStart" (spn_from.value as string)
				setinisetting (ASSET_PublishFunctions.INIget()) "xmeshFile" "FrameEnd" (spn_to.value as string)
				setinisetting (ASSET_PublishFunctions.INIget()) "xmeshFile" "SampleMode" (ddl_samples.selection as string)	
				destroydialog ASSET_Options_xmeshFile
					
				ASSET_PublishCenterRollout.FN_UpdateFrameRange ASSET_PublishCenterRollout.lab_xmeshAnimFrames "xmeshFile"
			)
			on buttonCancel pressed do( destroydialog ASSET_Options_xmeshFile )
		)
		createDialog ASSET_Options_xmeshFile
	),

	-- xmesh as Max File Options Rollout
	fn xmeshasmaxfile =
	(
		rollout ASSET_Options_xmeshAsMaxFile  "Publish Center Options" width:350 height:115
		(
			groupbox grp "XMESH as 3dsMax File" width:(ASSET_Options_xmeshAsMaxFile.width - 25) height:(ASSET_Options_xmeshAsMaxFile.height - 40)
				checkbox chk_exportAnimation "Export Animation" pos:[25,25]
				spinner spn_from "from" range:[-9999,9999,((animationrange.start / TicksPerFrame ) as integer )] type:#integer width:70 align:#left offset:[150,-19]
				spinner spn_to "to" range:[-9999,9999,((animationrange.end / TicksPerFrame ) as integer )] type:#integer width:70 align:#left offset:[240,-20]
				dropdownlist ddl_samples align:#left offset:[11,0] width:(ASSET_Options_xmeshAsMaxFile.width - 43) items:#("1 sample per frame","2 sample per frame","4 sample per frame","5 samples per frame","8 samples per frame","10 samples per frame")
				
			button buttonOK "OK" pos:[(ASSET_Options_xmeshAsMaxFile.width - 92),(ASSET_Options_xmeshAsMaxFile.height - 30)]
			button buttonCancel "Cancel" align:#right offset:[0,-26]
				
			on spn_from changed state do (if state >= spn_to.value then (spn_to.value = state)else())
			on spn_to changed state do (if state <= spn_from.value then (spn_from.value = state)else())
			
				on ASSET_Options_xmeshAsMaxFile open do
			(
				try( chk_exportAnimation.checked = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "xmeshAsMaxFile" "ExportAnimation" )) )catch()
				try( spn_from.value = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "xmeshAsMaxFile" "FrameStart" )) )catch()
				try( spn_to.value = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "xmeshAsMaxFile" "FrameEnd" )) )catch()
				try( ddl_samples.selection = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "xmeshAsMaxFile" "SampleMode" )) )catch()
			)
				
			on buttonOK pressed do
			(
				setinisetting (ASSET_PublishFunctions.INIget()) "xmeshAsMaxFile" "ExportAnimation" (chk_exportAnimation.checked as string)
				setinisetting (ASSET_PublishFunctions.INIget()) "xmeshAsMaxFile" "FrameStart" (spn_from.value as string)
				setinisetting (ASSET_PublishFunctions.INIget()) "xmeshAsMaxFile" "FrameEnd" (spn_to.value as string)
				setinisetting (ASSET_PublishFunctions.INIget()) "xmeshAsMaxFile" "SampleMode" (ddl_samples.selection as string)	
				destroydialog ASSET_Options_xmeshAsMaxFile
					
				ASSET_PublishCenterRollout.FN_UpdateFrameRange ASSET_PublishCenterRollout.lab_xmeshAsMaxAnimFrames "xmeshAsMaxFile"
			)
			on buttonCancel pressed do( destroydialog ASSET_Options_xmeshAsMaxFile )
		)
		createDialog ASSET_Options_xmeshAsMaxFile
	),

		-- Point Cache File Options Rollout
	fn pointcachefile =
	(
		rollout ASSET_Options_PointCacheFile  "Publish Center Options" width:350 height:115
		(
			groupbox grp "Point Cache File" width:(ASSET_Options_PointCacheFile.width - 25) height:(ASSET_Options_PointCacheFile.height - 40)
				checkbox chk_exportAnimation "Export Animation" pos:[25,25]
				spinner spn_from "from" range:[-9999,9999,((animationrange.start / TicksPerFrame ) as integer )] type:#integer width:70 align:#left offset:[150,-19]
				spinner spn_to "to" range:[-9999,9999,((animationrange.end / TicksPerFrame ) as integer )] type:#integer width:70 align:#left offset:[240,-20]
				dropdownlist ddl_samples align:#left offset:[11,0] width:(ASSET_Options_PointCacheFile.width - 43) items:#("Autodesk Cache (.xml)","Point Cache 2 (.pc2)")
				
			button buttonOK "OK" pos:[(ASSET_Options_PointCacheFile.width - 92),(ASSET_Options_PointCacheFile.height - 30)]
			button buttonCancel "Cancel" align:#right offset:[0,-26]
				
			on spn_from changed state do (if state >= spn_to.value then (spn_to.value = state)else())
			on spn_to changed state do (if state <= spn_from.value then (spn_from.value = state)else())

			on ASSET_Options_PointCacheFile open do
			(
				try( chk_exportAnimation.checked = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "PointCacheFile" "ExportAnimation" )) )catch()
				try( spn_from.value = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "PointCacheFile" "FrameStart" )) )catch()
				try( spn_to.value = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "PointCacheFile" "FrameEnd" )) )catch()
				try( ddl_samples.selection = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "PointCacheFile" "SampleMode" )) )catch()
			)
				
			on buttonOK pressed do
			(
				setinisetting (ASSET_PublishFunctions.INIget()) "PointCacheFile" "ExportAnimation" (chk_exportAnimation.checked as string)
				setinisetting (ASSET_PublishFunctions.INIget()) "PointCacheFile" "FrameStart" (spn_from.value as string)
				setinisetting (ASSET_PublishFunctions.INIget()) "PointCacheFile" "FrameEnd" (spn_to.value as string)
				setinisetting (ASSET_PublishFunctions.INIget()) "PointCacheFile" "SampleMode" (ddl_samples.selection as string)	
				destroydialog ASSET_Options_PointCacheFile
					
				ASSET_PublishCenterRollout.FN_UpdateFrameRange ASSET_PublishCenterRollout.lab_PointCacheFileAnimFrames "PointCacheFile"
			)
			on buttonCancel pressed do( destroydialog ASSET_Options_PointCacheFile )
		)
		createDialog ASSET_Options_PointCacheFile
	),

	-- Point Cache as Max File Options Rollout
	fn pointcacheasmaxfile =
	(
		rollout ASSET_Options_PointCacheAsMaxFile  "Publish Center Options" width:350 height:115
		(
			groupbox grp "Point Cache as 3dsMax File" width:(ASSET_Options_PointCacheAsMaxFile.width - 25) height:(ASSET_Options_PointCacheAsMaxFile.height - 40)
				checkbox chk_exportAnimation "Export Animation" pos:[25,25]
				spinner spn_from "from" range:[-9999,9999,((animationrange.start / TicksPerFrame ) as integer )] type:#integer width:70 align:#left offset:[150,-19]
				spinner spn_to "to" range:[-9999,9999,((animationrange.end / TicksPerFrame ) as integer )] type:#integer width:70 align:#left offset:[240,-20]
				dropdownlist ddl_samples align:#left offset:[11,0] width:(ASSET_Options_PointCacheAsMaxFile.width - 43) items:#("Autodesk Cache (.xml)","Point Cache 2 (.pc2)")
				
			button buttonOK "OK" pos:[(ASSET_Options_PointCacheAsMaxFile.width - 92),(ASSET_Options_PointCacheAsMaxFile.height - 30)]
			button buttonCancel "Cancel" align:#right offset:[0,-26]
				
			on spn_from changed state do (if state >= spn_to.value then (spn_to.value = state)else())
			on spn_to changed state do (if state <= spn_from.value then (spn_from.value = state)else())
			
				on ASSET_Options_PointCacheAsMaxFile open do
			(
				try( chk_exportAnimation.checked = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "PointCacheAsMaxFile" "ExportAnimation" )) )catch()
				try( spn_from.value = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "PointCacheAsMaxFile" "FrameStart" )) )catch()
				try( spn_to.value = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "PointCacheAsMaxFile" "FrameEnd" )) )catch()
				try( ddl_samples.selection = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "PointCacheAsMaxFile" "SampleMode" )) )catch()
			)
				
			on buttonOK pressed do
			(
				setinisetting (ASSET_PublishFunctions.INIget()) "PointCacheAsMaxFile" "ExportAnimation" (chk_exportAnimation.checked as string)
				setinisetting (ASSET_PublishFunctions.INIget()) "PointCacheAsMaxFile" "FrameStart" (spn_from.value as string)
				setinisetting (ASSET_PublishFunctions.INIget()) "PointCacheAsMaxFile" "FrameEnd" (spn_to.value as string)
				setinisetting (ASSET_PublishFunctions.INIget()) "PointCacheAsMaxFile" "SampleMode" (ddl_samples.selection as string)	
				destroydialog ASSET_Options_PointCacheAsMaxFile
					
				ASSET_PublishCenterRollout.FN_UpdateFrameRange ASSET_PublishCenterRollout.lab_PointCacheAsMaxFileAnimFrames "PointCacheAsMaxFile"
			)
			on buttonCancel pressed do( destroydialog ASSET_Options_PointCacheAsMaxFile )
		)
		createDialog ASSET_Options_PointCacheAsMaxFile
	),

		-- Save Animation Options Rollout
	fn saveanimationfile =
	(
		rollout ASSET_Options_SaveAnimationFile  "Publish Center Options" width:350 height:85
		(
			groupbox grp "Save Animation as File" width:(ASSET_Options_SaveAnimationFile.width - 25) height:(ASSET_Options_SaveAnimationFile.height - 40)
				label lab_nope "No options available to configure." pos:[25,25]
				button buttonOK "OK" pos:[(ASSET_Options_SaveAnimationFile.width - 92),(ASSET_Options_SaveAnimationFile.height - 30)]
				button buttonCancel "Cancel" align:#right offset:[0,-26]
					
				on spn_from changed state do (if state >= spn_to.value then (spn_to.value = state)else())
				on spn_to changed state do (if state <= spn_from.value then (spn_from.value = state)else())
				
				on buttonOK pressed do (destroydialog ASSET_Options_SaveAnimationFile)
				on buttonCancel pressed do( destroydialog ASSET_Options_SaveAnimationFile )
		)
		createDialog ASSET_Options_SaveAnimationFile
	)
)

-- Function that calls the publish center, and its constituents
function FN_PublishCenter = -- asset: the current asset definition
(	
	
	-- The main rollout
	rollout	ASSET_PublishCenterRollout "Publish Center 1.4" width:380 height:960
	(
		label lab_AssetName assetName

		groupbox grp_PrefixGang "Class Name" width:(ASSET_PublishCenterRollout.width - 15) align:#left offset:[-5,0] height:65
			dropdownlist  ddl_className items:#("Error loading presets") width:(ASSET_PublishCenterRollout.width - 80) align:#left offset:[-1,(grp_PrefixGang.height * -1 + 10)]
			button btn_PrefixGang_Preset "Presets" align:#left offset:[(ASSET_PublishCenterRollout.width - 80),-28]
			edittext edt_PrefixGang_Custom text:"Layout" width:(ASSET_PublishCenterRollout.width - 25) align:#left offset:[-3,0] enabled:true
		
		groupbox grp_MaxFile "" width:(ASSET_PublishCenterRollout.width - 15) align:#left offset:[-5,15] height:65
			checkbox chk_MaxFile "3ds Max File" align:#left offset:[0,((grp_MaxFile.height * -1) - 5)] checked:true --enabled:false
				dropdownlist ddl_MaxFile_Name "" items:#("name","none") width:60 align:#left offset:[-1,0]
				edittext edt_MaxFile_Prefex "" text: "ver" width:60 align:#left offset:[55,-25]
				spinner spinner_MaxFile_Number "" range:[1,999,1] type:#integer width:40 align:#left offset:[114,-21]
				button button_MaxFile_Options "Options" offset:[0,-25] align:#right
				label lab_MaxFile " error" style_sunkenedge:true height:16 width:(ASSET_PublishCenterRollout.width - 25) align:#left offset:[0,0]
		
		groupbox grp_MaxOptimizedFile "" width:(ASSET_PublishCenterRollout.width - 15) align:#left offset:[-5,5] height:65
			checkbox chk_MaxOptimizedFile "Optimized 3ds Max File" align:#left offset:[0,((grp_MaxOptimizedFile.height * -1) - 5)] -- enabled:false
				dropdownlist ddl_MaxOptimizedFile_Name "" items:#("name","none") width:60 align:#left offset:[-1,0]
				edittext edt_MaxOptimizedFile_Prefex "" text: "ver" width:60 align:#left offset:[55,-25]
				spinner spinner_MaxOptimizedFile_Number "" range:[1,999,1] type:#integer width:40 align:#left offset:[114,-21]
				button button_MaxOptimizedFile_Options "Options" offset:[0,-25] align:#right
				label lab_MaxOptimizedFile " error" style_sunkenedge:true height:16 width:(ASSET_PublishCenterRollout.width - 25) align:#left offset:[0,0]
			
		groupbox grp_MaterialFile "" width:(ASSET_PublishCenterRollout.width - 15) align:#left offset:[-5,5] height:65
			checkbox chk_MaterialFile "Material" align:#left offset:[0,((grp_MaterialFile.height * -1) - 5)] -- enabled:false
				dropdownlist ddl_MaterialFile_Name "" items:#("name","none") width:60 align:#left offset:[-1,0]
				edittext edt_MaterialFile_Prefex "" text: "ver" width:60 align:#left offset:[55,-25]
				spinner spinner_MaterialFile_Number "" range:[1,999,1] type:#integer width:40 align:#left offset:[114,-21]
				button button_MaterialFile_Options "Options" offset:[0,-25] align:#right
				label lab_MaterialFile " error" style_sunkenedge:true height:16 width:(ASSET_PublishCenterRollout.width - 25) align:#left offset:[0,0]
		
		groupbox grp_vrmeshFile "" width:(ASSET_PublishCenterRollout.width - 15) align:#left offset:[-5,5] height:65
			checkbox chk_vrmeshFile ".vrmesh" align:#left offset:[0,((grp_vrmeshFile.height * -1) - 5)] -- enabled:false
				dropdownlist ddl_vrmeshFile_Name "" items:#("name","none") width:60 align:#left offset:[-1,0]
				edittext edt_vrmeshFile_Prefex "" text: "ver" width:60 align:#left offset:[55,-25]
				spinner spinner_vrmeshFile_Number "" range:[1,999,1] type:#integer width:40 align:#left offset:[114,-21]
				button button_vrmeshFile_Options "Options" offset:[0,-25] align:#right
				label lab_vrmeshAnimFrames "frames:0" enabled:false align:#left offset:[180,-20]
				button button_vrmeshFileRefresh "R" align:#left offset:[160,-21] width:18 height:18
				label lab_vrmeshFile " error" style_sunkenedge:true height:16 width:(ASSET_PublishCenterRollout.width - 25) align:#left offset:[0,0]
		
		groupbox grp_vrmeshAsMaxFile "" width:(ASSET_PublishCenterRollout.width - 15) align:#left offset:[-5,5] height:65
			checkbox chk_vrmeshAsMaxFile ".vrmesh as Max File" align:#left offset:[0,((grp_vrmeshAsMaxFile.height * -1) - 5)] -- enabled:false
				dropdownlist ddl_vrmeshAsMaxFile_Name "" items:#("name","none") width:60 align:#left offset:[-1,0]
				edittext edt_vrmeshAsMaxFile_Prefex "" text: "ver" width:60 align:#left offset:[55,-25]
				spinner spinner_vrmeshAsMaxFile_Number "" range:[1,999,1] type:#integer width:40 align:#left offset:[114,-21]
				button button_vrmeshAsMaxFile_Options "Options" offset:[0,-25] align:#right
				label lab_vrmeshAsMaxAnimFrames "frames:0" enabled:false align:#left offset:[180,-20]
				button button_vrmeshAsMaxFileRefresh "R" align:#left offset:[160,-21] width:18 height:18
				label lab_vrmeshAsMaxFile " error" style_sunkenedge:true height:16 width:(ASSET_PublishCenterRollout.width - 25) align:#left offset:[0,0]
		
		groupbox grp_xmeshFile "" width:(ASSET_PublishCenterRollout.width - 15) align:#left offset:[-5,5] height:65
			checkbox chk_xmeshFile ".xmesh" align:#left offset:[0,((grp_xmeshFile.height * -1) - 5)] -- enabled:false
				dropdownlist ddl_xmeshFile_Name "" items:#("name","none") width:60 align:#left offset:[-1,0]
				edittext edt_xmeshFile_Prefex "" text: "ver" width:60 align:#left offset:[55,-25]
				spinner spinner_xmeshFile_Number "" range:[1,999,1] type:#integer width:40 align:#left offset:[114,-21]
				button button_xmeshFile_Options "Options" offset:[0,-25] align:#right
				label lab_xmeshAnimFrames "frames:0" enabled:false align:#left offset:[180,-20]
				button button_xmeshFileRefresh "R" align:#left offset:[160,-21] width:18 height:18
				label lab_xmeshFile " error" style_sunkenedge:true height:16 width:(ASSET_PublishCenterRollout.width - 25) align:#left offset:[0,0]
		
		groupbox grp_xmeshAsMaxFile "" width:(ASSET_PublishCenterRollout.width - 15) align:#left offset:[-5,5] height:65
			checkbox chk_xmeshAsMaxFile ".xmesh as Max File" align:#left offset:[0,((grp_xmeshAsMaxFile.height * -1) - 5)] -- enabled:false
				dropdownlist ddl_xmeshAsMaxFile_Name "" items:#("name","none") width:60 align:#left offset:[-1,0]
				edittext edt_xmeshAsMaxFile_Prefex "" text: "ver" width:60 align:#left offset:[55,-25]
				spinner spinner_xmeshAsMaxFile_Number "" range:[1,999,1] type:#integer width:40 align:#left offset:[114,-21]
				button button_xmeshAsMaxFile_Options "Options" offset:[0,-25] align:#right
				label lab_xmeshAsMaxAnimFrames "frames:0" enabled:false align:#left offset:[180,-20]
				button button_xmeshAsMaxFileRefresh "R" align:#left offset:[160,-21] width:18 height:18
				label lab_xmeshAsMaxFile " error" style_sunkenedge:true height:16 width:(ASSET_PublishCenterRollout.width - 25) align:#left offset:[0,0]
		
		groupbox grp_PointCacheFile "" width:(ASSET_PublishCenterRollout.width - 15) align:#left offset:[-5,5] height:65
			checkbox chk_PointCacheFile "Point Cache" align:#left offset:[0,((grp_PointCacheFile.height * -1) - 5)] enabled:false
				dropdownlist ddl_PointCacheFile_Name "" items:#("name","none") width:60 align:#left offset:[-1,0]
				edittext edt_PointCacheFile_Prefex "" text: "ver" width:60 align:#left offset:[55,-25]
				spinner spinner_PointCacheFile_Number "" range:[1,999,1] type:#integer width:40 align:#left offset:[114,-21]
				button button_PointCacheFile_Options "Options" offset:[0,-25] align:#right
				label lab_PointCacheFileAnimFrames "frames:0" enabled:false align:#left offset:[180,-20]
				button button_PointCacheFileRefresh "R" align:#left offset:[160,-21] width:18 height:18
				label lab_PointCacheFile " error" style_sunkenedge:true height:16 width:(ASSET_PublishCenterRollout.width - 25) align:#left offset:[0,0]
		
		groupbox grp_PointCacheAsMaxFile "" width:(ASSET_PublishCenterRollout.width - 15) align:#left offset:[-5,5] height:65
			checkbox chk_PointCacheAsMaxFile "Point Cache as Max File" align:#left offset:[0,((grp_PointCacheAsMaxFile.height * -1) - 5)] enabled:false
				dropdownlist ddl_PointCacheAsMaxFile_Name "" items:#("name","none") width:60 align:#left offset:[-1,0]
				edittext edt_PointCacheAsMaxFile_Prefex "" text: "ver" width:60 align:#left offset:[55,-25]
				spinner spinner_PointCacheAsMaxFile_Number "" range:[1,999,1] type:#integer width:40 align:#left offset:[114,-21]
				button button_PointCacheAsMaxFile_Options "Options" offset:[0,-25] align:#right
				label lab_PointCacheAsMaxFileAnimFrames "frames:0" enabled:false align:#left offset:[180,-20]
				button button_PointCacheAsMaxFileRefresh "R" align:#left offset:[160,-21] width:18 height:18
				label lab_PointCacheAsMaxFile " error" style_sunkenedge:true height:16 width:(ASSET_PublishCenterRollout.width - 25) align:#left offset:[0,0]
			
		groupbox grp_SaveAnimationFile "" width:(ASSET_PublishCenterRollout.width - 15) align:#left offset:[-5,5] height:65
			checkbox chk_SaveAnimationFile "Save Animation" align:#left offset:[0,((grp_SaveAnimationFile.height * -1) - 5)] enabled:false
				dropdownlist ddl_SaveAnimationFile_Name "" items:#("name","none") width:60 align:#left offset:[-1,0]
				edittext edt_SaveAnimationFile_Prefex "" text: "ver" width:60 align:#left offset:[55,-25]
				spinner spinner_SaveAnimationFile_Number "" range:[1,999,1] type:#integer width:40 align:#left offset:[114,-21]
				button button_SaveAnimationFile_Options "Options" offset:[0,-25] align:#right
				label lab_SaveAnimationFile " error" style_sunkenedge:true height:16 width:(ASSET_PublishCenterRollout.width - 25) align:#left offset:[0,0]
			
		groupbox grp_PublishAsset "Publish Asset" width:(ASSET_PublishCenterRollout.width - 15) align:#left offset:[-5,5] height:120
			label lab_PublishAssetDir  "" style_sunkenedge:true align:#left width:(ASSET_PublishCenterRollout.width - 68) height:16 offset:[0,((grp_PublishAsset.height * -1) + 10)]
				button btn_copyAssetDir "C" width:18 height:18 align:#left offset:[(ASSET_PublishCenterRollout.width - 65),-23]
				button btn_openAssetDir "..." width:18 height:18 align:#left offset:[(ASSET_PublishCenterRollout.width - 45),-23]
				button btn_PublishAsset " Publish Asset " height:40 width:(ASSET_PublishCenterRollout.width - 25)
				progressbar prog_totalprogress height:10 width:(ASSET_PublishCenterRollout.width - 25)
				label lab_Status " Status: ready" style_sunkenedge:true height:16 width:(ASSET_PublishCenterRollout.width - 65) align:#left
				button btn_logOpen "log" height:20 width:40 align:#left offset:[(ASSET_PublishCenterRollout.width - 65),-23]

	
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
				2: -- MaxOptimizedFile
				(
					curClassName = "MaxOptimized"
					curClassExtension = ".max"
				)
				3: -- MaterialFile
				(
					curClassName = "Material"
					curClassExtension = ".mat"
					
					comboString = (@"\" + curClassName + @"\" + curAssetName + nameVer + curClassExtension )
					target.text = comboString
			
					return comboString
					
				)
				4: -- vrmeshFile
				(
					curClassName = "Vrmesh"
					curClassExtension = ".vrmesh"
				)
				5: -- vrmeshAsMaxFile
				(
					curClassName = "VrmeshAsMax"
					curClassExtension = ".max"
				)
				6: -- xmeshFile
				(
					curClassName = "Xmesh"
					curClassExtension = ".xmesh"
					
					comboString = (@"\" + curClassName + @"\" + nameVer + @"\" + curAssetName + arg2 + "_" + curClassExtension )
					target.text = comboString
					
					return comboString
				)
				7: -- xmeshAsMaxFile
				(
					curClassName = "XmeshAsMax"
					curClassExtension = ".max"
				)
				8: -- PointCacheFile
				(
					curClassName = "PointCache"
					curClassExtension = ".xml" --???????????????????????????????
				)
				9: -- PointCacheAsMaxFile
				(
					curClassName = "PointCacheAsMax"
					curClassExtension = ".max"
				)
				10: -- PointCacheAsMaxFile
				(
					curClassName = "SaveAnimation"
					curClassExtension = ".xaf"
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
		function FN_RefreshFrameRange arg_iniKey arg_label = -- arg_iniKey: where to read out of the .ini file | arg_label: the label to update
		(
			startFrame = ((animationrange.start as integer / ticksperframe) as string)
			endFrame = ((animationrange.end as integer / ticksperframe) as string)
			
			setinisetting (ASSET_PublishFunctions.INIget()) arg_iniKey "ExportAnimation" "true"
			setinisetting (ASSET_PublishFunctions.INIget()) arg_iniKey "FrameStart" (startFrame as string)
			setinisetting (ASSET_PublishFunctions.INIget()) arg_iniKey "FrameEnd" (endFrame as string)
				
			arg_label.text = ("frames: " + startFrame + " to " + endFrame)
		)
		
		-- Function for reading and sorting the frame range for an asset publish, and updates the UI for it
		function FN_UpdateFrameRange arg_label arg_iniKey =  -- arg_label: the UI element to update |arg_iniKey: where to read out of the ini file
		(
			-- Get if animation is enabled
			if ( hasinisetting (ASSET_PublishFunctions.INIget()) arg_iniKey "ExportAnimation" )
			then
			(
				export_animation = ( execute ( getinisetting (ASSET_PublishFunctions.INIget()) arg_iniKey "ExportAnimation" ))
			)
			else
			(
				setinisetting (ASSET_PublishFunctions.INIget()) arg_iniKey "ExportAnimation" "false"
				export_animation = false
			)
			
			-- Set the approprite frame or frame range to the .ini and ui
			if export_animation
			then
			(
				startFrame = ( getinisetting (ASSET_PublishFunctions.INIget()) arg_iniKey "FrameStart" )
				endFrame = ( getinisetting (ASSET_PublishFunctions.INIget()) arg_iniKey "FrameEnd" )
				arg_label.text = ("frames: " + startFrame + " to " + endFrame)
			)
			else
			(
				curFrame = ((slidertime as integer / ticksperframe) as string)
				setinisetting (ASSET_PublishFunctions.INIget()) arg_iniKey "FrameStart" curFrame
				setinisetting (ASSET_PublishFunctions.INIget()) arg_iniKey "FrameEnd" curFrame
				arg_label.text = ("frames: " + curFrame + " to " + curFrame)
			)
		)
		
		-- Functions that update the filename and path for the desired asset class
		function FN_Update_3dsMaxFile =				(FN_UpdateLocalPath lab_MaxFile 1 ddl_MaxFile_Name.selection edt_MaxFile_Prefex.text spinner_MaxFile_Number.value)
		function FN_Update_MaxOptimizedFile =		(FN_UpdateLocalPath lab_MaxOptimizedFile 2 ddl_MaxOptimizedFile_Name.selection edt_MaxOptimizedFile_Prefex.text spinner_MaxOptimizedFile_Number.value)
		function FN_Update_MaterialFile =			(FN_UpdateLocalPath lab_MaterialFile 3 ddl_MaterialFile_Name.selection edt_MaterialFile_Prefex.text spinner_MaterialFile_Number.value)
		function FN_Update_vrmeshFile =				(FN_UpdateLocalPath lab_vrmeshFile 4 ddl_vrmeshFile_Name.selection edt_vrmeshFile_Prefex.text spinner_vrmeshFile_Number.value)
		function FN_Update_vrmeshAsMaxFile  =		(FN_UpdateLocalPath lab_vrmeshAsMaxFile 5 ddl_vrmeshAsMaxFile_Name.selection edt_vrmeshAsMaxFile_Prefex.text spinner_vrmeshAsMaxFile_Number.value)
		function FN_Update_xmeshFile =				(FN_UpdateLocalPath lab_xmeshFile 6 ddl_xmeshFile_Name.selection edt_xmeshFile_Prefex.text spinner_xmeshFile_Number.value)
		function FN_Update_xmeshAsMaxFile =			(FN_UpdateLocalPath lab_xmeshAsMaxFile 7 ddl_xmeshAsMaxFile_Name.selection edt_xmeshAsMaxFile_Prefex.text spinner_xmeshAsMaxFile_Number.value)
		function FN_Update_PointCacheFile =			(FN_UpdateLocalPath lab_PointCacheFile 8 ddl_PointCacheFile_Name.selection edt_PointCacheFile_Prefex.text spinner_PointCacheFile_Number.value)
		function FN_Update_PointCacheAsMaxFile =	(FN_UpdateLocalPath lab_PointCacheAsMaxFile 9 ddl_PointCacheAsMaxFile_Name.selection edt_PointCacheAsMaxFile_Prefex.text spinner_PointCacheAsMaxFile_Number.value)
		function FN_Update_SaveAnimationFile =		(FN_UpdateLocalPath lab_SaveAnimationFile 10 ddl_SaveAnimationFile_Name.selection edt_SaveAnimationFile_Prefex.text spinner_SaveAnimationFile_Number.value)
			
		function FN_ReportResult arg_result arg_timestart_minor = -- arg_result : the string returned from the publisher  | arg_timestart : the start time of the operation
		(
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": [   TASK RESULT   ] : " + arg_result )
			timeend_minor = timestamp()
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": [  TASK DURATION  ] : " + (((timeend_minor - arg_timestart_minor) * .001 ) as string) + " seconds")
			
			if arg_result == "Success!"	then (return 0) else (return 1)
		)
		
		function FN_RestoreFromHold =
		(
			print "---------------------------------------------- FETCH --------------------------------------------"
			fetchMaxFile quiet:true
			nodeAssetForPublish = (maxops.getnodebyhandle nodeAssetHandle)
			assetDir = ( getFilenamePath (getUserProp nodeAssetForPublish "asset_file"))
			assetName = (getfilenamefile  (getUserProp nodeAssetForPublish "asset_file"))

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
			local publish_filepath = ( assetDir + "\Publish" + (FN_Update_3dsMaxFile()))
			
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
		
		-- Publisher for the Optimized MaxOptimizedFile class
		function FN_Publish_MaxOptimizedFile =
		(
			local publish_filepath = ( assetDir + "\Publish" + (FN_Update_MaxOptimizedFile()))
			
			-- Prepare to publish
			timestart_minor = timestamp()
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": <<< Publishing Optimized 3dsMax File >>>")
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": [ ASSET DIRECTORY ] : " + publish_filepath )
			lab_Status.text = " Status: Publishing Optimized 3dsMax File"
			
			-- Call the publish function
			result = ASSET_PublishFunctions.pub_MaxOptimizedFile "asset" publish_filepath
				
			-- Restore the scene file
			FN_RestoreFromHold()
				
			-- Report result of the Publish
			FN_ReportResult result timestart_minor
		)
		
		-- Publisher for the MaterialFile class
		function FN_Publish_MaterialFile =
		(
			local publish_filepath = ( assetDir + "\Publish" + (FN_Update_MaterialFile()))
			
			-- Prepare to publish
			timestart_minor = timestamp()
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": <<< Publishing Material File >>>")
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": [ ASSET DIRECTORY ] : " + publish_filepath )
			lab_Status.text = " Status: Publishing Material File"
			
			-- Call the publish function
			result = ASSET_PublishFunctions.pub_MaterialFile "asset" publish_filepath
				
			-- Report result of the Publish
			FN_ReportResult result timestart_minor
		)
		
		-- Publisher for the vrmeshFile class
		function FN_Publish_vrmeshFile =
		(
			publish_filepath = ( assetDir + "\Publish" + (FN_Update_vrmeshFile()))
			
			-- Prepare to publish
			timestart_minor = timestamp()
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": <<< Publishing vrmesh File >>>")
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": [ ASSET DIRECTORY ] : " + publish_filepath)
			lab_Status.text = " Status: Publishing vrmesh File"
			
			-- Call the publish function
			result = ASSET_PublishFunctions.pub_vrmeshFile "asset" publish_filepath
				
			-- Restore the scene file
			FN_RestoreFromHold()
				
			-- Report result of the Publish
			FN_ReportResult result timestart_minor
		)
		
		-- Publisher for the vrmeshAsMaxFile class
		function FN_Publish_vrmeshAsMaxFile =
		(
			publish_filepath = ( assetDir + "\Publish" + (FN_Update_vrmeshAsMaxFile()))
			
			-- Prepare to publish
			timestart_minor = timestamp()
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": <<< Publishing vrmesh as Max File >>>")
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": [ ASSET DIRECTORY ] : " + publish_filepath)
			lab_Status.text = " Status: Publishing vrmesh as max File"
			
			-- Call the publish function
			result = ASSET_PublishFunctions.pub_vrmeshAsMaxFile "asset" publish_filepath
				
			-- Restore the scene file
			FN_RestoreFromHold()
				
			-- Report result of the Publish
			FN_ReportResult result timestart_minor
		)
		
		-- Publisher for the xmeshFile class
		function FN_Publish_xmeshFile =
		(
			publish_filepath = ( assetDir + "\Publish" + (FN_Update_xmeshFile()))
			
			-- Prepare to publish
			timestart_minor = timestamp()
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": <<< Publishing xmesh File >>>")
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": [ ASSET DIRECTORY ] : " + publish_filepath )
			lab_Status.text = " Status: Publishing xmesh File"
			
			-- Call the publish function
			result = ASSET_PublishFunctions.pub_xmeshFile "asset" publish_filepath "xmeshFile"
				
			-- Restore the scene file
			FN_RestoreFromHold()
				
			-- Report result of the Publish
			FN_ReportResult result timestart_minor
		)
		
		-- Publisher for the xmeshAsMaxFile class
		function FN_Publish_xmeshAsMaxFile =
		(
			publish_filepath = ( assetDir + "\Publish" + (FN_Update_xmeshAsMaxFile()))
			
			-- Prepare to publish
			timestart_minor = timestamp()
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": <<< Publishing xmesh as max File >>>")
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": [ ASSET DIRECTORY ] : " + publish_filepath )
			lab_Status.text = " Status: Publishing xmesh as max File"
			
			-- Call the publish function
			result = ASSET_PublishFunctions.pub_xmeshAsMaxFile "asset" publish_filepath "xmeshAsMaxFile"
				
			-- Restore the scene file
			FN_RestoreFromHold()
				
			-- Report result of the Publish
			FN_ReportResult result timestart_minor
		)
		
		-- Publisher for the PointCacheFile class
		function FN_Publish_PointCacheFile =
		(
			-- Prepare to publish
			timestart_minor = timestamp()
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": <<< Publishing Point Cache File >>>")
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": [ ASSET DIRECTORY ] : " + ( assetDir + "\Publish" + (FN_Update_PointCacheFile())))
			lab_Status.text = " Status: Publishing Point Cache File"
			
			-- Call the publish function
			result = ASSET_PublishFunctions.pub_PointCacheFile "asset" "path"
				
			-- Report result of the Publish
			FN_ReportResult result timestart_minor
		)
		
		-- Publisher for the PointCacheAsMaxFile class
		function FN_Publish_PointCacheAsMaxFile =
		(
			-- Prepare to publish
			timestart_minor = timestamp()
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": <<< Publishing 'Point Cache as max' File >>>")
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": [ ASSET DIRECTORY ] : " + ( assetDir + "\Publish" + (FN_Update_PointCacheAsMaxFile())))
			lab_Status.text = " Status: Publishing 'Point Cache as max' File"
			
			-- Call the publish function
			result = ASSET_PublishFunctions.pub_PointCacheAsMaxFile "asset" "path"
				
			-- Report result of the Publish
			FN_ReportResult result timestart_minor
		)
		
		-- Publisher for the SaveAnimationFile class
		function FN_Publish_SaveAnimationFile =
		(
			-- Prepare to publish
			timestart_minor = timestamp()
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": <<< Publishing 'Save Animation' File >>>")
			ASSET_PublishFunctions.LOGwrite (LocalTime + ": [ ASSET DIRECTORY ] : " + ( assetDir + "\Publish" + (FN_Update_SaveAnimationFile())))
			lab_Status.text = " Status: Publishing 'Save Animation' File"
			
			-- Call the publish function
			result = ASSET_PublishFunctions.pub_SaveAnimationFile "asset" "path"
				
			-- Report result of the Publish
			FN_ReportResult result timestart_minor
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
			
			-- Optimized 3dsMaxFile
			bool = chk_MaxOptimizedFile.checked
			lab_MaxOptimizedFile.enabled = bool
			spinner_MaxOptimizedFile_Number.enabled = bool
			edt_MaxOptimizedFile_Prefex.enabled = bool
			ddl_MaxOptimizedFile_Name.enabled = bool
			
			-- MaterialFile
			bool = chk_MaterialFile.checked
			lab_MaterialFile.enabled = bool
			spinner_MaterialFile_Number.enabled = bool
			edt_MaterialFile_Prefex.enabled = bool
			ddl_MaterialFile_Name.enabled = bool
			
			-- vrmeshFile
			bool = chk_vrmeshFile.checked
			lab_vrmeshFile.enabled = bool
			spinner_vrmeshFile_Number.enabled = bool
			edt_vrmeshFile_Prefex.enabled = bool
			ddl_vrmeshFile_Name.enabled = bool
			
			-- vrmeshAsMaxFile
			bool = chk_vrmeshAsMaxFile.checked
			lab_vrmeshAsMaxFile.enabled = bool
			spinner_vrmeshAsMaxFile_Number.enabled = bool
			edt_vrmeshAsMaxFile_Prefex.enabled = bool
			ddl_vrmeshAsMaxFile_Name.enabled = bool
			
			-- xmeshFile
			bool = chk_xmeshFile.checked
			lab_xmeshFile.enabled = bool
			spinner_xmeshFile_Number.enabled = bool
			edt_xmeshFile_Prefex.enabled = bool
			ddl_xmeshFile_Name.enabled = bool
			
			-- xmeshAsMaxFile
			bool = chk_xmeshAsMaxFile.checked
			lab_xmeshAsMaxFile.enabled = bool
			spinner_xmeshAsMaxFile_Number.enabled = bool
			edt_xmeshAsMaxFile_Prefex.enabled = bool
			ddl_xmeshAsMaxFile_Name.enabled = bool
			
			-- PointCacheFile
			bool = chk_PointCacheFile.checked
			lab_PointCacheFile.enabled = bool
			spinner_PointCacheFile_Number.enabled = bool
			edt_PointCacheFile_Prefex.enabled = bool
			ddl_PointCacheFile_Name.enabled = bool
			
			-- PointCacheAsMaxFile
			bool = chk_PointCacheAsMaxFile.checked
			lab_PointCacheAsMaxFile.enabled = bool
			spinner_PointCacheAsMaxFile_Number.enabled = bool
			edt_PointCacheAsMaxFile_Prefex.enabled = bool
			ddl_PointCacheAsMaxFile_Name.enabled = bool

			-- SaveAnimation
			bool = chk_SaveAnimationFile.checked
			lab_SaveAnimationFile.enabled = bool
			spinner_SaveAnimationFile_Number.enabled = bool
			edt_SaveAnimationFile_Prefex.enabled = bool
			ddl_SaveAnimationFile_Name.enabled = bool
		)
		
		function FN_CountEnabled =
		(
			count = 0
			if chk_MaxFile.checked then 			(count += 1)
			if chk_MaxOptimizedFile.checked then 	(count += 1)
			if chk_MaterialFile.checked then 		(count += 1)
			if chk_vrmeshFile.checked then 			(count += 1)
			if chk_vrmeshAsMaxFile.checked then 	(count += 1)
			if chk_xmeshFile.checked then 			(count += 1)
			if chk_xmeshAsMaxFile.checked then 		(count += 1)
			if chk_PointCacheFile.checked then 		(count += 1)
			if chk_PointCacheAsMaxFile.checked then (count += 1)
			if chk_SaveAnimationFile.checked then	(count += 1)
			
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
			FN_Update_MaxOptimizedFile()
			FN_Update_MaterialFile()
			FN_Update_vrmeshFile()
			FN_Update_vrmeshAsMaxFile()
			FN_Update_xmeshFile()
			FN_Update_xmeshAsMaxFile()
			FN_Update_PointCacheFile()
			FN_Update_PointCacheAsMaxFile()
			FN_Update_SaveAnimationFile()
		)

		-- Event Handlers

		on btn_PrefixGang_Preset pressed do
		(
			ASSET_PublishOptions.FN_classNamePreset_Dialog()
		)

		
		on ddl_className selected arg do
		(
			if arg != ddl_className.items.count 
			then
			(
-- 				edt_PrefixGang_Custom.enabled = false
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


		-- 3dsMaxFile
		on button_MaxFile_Options pressed do (ASSET_PublishOptions.maxfile())
		on chk_MaxFile changed state do 
		(
			setinisetting (ASSET_PublishFunctions.INIget()) "MaxFile" "OutputEnabled" (chk_MaxFile.checked as string)
			FN_CategoryToggle() 
		)
			on spinner_MaxFile_Number changed state do FN_Update_3dsMaxFile()
			on edt_MaxFile_Prefex changed state do FN_Update_3dsMaxFile()
			on ddl_MaxFile_Name selected state do FN_Update_3dsMaxFile()
			
		-- 3dsMaxOptimizedFile
 		on button_MaxOptimizedFile_Options pressed do (ASSET_PublishOptions.maxoptimizedfile())
		on chk_MaxOptimizedFile changed state do 
		(
			setinisetting (ASSET_PublishFunctions.INIget()) "MaxOptimizedFile" "OutputEnabled" (chk_MaxOptimizedFile.checked as string)
			FN_CategoryToggle() 
		)
			on spinner_MaxOptimizedFile_Number changed state do FN_Update_MaxOptimizedFile()
			on edt_MaxOptimizedFile_Prefex changed state do FN_Update_MaxOptimizedFile()
			on ddl_MaxOptimizedFile_Name selected state do FN_Update_MaxOptimizedFile()
		
		-- MaterialFile
		on button_MaterialFile_Options pressed do (ASSET_PublishOptions.materialfile())
		on chk_MaterialFile changed state do
		(
			setinisetting (ASSET_PublishFunctions.INIget()) "MaterialFile" "OutputEnabled" (chk_MaterialFile.checked as string)
			FN_CategoryToggle() 
		)
			on spinner_MaterialFile_Number changed state do FN_Update_MaterialFile()
			on edt_MaterialFile_Prefex changed state do FN_Update_MaterialFile() 
			on ddl_MaterialFile_Name selected state do FN_Update_MaterialFile()
		
		-- vrmeshFile
		on button_vrmeshFile_Options pressed do (ASSET_PublishOptions.vrmeshfile())
		on button_vrmeshFileRefresh pressed do (FN_RefreshFrameRange "vrmeshFile" lab_vrmeshAnimFrames)
		on chk_vrmeshFile changed state do
		(
			setinisetting (ASSET_PublishFunctions.INIget()) "vrmeshFile" "OutputEnabled" (chk_vrmeshFile.checked as string)
			FN_CategoryToggle() 
		)
			on spinner_vrmeshFile_Number changed state do FN_Update_vrmeshFile()
			on edt_vrmeshFile_Prefex changed state do FN_Update_vrmeshFile()
			on ddl_vrmeshFile_Name selected state do FN_Update_vrmeshFile()
			
		-- vrmeshAsMaxFile
		on button_vrmeshAsMaxFile_Options pressed do (ASSET_PublishOptions.vrmeshasmaxfile())
		on button_vrmeshAsMaxFileRefresh pressed do (FN_RefreshFrameRange "vrmeshAsMaxFile" lab_vrmeshAsMaxAnimFrames)
		on chk_vrmeshAsMaxFile changed state do
		(
			setinisetting (ASSET_PublishFunctions.INIget()) "vrmeshAsMaxFile" "OutputEnabled" (chk_vrmeshAsMaxFile.checked as string)
			FN_CategoryToggle() 
		)
			on spinner_vrmeshAsMaxFile_Number changed state do FN_Update_vrmeshAsMaxFile()
			on edt_vrmeshAsMaxFile_Prefex changed state do FN_Update_vrmeshAsMaxFile()
			on ddl_vrmeshAsMaxFile_Name selected state do FN_Update_vrmeshAsMaxFile()

		-- xmeshFile
		on button_xmeshFile_Options pressed do (ASSET_PublishOptions.xmeshfile())
		on button_xmeshFileRefresh pressed do (FN_RefreshFrameRange "xmeshFile" lab_xmeshAnimFrames)
		on chk_xmeshFile changed state do 
		(
			setinisetting (ASSET_PublishFunctions.INIget()) "xmeshFile" "OutputEnabled" (chk_xmeshFile.checked as string)
			FN_CategoryToggle() 
		)
			on spinner_xmeshFile_Number changed state do FN_Update_xmeshFile()
			on edt_xmeshFile_Prefex changed state do FN_Update_xmeshFile()
			on ddl_xmeshFile_Name selected state do FN_Update_xmeshFile()
			
		-- xmeshAsMaxFile
		on button_xmeshAsMaxFile_Options pressed do (ASSET_PublishOptions.xmeshasmaxfile())
		on button_xmeshAsMaxFileRefresh pressed do (FN_RefreshFrameRange "xmeshAsMaxFile" lab_xmeshAsMaxAnimFrames)
		on chk_xmeshAsMaxFile changed state do
		(
			setinisetting (ASSET_PublishFunctions.INIget()) "xmeshAsMaxFile" "OutputEnabled" (chk_xmeshAsMaxFile.checked as string)
			FN_CategoryToggle() 
		)
			on spinner_xmeshAsMaxFile_Number changed state do FN_Update_xmeshAsMaxFile()
			on edt_xmeshAsMaxFile_Prefex changed state do FN_Update_xmeshAsMaxFile()
			on ddl_xmeshAsMaxFile_Name selected state do FN_Update_xmeshAsMaxFile()
			
		-- PointCacheFile
		on button_PointCacheFile_Options pressed do (ASSET_PublishOptions.pointcachefile())
		on button_PointCacheFileRefresh pressed do (FN_RefreshFrameRange "PointCacheFile" lab_PointCacheFileAnimFrames)
		on chk_PointCacheFile changed state do
		(
			setinisetting (ASSET_PublishFunctions.INIget()) "PointCacheFile" "OutputEnabled" (chk_PointCacheFile.checked as string)
			FN_CategoryToggle() 
		)
			on spinner_PointCacheFile_Number changed state do FN_Update_PointCacheFile()
			on edt_PointCacheFile_Prefex changed state do FN_Update_PointCacheFile()
			on ddl_PointCacheFile_Name selected state do FN_Update_PointCacheFile()
			
		-- PointCacheAsMaxFile
		on button_PointCacheAsMaxFile_Options pressed do (ASSET_PublishOptions.pointcacheasmaxfile())
		on button_PointCacheAsMaxFileRefresh pressed do (FN_RefreshFrameRange "PointCacheAsMaxFile" lab_PointCacheAsMaxFileAnimFrames)
		on chk_PointCacheAsMaxFile changed state do	
		(
			setinisetting (ASSET_PublishFunctions.INIget()) "PointCacheAsMaxFile" "OutputEnabled" (chk_PointCacheAsMaxFile.checked as string)
			FN_CategoryToggle() 
		)
			on spinner_PointCacheAsMaxFile_Number changed state do FN_Update_PointCacheAsMaxFile()
			on edt_PointCacheAsMaxFile_Prefex changed state do FN_Update_PointCacheAsMaxFile()
			on ddl_PointCacheAsMaxFile_Name selected state do FN_Update_PointCacheAsMaxFile()

		-- SaveAnimationFile
		on button_SaveAnimationFile_Options pressed do (ASSET_PublishOptions.saveanimationfile())
		on chk_SaveAnimationFile changed state do
		(
			setinisetting (ASSET_PublishFunctions.INIget()) "SaveAnimationFile" "OutputEnabled" (chk_SaveAnimationFile.checked as string)
			FN_CategoryToggle() 
		)
			on spinner_SaveAnimationFile_Number changed state do FN_Update_SaveAnimationFile()
			on edt_SaveAnimationFile_Prefex changed state do FN_Update_SaveAnimationFile()
			on ddl_SaveAnimationFile_Name selected state do FN_Update_SaveAnimationFile()
		
		-- UI Update triggers for when the main rollout first opens
		on ASSET_PublishCenterRollout open do
		(
			-- Loads previous settings, if settings had been set
			try( chk_MaxFile.checked = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "MaxFile" "OutputEnabled")) )catch()
			try( chk_MaxOptimizedFile.checked = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "MaxOptimizedFile" "OutputEnabled")) )catch()
			try( chk_MaterialFile.checked = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "MaterialFile" "OutputEnabled")) )catch()
			try( chk_vrmeshFile.checked = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "vrmeshFile" "OutputEnabled")) )catch()
			try( chk_vrmeshAsMaxFile.checked = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "vrmeshAsMaxFile" "OutputEnabled")) )catch()
			try( chk_xmeshFile.checked = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "xmeshFile" "OutputEnabled")) )catch()
			try( chk_xmeshAsMaxFile.checked = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "xmeshAsMaxFile" "OutputEnabled")) )catch()
			try( chk_PointCacheFile.checked = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "PointCacheFile" "OutputEnabled")) )catch()
			try( chk_PointCacheAsMaxFile.checked = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "PointCacheAsMaxFile" "OutputEnabled")) )catch()
			try( chk_SaveAnimationFile.checked = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "SaveAnimationFile" "OutputEnabled")) )catch()
				
			-- Update individual paths for each asset
			FN_Update_3dsMaxFile()
			FN_Update_MaxOptimizedFile()
			FN_Update_MaterialFile()
			FN_Update_vrmeshFile()
			FN_Update_vrmeshAsMaxFile()
			FN_Update_xmeshFile()
			FN_Update_xmeshAsMaxFile()
			FN_Update_PointCacheFile()
			FN_Update_PointCacheAsMaxFile()
			FN_Update_SaveAnimationFile()
				
			--arg_enabled: if animation is enabled | arg_source: either scene or predefined range | arg_label: the UI element to update
			FN_UpdateFrameRange lab_vrmeshAnimFrames "vrmeshFile"
			FN_UpdateFrameRange lab_vrmeshAsMaxAnimFrames "vrmeshAsMaxFile"
			FN_UpdateFrameRange lab_xmeshAnimFrames "xmeshFile"
			FN_UpdateFrameRange lab_xmeshAsMaxAnimFrames "xmeshAsMaxFile"
			FN_UpdateFrameRange lab_PointCacheFileAnimFrames "PointCacheFile"
			FN_UpdateFrameRange lab_PointCacheAsMaxFileAnimFrames "PointCacheAsMaxFile"
				
			-- Update Ui Items
			FN_PublishAssetDirPreview()
			FN_CategoryToggle()

			ddl_className.items = (ASSET_PublishOptions.FN_GetPrefixList() + #("Layout")) 
				
-- 			updateAllPrefixes ddl_className.items[1]
		)
		
		-- Main publish Action
		on btn_PublishAsset pressed do
		(
			-- prepare for publishing
			nodeAssetForPublish = (maxops.getnodebyhandle nodeAssetHandle) -- DEFINE FOR CURRENT ASSET -16
			
			timestart = timestamp()
			errorcount = 0
			ASSET_PublishFunctions.LOGclear()
			prog_totalprogress.value = 0
			countCurrent = 0
			countTotal = FN_CountEnabled()

			try( setinisetting AssetFile "Global" "radius" 		(nodeAssetForPublish.radius as string)		) catch ()
			try( setinisetting AssetFile "Global" "wirecolor" 	(nodeAssetForPublish.wirecolor as string)	) catch ()
			try( setinisetting AssetFile "Global" "steps" 		(nodeAssetForPublish.steps as string)		) catch ()

			max hold
			
			-- individual publish operations, and progressbar updates
			if chk_MaxFile.checked then 
				(
					errorcount += FN_Publish_MaxFile()
					countCurrent += 1
					prog_totalprogress.value = ((( countCurrent / countTotal as float) * 100))
				)
			if chk_MaxOptimizedFile.checked then
				(
					errorcount += FN_Publish_MaxOptimizedFile()
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
			if chk_vrmeshAsMaxFile.checked then
				(
					errorcount += FN_Publish_vrmeshAsMaxFile()
					countCurrent += 1
					prog_totalprogress.value = ((( countCurrent / countTotal as float) * 100))
				)
			if chk_xmeshFile.checked then
				(
					errorcount += FN_Publish_xmeshFile()
					countCurrent += 1
					prog_totalprogress.value = ((( countCurrent / countTotal as float) * 100))
				)
			if chk_xmeshAsMaxFile.checked then
				(
					errorcount += FN_Publish_xmeshAsMaxFile()
					countCurrent += 1
					prog_totalprogress.value = ((( countCurrent / countTotal as float) * 100))
				)
			if chk_PointCacheFile.checked then
				(
					errorcount += FN_Publish_PointCacheFile()
					countCurrent += 1
					prog_totalprogress.value = ((( countCurrent / countTotal as float) * 100))
				)
			if chk_PointCacheAsMaxFile.checked then
				(
					errorcount += FN_Publish_PointCacheAsMaxFile()
					countCurrent += 1
					prog_totalprogress.value = ((( countCurrent / countTotal as float) * 100))
				)
			if chk_SaveAnimationFile.checked then
				(
					errorcount += FN_Publish_SaveAnimationFile()
					countCurrent += 1
					prog_totalprogress.value = ((( countCurrent / countTotal as float) * 100))
				)

			-- report the results of the publishing operations
			FN_ReportEnd errorcount timestart
			if errorcount > 0 then(ASSET_PublishFunctions.LOGopen()) else(destroydialog ASSET_PublishCenterRollout)
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
	createDialog ASSET_PublishCenterRollout --modal:true


)

FN_PublishCenter()