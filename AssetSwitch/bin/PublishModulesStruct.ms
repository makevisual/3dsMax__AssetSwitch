--*****************************************************
--Aaron Dabelow, theonlyaaron@gmail.com
--*****************************************************
-- HISTORY:
--- version 1.0 : 08.05.2014  	>> Created by Aaron Dabelow
--- version 1.4 : 01.16.2015  	>> Xmesh publish ignores non-renderable geometry
--					>> vrMesh publish ignores non-renderable geometry
--					>> max optimized publish ignores non-renderable geometry
--*****************************************************

global ASSET_PublishFunctions
struct ASSET_PublishFunctions
(


	-- Returns the asset switch .ini file, making one if none exists
	function INIget =
	(
		INIfile = ((getdir #userscripts) + @"\asset_switch.ini")
		
		if doesfileexist INIfile
		then (return INIfile)
		else 
		(
			newINI = createFile INIfile
			close newINI
			return INIfile
		)
	),
	
	-- Returns the log file as string
	function LOGget =
	(
		LOGfile = ((getdir #userscripts) + @"\asset_switch_log.txt")
		return LOGfile
	),
	
	-- Clear out the old log and making a new one
	function LOGclear =
	(
		LOGfile = ASSET_PublishFunctions.LOGget()
		try deleteFile (LOGfile)catch()
		logFilestream = createfile LOGfile
		close logFilestream
	),
	
	-- Write to the log file
	function LOGwrite arg_String = -- arg_String: the string to write to the file
	(
		LOGfile = ASSET_PublishFunctions.LOGget()
		logFilestream = (openfile LOGfile mode:"a+")
		print arg_String to:logFilestream
		close logFilestream
	),
	
	-- Open the latest log file
	function LOGopen =
	(
		fileString = ASSET_PublishFunctions.LOGget()
		shelllaunch "notepad.exe" fileString
	),
	
	-- Function for recursivly selecting all of the children of an inital object
	function CollectAllChildren obj includeParent:true MeshObjOnly:false =
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
	),
	-- Returns an array of meshes, that have been collapsed
	function ReduceToMeshes arg_Arr = 
	(
		-- change the command panel to create mode, for performance
		max create mode 

		-- prepare the base object, and delete set
		resultArr = #()
		-- loop through the other objects in the array
		for i in 1 to (arg_Arr.count) do
		(
			ObjClass = (classof arg_Arr[i])
			if (((classof ObjClass) == geometryclass) AND (ObjClass != Biped_Object) AND (ObjClass != BoneGeometry) AND (ObjClass != HubObject)
				(ObjClass != CATBone)) do
			(
				-- This method creates and instance of the object, and then collapses it to a mesh before passing the array to be exported
				InstanceObj = instance arg_Arr[i]
				InstanceObj.name = arg_Arr[i].name
				collapse.setDoBool false
				collapse.setOutputType #Mesh
				collapse.setCollapseTo #Single
				collapse.doCollapse InstanceObj
				--MesherObj = Mesher pick:arg_Arr[i] transform:arg_Arr[i].transform name:arg_Arr[i].name parent:arg_Arr[i].parent material:arg_Arr[i].material
				append resultArr InstanceObj
			)
		)
		return resultArr
	),

	function FindChildrenMaterials ChildrenNodes &MatCollection =
	(
		MaterialMapArray = #()
		for i = 1 to ChildrenNodes.count do
		(
			if (ChildrenNodes[i].material != undefined) do
			(
				MatIndex = (findItem MatCollection ChildrenNodes[i].material)
				if MatIndex != 0 then -- Material already presend in the Array
				(
					append MaterialMapArray[MatIndex] ChildrenNodes[i].name
				)
				else -- Material not present in the Array
				(
					append MatCollection ChildrenNodes[i].material
					NewIndex = MaterialMapArray.count + 1
					MaterialMapArray[NewIndex] = #()
					append MaterialMapArray[NewIndex] ChildrenNodes[i].name
				)
			)
		)
		return MaterialMapArray
	),
	-- Returns a material applied to selected object, or is children
	function FindTheMaterial arg_path =
	(

		MatCollection = #()
		AllNodesArray = ASSET_PublishFunctions.CollectAllChildren nodeAsset includeParent:true
		MaterialMapArray = FindChildrenMaterials AllNodesArray MatCollection
		setinisetting ((substring arg_path[1] 1 (arg_path[1].count - 4)) + ".matmap") "MaterialNodeMap" "MaterialMapArray" (MaterialMapArray as string)
		-- If there is more than one material collected 
		if MatCollection.count > 1 then
		(
			if MatCollection[1] == nodeAsset.material then
			(
				-- Global has a material, but children have different materials
				GlobalChildrenConflict = (getINISetting (ASSET_PublishFunctions.INIget()) "MaterialFile" "GlobalChildrenConflict")
				case GlobalChildrenConflict of
				(
					-- Defaults to Use only Global's material.
					"1":
					(
						MatCollection = (#(nodeAsset.material))
						return MatCollection
					)
					-- Defaults to Use the Global and children's materials.
					"2":
					(
						return MatCollection
					)
					-- Defaults to open a yesNoCancelBox
					"3":
					(
						IgnoreChilrend = yesNoCancelBox ("The Asset's Global and children nodes have different" +
						"\nmaterials. It is RECOMMENDED to cancel and use the" +
						"\nMultSubCreator tool on MakeToolbox to unify them." +
						"\n\nIgnore children's material on material asset creation?" +
						"\n\nYES - Use only Global's material." +
						"\nNO  - Use the Global and children's materials." +
						"\nCANCEL - Cancels publishing.") title:"AssetSwitch - Material Conflict"
						case IgnoreChilrend of
						(
							(#yes):
							(
								MatCollection = (#(nodeAsset.material))
								return MatCollection
							)
							(#no):
							(
								return MatCollection
							)
							(#cancel):
							(
								return (#())
							)
						)
					)
				)
			)
			else
			(
				-- Global has no material but some children do and they are not the same material across them
				ChildrenConflict = (getINISetting (ASSET_PublishFunctions.INIget()) "MaterialFile" "ChildrenConflict")
				if ChildrenConflict == "1" then
				(
					return MatCollection
				)
				else
				(
					CollectAllChildrenMaterial = queryBox ("The Asset's children have different materials" +
					"\nIt is RECOMMENDED to cancel and use the" +
					"\nMultSubCreator tool on MakeToolbox to unify them." +
					"\n\nContinue anyway?" +
					"\n\nYES - Collect children's materials as is." +
					"\nNO  - Cancels publishing.") title:"AssetSwitch - Material Conflict"
					if CollectAllChildrenMaterial then
					(
						return MatCollection
					)
					else
					(
						return (#())
					)
				)
			)
		)
		-- Only one (or none) material was collected 
		else
		(
			return MatCollection
		)
	),
	
	-- Publish a 3dsMaxFile	
	function pub_3dsMaxFile arg_asset arg_path =
	(
		try
		(
			-- Collect all child nodes in array
			saveArr = ASSET_PublishFunctions.CollectAllChildren nodeAsset includeParent:true
			-- Bakes on ALL children the Asset Name as a User Properties.
			if saveArr.count > 1 do
			(
				Global_Asset_Name = (getINISetting assetFile "Global" "name")
				ChildArray = deepCopy saveArr
				deleteItem ChildArray 1
				for child in ChildArray do
				(
					if (doesUserPropExist child "AssetName") do
					(
						deleteUserProp child "AssetName"
					)
					setUserProp child "MAKE_NodeName" child.name
				)
			)
			-- Make the target folder if it doesn't exist, and saves the file to it
			makeDir (getFilenamePath arg_path)
			saveNodes saveArr arg_path
			
			return "Success!"
		)
		Catch(return "ERROR: MaxFile Publish failed")
	),
	











	function pub_AnimationFile arg_asset arg_path = --TODO: Create animation publishing routine
	(

	),


















	-- Publish a MaterialFile	
	function Create_TyLibMaterial currentMaterialLibrary arg_path =
	(
		for i in 1 to currentMaterialLibrary.count do (deleteItem currentMaterialLibrary 1)
		loadDefaultMatLib()
		TylibMaterial = (tylibMtl())
		TylibMaterial.filename = arg_path[1]
		append currentMaterialLibrary TylibMaterial
		saveMaterialLibrary arg_path[2]
		--setUserProp nodeAsset "MAKE_Asset_tylibMtl_File" arg_path[2]
	),
	function pub_MaterialFile arg_asset arg_path tyLibSave =
	(
		try(
			-- Attempt to get the assets material
			theMaterialArray = ASSET_PublishFunctions.FindTheMaterial arg_path
			-- Clear the temporary library and add the current material to it
			for i in 1 to currentMaterialLibrary.count do (deleteItem currentMaterialLibrary 1)
			loadDefaultMatLib()
			for Mat in theMaterialArray do
			(
				if Mat != undefined do
				(
					append currentMaterialLibrary Mat
				)
			)
			if currentMaterialLibrary.count != 0 then
			(
				makeDir (getFilenamePath arg_path[1])
				saveMaterialLibrary arg_path[1]
				if tyLibSave == "true" do
				(
					Create_TyLibMaterial currentMaterialLibrary arg_path
				)
				return "Success!"
			)
			else
			(
				return "ERROR: No material present to export"
			)
		)
		Catch(return "ERROR: Material Publish failed")
	),
	
	-- Publish a vrmeshFile	
	function pub_vrmeshFile arg_asset arg_path CombineAllMeshes =
	(
		try(
			-- read settings from the .INI file
			ExportAnimation =	(execute (getinisetting (ASSET_PublishFunctions.INIget()) "vrmeshFile" "ExportAnimation" ))
			FrameStart =		(execute (getinisetting (ASSET_PublishFunctions.INIget()) "vrmeshFile" "FrameStart" ))
			FrameEnd = 			(execute (getinisetting (ASSET_PublishFunctions.INIget()) "vrmeshFile" "FrameEnd" ))
			Facecount = 		(execute (getinisetting (ASSET_PublishFunctions.INIget()) "vrmeshFile" "Facecount" ))
			
			if ExportAnimation == ok 	do ( ExportAnimation= false )
			if FrameStart == ok 		do ( FrameStart  = 0 )
			if FrameEnd == ok 			do ( FrameEnd = 10 )
			if Facecount == ok 			do ( Facecount = 1000 )
				
			-- convert export animation data for vrmesh exporter
			if ExportAnimation
			then ( anim = on )
			else ( anim = off )
			
			-- collect the objects to export
			export_arr = (ASSET_PublishFunctions.CollectAllChildren nodeAsset includeParent:false MeshObjOnly:true)
			hierarchy_Array = (ASSET_PublishFunctions.CollectAllChildren nodeAsset includeParent:false MeshObjOnly:false)
			for obj in export_arr do
			(
				IndexToDelete = FindItem hierarchy_Array obj
				DeleteItem hierarchy_Array IndexToDelete
			)
			-- Temporarily storing the Asset's tranform				
			NodeTemporaryTransform = nodeAsset.transform
			nodeAsset.position = [0,0,0]
			nodeAsset.rotation = quat 0 0 0 0
			nodeAsset.scale = [1,1,1]
			
			export_arr = ASSET_PublishFunctions.ReduceToMeshes export_arr
			ExportedNodesNames = #()
			if CombineAllMeshes then
			(
				ExportedNodesNames[1] = undefined
			)
			else
			(
				ExportedNodesNames[export_arr.count] = undefined
			)
			ExportedNodesFilePath = deepCopy ExportedNodesNames
			ExportedNodesParents = deepCopy ExportedNodesNames
			ExportedNodesTransforms = deepCopy ExportedNodesNames

			if CombineAllMeshes then
			(
				makeDir (getFilenamePath arg_path)
				vrayMeshExport meshFile:arg_path nodes:export_arr autoCreateProxies:false exportMultiple:false maxPreviewFaces:Facecount animation:anim animationRange:#explicit animationStart:FrameStart animationEnd:FrameEnd animationRedrawViews:true
				ExportedNodesNames[1] = nodeAsset.name
				ExportedNodesFilePath[1] = arg_path
				ExportedNodesTransforms[1] = export_arr[1].transform
				ExportedNodesParents[1] = nodeAsset.name
				MapIniName = (substring arg_path 1 (arg_path.count - 7)) + ".vpmap"
			)
			else
			(
				PartsDirectory = ((pathConfig.removePathLeaf(getFilenamePath arg_path)) + @"\" + ((pathConfig.stripPathToLeaf (pathConfig.removePathLeaf arg_path)) + @"_Parts\"))
				CurrentAssetName = ((substring (pathConfig.stripPathToLeaf arg_path) 1 ((pathConfig.stripPathToLeaf arg_path).count - 7)))
				PartsPartialName = PartsDirectory + CurrentAssetName
				makeDir PartsDirectory

				for i = 1 to export_arr.count do
				(
					NodetoExportPath = PartsPartialName + "_" + export_arr[i].name + ".vrmesh"
					vrayMeshExport meshFile:NodetoExportPath nodes:export_arr[i] autoCreateProxies:true exportMultiple:true maxPreviewFaces:Facecount animation:false animationRange:#explicit animationStart:FrameStart animationEnd:FrameEnd animationRedrawViews:true 
					ExportedNodesNames[i] = export_arr[i].name
					ExportedNodesFilePath[i] = NodetoExportPath
					ExportedNodesTransforms[i] = (export_arr[i].transform*(inverse export_arr[i].parent.transform)) -- new method for safe asset replace in case the replacement node is absent
					ExportedNodesParents[i] = (export_arr[i].parent).name
				)
				MapIniName = PartsPartialName + "_Parts.vpmap"
				Max_nodes_to_Save = export_arr + hierarchy_Array
				print Max_nodes_to_Save
				saveNodes Max_nodes_to_Save (PartsPartialName + "_Parts.max" )
			)
			setinisetting (MapIniName) "NodesNames" "NodesNamesArray" (ExportedNodesNames as string)
			setinisetting (MapIniName) "NodesPath" "NodesFilePath" (ExportedNodesFilePath as string)
			setinisetting (MapIniName) "NodesTransform" "NodesTranformArray" (ExportedNodesTransforms as string)
			setinisetting (MapIniName) "NodesParent" "NodesParentArray" (ExportedNodesParents as string)
			-- reverting the asset back to its original transform
			nodeAsset.transform = NodeTemporaryTransform
			delete export_arr
			return "Success!"
		)
		Catch(return "ERROR: vrmesh Publish failed")
	)
)
