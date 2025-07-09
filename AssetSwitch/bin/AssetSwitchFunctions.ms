struct ASSET_Functions
(
	function Asset_Initialize arg_Obj arg_assetFile =
	(
		assetFile = arg_assetFile

		setUserProp arg_Obj "MAKE_Asset_Filepath" assetFile
		setUserProp arg_Obj "MAKE_Asset_Loaded_Filetype" ""
		setUserProp arg_Obj "MAKE_Asset_Loaded_Version" ""

		setINISetting assetFile "Global" "name" arg_Obj.name -- This MOTHER OF WASPS creates the .asset file if this file does not exist.... 2 hours fooling around it.
		
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
																				  -- Still in doubt about the name of the folder. Should it be "Projects" or "[Project]"?
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
					--lab_Project.text = ""

					-- New funcionality: Create the .ini file if it was not found in the test clause above
					NewDirectories = (curPath + @"\Source\Data")






				)
			)
			
			on ddl_AssetClass selected arg do ( update_lab_create() )
			on edt_Handle changed state do ( update_lab_create() )
			on edt_Name changed state do ( update_lab_create() )
			
			on btn_ChooseProject pressed do
			(
				chooseProject_manual() -- TODO: This function is only called once. Maybe it could be retired...
			)
			
			on CreateNewAsset_Dialog open do
			(
-- 				edt_Handle.text = "TST"
-- 				edt_Name.text	= "Test"
				
				curProj = ASSET_Functions.ChooseProject_auto()
				chooseProject_check curProj
				update_lab_create()
			)
			
			on btn_create pressed do
			(
				newPath 		= lab_Project.text
				newClass		= ddl_AssetClass.selected
				newAssetName 	= makeAssetName()
				ASSET_Functions.CreateNewAsset newPath newClass newAssetName CreateNewAsset_Dialog
			)
		)
		createDialog CreateNewAsset_Dialog
	),
	
	function CreateNewAsset_Node arg_Class arg_Name =
	(
		newNode = circle wirecolor:blue radius:20 renderable:off steps:1 optimize:false
		
		filteredName = filterstring arg_Name "_"
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
		RootAssetDir 				= ( arg_Path + @"\Assets\" + arg_Class + @"\" ) -- TODO: This should be called RootAssetDir for readability?
		CurrentAssetDir 			= ( RootAssetDir + arg_Class[1] + "_" + arg_Name + @"\" )					-- TODO: This should be called CurrentAssetDir for readability?
		
		newAssetFilename 	= ( CurrentAssetDir + arg_Class[1] + "_" + arg_Name + ".asset" )
		newSaveFileName 	= (	CurrentAssetDir + @"Build\Model\" + arg_Class[1] + "_" + arg_Name +"_Model_001.max" )
		
		if ( doesfileexist CurrentAssetDir ) then
		(
			messagebox "Asset Already Exists"
		)
		else
		(
			makedir CurrentAssetDir
			-- TODO: This following commented section does not seem to impact the script's ability to create assets...
			-- It was supposed to:
			-- Copy all the folders inside "U:\Pitches\[Project]\Assets\Characters\[Asset3D]" into the Current Asset Directory, namely
			-- "D:\David\Documents\3dsMax\[Project]\Assets\Characters\AssetHandle_AssetName\". The folder structure copied is as follows:
			-- Build
			-- Cache
			-- Comp
			-- Image_Sequences
			-- Publish
			-- References
			-- Renders
			-- Surfaces
			-- and an empty .asset file called "[Object_A].asset"
			-- There are subfolders that account for a total of 17 folders. Do we need this folder structure? Or when a [Project] template folder is
			-- copied over this structure is already present?

			--copyFolder = ("xcopy " + "\"" + @"U:\Pitches\[Project]\Assets\Characters\[Asset3D]" + "\"" + " " + "\"" + CurrentAssetDir + "\"" + " /E")
 			--hiddendoscommand copyFolder
 			
			--renameFile ( newDir + "[Asset3D]" ) ( newDir + arg_Name + @"\" ) -- This line is also returning FALSE
			--renameFile ( CurrentAssetDir + @"\" + "[Object_A].asset" ) newAssetFilename -- This line is also returning FALSE
			
			newNode = ASSET_Functions.CreateNewAsset_Node arg_Class arg_Name
			ASSET_Functions.Asset_Initialize newNode newAssetFilename
			ASSET_FolderStructure.InitializeFolderStrucure CurrentAssetDir
			
			saveMaxFile newSaveFileName quiet:true

			try (destroydialog arg_Dialog) catch()
		)
	)
)

-- ASSET_Functions.CreateNewAsset_UI()