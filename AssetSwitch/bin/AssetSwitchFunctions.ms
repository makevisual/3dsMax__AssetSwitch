struct ASSET_Functions
(
	function Asset_Initialize arg_Obj arg_assetFile =
	(
		assetFile = arg_assetFile
		
		setUserProp arg_Obj "MAKE_Asset_Filepath" assetFile
		setUserProp arg_Obj "MAKE_Asset_Loaded_Filetype" ""
		setUserProp arg_Obj "MAKE_Asset_Loaded_Version" ""
		
		setINISetting assetFile "Global" "name" arg_Obj.name
		--select arg_Obj -- Selecting this BUGGER is clearing the listener and avoiding me to troubleshoot the script because there is a CALLBACK that has a ton of clearListener() all over it
	),
	
	function ChangeAsset_auto arg_assetFile arg_assetName =
	(
	-- open file pick dialog to choose a .asset file
	newAsset = undefined
	newAsset =  getOpenFileName \
	types:"Asset Files (*.asset)|*.asset|"
	
	-- gracefully exit no choice, or set data if valid choice
	if newAsset == undefined
	then ()
	else(
		assetFile = newAsset
		assetName = (getFilenameFile assetFile)
		assetDir = (getFilenamePath assetFile)
		
		-- Read and test if there is a valid 'Global' name in the .asset file
		assetGlobalName = (getINISetting assetFile "Global" "name")
		
		if assetGlobalName == ""
		then
			(
			messagebox " This asset has not yet been initalized, you must choose a name for the global "
			FN_setup_Initalize()
			)
		else ()

		-- Set userprops for first instance:
		objArr = FN_GetObjectsInDir()
		initalType = objArr[1]
		
		verArr = FN_GetVersionsInDir()
		initalVer = objArr[1]
			
		selectionArray = (selection as array)
		for i in 1 to selectionArray.count do
			(
			-- Reset userProperties
			setUserProp selectionArray[i] "MAKE_Asset_Filepath" assetFile
			setUserProp selectionArray[i] "MAKE_Asset_Loaded_Filetype" initalType
			setUserProp selectionArray[i] "MAKE_Asset_Loaded_Version" initalVer













			--clearListener() -- REMEMBER TO UNCOMMENT THIS


















			assetGlobalName = (getINISetting assetFile "Global" "name")				
			--print assetGlobalName
			selectionArray[i].name = assetGlobalName
			)
			
		-- Trigger full UI and settings redraw
		FN_Callback_SelectionChange()
		)
	),
	
	function ChooseProject_auto =
	(
		curFile = maxFilePath
		curFileParts = (filterString curFile @"\")
		str = ""

		-- Get the project folder
		for i in 1 to curFileParts.count do
		(
			if curFileParts[i] == "Projects" or curFileParts[i] == "Pitches" then -- TODO: Resolve this hardcoded project structure that expects a Projects or Pitches folder
			(
				for j in 1 to i do
				(
					str = str + curFileParts[j] + @"\"
				)
				str = ( str + curFileParts[ ( i + 1 ) ] )
				exit
			)
			else ( str = "" )
		)
		str
	),
	
	function CreateNewAsset_UI =
	(
		try (destroydialog CreateNewAsset_Dialog) catch()

		rollout CreateNewAsset_Dialog  "Create New Asset 1.6" width:350 height:250
		(
			groupbox			grp_project			"Project" 			width: (CreateNewAsset_Dialog.width - 25 ) height:65
				button 			btn_ChooseProject 	"Choose Project" 	width: (CreateNewAsset_Dialog.width - 35 ) offset:[0,(grp_project.height * -1 + 10)]
				label 			lab_Project 		""				align:#left offset:[6,0] style_sunkenedge:true height:18 width: (CreateNewAsset_Dialog.width - 38 )

			groupbox			grp_Asset 			"Asset Information" width: (CreateNewAsset_Dialog.width - 25 ) height:95 offset:[0,5]
				label 			lab_AssetClass 		"Category:"  		offset:[8,(grp_Asset.height * -1 + 15)] align:#left
				dropdownlist 	ddl_AssetClass 							offset:[60,-20] width:(CreateNewAsset_Dialog.width - 90 ) items:#("Characters","Effects","Misc","Objects","Sets")
				label 			lab_Handle 			"Handle:" 			align:#left offset:[8,0]
				edittext 		edt_Handle 			"" 		 			offset:[58,-20]  width:50 -- width:(CreateNewAsset_Dialog.width - 90 )
				label 			lab_Name 			"Name:" 			align:#left offset:[8,3]
 				edittext 		edt_Name 			"" 					offset:[58,-20] width:(CreateNewAsset_Dialog.width - 90 )

			groupbox			grp_create			"Create" 			width: (CreateNewAsset_Dialog.width - 25 ) height:65 offset:[0,10]
				button 			btn_create		 	"Create Asset"	 	width: (CreateNewAsset_Dialog.width - 35 ) offset:[0,(grp_project.height * -1 + 10)]									enabled:false
				label 			lab_create 			""					align:#left offset:[6,0] style_sunkenedge:true height:18 width: (CreateNewAsset_Dialog.width - 38 )
			
			function makeAssetName =
			(
				str = ( edt_Handle.text + "_" + edt_Name.text )
				
				if (edt_Handle.text == "") or (edt_Name.text == "") or (lab_Project.text == "") then -- Added (lab_Project.text == "") so the Create Asset Button would only be enabled
																									 -- in case a valid project folder is selected
				(
					btn_create.enabled = false
				)
				else
				(
					btn_create.enabled = true
				)
				
				return str
			)
			
			function chooseProject_check arg_proj =
			(
				print "arg_proj"
				print arg_proj
 				if arg_proj != "" then
				(
					lab_Project.text = arg_proj
					btn_create.enabled = true
				)
 				else
				(
					lab_Project.text = ""
					btn_create.enabled = false
				)
			)
			

			
			function update_lab_create =
			(
				assetNameStr		= makeAssetName()
				lab_create.text 	= ( @"\Assets\" + ddl_AssetClass.selected + @"\" + assetNameStr + @"\" )
			)
			function chooseProject_manual =
			(
				curPath = getSavepath()
				
				if curPath == undefined then curPath = ""
				
				if ( DoesFileExist (curPath + @"\Data\assetSwitch.ini") ) OR ( DoesFileExist (curPath + @"\Source\Data\assetSwitch.ini") ) then
				(
					lab_Project.text = curPath
					update_lab_create() -- Added to enable the Create Asset Button in case a valid project folder is selected
				)
				else
				(
					lab_Project.text = ""
				)
			)
			
			on ddl_AssetClass selected arg do ( update_lab_create() )
			on edt_Handle changed state do ( update_lab_create() )
			on edt_Name changed state do ( update_lab_create() )
			
			on btn_ChooseProject pressed do
			(
				chooseProject_manual()
			)
			
			on CreateNewAsset_Dialog open do
			(
				print "heey!!"
-- 				edt_Handle.text = "TST"
-- 				edt_Name.text	= "Test"
				
				curProj = ASSET_Functions.ChooseProject_auto()
				print "curProj"
				print curProj
				chooseProject_check curProj
				update_lab_create()
			)
			
			on btn_create pressed do
			(
				newPath 		= lab_Project.text
				newClass		= ddl_AssetClass.selected
				newAssetName 	= makeAssetName()
				print "newClass"
				print newClass
				print "newAssetName"
				print newAssetName
				ASSET_Functions.CreateNewAsset newPath newClass newAssetName CreateNewAsset_Dialog
			)
		)
		createDialog CreateNewAsset_Dialog
	),
	
	function CreateNewAsset_Node arg_class arg_name =
	(
		newNode = circle wirecolor:blue radius:20 renderable:off steps:1 optimize:false
		
		filteredName = filterstring arg_name "_"
		globalName = (arg_Class[1] + "_" + filteredName[1] + "_Global")
		newNode.name = globalName
		
		newCTRL_layer 		= LayerManager.newLayerFromName (arg_Class[1] + "_" + filteredName[1] + "_Ctrl" )
		newOBJ_layer 		= LayerManager.newLayerFromName (arg_Class[1] + "_" + filteredName[1] + "_Geo" )
		newCTRL_layer 		= LayerManager.getlayerfromname (arg_Class[1] + "_" + filteredName[1] + "_Ctrl" )
		newCTRL_layer.addNode newNode
		
		newNode
	),
	
	function CreateNewAsset arg_Path arg_Class arg_Name arg_Dialog =
	(
		newDir 				= ( arg_Path + @"\Assets\" + arg_Class + @"\" )
		newDir2 			= ( newDir + arg_Name + @"\" )
		
		newAssetFilename 	= ( newDir + arg_Name + @"\" + arg_Name + ".asset" )
		newSaveFileName 	= (	newDir2 + @"Build\Model\" + arg_Name +"_Model_001.max" ) -- This line is never creating a file because there is no folder structure that has "Build/Model"
		print "newAssetFilename"
		print newAssetFilename
		print "newSaveFileName"
		print newSaveFileName
		
		if ( doesfileexist newDir2 ) then
		(
			messagebox "Asset Already Exists"
		)
		else
		(
			makedir newDir2
			copyFolder = ("xcopy " + "\"" + @"U:\Pitches\[Project]\Assets\Characters\[Asset3D]" + "\"" + " " + "\"" + newDir2 + "\"" + " /E")
 			hiddendoscommand copyFolder
 			
			renameFile ( newDir + "[Asset3D]" ) ( newDir + arg_Name + @"\" )
			renameFile ( newDir2 + @"\" + "[Object_A].asset" ) newAssetFilename
			
			newNode = ASSET_Functions.CreateNewAsset_Node arg_Class arg_Name
			ASSET_Functions.Asset_Initialize newNode newAssetFilename
			saveMaxFile newSaveFileName quiet:true
			--try (destroydialog arg_Dialog) catch()
		)
	)
)

-- ASSET_Functions.CreateNewAsset_UI()