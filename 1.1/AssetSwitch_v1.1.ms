--*****************************************************
--Aaron Dabelow, theonlyaaron@gmail.com
--*****************************************************
-- HISTORY:
--- version 1.0 : 02.17.2014  >> Created by Aaron Dabelow
--- version 1.1 : 04.29.2014  >> Publish selected bug fixed
--					 >> Publish material added
--					 >> About window fixed
--*****************************************************

-- clearListener()
try(DestroyDialog MAIN_AssetSwitchUI)catch()

global MAIN_AssetSwitchUI
global assetFile = undefined
global assetName = undefined
global assetDir = undefined
global curTypeImporter = undefined

global curMaterial = undefined
global curMaterialFile = undefined

global curType = undefined
global curVersion = undefined
global curVersionFile = undefined

global nodeAsset = undefined  -- The target node
global switchObjectsHandleArray = undefined -- The objects selected when a switch is performed (used for fetching)

global FN_DoSwitch_Type
global FN_Callback_SelectionChange
global FN_setup_Initalize

versionNumber = 1.1

-- =========================================
-- FUNCTIONS FOR DEALING WITH FILES
-- =========================================

-- Get the filetype of the files in the location
fn FN_importTypeTest arg = --arg: the folder to look at the filetypes in
	(
	importType = undefined
-- 	clearlistener()
	print arg
		
	-- .MAX Test
	curFiles = getfiles (arg + @"\*.max")
	if curFiles.count > 0
	then
		(
		curTypeImporter = 1
		curMaterialFile
		MAIN_AssetSwitchUI.btn_SwitchAsset.enabled = true
		return "Max File Merge"
		)
	else()
		
	-- .VRMESH Test
	curFiles = getfiles (arg + @"\*.vrmesh")
	if curFiles.count > 0
	then
		(
		curTypeImporter = 2
		MAIN_AssetSwitchUI.btn_SwitchAsset.enabled = true
		return "V-Ray Mesh Loader"
		)
	else()

	-- .XMeshTest
	curFiles =  getfiles (arg + @"\*.ms")
	if curFiles.count > 0
	then
		(
		curTypeImporter = 3
		MAIN_AssetSwitchUI.btn_SwitchAsset.enabled = true
		return "XMesh Loader"
		)
	else()

	-- PRT Test
	curFiles =  getfiles (arg + @"\*.prt")
	if curFiles.count > 0
	then
		(
		curTypeImporter = 4
		MAIN_AssetSwitchUI.btn_SwitchAsset.enabled = true
		return "PRT Loader"
		)
	else()

	-- Point Cache Test
	curFiles =  getfiles (arg + @"\*.mc")
	if curFiles.count > 0
	then
		(
		curTypeImporter = 5
		MAIN_AssetSwitchUI.btn_SwitchAsset.enabled = true
		return "Point Cache Modifer"
		)
	else()
		
	curTypeImporter = undefined
	MAIN_AssetSwitchUI.btn_SwitchAsset.enabled = false
	return "no valid files found"
	)
	
