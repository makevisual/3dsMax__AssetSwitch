struct ASSET_Functions
(
	function Asset_Initialize arg_Obj arg_assetFile =
	(
		assetFile = arg_assetFile
		
		setUserProp arg_Obj "asset_file" assetFile
		setUserProp arg_Obj "asset_file_curType" ""
		setUserProp arg_Obj "asset_file_curVersion" ""
		
		setINISetting assetFile "Global" "name" arg_Obj.name
		select arg_Obj
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
			setUserProp selectionArray[i] "asset_file" assetFile
			setUserProp selectionArray[i] "asset_file_curType" initalType
			setUserProp selectionArray[i] "asset_file_curVersion" initalVer

			clearListener()
			assetGlobalName = (getINISetting assetFile "Global" "name")				
			print assetGlobalName
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
			if curFileParts[i] == "Projects" or curFileParts[i] == "Pitches"
			then
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

		rollout CreateNewAsset_Dialog  "Create New Asset" width:350 height:250
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
				
				if edt_Handle.text == "" or edt_Name.text == ""
				then( btn_create.enabled = false )
				else( btn_create.enabled = true )
				
				return str
			)
			
			function chooseProject_check arg_proj =
			(
 				if arg_proj != ""
 				then
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
			
			function chooseProject_manual =
			(
				curPath = getSavepath()
				
				if curPath == undefined then curPath = ""
				
				if ( DoesFileExist (curPath + @"\Data\assetSwitch.ini") ) 
				then ( lab_Project.text = curPath )
				else ( lab_Project.text = "" )
			)
			
			function update_lab_create =
			(
				assetNameStr		= makeAssetName()
				lab_create.text 	= ( @"\Assets\" + ddl_AssetClass.selected + @"\" + assetNameStr + @"\" )
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
-- 				edt_Handle.text = "TST"
-- 				edt_Name.text	= "Test"
				
				curProj = ASSET_Functions.chooseProject_auto()
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
	
	function CreateNewAsset_Node arg_class arg_name =
	(
		newNode = circle wirecolor:blue radius:20 renderable:off steps:1 optimize:false
		
		filteredName = filterstring arg_name "_"
		globlalName = (arg_Class[1] + "_" + filteredName[1] + "_Global")
		newNode.name = globlalName
		
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
		newSaveFileName 	= (	newDir2 + @"\Build\Model\" + arg_Name +"_Model_001.max" )
		
		if ( doesfileexist newDir2 )
		then (messagebox "Asset Already Exists")
		else
		(
			makedir newDir2

			copyFolder = ("xcopy " + "\"" + @"U:\Pitches\[project]\Assets\Characters\[Character_A]" + "\"" + " " + "\"" + newDir2 + "\"" + " /E")
 			hiddendoscommand copyFolder
 			
			renameFile ( newDir + "[Character_A]" ) ( newDir + arg_Name + @"\" )
			renameFile ( newDir2 + @"\" + "[Character_A].asset" ) newAssetFilename
			 
			newNode = ASSET_Functions.CreateNewAsset_Node arg_Class arg_Name
			ASSET_Functions.Asset_Initialize newNode newAssetFilename
			
			saveMaxFile newSaveFileName quiet:true
			
			try (destroydialog arg_Dialog) catch()
		)
	)
)

-- ASSET_Functions.CreateNewAsset_UI()