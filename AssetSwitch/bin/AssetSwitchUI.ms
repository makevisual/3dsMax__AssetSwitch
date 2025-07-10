--*****************************************************
--Aaron Dabelow, theonlyaaron@gmail.com
--*****************************************************
-- HISTORY:
--- version 1.0 : 02.17.2014  >> Created by Aaron Dabelow
--- version 1.1 : 04.29.2014  >> Publish selected bug fixed
--					 >> Publish material added
--					 >> About window fixed
--- version 1.2 : 08.05.2014  >> Publish Center added
--					 >> Fixed xmesh import bug
--- version 1.4 : 01.16.2015  >> No longer allow publish with scaled global
--					>> Manage globalNode properties, if present
--					>> New asset on set asset setup
--- version 1.4.1 : 02.10.2015  >> Fixed character asset creation overwrite bug
--					>> Fixed asset publish nothing selected bug
--- version 1.4.2 : 02.10.2015  >> Added xmesh name tweak
--- version 1.7.0 : 07.10.2025  >> Major functionality changes:
--								>> Removed XREF, PRT and POINT CACHE modes
--								>> Added publishing VrayProxies individual parts
--								>> Added MultiMaterial publishing and tyLibMtl support
--*****************************************************

try(DestroyDialog MAIN_AssetSwitchUI)catch()

-- =========================================
-- FUNCTIONS FOR DEALING WITH FILES
-- =========================================

-- Get the filetype of the files in the location
fn FN_importTypeTest arg = --arg: the folder to look at the filetypes in
(
	importType = undefined
		
	-- .MAX Test
	curFiles = getfiles (arg + @"\*.max")
	if curFiles.count > 0 do
	(
		curTypeImporter = 1
		curMaterialFile
		MAIN_AssetSwitchUI.btn_SwitchAsset.enabled = true
		return "Max File Merge"
	)
	-- .VRMESH Test
	curFiles = getfiles (arg + @"\*.vrmesh")
	if curFiles.count > 0 do
	(
		AddFiles = getfiles (arg + @"\*.vpmap")
		if AddFiles.count > 0 then
		(
			curTypeImporter = 2
			MAIN_AssetSwitchUI.btn_SwitchAsset.enabled = true
			return "V-Ray Parts Loader"
		)
		else
		(
			curTypeImporter = 2
			MAIN_AssetSwitchUI.btn_SwitchAsset.enabled = true
			return "V-Ray Mesh Loader"
		)
	)
	curTypeImporter = undefined
	MAIN_AssetSwitchUI.btn_SwitchAsset.enabled = false
	return "no valid files found"
)
	
-- gets all of the .mtl files in the assedts directory and returns them as an array
fn FN_GetMtlsInDIr =
(
	matArr = getfiles (assetDir + @"Publish\Material\*.mat")
	matNames = #()
	for i in 1 to matArr.count do
	(
		join matNames #((getFilenameFile matArr[i]))
	)
	if matNames.count == 0 do
	(
		matNames = #(" No Materials Found")
	)
	curMaterial = matNames[1]
	return matNames
)

-- gets all of the 'type folders' in the assedts directory and returns them as an array
fn FN_GetObjectsInDir =
(
	typeArr = getDirectories  (assetDir + @"Publish\*")
	typeNames = #()
	for i in 1 to typeArr.count do
	(
		foldersArr = filterstring typeArr[i] @"\"
		curFolder = #(foldersArr[foldersArr.count])
		if curFolder[1] != "Material" do
		(
			join typeNames curFolder
		)
	)
	if typeNames.count == 0 do
	(
		typeNames = #(" No Types Found")
	)
	curType = typeNames[1]
	return typeNames
)
	
