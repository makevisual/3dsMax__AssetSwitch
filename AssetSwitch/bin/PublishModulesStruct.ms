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
		setinisetting ((substring arg_path[1] 1 (arg_path[1].count - 4)) + ".matmap") "MaterialNodeMap" "MaterialMapArray" (with printAllElements on (MaterialMapArray as string))
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
			-- Make the target folder if it doesn't exist, and saves the file to it
			makeDir (getFilenamePath arg_path)
			saveNodes saveArr arg_path
			
			return "Success!"
		)
		catch(return "ERROR: MaxFile Publish failed")
	),
	-- Function to collect all objects that have animation keys on any of its properties/controllers
	function Collect_Animated_Properties theObject &Animated_Properties=
	(
		if try (theObject.isAnimated) catch (false) do
		append Animated_Properties theObject
		for i = 1 to theObject.numSubs do
		Collect_Animated_Properties theObject[i] &Animated_Properties

	),
	-- Function to find and remove from the Animation Publishing array any objects that have an Attachment Constraint controller applied, since the Save/Load animation function in 3dsMax does not
	-- currently saves and loads keys on such controller type (Attachment Constraint keys are not saved when using Save/Load Animation)
	function Remove_Objects_With_Attachment_Constraint &ObjArray =
	(
		for i = ObjArray.count to 1 by -1 do
		(
			if ObjArray[i].isAnimated do
			(
				Animated_Properties = #()
				Collect_Animated_Properties ObjArray[i] &Animated_Properties
				HasAttachmentConstraint = false
				for CurrentAnim in Animated_Properties do
				(
					if (classof CurrentAnim.controller) == Attachment do
					(
						HasAttachmentConstraint = true
					)
				)
				if HasAttachmentConstraint do
				(
					deleteItem ObjArray i
				)
			)
		)
	),
	-- Function to find duplicate objects on the Animation Publishing array, and later report to the user about such duplicates
	function Find_Duplicate_Objects &ObjArray &DuplicateNameArray =
	(
		DuplicateIndexes = #()
		if ObjArray.count > 1 do
		(
			for i = ObjArray.count to 2 by -1 do
			(
				for j = (i - 1) to 1 by -1 do
				(
					if i != j do
					(
						if ObjArray[i].name == ObjArray[j].name do
						(
							append DuplicateNameArray ObjArray[i].name
							append DuplicateNameArray ObjArray[j].name
						)
					)
				)
			)
		)
	),
	-- Function to find and remove from the Animation Publishing array any objects that have a Point Cache modifier applied to them, since the animation of such objects must come from the Point Cache
	-- modifier itself and not keyframed animation on these objects.
	function Remove_PointCache_Objects &ObjArray =
	(
		for i = ObjArray.count to 1 by -1 do
		(
			removeObj = false
			for CurrentMod in ObjArray[i].modifiers do
			(
				if (classof CurrentMod) == Point_Cache do
				(
					removeObj = true
				)
			)
			if removeObj do
			(
				deleteItem ObjArray i
			)
		)
	),
	-- Function to publish the animation of the currently selected asset
	function pub_AnimationFile arg_asset arg_path =
	(
		try
		(
			makeDir (pathConfig.removePathLeaf arg_path)
			SetRange = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "AnimationPublish" "SetRange" ))
			FrameStart = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "AnimationPublish" "FrameStart" ))
			FrameEnd = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "AnimationPublish" "FrameEnd" ))
			LoadSavedNames = (execute (getinisetting (ASSET_PublishFunctions.INIget()) "AnimationPublish" "LoadSavedNames" ))
			-- Collects in an array the objects which animation is to be published
			saveArr = ASSET_PublishFunctions.CollectAllChildren nodeAsset includeParent:true MeshObjOnly:false
			PointCacheRemoved = ""
			AttachmentRemoved = ""
			BeforePointCacheRemoval = saveArr.count
			-- Removes from the Objects Array those which have a Point Cache modifier
			Remove_PointCache_Objects &saveArr
			-- Compares the array size to assess if objects were removed from the original Object Array
			if BeforePointCacheRemoval - saveArr.count != 0 do
			(
				-- Creates an appropriate warning message in case objects were removed because they had a Point Cache modifier
				PointCacheRemoved = ((BeforePointCacheRemoval - saveArr.count) as string) + " nodes removed from Animation publishing due to having point cache modifiers"
			)
			BeforeAttachmentRemoval = saveArr.count
			-- Removes from the Objects Array those which have an Attachment Constraint controller (because, as of now, the Save/Load Max command does not support this controller)
			Remove_Objects_With_Attachment_Constraint &saveArr
			-- Compares the array size to assess if objects were removed from the original Object Array
			if BeforeAttachmentRemoval - saveArr.count != 0 do
			(
				-- Creates an appropriate warning message in case objects were removed because they had an Attachment Constraint controller
				if PointCacheRemoved == "" then
				(
					AttachmentRemoved = ((BeforeAttachmentRemoval - saveArr.count) as string) + " nodes removed from Animation publishing due to having Attachment Constraints"
				)
				else
				(
					AttachmentRemoved = ", and " + ((BeforeAttachmentRemoval - saveArr.count) as string) + " nodes removed from Animation publishing due to having Attachment Constraints"
				)
			)
			-- Loads back to the objects their saved UserProperties name
			if LoadSavedNames do
			(
				for CurrentNode in saveArr do
				(
					MAKE_NodeName = (getUserProp CurrentNode "MAKE_NodeName")
					if MAKE_NodeName != undefined do
					(
						CurrentNode.name = MAKE_NodeName
					) 
				)
			)
			-- Creates the interval to be used on the LoadSaveAnimation command
			if SetRange then
			(
				IntervalRange = interval FrameStart FrameEnd
			)
			else
			(
				IntervalRange = (interval 0f 0f)
			)
			-- Tries to Publish the animation. Returns "False" if the process fails (most commonly because of the presence of objects with duplicate names)
			AnimationSaveStatus = LoadSaveAnimation.saveAnimation arg_path &saveArr (#()) (#()) animatedTracks:false includeConstraints:true keyableTracks:true saveSegment:SetRange segInterval:IntervalRange
			if AnimationSaveStatus then
			(
				-- If the Animation publishing is successful returns "Success", or if it's partially successful returns a "Warning" in case some objects had point cache modifiers or attachment constraint present
				if (PointCacheRemoved != "") OR (AttachmentRemoved != "") then
				(
					return ("WARNING: " + PointCacheRemoved + AttachmentRemoved + ". Animation was still published for valid nodes.")
				)
				else
				(
					return "Success!"
				)
			)
			else
			(
				DuplicateNames = #()
				Find_Duplicate_Objects &saveArr &DuplicateNames
				print "Duplicate Object Names:"
				for objName in DuplicateNames do (print objName)
				return "ERROR: Animation Publish failed. Check for duplicate names on Maxscript Listener"
			)
		)
		catch(return "ERROR: Animation Publish failed")
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
	function Reparent_VrayProxies &HierarchyArray &NodesArray &RevertHierarchyArray NodesNamesArray =
	(
		for j = HierarchyArray.count to 1 by -1 do
		(
			-- Checks if a node on the ExportedNodeNames exists on the hierarchy_array (implying an exported node is also a parent of some other node)
			ParentIndex = findItem NodesNamesArray HierarchyArray[j].name
			if ParentIndex != 0 do
			(
				-- Grabs all the children of the Hierarchy_Array node to assign them to a new parent inside the Export Array
				ChildrenToReparent = (for CurrentChild in HierarchyArray[j].children collect CurrentChild)
				for ChildIndex = ChildrenToReparent.count to 1 by -1 do
				(
					IndexinExportArray = (FindItem NodesArray ChildrenToReparent[ChildIndex])
					IndexinHierarchyArray = (FindItem HierarchyArray ChildrenToReparent[ChildIndex])
					-- Checks to see if all the children are included on the Export_Array or Hierarchy Array. If they are not, exclude such node to be reparented.
					if (IndexinExportArray == 0) AND (IndexinHierarchyArray == 0) do
					(
						deleteItem ChildrenToReparent ChildIndex
					)
					-- Checks if a to be reparent node is originally part of the hierarchy array (and hence, it is a control object, like a spline or helper)
					if IndexinHierarchyArray != 0 do
					(
						-- adds such objects to the ParentRevert array along with its original parent
						append RevertHierarchyArray ChildrenToReparent[ChildIndex]
						append RevertHierarchyArray HierarchyArray[j]
					)
				)
				-- Reparent the children to a node inside the export array
				ChildrenToReparent.parent = NodesArray[ParentIndex]
				-- Removes the Geometry that had children on the Export Array from the hierarchy array to be published afterwards
				deleteItem HierarchyArray j
			)
		)
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
			export_arr_Names = #()
			export_arr = (ASSET_PublishFunctions.CollectAllChildren nodeAsset includeParent:false MeshObjOnly:true)
			hierarchy_Array = (ASSET_PublishFunctions.CollectAllChildren nodeAsset includeParent:false MeshObjOnly:false)
			-- Removes from the Hierarchy Array all objects that have no children
			for obj in export_arr do
			(
				append export_arr_Names obj.name
				if obj.children.count == 0 do
				(
					IndexToDelete = FindItem hierarchy_Array obj
					DeleteItem hierarchy_Array IndexToDelete
				)
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
				-- Initializes an Array to reparent nodes back to their original parents in case they had to be parented to VrayProxy nodes
				ParentRevertArray = #()
				BadHierarchy = false
				-- Checks for Geometry that has any children inside the Export Array and reassigns the parent to be the newly created VrayProxy Object
				for CurrentNode in hierarchy_Array do
				(
					-- Checks if a node on the ExportedNodeNames exists on the hierarchy_array (implying an exported node is also a parent of some other node)
					ParentIndex = findItem export_arr_Names CurrentNode.name
					if ParentIndex != 0 do
					(
						BadHierarchy = true
					)
				)
				if BadHierarchy do
				(
					ReparentVrayProxies = queryBox ("The Asset contains geometry parented to other" +
					"\ngeometry objects. IT IS HIGHLY RECOMMENDED to" +
					"\nCANCEL the publishing of this Asset and fix" +
					"\nthe hierarchy, making sure all geometry is" +
					"\nparented to point helpers or controllers objects." +
					"\n\nContinue anyways?" +
					"\n\nYES - Ignore and continue." +
					"\nNO - Cancels publishing (RECOMMENDED).") title:"AssetSwitch - Material Conflict"
					if ReparentVrayProxies then
					(
						Reparent_VrayProxies &hierarchy_Array &export_arr &ParentRevertArray export_arr_Names
					)
					else
					(
						return ("ERROR: vrmesh Publish cancelled by user")
					)
				)
				makeDir PartsDirectory
				for i = 1 to export_arr.count do
				(
					NodetoExportPath = PartsPartialName + "_" + export_arr[i].name + ".vrmesh"
					OriginalMeshName = export_arr[i].name
					vrayMeshExport meshFile:NodetoExportPath nodes:export_arr[i] autoCreateProxies:true exportMultiple:true maxPreviewFaces:Facecount animation:false animationRange:#explicit animationStart:FrameStart animationEnd:FrameEnd animationRedrawViews:true
					ExportedNodesNames[i] = export_arr[i].name
					ExportedNodesFilePath[i] = NodetoExportPath
					ExportedNodesTransforms[i] = (export_arr[i].transform*(inverse export_arr[i].parent.transform)) -- new method for safe asset replace in case the replacement node is absent
					ExportedNodesParents[i] = (export_arr[i].parent).name
					setUserProp export_arr[i] "MAKE_Asset_Original_Mesh" OriginalMeshName
				)
				MapIniName = PartsPartialName + "_Parts.vpmap"
				Max_nodes_to_Save = export_arr + hierarchy_Array
				saveNodes Max_nodes_to_Save (PartsPartialName + "_Parts.max")
				-- Checks if there are elements on the ParentRevert array
				if ParentRevertArray.count != 0 do
				(	
					-- Proceeds to parent those objects back to their original parents
					for i = 1 to (ParentRevertArray.count*0.5) do
					(
						ParentRevertArray[(i*2) - 1].parent = ParentRevertArray[i*2]
					)
				)
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