-- gets all of the .mtl files in the assedts directory and returns them as an array
fn FN_GetMtlsInDIr =
	(
	matArr = getfiles (assetDir + @"Publish\Material\*.mat")
	matNames = #()
	for i in 1 to matArr.count do (join matNames #((getFilenameFile matArr[i])))
	if matNames.count == 0 then (matNames = #(" No Materials Found"))else()
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
		if curFolder[1] == "Material"
		then()
		else( join typeNames curFolder)
		)
	if typeNames.count == 0 then (typeNames = #(" No Types Found"))else()
	curType = typeNames[1]
	return typeNames
	)
	
-- gets all of the 'version folders' in the assedts directory and returns them as an array
fn FN_GetVersionsInDir = -- arg: curType
	(
	try(
		versionArr = getDirectories  (assetDir + @"Publish\" + curType + "\*")	
		versionNames = #()
		for i in 1 to versionArr.count do
			(
			foldersArr = filterstring versionArr[i] @"\"
			curFolder = #(foldersArr[foldersArr.count])
			join versionNames curFolder
			)
		if versionNames.count == 0 then (versionNames = #(" No Versions Found"))else()
		curVersion = versionNames[1]
		return versionNames
		)
	catch(return #())
	)
	
-- Changes the asset file and redefines all of the global asset variables used by other functions
fn FN_ChangeAsset =
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
	try(
		curMaterial = MAIN_AssetSwitchUI.ddl_matDropdown.selected
		curMaterialFile = (assetDir + @"Publish\Material\" + curMaterial + ".mat")
		)
	catch()
		
	try(
		curType = MAIN_AssetSwitchUI.ddl_objDropdown.selected
		curVersion = MAIN_AssetSwitchUI.ddl_versionDropdown.selected
		curVersionFile = (assetDir + @"Publish\" + curType + @"\" + curVersion + @"\")	
		
		FN_importTypeTest curVersionFile
		)
	catch()
		
	-- Set the bitmap image
	bmp_PreviewFilename = (substring assetFile 1 (assetFile.count - 5) + "jpg")
	if (doesFileExist bmp_PreviewFilename)
	then
		(
		MAIN_AssetSwitchUI.bmp_preview.filename = bmp_PreviewFilename
		MAIN_AssetSwitchUI.bmp_preview.visible = true
		)
	else
		(
		MAIN_AssetSwitchUI.bmp_preview.visible = false
		)
		
	-- Set the material file
-- 		curMaterialFile = (assetDir + @"Publish\Material\" + curMaterial + ".mat")
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
		1: (
			curFileExtension =@"*.max"
			targetFrameRangeparsed = "unknown"
			)
		-- V-Ray Mesh Import
		2: (
			curFileExtension =@"*.vrmesh"
			targetFrameRangeparsed = "unknown"
			)
		-- XMesh Import
		3: (
			curFileExtension =@"*.ms"
			
			XMSH_FileArr = (getfiles (searchDir + @"*.xmesh"))
			startFile = getfilenamefile XMSH_FileArr[1]
			endFile = getfilenamefile XMSH_FileArr[(XMSH_FileArr.count)]
			startVal = ((substring startFile (startFile.count - 3) startFile.count) as integer)
			endVal = ((substring endFile (endFile.count - 3) endFile.count) as integer)
			targetFrameRange = #(startVal,endVal)
			targetFrameRangeparsed = ((targetFrameRange[1] as string)+" to "+(targetFrameRange[2] as string))
			)
		-- PRT Importer
		4: (
			curFileExtension =@"*.prt"
			
			PRT_FileArr = (getfiles (searchDir + @"*.prt"))
			startFile = getfilenamefile PRT_FileArr[1]
			endFile = getfilenamefile PRT_FileArr[(PRT_FileArr.count)]
			startVal = ((substring startFile (startFile.count - 3) startFile.count) as integer)
			endVal = ((substring endFile (endFile.count - 3) endFile.count) as integer)
			targetFrameRange = #(startVal,endVal)
			targetFrameRangeparsed = ((targetFrameRange[1] as string)+" to "+(targetFrameRange[2] as string))
			)
		-- Point Cache Importer
		5: (
			targetFrameRangeparsed = "unknown"
			-- todo:
			)
		)
		
	FileArr = getfiles ((assetDir + @"Publish\" + curType + @"\" + curVersion + @"\") + curFileExtension)
	
	if FileArr.count == 0
	then(MAIN_AssetSwitchUI.lab_versionInfo_Filename.text = ("File name: N/A"))
	else(
		lastFile = fileArr[fileArr.count]
		lastFileSS = ("..." + (substring lastFile (lastFile.count - 43) 99999))
		MAIN_AssetSwitchUI.lab_versionInfo_Filename.text = ("File name: " + lastFileSS)
		)
		
	-- Set Date created
	try(
		lastFileDate = getFileModDate lastFile
		MAIN_AssetSwitchUI.lab_versionInfo_Date.text = ("Date modified: "+ lastFileDate)
		)
	catch(MAIN_AssetSwitchUI.lab_versionInfo_Date.text = ("Date modified: N/A"))
		
		
	-- Set the UI to match collected Data
	try(
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
	
	curVersion = getUserProp selection[1] "asset_file_curVersion"
		
	curVersionArr =	FN_GetVersionsInDir()
	for i in 1 to curVersionArr.count do
		(
		if curVersion == curVersionArr[i]
		then (MAIN_AssetSwitchUI.ddl_versionDropdown.selection = i)else ()
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
		
	curMaterial = getUserProp selection[1] "asset_file_curMaterial"
	curType = getUserProp selection[1] "asset_file_curType"
	curVersion = getUserProp selection[1] "asset_file_curVersion"
		
	for i in 1 to curMaterialsArr.count do
		(
		if curMaterial == curMaterialsArr[i]
		then (MAIN_AssetSwitchUI.ddl_matDropdown.selection = i)else ()
		)
		
	for i in 1 to curTypesArr.count do
		(
		if curType == curTypesArr[i]
		then (MAIN_AssetSwitchUI.ddl_objDropdown.selection = i)else ()
		)
	
	curVersionArr =	FN_GetVersionsInDir()
	for i in 1 to curVersionArr.count do
		(
		if curVersion == curVersionArr[i]
		then (MAIN_AssetSwitchUI.ddl_versionDropdown.selection = i)else ()
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
-- 	clearListener()
	
	-- Test if there are any objects selected, and update the ui if there are things to update it with
	if ((selection as array).count) == 0
	then(FN_UiReset())
	else
		(
		-- If objects are selected, Parse and test them, on vailid selection, update ui
		selectionArray = (selection as array)
		assetArray = #()
		failCase = ""
		
		-- Read the 'asset_file' property from all objects and store it in 'assetArray'
		for i in 1 to selectionArray.count do
			(
			-- reads the 'asset_file' property from the object, and returns it, if there is no stored property, returns 'invald' instead
			curAssetFile = (getUserProp selectionArray[i] "asset_file")
				
			if curAssetFile == undefined
			then(failCase = "invalid")
			else(join assetArray #(curAssetFile))
			)
			
		-- Check 'assetArray' for clashing, or missing asset definitions
		for i in 1 to assetArray.count do
			(
			if assetArray[1] == assetArray[i]
			then()
			else(failCase = "mismatch")
			)
			
		print assetArray
		
		-- Calls the correct UI update based on 'failCase'
		case failCase of
			(
			"":(
				assetFile = (getUserProp selectionArray[1] "asset_file")
				assetName = try((getFilenameFile assetFile))catch()
				assetDir = try((getFilenamePath assetFile))catch()
				
				FN_UiUpdate()
				
				-- Attempt to set the VERSION dropdown based off of a stored value ( this is the gross hack to get this thing into place..... I am ashamed )
				try
					(
					curVersion_temp = getUserProp selection[1] "asset_file_curVersion"
					curVersionArr =	FN_GetVersionsInDir()
					
					-- Loop throught the possible choices and set it if the prefferd choice is there
					for i in 1 to curVersionArr.count do
						(
						if curVersion_temp == curVersionArr[i]
						then (MAIN_AssetSwitchUI.ddl_versionDropdown.selection = i)else ()
						)
						
					curMaterialFile = (assetDir + @"Publish\Material\" + curMaterial + ".mat")
					curVersionFile = (assetDir + @"Publish\" + curType + @"\" + curVersion + @"\")
					)catch()
					
					
				
-- 				curMaterialFile = (assetDir + @"Publish\Material\" + curMaterial + ".mat")
-- 				curVersionFile = (assetDir + @"Publish\" + curType + @"\" + curVersion + @"\")
					
					
				FN_UiInformationUpdate()
					
				)
			"invalid":(FN_UiWarnInvalid())
			"mismatch":(FN_UiWarnMismatch())
			)
		)	
	)
	
-- Callback trigger for selection change
fn FN_Callback_SelectionChange =
	(
	FN_UiUpdate_SelectionCheck()
	clearlistener()
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
	if arg == true
	then(
		MAIN_AssetSwitchUI.height = 362
		MAIN_AssetSwitchUI.grp_Info.height = 110
		FN_UiToggleInformation true
		)
	else(
		MAIN_AssetSwitchUI.height = 292
		MAIN_AssetSwitchUI.grp_Info.height = 40
		FN_UiToggleInformation false
		)
	)
	
-- ================================
-- FUNCTIONS FOR IMPORTING!!!
-- ================================
	
-- Function for recursivly selecting all of the children of an inital object
fn FN_collectAllChildren obj includeParent:true =
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

	-- return array containing children
	allChildren
	)	
	
-- Load and apply the chosen material
fn	FN_DoSwitch_Material arg arg2 = -- arg: the material file | arg2: the node to do the switch on
	(
	nodeAsset = arg2
	curMaterialFile = arg
		
	-- Test to see if there is a file
	if (doesfileexist curMaterialFile)
	then 
		(
		for i in 1 to currentMaterialLibrary.count do(deleteItem currentMaterialLibrary 1)
		loadMaterialLibrary curMaterialFile
		theMaterial = currentMaterialLibrary[1]
				
		-- Collect the entire family
		theObjects = (FN_collectAllChildren nodeAsset includeParent:false)

		-- Apply the material to the objects children
		for i in 1 to theObjects.count do
			(
			theObjects[i].material = theMaterial
			)
		)
	else()
	)
	
fn	FN_DoSwitch_Standard arg arg2= -- arg: the filepath to import | arg2: the node to do the switch on
	(
	-- set some stuff up
	nodeAsset = arg2
	heroName = nodeAsset.name
	allObjectsArr = (objects as array)
	nameDuplicatesArr = #()

	-- Put all objects named the same in an array
	for i in 1 to allObjectsArr.count do
		(
		if allObjectsArr[i].name == heroName
		then(join nameDuplicatesArr #(allObjectsArr[i]))		
		else()
		)
	
	-- Set all of the names to HERONAME_temp, except the chosen node
	for i in 1 to nameDuplicatesArr.count do (nameDuplicatesArr[i].name = (heroName + "_temp"))
	nodeAsset.name = heroName
		
	-- Load objects from the scenefile into an array
	mergeFile = arg
	mergeObjects = getmaxfileobjectnames mergeFile
		
	try(
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
	Catch(messagebox ("No objects with the name '" + heroName + "' were found in the target asset file. Please check your target file and verify the naming is correct."))
	)

-- Load in the chosen vray proxy	
fn	FN_DoSwitch_vRay arg arg2 = -- arg: the filepath to import | arg2: the node to do the switch on
	(
	nodeAsset = arg2
	
	-- Collect all the children of the nodeAsset, and delete them
	deleteMe = (FN_collectAllChildren nodeAsset includeParent:false)
	delete deleteMe
		
	newProxy = VRayProxy()
	newProxy.display = 3
	newProxy.wirecolor = black
	newProxy.transform = nodeAsset.transform
	newProxy.parent = nodeAsset
	newProxy.filename = arg
	newProxy.name = ((getFilenameFile arg) + "_VRMESH" )
	)

-- Load in the xMesh file	
fn	FN_DoSwitch_xMesh arg arg2 = -- arg: the filepath to import | arg2: the node to do the switch on
	(
	nodeAsset = arg2
		
	-- Collect all the children of the nodeAsset, and delete them
	deleteMe = (FN_collectAllChildren nodeAsset includeParent:false)
	delete deleteMe
		
 	filein arg
	newXMESH = selection[1]
	clearSelection()
	newXMESH.wirecolor = black
	newXMESH.transform = nodeAsset.transform
	newXMESH.parent = nodeAsset
	newXMESH.name = ((substring (getFilenameFile arg) 12 9999) + "_XMESH" )
	)
	
fn	FN_DoSwitch_PRT arg arg2= -- arg: the filepath to import | arg2: the node to do the switch on
	(
	nodeAsset = arg2
		
	-- Collect all the children of the nodeAsset, and delete them
	deleteMe = (FN_collectAllChildren nodeAsset includeParent:false)
	delete deleteMe
		
	-- Create the new Prt Loader and set its common properties
	newPRTLoader = KrakatoaPRTLoader ViewportParticleColorSource:4 pos:[-20.9197,-31.3314,0] isSelected:off iconSize:50 gizmoBoxX:100 gizmoBoxY:100 gizmoBoxZ:100
	newPRTLoader.fileList.count = 1
	newPRTLoader.fileList[1] = arg
	newPRTLoader.fileListFlags.count = 1
	newPRTLoader.fileListFlags[1] = 3
	newPRTLoader.wirecolor = black
	newPRTLoader.transform = nodeAsset.transform
	newPRTLoader.parent = nodeAsset
		
	-- read and set the display range, and get the frame range from the files
	newPRTLoader.limitToRange = on
	PRT_FileArr = (getfiles ((getfilenamepath arg) + @"\*.prt"))
	startFile = getfilenamefile PRT_FileArr[1]
	endFile = getfilenamefile PRT_FileArr[(PRT_FileArr.count)]
	startVal = ((substring startFile (startFile.count - 3) startFile.count) as integer)
	endVal = ((substring endFile (endFile.count - 3) endFile.count) as integer)
	newPRTLoader.rangeStartFrame = startVal
	newPRTLoader.rangeEndFrame = endVal
		
	-- Calculate renaming
	s = (getFilenameFile arg) 	-- creates a string from the filename of the loaded file
	ss = substring s 5 9999		-- trinms off the "PRT_" at the beginning of the fileneame
	sa = filterstring ss @"_"	-- breaks it up into an array of strings broken up by the character "_"
	ns=""								-- creates a new empty string
	if sa.count > 2 then (sc = (sa.count - 2))else(sc = 1)	-- sets the number of elements from the filtered array to use, differing cases for diferent length arrays, this removes the last bit of garbage "part 1 of 2" etc...
	for i in 1 to sc do(ns = (ns + sa[i] + "_"))						-- stitches back together the relevant parts of the string, with the underscores put back in
	newPRTLoader.name = (ns + "PRT")								-- adds the "PRT" onto the end, and assigns it to the object
		
	-- Toggles a display property to make the particles show up in viewport
	newPRTLoader.ignoreMaterial = true
	newPRTLoader.ignoreMaterial = false
	)
	
-- Select the correct importer, and find the filename/type for the selected importer
fn	FN_DoSwitch_Type arg1 arg2 arg3 arg4 = -- arg1: the type of import to do | arg2: the filepath to import | arg3: the node to do the switch on | arg4: import (true) return name (false)
	(
	case arg1 of
		(
		-- standard Import
		1: (
			maxFileArr = getfiles (arg2 + @"*.max")
			parsedFile = (maxFileArr[maxFileArr.count])
			if arg4 == true
			then(FN_DoSwitch_Standard parsedFile arg3)
			else(return parsedFile)
			)
		-- V-Ray Mesh Import
		2: (
			vrayMeshFileArr = getfiles (arg2 + @"*.vrmesh")
			parsedFile = (vrayMeshFileArr[vrayMeshFileArr.count])
			if arg4 == true
			then(FN_DoSwitch_vRay parsedFile arg3)
			else(return parsedFile)
			)
		-- XMesh Import
		3: (
			xMeshFileArr = getfiles (arg2 + @"*.ms")
			parsedFile = (xMeshFileArr[xMeshFileArr.count])
			if arg4 == true
			then(FN_DoSwitch_xMesh parsedFile arg3)
			else(return parsedFile)
			)
		-- PRT Importer
		4: (
			PRT_FileArr = getfiles (arg2 + @"*.prt")
			parsedFile = (PRT_FileArr[PRT_FileArr.count])
			if arg4 == true
			then(FN_DoSwitch_PRT parsedFile arg3)
			else(return parsedFile)
			)
		-- Point Cache Importer
		5: (
			
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
	for i in 1 to switchObjectsHandleArray.count do (selectmore (maxOps.getNodeByHandle switchObjectsHandleArray[i]))
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
	curVersionFile = (assetDir + @"Publish\" + curType + @"\" + curVersion + @"\")
	switchObjectsArray = (selection as array)
	switchObjectsHandleArray = #()
	assetGlobalName = (getINISetting assetFile "Global" "name")
		
	-- Set selection as inode handles for use in fetching, and store the currently chosen settings
	for i in 1 to switchObjectsArray.count do
		(
		setUserProp switchObjectsArray[i] "asset_file_curMaterial" curMaterial
		setUserProp switchObjectsArray[i] "asset_file_curType" curType
		setUserProp switchObjectsArray[i] "asset_file_curVersion" curVersion
			
		switchObjectsHandle = switchObjectsArray[i].inode.handle
		join switchObjectsHandleArray #(switchObjectsHandle)
		)
		
	-- Loop through switch objects, and perform selected switching
	for i in 1 to switchObjectsArray.count do
		(
		-- Test for if an object switch is desired, and do it if so
		if MAIN_AssetSwitchUI.chkbox_objects.checked == true
		then (
			switchObjectsArray[i].name = assetGlobalName
			
			print curTypeImporter
			print curVersionFile
			
			FN_DoSwitch_Type curTypeImporter curVersionFile switchObjectsArray[i] true
			)
		else()
		
		-- Test for if a material switch is desired, and do it if so			
		if MAIN_AssetSwitchUI.chkbox_materials.checked == true
		then 
			(
			print curMaterialFile
			FN_DoSwitch_Material curMaterialFile switchObjectsArray[i]
			)
		else()
		)
	
	-- Reset the selection to match what it was at the beginning of the switch
	clearselection()
	for i in 1 to switchObjectsHandleArray.count do (selectmore (maxOps.getNodeByHandle switchObjectsHandleArray[i]))
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
fn FN_publish_Selected =
	(
	if selection.count == 1 
	then(
		if assetFile == undefined
		then(messagebox " no asset file loaded ")
		else
			(
			
			saveArr = FN_collectAllChildren selection[1] includeParent:true
			saveLocation = (assetDir + @"\Publish\")

			if (doesFileExist saveLocation)
			then
				( -- Save Dialog for VALID save location
				saveName = getSaveFileName \
				filename:saveLocation \
				types:"3ds max scene file (*.max)|*.max|"
				)
			else( -- Save Dialog for INVALID save location
				saveName = getSaveFileName\
				types:"3ds max scene file (*.max)|*.max|")

			-- If a valid filename was chosen, and the user did not cancel out, proceed to save
			if saveName == undefined
			then ()
			else(
				saveNodes saveArr saveName
				messagebox (saveName + " Published successfully!")
				)
			
			)
		)
	else( messagebox " you may only export by selecting a (1) global, the children will be exported automatically ")
	)
	
fn FN_publish_Material =
	(
		clearlistener()
		
		if selection.count != 1
		then(messagebox "Select exactly 1 object")
		else
		(
			theObj = selection[1]
			theMaterial = theObj.material
			
			-- Clear the temporary library and add the current material to it
			for i in 1 to currentMaterialLibrary.count do(deleteItem currentMaterialLibrary 1)
			loadDefaultMatLib()
			append currentMaterialLibrary theMaterial
			
			-- Get the save filename, and save the temporary library
			curFileName = undefined
			curFileName = getSaveFileName types:"Material(*.mat)|*.mat"
			if curFileName != undefined then
			(
				saveMaterialLibrary curFileName
				setUserProp selection[1] "multiMaterial_file" curFileName
			)else()
		)
	)
	
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
			
		if initAssetFile == undefined
		then()
		else
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
			
		if initAssetFile == undefined
		then()
		else
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
		if selection.count == 1
		then (txt_NameAsset.text = selection[1].name)
		else()
		)
	)
	
	-- Create the rollout
	createdialog ROLL_AssetSwitch_Initalize 200 105
	)
	
fn FN_help_About = 
	(
	try(DestroyDialog ROLL_AssetSwitch_Help)catch()

	L1 = ("Asset Switch v" + (versionNumber as string) + "")
	L2 = "4/29/2014"
	L0 = ""
	L3 = "Publish obj tool fixed"
	L4 = "Publish material added"

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
		menuItem	MI_setup_Initalize	"Initalize .asset file"
		menuItem	MI_setup_RemoveInfo	"Remove Asset Information from selection"
-- 		seperator Sep1
		)	
	subMenu		"Asset"
		(
		menuItem	MI_asset_Choose	"Choose Asset"
		menuItem	MI_asset_Explore	"Open Asset Directory"
		)
	subMenu		"Publish"
		(
		menuItem	MI_publish_Selected	"Publish object"	
		menuItem	MI_publish_Selected_Material	"Publish material"	
		)
	subMenu		"Help"
		(
		menuItem	MI_help_About	"About"	
		)
	
	on MI_setup_Initalize picked do
		(
-- 		print "== MI_setup_Initalize =="
		FN_setup_Initalize()
			
		)
		
	on MI_setup_RemoveInfo picked do
		(
-- 		print "== MI_setup_RemoveInfo =="
		
		-- Loop through selected objects and remove any user defined properties that start with "asset_file"
		for i in 1 to selection.count do
			(
			FN_setup_RemoveInfo selection[i] "asset_file"
			)
			
		)
		
	on MI_asset_Choose picked do
		(
-- 		print "== MI_asset_Choose =="
		FN_ChangeAsset()
			
		)
		
	on MI_asset_Explore picked do
		(
-- 		print "== MI_asset_Explore =="
		
		try(
			shelllaunch assetDir ""
			)
		catch
			(
			messagebox "no asset file loaded"
			)
			
		)
	
	on MI_publish_Selected picked do
		(
-- 		print "== MI_publish_Selected =="
		FN_publish_Selected()
			
		)
		
	on MI_publish_Selected_Material picked do
		(
-- 		print "== MI_publish_Material =="
		FN_publish_Material()
			
		)
		
	on MI_help_About picked do
		(
		FN_help_About()
			
		)
	
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
		
	button btn_SwitchAsset "<< Switch Asset >>" height:25 width:336 align:#left offset:[-8,15]
	checkbutton chkbtn_SwitchHold "Hold" height:25 width:40 align:#left offset:[329,-30] checked:true
	button btn_Revert "Revert" height:25 width:60 align:#left offset:[370,-30] enabled:false
	
-- ===================
-- EVENT HANDLERS
-- ===================
		
	-- Starts a switch operation, and holds first if told to
	on btn_SwitchAsset pressed do
		(
		-- Give it a good go
		try(
			disablesceneredraw()
			
			-- Perform max hold if told to
			if chkbtn_SwitchHold.checked == true
			then(
				holdMaxFile()
				btn_Revert.enabled = true
				)
			else()
				
			-- call the switch function
			FN_DoSwitch()
				
			enablesceneredraw()
			)
		catch
			(
			enablesceneredraw()
			
			-- On crashed import, check if 'hold' was perfromed, if so, fetch
			if chkbtn_SwitchHold.checked == true
			then(
				Messagebox "Unhandled exception! attempting to revert scene..."
				FN_Revert()
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
		print curMaterial
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
	on btn_chooseAsset pressed do(FN_ChangeAsset())
		
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
	on btn_copyMatDir pressed do (setclipboardText (assetDir + "\Publish\Material"))
	on btn_copyObjDir pressed do (setclipboardText (assetDir + @"Publish\" + curType + @"\"))
	on btn_copyVerDir pressed do (setclipboardText (assetDir + @"Publish\" + curType + @"\"+ curVersion + @"\") )
		
	-- When the Open Directory button is pressed, open the file path in windows explorer
	on btn_openAssetDir pressed do(shelllaunch assetDir "")
	on btn_openMatDir pressed do(shelllaunch (assetDir + "\Publish\Material") "")
	on btn_openObjDir pressed do(shelllaunch (assetDir + @"Publish\" + curType + @"\") "")
	on btn_openVerDir pressed do(shelllaunch (assetDir + @"Publish\" + curType + @"\"+ curVersion + @"\") "")

	-- When the Info Group Checkbox is toggled hide/unhide the contents of the information group
	on chkbox_info changed state do(FN_UiToggleInformationTest state)
	
	-- When the main rollout windows size is changed, reposition the 'switch asset' buttons along the bottom
	on MAIN_AssetSwitchUI resized arg do
		(
		btn_SwitchAsset.pos = [5,(MAIN_AssetSwitchUI.height - 30)]
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
clearListener()