-- gets all of the 'version folders' in the assets directory and returns them as an array
fn FN_GetVersionsInDir = -- arg: curType
(
	try
	(
		versionArr = getDirectories (assetDir + @"Publish\" + curType + "\*")	
		versionNames = #()
		for i in 1 to versionArr.count do
		(
			foldersArr = filterstring versionArr[i] @"\"
			curFolder = #(foldersArr[foldersArr.count])
			join versionNames curFolder
		)
		if versionNames.count == 0 do
		(
			versionNames = #(" No Versions Found")
		)
		curVersion = versionNames[1]
		return versionNames
	)
	catch
	(
		return #()
	)
)
	
-- Changes the asset file and redefines all of the global asset variables used by other functions
fn FN_ChangeAsset =
(
	-- open file pick dialog to choose a .asset file
	newAsset = undefined
	newAsset =  getOpenFileName \
	types:"Asset Files (*.asset)|*.asset|"

	-- gracefully exit no choice, or set data if valid choice
	if newAsset != undefined do
	(
		assetFile = newAsset
		assetName = (getFilenameFile assetFile)
		assetDir = (getFilenamePath assetFile)
	
		-- Read and test if there is a valid 'Global' name in the .asset file
		assetGlobalName = (getINISetting assetFile "Global" "name")

		if assetGlobalName == "" do
		(
			messagebox " This asset has not yet been initalized, you must choose a name for the global "
			FN_setup_Initalize()
		)

		-- Set userprops for first instance:
		objArr = FN_GetObjectsInDir()
		initalType = objArr[1]
		
		verArr = FN_GetVersionsInDir()
		initalVer = objArr[1]
			
		selectionArray = (selection as array)


		-- If there are no objects selected, then create a new global, with the correct properties 
		if selectionArray.count == 0 do
		(
			newGlobal = circle radius:50 wirecolor:blue steps:1
			select newGlobal
			selectionArray = (selection as array)
		)

		for i in 1 to selectionArray.count do
		(
			-- Reset userProperties
			setUserProp selectionArray[i] "MAKE_Asset_Filepath" newAsset
			setUserProp selectionArray[i] "MAKE_Asset_Loaded_Filetype" initalType
			setUserProp selectionArray[i] "MAKE_Asset_Loaded_Version" initalVer

			assetGlobalName = (getINISetting newAsset "Global" "name")				
			selectionArray[i].name = assetGlobalName

			-- Try and set the paramaters of the global
			try ( selectionArray[i].radius = 		( execute ( getinisetting newAsset "Global" "radius" ) ) ) catch ()
			try ( selectionArray[i].wirecolor =		( execute ( getinisetting newAsset "Global" "wirecolor" ) ) ) catch ()
			try ( selectionArray[i].steps = 		( execute ( getinisetting newAsset "Global" "steps" ) ) ) catch ()

		)
		
		-- Trigger full UI and settings redraw
		FN_Callback_SelectionChange()
	)
)
	
-- =====================================
-- FUNCTIONS FOR UPDATING THE UI
-- =====================================

-- Set the ui to a no selection case
fn FN_UiReset =
(
	assetFile = undefined
	assetName = undefined
	assetDir = undefined
		
	MAIN_AssetSwitchUI.btn_chooseAsset.text = " No Object(s) Selected "
	MAIN_AssetSwitchUI.lab_assetDir.text = ""
	MAIN_AssetSwitchUI.btn_SwitchAsset.enabled = false
	MAIN_AssetSwitchUI.btn_copyAssetDir.enabled = false
	MAIN_AssetSwitchUI.btn_openAssetDir.enabled = false
	MAIN_AssetSwitchUI.btn_copyMatDir.enabled = false
	MAIN_AssetSwitchUI.btn_openMatDir.enabled = false
	MAIN_AssetSwitchUI.btn_copyObjDir.enabled = false
	MAIN_AssetSwitchUI.btn_openObjDir.enabled = false
	MAIN_AssetSwitchUI.btn_copyVerDir.enabled = false
	MAIN_AssetSwitchUI.btn_openVerDir.enabled = false
		
	MAIN_AssetSwitchUI.chkbox_materials.text = "Materials"
	MAIN_AssetSwitchUI.chkbox_objects.text = "Objects"

	MAIN_AssetSwitchUI.ddl_matDropdown.items = #(" -- No Materials Present --")
	MAIN_AssetSwitchUI.ddl_matDropdown.selection = 1
	
	MAIN_AssetSwitchUI.ddl_objDropdown.items =#(" -- No Objects Present --")
	MAIN_AssetSwitchUI.ddl_objDropdown.selection = 1
	
	MAIN_AssetSwitchUI.ddl_versionDropdown.items =#(" -- No Versions Present --")
	MAIN_AssetSwitchUI.ddl_versionDropdown.selection = 1
	
	MAIN_AssetSwitchUI.lab_importType.text = ( "Import Module: N/A")
	
	
	-- Information portion
	MAIN_AssetSwitchUI.lab_versionInfo_Filename.text = ("File name: N/A")
	MAIN_AssetSwitchUI.lab_versionInfo_Materialname.text = ("Material name: N/A")
	MAIN_AssetSwitchUI.lab_versionInfo_Frames.text = ("Frame range: N/A")
	MAIN_AssetSwitchUI.lab_versionInfo_Date.text = ("Date modified: N/A")
	MAIN_AssetSwitchUI.bmp_preview.visible = false
	
		
)

-- Set the ui to a invalid selection case	
fn FN_UiWarnInvalid =
	(
	FN_UiReset()
	MAIN_AssetSwitchUI.btn_chooseAsset.text = " Node(s) do not have an asset set! "
	)
	
-- Set the ui to a mismatched selection case
fn FN_UiWarnMismatch =
(
	FN_UiReset()
	MAIN_AssetSwitchUI.btn_chooseAsset.text = " Nodes do not share the same asset! "
)
	
-- Update all the elements in the Information panel except the import module
fn FN_UiInformationUpdate = 
(
	-- Prepare data for inspection	
	try
	(
		curMaterial = MAIN_AssetSwitchUI.ddl_matDropdown.selected
		curMaterialFile = (assetDir + @"Publish\Material\" + curMaterial + ".mat")
	)
	catch()
		
	try
	(
		curType = MAIN_AssetSwitchUI.ddl_objDropdown.selected
		curVersion = MAIN_AssetSwitchUI.ddl_versionDropdown.selected
		curVersionFile = (assetDir + @"Publish\" + curType + @"\" + curVersion + @"\")	
		
		FN_importTypeTest curVersionFile
	)
	catch()
		
	-- Set the bitmap image
	bmp_PreviewFilename = (substring assetFile 1 (assetFile.count - 5) + "jpg")
	if (doesFileExist bmp_PreviewFilename) then
	(
		MAIN_AssetSwitchUI.bmp_preview.filename = bmp_PreviewFilename
		MAIN_AssetSwitchUI.bmp_preview.visible = true
	)
	else
	(
		MAIN_AssetSwitchUI.bmp_preview.visible = false
	)
		
	-- Set the material file
 	--	curMaterialFile = (assetDir + @"Publish\Material\" + curMaterial + ".mat")
	try
	(
		curMaterialFileSS = ("..." + (substring curMaterialFile (curMaterialFile.count - 40) 99999))
	)
	catch
	(
		curMaterialFileSS = ("invalid")	
	)
	MAIN_AssetSwitchUI.lab_versionInfo_Materialname.text = ("Material name: " + curMaterialFileSS)
	
		
	-- Set the Import file name
		
		
		
		
	searchDir = (assetDir + @"Publish\" + curType + @"\" + curVersion + @"\")
	curFileExtension = @"*.*"
		
	case curTypeImporter of
	(
		-- standard Import
		1:
		(
			curFileExtension =@"*.max"
			targetFrameRangeparsed = "unknown"
		)
		-- V-Ray Mesh Import
		2:
		(
			curFileExtension =@"*.vrmesh"
			targetFrameRangeparsed = "unknown"
		)
	)
		
	FileArr = getfiles ((assetDir + @"Publish\" + curType + @"\" + curVersion + @"\") + curFileExtension)
	
	if FileArr.count == 0 then
	(
		MAIN_AssetSwitchUI.lab_versionInfo_Filename.text = ("File name: N/A")
	)
	else
	(
		lastFile = fileArr[fileArr.count]
		lastFileSS = ("..." + (substring lastFile (lastFile.count - 43) 99999))
		MAIN_AssetSwitchUI.lab_versionInfo_Filename.text = ("File name: " + lastFileSS)
	)
		
	-- Set Date created
	try
	(
		lastFileDate = getFileModDate lastFile
		MAIN_AssetSwitchUI.lab_versionInfo_Date.text = ("Date modified: "+ lastFileDate)
	)
	catch
	(
		MAIN_AssetSwitchUI.lab_versionInfo_Date.text = ("Date modified: N/A")
	)
		
		
	-- Set the UI to match collected Data
	try
	(
		MAIN_AssetSwitchUI.lab_versionInfo_Frames.text = ("Frame range: " + targetFrameRangeparsed)
	)
	catch
	(
		MAIN_AssetSwitchUI.lab_versionInfo_Frames.text = ("Frame range: N/A")
	)
	
)		
	
-- Update the Ui when the objects dropdown is changed
fn FN_UiUpdate_Versions = 
(
	-- 	MAIN_AssetSwitchUI.ddl_versionDropdown.items = (FN_GetVersionsInDir())
	MAIN_AssetSwitchUI.chkbox_objects.text = ("Objects : " + (MAIN_AssetSwitchUI.ddl_objDropdown.items.count as string) + " available, " + (MAIN_AssetSwitchUI.ddl_versionDropdown.items.count as string) + " versions")
	
	-- Search the current directory for the filetype, and set the importer for it
	curVersionFile = (assetDir + @"Publish\" + curType + @"\" + curVersion + @"\")
		
	MAIN_AssetSwitchUI.lab_importType.text = ( "Import Module: " + (FN_importTypeTest curVersionFile))
	
	curVersion = getUserProp selection[1] "MAKE_Asset_Loaded_Version"
		
	curVersionArr =	FN_GetVersionsInDir()
	for i in 1 to curVersionArr.count do
	(
		if curVersion == curVersionArr[i] do
		(
			MAIN_AssetSwitchUI.ddl_versionDropdown.selection = i
		)
	)
		
	FN_UiInformationUpdate()
)	
	
-- Update the Ui when the objects dropdown is changed
fn FN_UiUpdate_Objects = 
(
	MAIN_AssetSwitchUI.ddl_versionDropdown.items = (FN_GetVersionsInDir())
	MAIN_AssetSwitchUI.ddl_versionDropdown.selection = 1
	MAIN_AssetSwitchUI.chkbox_objects.text = ("Objects : " + (MAIN_AssetSwitchUI.ddl_objDropdown.items.count as string) + " available, " + (MAIN_AssetSwitchUI.ddl_versionDropdown.items.count as string) + " versions")
		
	-- Search the current directory for the filetype, and set the importer for it
	curVersionFile = (assetDir + @"Publish\" + curType + @"\" + curVersion + @"\")
	MAIN_AssetSwitchUI.lab_importType.text = ( "Import Module: " + (FN_importTypeTest curVersionFile))
		
	FN_UiUpdate_Versions()
		
)
	
-- Set the Ui to a succsessfull selection and check, the user can now procede with choosing switch
fn FN_UiUpdate =
(
	curMaterialsArr =	FN_GetMtlsInDIr()
	curTypesArr =	FN_GetObjectsInDir()
	curVersionArr = FN_GetVersionsInDir()
		
	curMaterial = getUserProp selection[1] "MAKE_Asset_Loaded_Material"
	curType = getUserProp selection[1] "MAKE_Asset_Loaded_Filetype"
	curVersion = getUserProp selection[1] "MAKE_Asset_Loaded_Version"
		
	for i in 1 to curMaterialsArr.count do
	(
		if curMaterial == curMaterialsArr[i] do
		(
			MAIN_AssetSwitchUI.ddl_matDropdown.selection = i
		)
	)
		
	for i in 1 to curTypesArr.count do
	(
		if curType == curTypesArr[i] do
		(
			MAIN_AssetSwitchUI.ddl_objDropdown.selection = i
		)
	)
	
	curVersionArr =	FN_GetVersionsInDir()
	for i in 1 to curVersionArr.count do
	(
		if curVersion == curVersionArr[i] do
		(
			MAIN_AssetSwitchUI.ddl_versionDropdown.selection = i
		)
	)
		
	-- Update the asset groupbox
	MAIN_AssetSwitchUI.btn_chooseAsset.text = assetName			
	MAIN_AssetSwitchUI.lab_assetDir.text = (" " + assetDir)
	MAIN_AssetSwitchUI.btn_SwitchAsset.enabled = true
	MAIN_AssetSwitchUI.btn_copyAssetDir.enabled = true
	MAIN_AssetSwitchUI.btn_openAssetDir.enabled = true
		
	-- Update UI Items
	MAIN_AssetSwitchUI.ddl_matDropdown.items = (curMaterialsArr)
	MAIN_AssetSwitchUI.btn_copyMatDir.enabled = true
	MAIN_AssetSwitchUI.btn_openMatDir.enabled = true
		
	MAIN_AssetSwitchUI.ddl_objDropdown.items = (curTypesArr)
	MAIN_AssetSwitchUI.btn_copyObjDir.enabled = true
	MAIN_AssetSwitchUI.btn_openObjDir.enabled = true
	MAIN_AssetSwitchUI.ddl_versionDropdown.items = (curVersionArr)
		
	MAIN_AssetSwitchUI.btn_copyVerDir.enabled = true
	MAIN_AssetSwitchUI.btn_openVerDir.enabled = true
		
	MAIN_AssetSwitchUI.chkbox_materials.text = ("Materials : " + (MAIN_AssetSwitchUI.ddl_matDropdown.items.count as string) + " available")
	MAIN_AssetSwitchUI.chkbox_objects.text = ("Objects : " + (MAIN_AssetSwitchUI.ddl_objDropdown.items.count as string) + " available, " + (MAIN_AssetSwitchUI.ddl_versionDropdown.items.count as string) + " versions")
		
	-- Search the current directory for the filetype, and set the importer for it
	curVersionFile = (assetDir + @"Publish\" + curType + @"\" + curVersion + @"\")
	MAIN_AssetSwitchUI.lab_importType.text = ( "Import Module: " + (FN_importTypeTest curVersionFile))
		
	FN_UiUpdate_Objects()
)
	
-- Test the selection for count, an assigned asset file, and matching asset types
fn FN_UiUpdate_SelectionCheck =
(		
	-- Test if there are any objects selected, and update the ui if there are things to update it with
	if ((selection as array).count) == 0 then
	(
		FN_UiReset()
	)
	else
	(
		-- If objects are selected, Parse and test them, on valid selection, update ui
		selectionArray = (selection as array)
		assetArray = #()
		failCase = ""
		
		-- Read the 'asset_file' property from all objects and store it in 'assetArray'
		for i in 1 to selectionArray.count do
		(
			-- reads the 'asset_file' property from the object, and returns it, if there is no stored property, returns 'invald' instead
			curAssetFile = (getUserProp selectionArray[i] "MAKE_Asset_Filepath")
				
			if curAssetFile == undefined then
			(
				failCase = "invalid"
			)
			else
			(
				join assetArray #(curAssetFile)
			)
		)
		-- Check 'assetArray' for clashing, or missing asset definitions
		for i in 1 to assetArray.count do
		(
			if assetArray[1] != assetArray[i] do
			(
				failCase = "mismatch"
			)
		)
		
		-- Calls the correct UI update based on 'failCase'
		case failCase of
		(
			"":
			(
				assetFile = (getUserProp selectionArray[1] "MAKE_Asset_Filepath")
				assetName = try((getFilenameFile assetFile))catch()
				assetDir = try((getFilenamePath assetFile))catch()
				
				FN_UiUpdate()
				
				-- Attempt to set the VERSION dropdown based off of a stored value ( this is the gross hack to get this thing into place..... I am ashamed -> Don't be!)
				try
				(
					curVersion_temp = getUserProp selection[1] "MAKE_Asset_Loaded_Version"
					curVersionArr =	FN_GetVersionsInDir()

					FN_UiUpdate_Objects() -- ASK AARON -> Added thi line to Brute Force fix for the unpopulated Objects DropDownList


					-- Loop throught the possible choices and set it if the prefferd choice is there
					for i in 1 to curVersionArr.count do
					(
						if curVersion_temp == curVersionArr[i] do
						(
							MAIN_AssetSwitchUI.ddl_versionDropdown.selection = i
						)
					)
					curMaterialFile = (assetDir + @"Publish\Material\" + curMaterial + ".mat")
					curVersionFile = (assetDir + @"Publish\" + curType + @"\" + curVersion + @"\")
				)
				catch()
				-- curMaterialFile = (assetDir + @"Publish\Material\" + curMaterial + ".mat")
				-- curVersionFile = (assetDir + @"Publish\" + curType + @"\" + curVersion + @"\")
				FN_UiInformationUpdate()	
			)
			"invalid":
			(
				FN_UiWarnInvalid()
			)
			"mismatch":
			(
				FN_UiWarnMismatch()
			)
		)
	)	
)
	
-- Callback trigger for selection change
fn FN_Callback_SelectionChange =
(
	FN_UiUpdate_SelectionCheck()
	nodeAsset = selection[1] -- TODO: ADDED THIS CHANGE TO UPDATE THE nodeAsset Global Variable
	--clearlistener()
)
	
-- Set the visibility for the contents of the information groupbox
fn FN_UiToggleInformation arg = 
(
	MAIN_AssetSwitchUI.lab_versionInfo_Frames.visible = arg
	MAIN_AssetSwitchUI.lab_versionInfo_Filename.visible = arg
	MAIN_AssetSwitchUI.lab_versionInfo_Date.visible = arg
	MAIN_AssetSwitchUI.lab_versionInfo_Materialname.visible = arg
	MAIN_AssetSwitchUI.bmp_preview.visible = arg
)
	
-- Check for the state of the information checkbox, and set UI elements accordingly
fn FN_UiToggleInformationTest arg =
(
	if arg == true then
	(
		MAIN_AssetSwitchUI.height = 362
		MAIN_AssetSwitchUI.grp_Info.height = 110
		FN_UiToggleInformation true
	)
	else
	(
		MAIN_AssetSwitchUI.height = 292
		MAIN_AssetSwitchUI.grp_Info.height = 40
		FN_UiToggleInformation false
	)
)
	
-- ================================
-- FUNCTIONS FOR IMPORTING!!!
-- ================================
	
-- Function for recursivly selecting all of the children of an inital object
fn FN_collectAllChildren obj includeParent:true MeshObjOnly:false =
(
	-- start collecting direct children of <obj>
	allChildren = #(obj)

	-- add children and their children etc recursively
	i = 0
	while i < allChildren.count do
	(
		i += 1
		join allChildren allChildren[i].children
	)

	-- remove initial object if <includeParent> == false
	if not includeParent then deleteitem allChildren 1
	if MeshObjOnly do
	(
		for i = allChildren.count to 1 by -1 do
		(
			ChildSuperClass = (superClassOf allChildren[i])
			if ChildSuperClass != GeometryClass do
			(
				deleteitem allChildren i
			)
		)
	)
	-- return array containing children
	allChildren
)	
	
-- Load and apply the chosen material
fn	FN_DoSwitch_Material curMaterialFile curMaterialMapFile nodeAsset LoadtyLibMtl = -- arg: the material file | arg2: the node to do the switch on
(
	-- Collect the entire family
	theObjects = (FN_collectAllChildren nodeAsset includeParent:true)
	theObjectsNames = (for obj in theObjects collect (obj.name))
	MaterialMapArray = execute (getinisetting curMaterialMapFile "MaterialNodeMap" "MaterialMapArray")
	-- Test to see if there is a file
	if (doesfileexist curMaterialFile) then
	(
		if LoadtyLibMtl then
		(
			NumberMaterials = MaterialMapArray.count
			for i = 1 to NumberMaterials do
			(
				loadMaterialLibrary curMaterialFile
				loadMaterialLibrary curMaterialFile -- TODO: This is a HACK because tyLibMtl for some reason has to be called TWICE in order to be loaded properly on the first time...

				ObjectsToApplyMaterial = #()
				-- loops through all 
				for CurrentObjectName in MaterialMapArray[i] do
				(
					ObjectIndex = findItem theObjectsNames CurrentObjectName
					if ObjectIndex != 0 do
					(
						append ObjectsToApplyMaterial theObjects[ObjectIndex]
					)
				)
				LoadedtyLibMtl = currentMaterialLibrary[1]
				LoadedtyLibMtl.index = (i - 1)
				ObjectsToApplyMaterial.material = LoadedtyLibMtl
			)
		)
		else
		(
			loadMaterialLibrary curMaterialFile
			NumberMaterials = MaterialMapArray.count
			for i = 1 to NumberMaterials do
			(
				ObjectsToApplyMaterial = #()
				-- loops through all 
				for CurrentObjectName in MaterialMapArray[i] do
				(
					ObjectIndex = findItem theObjectsNames CurrentObjectName
					if ObjectIndex != 0 do
					(
						append ObjectsToApplyMaterial theObjects[ObjectIndex]
					)
				)
				ObjectsToApplyMaterial.material = currentMaterialLibrary[i]
			)
		)
	)
)
	
fn	FN_DoSwitch_Standard arg arg2 = -- arg: the filepath to import | arg2: the node to do the switch on
(
	-- set some stuff up
	nodeAsset = arg2
	heroName = nodeAsset.name
	allObjectsArr = (objects as array)
	nameDuplicatesArr = #()

	-- Put all objects named the same in an array
	for i in 1 to allObjectsArr.count do
	(
		if allObjectsArr[i].name == heroName do
		(
			join nameDuplicatesArr #(allObjectsArr[i])
		)		
	)
	
	-- Set all of the names to HERONAME_temp, except the chosen node
	for i in 1 to nameDuplicatesArr.count do (nameDuplicatesArr[i].name = (heroName + "_temp"))
	nodeAsset.name = heroName
		
	-- Load objects from the scenefile into an array
	mergeFile = arg
	mergeObjects = getmaxfileobjectnames mergeFile
		
	try
	(
		-- Search the names of the objects in the scene for the hero name
		removeGlobalIndex = findItem mergeObjects heroName
		
		-- remove it from the list, and then import the other objects
		deleteItem mergeObjects removeGlobalIndex
		
		-- Collect all the children of the nodeAsset, and delete them
		deleteMe = (FN_collectAllChildren nodeAsset includeParent:false)
		delete deleteMe
		
		mergeMAXfile mergeFile mergeObjects #useMergedMtlDups  #mergeDups #alwaysReparent 
			
		-- Put all of the nodes back to having the same name	
		for i in 1 to nameDuplicatesArr.count do (nameDuplicatesArr[i].name = (heroName))
	)
	Catch
	(
		messagebox ("No objects with the name '" + heroName + "' were found in the target asset file. Please check your target file and verify the naming is correct.")
	)
)

-- Load in the chosen vray proxy	
fn	FN_DoSwitch_vRay arg arg2 = -- arg: the filepath to import | arg2: the node to do the switch on
(
	nodeAsset = arg2
	NodesToDelete = #()
	NodesToDeleteNames = #()
	NodesToLinkNames = #()
	HierarchyNodes = (FN_collectAllChildren nodeAsset includeParent:true MeshObjOnly:false)
	for i = (HierarchyNodes.count) to 1 by -1 do
	(
		NodeSuperClass = (superClassOf HierarchyNodes[i])
		if NodeSuperClass == GeometryClass then
		(
			append NodesToDelete HierarchyNodes[i]
			append NodesToDeleteNames HierarchyNodes[i].name
			deleteItem HierarchyNodes i
		)
		else
		(
			NodesToLinkNames[i] = HierarchyNodes[i].name
		)
	)
	VrayMapFile = (assetDir + @"Publish\" + curType + @"\" + curVersion + @"\" + Assetname + "_" + curVersion + ".vpmap")
	ExportedNodesNames = (execute (getinisetting VrayMapFile "NodesNames" "NodesNamesArray"))
	ExportedNodesTransform = (execute (getinisetting VrayMapFile "NodesTransform" "NodesTranformArray"))
	ExportedNodesParents = (execute (getinisetting VrayMapFile "NodesParent" "NodesParentArray"))
	FilesInFolder = (execute (getinisetting VrayMapFile "NodesPath" "NodesFilePath"))
	NumberOfFiles = FilesInFolder.count
	for i = 1 to NumberOfFiles do
	(
		newProxy = VRayProxy()
		newProxy.display = 3
		newProxy.wirecolor = black
		newProxy.filename = FilesInFolder[i]
		newProxy.name = ((getFilenameFile FilesInFolder[i]) + "_VRMESH" )


		NodeToReplaceIndex = FindItem NodesToDeleteNames ExportedNodesNames[i]
		if NodeToReplaceIndex == 0 then
		(
			NodeToReplaceIndex = FindItem NodesToLinkNames ExportedNodesNames[i]
			NodeToReplace = HierarchyNodes[NodeToReplaceIndex]
		)
		else
		(
			NodeToReplace = NodesToDelete[NodeToReplaceIndex]
		)
		newProxy.transform = NodeToReplace.transform
		NodeToLinkIndex = FindItem NodesToLinkNames ExportedNodesParents[i]
		NodeToLink = HierarchyNodes[NodeToLinkIndex]
		newProxy.parent = NodeToLink
	)
	delete NodesToDelete
)

-- Select the correct importer, and find the filename/type for the selected importer
fn	FN_DoSwitch_Type arg1 arg2 arg3 arg4 = -- arg1: the type of import to do | arg2: the filepath to import | arg3: the node to do the switch on | arg4: import (true) return name (false)
(
	case arg1 of
	(
		-- standard Import
		1:
		(
			maxFileArr = getfiles (arg2 + @"*.max")
			parsedFile = (maxFileArr[maxFileArr.count])
			if arg4 == true
			then(FN_DoSwitch_Standard parsedFile arg3)
			else(return parsedFile)
		)
		-- V-Ray Mesh Import
		2:
		(
			vrayMeshFileArr = getfiles (arg2 + @"*.vrmesh")
			parsedFile = (vrayMeshFileArr[vrayMeshFileArr.count])
			if arg4 == true
			then(FN_DoSwitch_vRay parsedFile arg3)
			else(return parsedFile)
		)
	)
)
	
-- Fetch the held file, and reset selection to match selection when the hold was performed
fn FN_Revert =
(
	-- Fetch the held file without interruption
	fetchMaxFile quiet:true
		
	-- Reset the selection to match what it was at the beginning of the switch
	clearselection()
	for i in 1 to switchObjectsHandleArray.count do
	(
		selectmore (maxOps.getNodeByHandle switchObjectsHandleArray[i])
	)
)
	
-- Prepare all chosen data, and apply it to the selected node ( THE MAIN ACTION )
fn FN_DoSwitch =
(
-- 	clearlistener()

	curMaterial = MAIN_AssetSwitchUI.ddl_matDropdown.selected
	curType = MAIN_AssetSwitchUI.ddl_objDropdown.selected
	curVersion = MAIN_AssetSwitchUI.ddl_versionDropdown.selected
		
	-- Prepare data for switch
	curMaterialFile = (assetDir + @"Publish\Material\" + curMaterial + ".mat")
	curMaterialMapFile = (assetDir + @"Publish\Material\" + curMaterial + ".matmap")
	tyLibMtlSplice = findString curMaterialFile "tyLibMtl"
	LoadtyLibMtl = false
	if tyLibMtlSplice != undefined do
	(
		LoadtyLibMtl = true
		curMaterialMapFile = ((substring curMaterialMapFile 1 (tyLibMtlSplice - 2)) + ".matmap")
	)
	curVersionFile = (assetDir + @"Publish\" + curType + @"\" + curVersion + @"\")
	switchObjectsArray = (selection as array)
	switchObjectsHandleArray = #()
	assetGlobalName = (getINISetting assetFile "Global" "name")
		
	-- Set selection as inode handles for use in fetching, and store the currently chosen settings
	for i in 1 to switchObjectsArray.count do
	(
		setUserProp switchObjectsArray[i] "MAKE_Asset_Loaded_Material" curMaterial
		setUserProp switchObjectsArray[i] "MAKE_Asset_Loaded_Filetype" curType
		setUserProp switchObjectsArray[i] "MAKE_Asset_Loaded_Version" curVersion

		-- Try and set the paramaters of the global
		try ( switchObjectsArray[i].radius = 		( execute ( getinisetting AssetFile "Global" "radius" ) ) ) catch ()
		try ( switchObjectsArray[i].wirecolor =		( execute ( getinisetting AssetFile "Global" "wirecolor" ) ) ) catch ()
		try ( switchObjectsArray[i].steps = 		( execute ( getinisetting AssetFile "Global" "steps" ) ) ) catch ()
		
		switchObjectsHandle = switchObjectsArray[i].inode.handle
		join switchObjectsHandleArray #(switchObjectsHandle)
	)
		
	-- Loop through switch objects, and perform selected switching
	for i in 1 to switchObjectsArray.count do
	(
		-- Test for if an object switch is desired, and do it if so
		if MAIN_AssetSwitchUI.chkbox_objects.checked == true do
		(
			switchObjectsArray[i].name = assetGlobalName
			FN_DoSwitch_Type curTypeImporter curVersionFile switchObjectsArray[i] true
		)
		
		-- Test for if a material switch is desired, and do it if so			
		if MAIN_AssetSwitchUI.chkbox_materials.checked == true do
		(
			FN_DoSwitch_Material curMaterialFile curMaterialMapFile switchObjectsArray[i] LoadtyLibMtl -- TODO: If we load the materials inside this function, it will 
																						  -- change at every iteration (meaning the material will NOT be 
																						  -- instanced across objects. Several objects will have the SAME 
																						  -- material, with the SAME name, but with potentially different values.
																						  -- To avoid this the materials should be defined BEFORE the loop on
																						  -- line 1038 ("for i in 1 to switchObjectsArray.count do")
		)
	)
	
	-- Reset the selection to match what it was at the beginning of the switch
	clearselection()
	for i in 1 to switchObjectsHandleArray.count do
	(
		selectmore (maxOps.getNodeByHandle switchObjectsHandleArray[i])  --- TODO: Better method than SelectMore?
	)
)

-- ============================
-- FUNCTIONS FOR MENUBAR
-- ============================
	
-- Function for removing userDefinedProperties using passed string
fn FN_setup_RemoveInfo node prop = if getUserProp node prop != undefined do
(
	buff = (getUserPropBuffer node) as stringStream 
	newb = stringStream ""
	while not eof buff do
	(
		str = readLine buff
		if str != "" and not matchpattern str pattern:("*" + prop + "*=*") do format "%\n" str to:newb
	)
	setUserPropBuffer node (replace_LF_with_CRLF (newb as string))
)
	
-- Collects selected files, and prompts user with a directory to save them into
	
fn FN_setup_Initalize  = 
(
	-- Get rid of any pre-existing initalizing rollouts
	try(DestroyDialog ROLL_AssetSwitch_Initalize)catch()

	-- Define the rollout
	rollout ROLL_AssetSwitch_Initalize ("Initalize .asset " +(versionNumber as string) )
	(
		button btn_OpenAsset "Open Asset" width:190
		groupbox grp_GlobalName "Global Name" width:190 height:40 align:#left offset:[-8,0]
		editText txt_NameAsset "" width:180 align:#left offset:[-5,-30]--[0,((grp_GlobalName.height * -1) -10)]
		button btn_SaveAsset "Save Asset" width:190 offset:[0,10]
			
		-- Load an Asset File, and set the edittext to its contents
		on btn_OpenAsset pressed do
		(
			initAssetFile = undefined
			initAssetFile =  getOpenFileName \
			types:"Asset Files (*.asset)|*.asset|"
				
			if initAssetFile != undefined do
			(
				initAssetGlobalName = (getINISetting initAssetFile "Global" "name")
				txt_NameAsset.text = initAssetGlobalName
			)
		)
			
		-- Save an asset file
		on btn_SaveAsset pressed do
		(
			initAssetFile = undefined
			initAssetFile =  getSaveFileName \
			types:"Asset Files (*.asset)|*.asset|"
				
			if initAssetFile != undefined do
			(
				initAssetGlobalName = (setINISetting initAssetFile "Global" "name" txt_NameAsset.text)
				DestroyDialog ROLL_AssetSwitch_Initalize
					
				-- Set name of object, after resetting
				selection[1].name = txt_NameAsset.text
			)
		)
			
		-- Launch the Asset Switch Initializer ( loads selected objects name into the global field )
		on ROLL_AssetSwitch_Initalize open do
		(
			if selection.count == 1 do
			(
				txt_NameAsset.text = selection[1].name
			)
		)
	)
	
	-- Create the rollout
	createdialog ROLL_AssetSwitch_Initalize 200 105
)
	
fn FN_help_About = 
(
	try(DestroyDialog ROLL_AssetSwitch_Help)catch()

	L1 = ("Asset Switch v" + (versionNumber as string) + "")
	L2 = "7/10/2025"
	L0 = "Major ovewhaul"
	L3 = "Removed xref"
	L4 = "Added Vray and Material improvements"

	global helptext = #(L1,L2,L0,L3,L4)
		
	rollout ROLL_AssetSwitch_Help "About"
	(
		multilistbox multi_help "" items:helpText height:6 width:190 pos:[5,5]
	)
		
	createdialog ROLL_AssetSwitch_Help 200 105
)
	
-- =======================
-- THE USER INTERFACE
-- =======================

rcMenu rc_MainMenu
(

	subMenu		"Setup"
	(
		menuItem	MI_setup_CreateAsset	"Create new Asset"
		menuItem	MI_setup_Initalize		"re-initalize .asset file"
		menuItem	MI_setup_RemoveInfo		"Remove Asset Information from selection"
	-- 		seperator Sep1
	)	
	subMenu		"Asset"
	(
		menuItem	MI_asset_Choose	"Choose Asset"
		menuItem	MI_asset_Explore	"Open Asset Directory"
	)

	subMenu		"Help"
	(
		menuItem	MI_help_About	"About"	
	)

	on MI_setup_CreateAsset picked do ( ASSET_Functions.CreateNewAsset_UI() )
		
	on MI_setup_Initalize picked do ( FN_setup_Initalize() )
	-- Loop through selected objects and remove any user defined properties that start with "Make_Asset_Filepath"
	on MI_setup_RemoveInfo picked do ( for i in 1 to selection.count do	( FN_setup_RemoveInfo selection[i] "MAKE_Asset_Filepath" ) )
		
	on MI_asset_Choose picked do ( FN_ChangeAsset() )
		
	on MI_asset_Explore picked do (	try( shelllaunch assetDir "") catch	( messagebox "no asset file loaded") )
		
	on MI_help_About picked do ( FN_help_About() )
	
)

rollout MAIN_AssetSwitchUI ("Asset Switch v" +(versionNumber as string) )
(
	groupbox grp_Asset "Asset" height:71 width:438 pos:[5,5]-- offset:[-8,8]
		button btn_chooseAsset "" height:25 width:420 align:#left offset:[0,((grp_Asset.height * -1) +12)]
		label lab_assetDir  " " style_sunkenedge:true align:#left width:378 height:16 offset:[1,0]
			button btn_copyAssetDir "C" width:18 height:18 align:#left offset:[382,-22]
			button btn_openAssetDir "..." width:18 height:18 align:#left offset:[401,-23]
			
	groupBox grp_materials "" width:438 offset:[-8,8] height:50
		checkbox chkbox_materials "Materials" offset:[0,((grp_materials.height * -1)-6)] checked:true align:#left
		dropdownlist ddl_matDropdown width:381 items:#(" -- No Materials Present --") align:#left offset:[0,0] 
			button btn_copyMatDir "C" width:18 height:18 align:#left offset:[382,-25]
			button btn_openMatDir "..." width:18 height:18 align:#left offset:[401,-23]
		
	groupBox grp_objects "" width:438 align:#left offset:[-8,13] height:75
		checkbox chkbox_objects "Objects" offset:[0,((grp_objects.height * -1)-6)] checked:true align:#left
		dropdownlist ddl_objDropdown width:381 items:#(" -- No Objects Present --") align:#left offset:[0,0]
			button btn_copyObjDir "C" width:18 height:18 align:#left offset:[382,-25]
			button btn_openObjDir "..." width:18 height:18 align:#left offset:[401,-23]
		label lab_versionDropdown "Ver:" offset:[0,3] align:#left
		dropdownlist ddl_versionDropdown width:361 items:#(" -- No Versions Present --") align:#left offset:[20,-22]
			button btn_copyVerDir "C" width:18 height:18 align:#left offset:[382,-25]
			button btn_openVerDir "..." width:18 height:18 align:#left offset:[401,-23]
		
	groupbox grp_Info "" offset:[-8,13] width:438 height:40 align:#left
		checkbox chkbox_info "Information" offset:[0,((grp_info.height * -1)-6)] checked:true 					-- TOGGLE FOR INFO PANEL
		label lab_importType "Import Module: N/A" align:#left offset:[3,-2]
		label lab_versionInfo_Filename "File name: N/A" align:#left offset:[3,0] visible:false
		label lab_versionInfo_Materialname "Material name: N/A"  align:#left offset:[3,0] visible:false
		label lab_versionInfo_Frames "Frame Range: N/A" align:#left offset:[3,0] visible:false
		label lab_versionInfo_Date "Date Created: N/A" align:#left offset:[3,0] visible:false
		bitmap bmp_preview filename:"" width:82 height:82 align:#right offset:[-5,-90] visible:false
		
	button btn_SwitchAsset "<< Switch Asset! >>" height:25 width:282 align:#right pos:[60,(MAIN_AssetSwitchUI.height - 30)]--offset:[100, 15] -- w 336
	button btn_Open_Publish_Center "Publish" height:25 width:55 align:#left offset:[-8,-41]
	checkbutton chkbtn_SwitchHold "Hold" height:25 width:40 align:#left offset:[329,-30] checked:false
	button btn_Revert "Revert" height:25 width:60 align:#left offset:[370,-30] enabled:false
	
-- ===================
-- EVENT HANDLERS
-- ===================

	on btn_Open_Publish_Center pressed do
	(
		doPublish = true
		nodeAsset = selection[1]

		if isvalidnode nodeAsset then -- TODO: How can this node be invalid to justify this check?
		(
			-- Changed this to use "Close_Enough" instead of ==, and also created a check for offsetscales
			if ((NOT (close_enough nodeAsset.scale[1] 1.0 100)) OR (NOT (close_enough nodeAsset.scale[2] 1.0 100)) OR (NOT (close_enough nodeAsset.scale[3] 1.0 100)) OR
			(NOT (close_enough nodeAsset.objectoffsetscale[1] 1.0 100)) OR (NOT (close_enough nodeAsset.objectoffsetscale[2] 1.0 100)) OR (NOT (close_enough nodeAsset.objectoffsetscale[3] 1.0 100))) 
			do
			(
				doPublish = ( queryBox @"Global is not at 100% scale, proceed with publish? THIS IS STRONGLY NOT RECCOMENDED!" )
			)
		)

		if doPublish do
		(
			global assetName
			global assetDir
			global nodeAsset
			try
			(
				getUserProp selection[1] "MAKE_Asset_Filepath"
				filein PublishCenterExecutable
			)
			catch
			(
				messagebox "Select a node with a valid asset definition"
			)
		)
	)
		
	-- Starts a switch operation, and holds first if told to
	on btn_SwitchAsset pressed do
		(
			-- Give it a good go
			try
			(
				disablesceneredraw()
				
				-- Perform max hold if told to
				if chkbtn_SwitchHold.checked == true do
				(
					holdMaxFile()
					btn_Revert.enabled = true
				)
					
				-- call the switch function
				FN_DoSwitch()
				SwtichEnd = timestamp()
				enablesceneredraw()
			)
			catch
			(
				enablesceneredraw()
				
				-- On crashed import, check if 'hold' was perfromed, if so, fetch
				if chkbtn_SwitchHold.checked == true then
				(
					Messagebox "Unhandled exception! attempting to revert scene..."
					try ( FN_Revert() )	catch (Messagebox "Unhandled exception, sorry! -David")
				)
				else
				(
					Messagebox "Unhandled exception, sorry! -Aaron"
				)
			)
		)
		
	-- Revert to scene / selection from before last switch
	on btn_Revert pressed do
	(
		FN_Revert()
	)
		
	-- Triggers on MATERIAL selection, from its dropdown
	on ddl_matDropdown selected arg do
	(
		curMaterial = ddl_matDropdown.items[arg]
		FN_UiInformationUpdate()
	)
	
	-- Triggers on OBJECT selection, from its dropdown		
	on ddl_objDropdown selected arg do
	(
		curType = ddl_ObjDropdown.items[arg]
		FN_UiUpdate_Objects()
	)
		
	-- Triggers on VERSION selection, from its dropdown
	on ddl_versionDropdown selected arg do
	(
		curVersion = ddl_versionDropdown.items[arg]
		curVersionFile = (assetDir + @"Publish\" + curType + @"\" + curVersion + @"\")
			
		FN_importTypeTest curVersionFile
		FN_UiInformationUpdate()
	)
		
	-- Choose an Asset: set the type and update interested UI items
	on btn_chooseAsset pressed do
	(
		FN_ChangeAsset()
	)
		
	-- Enable / Disable the Materials dropdown on the checkbox toggle
	on chkbox_materials changed state do (ddl_matDropdown.enabled = state)
		
	-- Enable / Disable the Object and Version dropdown on the checkbox toggle
	on chkbox_objects changed state do
	(
		ddl_objDropdown.enabled = state
		lab_versionDropdown.enabled = state
		ddl_versionDropdown.enabled = state
	)
		
	-- When the Copy button is pressed, copy file path of the asset to the clipboard
	on btn_copyAssetDir pressed do (setclipboardText assetDir)
	on btn_copyMatDir pressed do (setclipboardText (assetDir + @"\Publish\Material"))
	on btn_copyObjDir pressed do (setclipboardText (assetDir + @"Publish\" + curType + @"\"))
	on btn_copyVerDir pressed do (setclipboardText (assetDir + @"Publish\" + curType + @"\"+ curVersion + @"\") )
		
	-- When the Open Directory button is pressed, open the file path in windows explorer
	on btn_openAssetDir pressed do(shelllaunch assetDir "")
	on btn_openMatDir pressed do(shelllaunch (assetDir + @"\Publish\Material") "")
	on btn_openObjDir pressed do(shelllaunch (assetDir + @"Publish\" + curType + @"\") "")
	on btn_openVerDir pressed do(shelllaunch (assetDir + @"Publish\" + curType + @"\"+ curVersion + @"\") "")

	-- When the Info Group Checkbox is toggled hide/unhide the contents of the information group
	on chkbox_info changed state do(FN_UiToggleInformationTest state)
	
	-- This is to rearrange and distribute the UI elements. A Rewrite of this whole tool can make this thing more streamlined
	on MAIN_AssetSwitchUI resized arg do
	(
		btn_SwitchAsset.pos = [60,(MAIN_AssetSwitchUI.height - 30)]
		btn_Open_Publish_Center.pos = [5,(MAIN_AssetSwitchUI.height - 30)]
		chkbtn_SwitchHold.pos = [342,(MAIN_AssetSwitchUI.height - 30)]
		btn_Revert.pos = [383,(MAIN_AssetSwitchUI.height - 30)]
	)


	-- When the window is opened, perform a selection check, and register the selection check callback
	on MAIN_AssetSwitchUi open do
	(
		FN_UiToggleInformationTest chkbox_info.checked
		FN_UiUpdate_SelectionCheck()
		callbacks.addScript #selectionSetChanged "FN_Callback_SelectionChange()" id:#AssetSwitchCallbackID001
		print "Selection Check callback registered"
	)
	
	-- When the window is closed, remove the selection check callback
	on MAIN_AssetSwitchUI close do
	(
		callbacks.removeScripts #selectionSetChanged id:#AssetSwitchCallbackID001
		print "Selection Check callback removed"
	)
)
	
createdialog MAIN_AssetSwitchUI 450 300 menu:rc_MainMenu style:#(#style_titlebar, #style_border, #style_sysmenu)
--clearListener()