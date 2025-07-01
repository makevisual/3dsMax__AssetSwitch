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
	)
)

-- Function that calls the publish center, and its constituents
function FN_PublishCenter = -- asset: the current asset definition
(	
	
	-- The main rollout
	rollout	ASSET_PublishCenterRollout "Publish Center 1.6" width:380 height:505
	(
		label lab_AssetName assetName

		groupbox grp_PrefixGang "Class Name" width:(ASSET_PublishCenterRollout.width - 15) align:#left offset:[-5,0] height:65
			dropdownlist  ddl_className items:#("Error loading presets") width:(ASSET_PublishCenterRollout.width - 80) align:#left offset:[-1,(grp_PrefixGang.height * -1 + 10)]
			button btn_PrefixGang_Preset "Presets" align:#left offset:[(ASSET_PublishCenterRollout.width - 80),-28]
			edittext edt_PrefixGang_Custom text:"Layout" width:(ASSET_PublishCenterRollout.width - 25) align:#left offset:[-3,0] enabled:true

		groupbox grp_MaterialFile "" width:(ASSET_PublishCenterRollout.width - 15) align:#left offset:[-5,5] height:65
			checkbox chk_MaterialFile "Material" align:#left offset:[0,((grp_MaterialFile.height * -1) - 5)] -- enabled:false
				dropdownlist ddl_MaterialFile_Name "" items:#("name","none") width:60 align:#left offset:[-1,0]
				edittext edt_MaterialFile_Prefex "" text: "ver" width:60 align:#left offset:[55,-25]
				spinner spinner_MaterialFile_Number "" range:[1,999,1] type:#integer width:40 align:#left offset:[114,-21]
				button button_MaterialFile_Options "Options" offset:[0,-25] align:#right
				label lab_MaterialFile " error" style_sunkenedge:true height:16 width:(ASSET_PublishCenterRollout.width - 25) align:#left offset:[0,0]
		
		groupbox grp_MaxFile "" width:(ASSET_PublishCenterRollout.width - 15) align:#left offset:[-5,5] height:65
			checkbox chk_MaxFile "3ds Max File" align:#left offset:[0,((grp_MaxFile.height * -1) - 5)] checked:true --enabled:false
				dropdownlist ddl_MaxFile_Name "" items:#("name","none") width:60 align:#left offset:[-1,0]
				edittext edt_MaxFile_Prefex "" text: "ver" width:60 align:#left offset:[55,-25]
				spinner spinner_MaxFile_Number "" range:[1,999,1] type:#integer width:40 align:#left offset:[114,-21]
				button button_MaxFile_Options "Options" offset:[0,-25] align:#right
				label lab_MaxFile " error" style_sunkenedge:true height:16 width:(ASSET_PublishCenterRollout.width - 25) align:#left offset:[0,0]
			
		groupbox grp_vrmeshFile "" width:(ASSET_PublishCenterRollout.width - 15) align:#left offset:[-5,5] height:65
			checkbox chk_vrmeshFile ".vrmesh" align:#left offset:[0,((grp_vrmeshFile.height * -1) - 5)] -- enabled:false
				dropdownlist ddl_vrmeshFile_Name "" items:#("name","none") width:60 align:#left offset:[-1,0]
				edittext edt_vrmeshFile_Prefex "" text: "ver" width:60 align:#left offset:[55,-25]
				spinner spinner_vrmeshFile_Number "" range:[1,999,1] type:#integer width:40 align:#left offset:[114,-21]
				button button_vrmeshFile_Options "Options" offset:[0,-25] align:#right
				label lab_vrmeshAnimFrames "frames:0" enabled:false align:#left offset:[180,-20]
				button button_vrmeshFileRefresh "R" align:#left offset:[160,-21] width:18 height:18
				label lab_vrmeshFile " error" style_sunkenedge:true height:16 width:(ASSET_PublishCenterRollout.width - 25) align:#left offset:[0,0]

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
			
			case curClass of 	--------------------------------------------- ASK_AARON - Maybe some of these test clauses could be eliminated since their formats are deprecated?
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
			
					return comboString 	------------------------------------------------------------------ ASK_AARON -Why are we using RETURN on this clause?
					
				)
				4: -- vrmeshFile
				(
					curClassName = "Vrmesh"
					curClassExtension = ".vrmesh"
				)
				5: -- vrmeshAsMaxFile
				(
					curClassName = "VrmeshAsMax"     -- TODO: Reevaluate (maybe turn to VrayRig - Rigid objects only)
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
				10: -- PointCacheAsMaxFile  --???????????????????????????????
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
		function FN_Update_MaterialFile =			(FN_UpdateLocalPath lab_MaterialFile 3 ddl_MaterialFile_Name.selection edt_MaterialFile_Prefex.text spinner_MaterialFile_Number.value)
		function FN_Update_vrmeshFile =				(FN_UpdateLocalPath lab_vrmeshFile 4 ddl_vrmeshFile_Name.selection edt_vrmeshFile_Prefex.text spinner_vrmeshFile_Number.value)
			
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
			assetDir = ( getFilenamePath (getUserProp nodeAssetForPublish "Make_Asset_Filepath"))
			assetName = (getfilenamefile  (getUserProp nodeAssetForPublish "Make_Asset_Filepath"))

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
			local publish_filepath = ( assetDir + @"\Publish" + (FN_Update_3dsMaxFile())) -- ASK_AARON - Maybe add @ on this string?
			
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
		
		-- Publisher for the Optimized MaxOptimizedFile class <-- ASK_AARON - MAYBE THIS IS DEPRECATED AND CAN BE REMOVED?
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
			local publish_filepath = ( assetDir + "\Publish" + (FN_Update_MaterialFile())) -- ASK_AARON - Maybe add @ on this string?
			
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
			publish_filepath = ( assetDir + "\Publish" + (FN_Update_vrmeshFile())) -- ASK_AARON - Maybe add @ on this string?
			
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
		
		
		function FN_PUBhistSave = -- ASK_AARON - 
								  -- This function is adding User Properties to the Global/Root of the asset, "nodeAssetForPublish" is the Global Variable that stores this object and this 
								  -- variable is defined earlier at this script if the function FN_RestoreFromHold is invoked or, most likely, was already defined when the file 
								  -- "PublishModulesStruct.ms" was loaded and executed by another file called "PublishCenter.ms". This "PublishCenter.ms" is defined to another Global
								  -- Variable called "PublishCenterExecutable", which is defined on the "AssetSwitch_Launch.ms" located one folder up from where this very script is
								  -- located. This Global Variable is finally called when the Publish button ("btn_PublishAsset", on the "AssetSwitchUI.ms" file) on the Asset Switch v1.6.0 
								  -- rollout is pressed.
								  --
								  -- So, the Flow of this logic is:
								  -- 1. - The "AssetSwitchUI.ms" is called from the "MAKE Tools" menu bar when the user selects "AssetSwitch". This script then:
								  -- 2. - Creates the Global Variable "PublishCenterExecutable", defined as the path to the "PublishCenter.ms" script.
								  -- 3. - When the user clicks the Publish button ("btn_PublishAsset"), the "PublishCenterExecutable" variable is called (using FileIn)
								  -- 4. - The "PublishCenterExecutable" calls the "PublishCenter.ms", which calls the "PublishModulesStruct.ms"
								  -- 5. - The "PublishModulesStruct.ms" creates the "nodeAssetForPublish" Global Variable
								  --
								  -- Worth noting that the "nodeAssetForPublish" depends on another Global Variable to be defined - "nodeAssetHandle". This later variable is initialized
								  -- at the "PublishCenter.ms"
		(
 			--setUserProp nodeAssetForPublish "PUBhist_Material" edt_MaterialFile_Prefex.text
 			setUserProp nodeAssetForPublish "Make_Asset_Material_Versions" spinner_MaterialFile_Number.value
 			--setUserProp nodeAssetForPublish "PUBhist_MaxFile" edt_MaxFile_Prefex.text
 			setUserProp nodeAssetForPublish "Make_Asset_Max_Versions" spinner_MaxFile_Number.value
 			--setUserProp nodeAssetForPublish "PUBhist_Vrmesh" edt_vrmeshFile_Prefex.text
 			setUserProp nodeAssetForPublish "Make_Asset_Vrmesh_Versions" spinner_vrmeshFile_Number.value







 			setUserProp nodeAssetForPublish "Make_Asset_TimeStamp" localTime           --------- ASK_AARON - This whole procedure can be faster if instead of using the
 																					-- "setUserProp" command, create the whole string with all the variables and
 																					-- their values and apply that string with the "setUserPropBuffer" command.
 																					-- the caveats is that using the latter command ALL THE USER PROPERTIES will
 																					-- be erased and replaced by the new one
 			setUserProp nodeAssetForPublish "Make_Asset_Author" sysInfo.username
 			setUserProp nodeAssetForPublish "Make_Asset_Computer" sysInfo.computername 
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
		)
		
		function FN_CountEnabled =
		(
			count = 0
			if chk_MaxFile.checked then 			(count += 1)
			if chk_MaterialFile.checked then 		(count += 1)
			if chk_vrmeshFile.checked then 			(count += 1)
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
			--FN_Update_MaxOptimizedFile() ----> ASK_AARON - Deprecated?
			FN_Update_MaterialFile()
			FN_Update_vrmeshFile()
			--FN_Update_vrmeshAsMaxFile() ----> ASK_AARON - Deprecated?

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
			
		-- UI Update triggers for when the main rollout first opens
		on ASSET_PublishCenterRollout open do
		(
			-- Loads previous settings, if settings had been set
			try( chk_MaxFile.checked = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "MaxFile" "OutputEnabled")) )catch()
			try( chk_MaxOptimizedFile.checked = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "MaxOptimizedFile" "OutputEnabled")) )catch() ----> ASK_AARON - This option is absent on the INI file
			try( chk_MaterialFile.checked = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "MaterialFile" "OutputEnabled")) )catch()
			try( chk_vrmeshFile.checked = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "vrmeshFile" "OutputEnabled")) )catch()
			try( chk_vrmeshAsMaxFile.checked = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "vrmeshAsMaxFile" "OutputEnabled")) )catch() ----> ASK_AARON - This option is absent on the INI file

			-- Update stored names 
			curStr = ((getUserProp nodeAssetForPublish "PUBhist_MaxFile") as string )
			if curStr == "undefined" then( curStr = "ver" )
			edt_MaxFile_Prefex.text = curStr

			curStr = ((getUserProp nodeAssetForPublish "PUBhist_Material") as string )
			if curStr == "undefined" then( curStr = "ver" )
			edt_MaterialFile_Prefex.text = curStr

			curStr = ((getUserProp nodeAssetForPublish "PUBhist_Vrmesh") as string )
			if curStr == "undefined" then( curStr = "ver" )
			edt_vrmeshFile_Prefex.text = curStr
			
			-- Update stored interations
			try( spinner_MaxFile_Number.value 			= ( ( getUserProp nodeAssetForPublish "PUBhist_MaxFileVer" ) 		as integer ) ) catch ( spinner_MaxFile_Number.value 			= 001 )
			try( spinner_MaterialFile_Number.value 		= ( ( getUserProp nodeAssetForPublish "PUBhist_MaterialVer" ) 		as integer ) ) catch ( spinner_MaterialFile_Number.value 		= 001 )
			try( spinner_vrmeshFile_Number.value 		= ( ( getUserProp nodeAssetForPublish "PUBhist_VrmeshVer" ) 		as integer ) ) catch ( spinner_vrmeshFile_Number.value 			= 001 )
				
			-- Update individual paths for each asset
			FN_Update_3dsMaxFile()
			FN_Update_MaterialFile()
			FN_Update_vrmeshFile()


				
			--arg_enabled: if animation is enabled | arg_source: either scene or predefined range | arg_label: the UI element to update
			FN_UpdateFrameRange lab_vrmeshAnimFrames "vrmeshFile"
				
			-- Update Ui Items
			FN_PublishAssetDirPreview()
			FN_CategoryToggle()
			
			
			--todo
			--try(ddl_className.items = (ASSET_PublishOptions.FN_GetPrefixList() + #("Layout"))) catch (ddl_className.items = #("Layout"))
				

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

			try( setinisetting AssetFile "Global" "radius" 		(nodeAssetForPublish.radius as string)		) catch ()
			try( setinisetting AssetFile "Global" "wirecolor" 	(nodeAssetForPublish.wirecolor as string)	) catch ()
			try( setinisetting AssetFile "Global" "steps" 		(nodeAssetForPublish.steps as string)		) catch ()

			max hold
			
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
	createDialog ASSET_PublishCenterRollout 380 430 --modal:true -- added a fixed size for this dialog


)

FN_PublishCenter()