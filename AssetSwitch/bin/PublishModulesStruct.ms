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
--global nodeAssetForPublish = (maxops.getnodebyhandle 16) --nodeAssetHandle)
global nodeAssetForPublish = (maxops.getnodebyhandle nodeAssetHandle)

struct ASSET_PublishFunctions
(



	-- Variable to store Materials from assets and be used on "FindTheMaterial" function
	--MatCollection = #(),




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
		LOGfile = ((getdir #userscripts) + @"\asset_switch_log.txt") -- Maybe add @ at the beggining of the string to avoid string escapes?
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
		shelllaunch "notepad.exe" fileString --ASSET_PublishFunctions.LOGget()
	),
	
	-- Function for recursivly selecting all of the children of an inital object
	function CollectAllChildren obj includeParent:true =
	(
		-- start collecting direct children of <obj>
		allChildren = #(obj)

		-- add children and their children etc recursively  ----- VERY CLEVER SOLUTION!
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
	),	

	-- attach all geometry objects in passed array, deletes anything else
	function AttachAll arg_Arr =
	(
		-- change the command panel to create mode, for performance
		max create mode 
		
		-- prepare the base object, and delete set
		baseObj = arg_Arr[1]
		converttopoly baseObj
		delArr = #()
		
		-- loop through the other objects in the array
		for i in 2 to (arg_Arr.count) do
		(
			curObj = arg_Arr[i]
			
			if		-- if the object is geometry class
			(
				iskindof curObj geometryclass
			)
			then 	-- convert and attach it
			(
				converttopoly curObj
				polyop.attach baseObj curObj
			)
			else	-- collect for deletion
			(
				join delArr #(curObj)
			)
		)
		
		-- delete non geometry objects
		delete delArr
		
		return #(baseObj)
	),
	
	-- Reduces an array of objects to match the passed class
	function FilterToClass arg_Arr arg_Class = -- geometryclass
	(
		-- change the command panel to create mode, for performance
		max create mode 
		
		-- prepare the base object, and delete set
		resultArr = #()
		
		-- loop through the other objects in the array
		for i in 1 to (arg_Arr.count) do
		(
			-- if the object is geometry class
			if ( iskindof arg_Arr[i] arg_Class )
			-- join it
			then (join resultArr #(arg_Arr[i]))
			else ()
		)
		
		return resultArr
	),
	
	-- Returns an array of meshes, that have been collapsed
	function ReduceToMeshes arg_Arr = 
	(
		-- change the command panel to create mode, for performance
		max create mode 
		
		-- prepare the base object, and delete set
		resultArr = #()
		delArr = #()
		
		-- loop through the other objects in the array
		for i in 1 to (arg_Arr.count) do
		(
			-- if the object is geometry class
			if ( iskindof arg_Arr[i] geometryclass )
			-- convert and join it
			then
			(
				if (classof arg_Arr[i] ) != BoneGeometry
				then
				(
					converttopoly arg_Arr[i]
					join resultArr #(arg_Arr[i])
				)
				else (join delArr #(arg_Arr[i]))
			)
			-- collect for deletion
			else (join delArr #(arg_Arr[i]))
		)
		
		-- delete non geometry objects
		delete delArr
		
		return resultArr
	),

	-- Returns an array of meshes, that have been collapsed
	function FilterToMeshes arg_Arr = 
	(
		-- change the command panel to create mode, for performance
		max create mode 
		
		-- prepare the base object, and delete set
		resultArr = #()
		delArr = #()
		
		-- loop through the other objects in the array
		for i in 1 to (arg_Arr.count) do
		(
			-- if the object is geometry class
			if ( iskindof arg_Arr[i] geometryclass )
			-- convert and join it
			then
			(
				if (classof arg_Arr[i] ) != BoneGeometry
				then
				(
					join resultArr #(arg_Arr[i])
				)
				else (join delArr #(arg_Arr[i]))
			)
			-- collect for deletion
			else (join delArr #(arg_Arr[i]))
		)

		return resultArr
	),
	
	-- Returns a material applied to selected object, or is children
	function FindTheMaterial arg_Node =
	(

		MatCollection = #()





		-- TODO: Create a collection of materials from the child nodes
		









		print "Coletando Materiais"
		-- If the global doesn't have a material
		if nodeAssetForPublish.material == undefined then -- search its children for materials
		(
			print "o parent nao tem material"
			objArr = ASSET_PublishFunctions.CollectAllChildren nodeAssetForPublish includeParent:false
			
			print "Os Child Nodes"
			print objArr

			for i in 1 to objArr.count do
			(
				print "Loop pelos Child Nodes"
				print objArr[i]
				if (objArr[i].material == undefined) then
				(
					--append (ASSET_PublishFunctions()).MatCollection undefined
					append MatCollection undefined
				)
				-- return the material when found
				else
				(

					print "Colocando o Material na Array"
					print objArr[i].material


					append MatCollection objArr[i].material
					--return objArr[i].material -- This is a SLOW procedure (return command) and it is getting just the first material it finds on the
												-- assets selected

					print "A Array"
					print MatCollection

											  
				)
			)
			-- return undefined if none found
			return MatCollection
		)
		--return the global's material
		else
		(		
			return (#(nodeAssetForPublish.material))
		)
	),
	
	-- Publish a 3dsMaxFile	
	function pub_3dsMaxFile arg_asset arg_path =
	(
		try
		(
			-- Collect all child nodes in array
			saveArr = ASSET_PublishFunctions.CollectAllChildren nodeAssetForPublish includeParent:true














			-- Bakes on ALL children the Asset Name as a User Properties. -- TODO: Change the functionality to add the object itself to it

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
	
	-- Publish a 3dsMaxOptimizedFile	
	function pub_MaxOptimizedFile arg_asset arg_path =
	(
 		--try(
			-- read settings from the .INI file
			AttachAllElements = 	(execute (getinisetting (ASSET_PublishFunctions.INIget()) "MaxOptimizedFile" "AttachAllElements" ))
			VertexCapType = 		(execute (getinisetting (ASSET_PublishFunctions.INIget()) "MaxOptimizedFile" "VertexCapType" ))
			VertexCapPercent = 		(execute (getinisetting (ASSET_PublishFunctions.INIget()) "MaxOptimizedFile" "VertexCapPercent" ))
			VertexCapCount = 		(execute (getinisetting (ASSET_PublishFunctions.INIget()) "MaxOptimizedFile" "VertexCapCount" ))

			if AttachAllElements == ok 	do ( AttachAllElements = true )
			if VertexCapType == ok 		do ( VertexCapType  = 1 )
			if VertexCapPercent == ok 	do ( VertexCapPercent = 10 )
			if VertexCapCount == ok 	do ( VertexCapCount = 200 )
				
			-- Collect all objects
			objArr = ASSET_PublishFunctions.CollectAllChildren nodeAssetForPublish includeParent:false
			objArr = ASSET_PublishFunctions.ReduceToMeshes objArr
				
			if AttachAllElements
			then (optimizeArr = ASSET_PublishFunctions.AttachAll objArr)
			else (optimizeArr = ASSET_PublishFunctions.ReduceToMeshes objArr)
			
			-- define new optimize
			OptimizeMod = ProOptimizer LockMat:off
			
			-- Apply the optimization and collapse mesh(es)
			for i in 1 to optimizeArr.count do
			(
				newOptimize = copy OptimizeMod
				
				curObj = optimizeArr[i]
				addmodifier curObj newOptimize
				validModifier curObj newOptimize
				newOptimize.Calculate = True
				validModifier curObj newOptimize
				
				-- With the chose optimization level
				max modify mode 
				case VertexCapType of
				(
					1:	(newOptimize.VertexPercent = VertexCapPercent)
					2:	(newOptimize. VertexCount = VertexCapCount)
				)
				converttopoly curObj
			)

			
			-- Publish as 3dsMax File
			ASSET_PublishFunctions.pub_3dsMaxFile "asset" arg_path
 		--)
 		--Catch(return "ERROR: Max Optimized File Publish failed")
	),
	
	-- Publish a MaterialFile	
	function pub_MaterialFile arg_asset arg_path =
	(
		print "Começar a coletar materiais"
		try(
			-- Attempt to get the assets material
			theMaterialArray = ASSET_PublishFunctions.FindTheMaterial nodeAssetForPublish
			

			if theMaterialArray.count == 1 then
			(
				if theMaterialArray[1] == undefined then
				(
					return "ERROR: No material present to export"
				)
				else
				(
					-- Clear the temporary library and add the current material to it
					for i in 1 to currentMaterialLibrary.count do (deleteItem currentMaterialLibrary 1)
					loadDefaultMatLib()
					append currentMaterialLibrary theMaterialArray[1]
					
					makeDir (getFilenamePath arg_path)
					saveMaterialLibrary arg_path
					setUserProp nodeAssetForPublish "multiMaterial_file" arg_path
					--setUserProp nodeAssetForPublish "PUB_Material" arg_path
					
					return "Success!"
				)
			)
			else
			(
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
					makeDir (getFilenamePath arg_path)
					saveMaterialLibrary arg_path
					setUserProp nodeAssetForPublish "multiMaterial_file" arg_path
					return "Success!"
				)
				else
				(
					return "ERROR: No material present to export"
				)
			)



		)
		Catch(return "ERROR: Material Publish failed")
	),
	
	-- Publish a vrmeshFile	
	function pub_vrmeshFile arg_asset arg_path =
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
			export_arr = (ASSET_PublishFunctions.CollectAllChildren nodeAssetForPublish includeParent:false)
				
			-- transform them to the origin, for proper export
			nodeAssetForPublish.position = [0,0,0]
			nodeAssetForPublish.rotation = quat 0 0 0 0
			nodeAssetForPublish.scale = [1,1,1]

			-- Converts all renderable geometry to edit polys, and deletes the rest
			export_arr = ASSET_PublishFunctions.ReduceToMeshes export_arr
				
			-- select the objects and export them
			select export_arr
			makeDir (getFilenamePath arg_path)
			vrayMeshExport meshFile:arg_path autoCreateProxies:false exportMultiple:false maxPreviewFaces:Facecount animation:anim animationRange:#explicit animationStart:FrameStart animationEnd:FrameEnd animationRedrawViews:true
			
			return "Success!"
		)
		Catch(return "ERROR: vrmesh Publish failed")
	),

	-- Publish a vrmeshAsMaxFile	                                                 ----> ASK_AARON - To Deprecate?
	function pub_vrmeshAsMaxFile arg_asset arg_path =
	(
		try(
			-- read settings from the .INI file
			ExportAnimation = 	(execute (getinisetting (ASSET_PublishFunctions.INIget()) "vrmeshAsMaxFile" "ExportAnimation" ))
			FrameStart = 		(execute (getinisetting (ASSET_PublishFunctions.INIget()) "vrmeshAsMaxFile" "FrameStart" ))
			FrameEnd = 			(execute (getinisetting (ASSET_PublishFunctions.INIget()) "vrmeshAsMaxFile" "FrameEnd" ))
			Facecount = 		(execute (getinisetting (ASSET_PublishFunctions.INIget()) "vrmeshAsMaxFile" "Facecount" ))
				
			if ExportAnimation == ok 	do ( ExportAnimation= false )
			if FrameStart == ok 		do ( FrameStart  = 0 )
			if FrameEnd == ok 			do ( FrameEnd = 10 )
			if Facecount == ok 			do ( Facecount = 1000 )
				
			-- convert export animation data for vrmesh exporter
			if ExportAnimation
			then ( anim = on )
			else ( anim = off )
			
			-- collect the objects to export
			export_arr = (ASSET_PublishFunctions.CollectAllChildren nodeAssetForPublish includeParent:false)
				
			-- transform them to the origin, for proper export
			nodeAssetForPublish.position = [0,0,0]
			nodeAssetForPublish.rotation = quat 0 0 0 0
			nodeAssetForPublish.scale = [1,1,1]
				
			-- Prepare directory for .vrmesh file
			dataDir = ((getFilenamePath arg_path) + @"data\")
			makeDir dataDir
			
			-- select the objects and export them
			select export_arr		
			obj = vrayMeshExport meshFile:dataDir autoCreateProxies:true exportMultiple:false maxPreviewFaces:Facecount animation:anim animationRange:#explicit animationStart:FrameStart animationEnd:FrameEnd animationRedrawViews:true
			
			-- integrate the .vrmesh to the scene
			obj.parent = nodeAssetForPublish
			
			-- Publish as 3dsMax File
			ASSET_PublishFunctions.pub_3dsMaxFile "asset" arg_path
			
			return "Success!"
		)
		Catch(return "ERROR: vrmesh as max Publish failed")
	),

	-- Publish a xmeshFile		                                                 ----> ASK_AARON - To Deprecate? ToDo: YES!
	function pub_xmeshFile arg_asset arg_path arg_iniKey =
	(
		try(
			-- read settings from the .INI file
			ExportAnimation = 	(execute (getinisetting (ASSET_PublishFunctions.INIget()) arg_iniKey "ExportAnimation" ))
			FrameStart = 		(execute (getinisetting (ASSET_PublishFunctions.INIget()) arg_iniKey "FrameStart" ))
			FrameEnd =			(execute (getinisetting (ASSET_PublishFunctions.INIget()) arg_iniKey "FrameEnd" ))
			SampleMode = 		(execute (getinisetting (ASSET_PublishFunctions.INIget()) arg_iniKey "SampleMode" )) ----> ASK_AARON - This option is absent on the INI file
				
			if ExportAnimation == ok 	do (ExportAnimation = false )
			if FrameStart == ok 		do (FrameStart = 0 )
			if FrameEnd == ok 			do (FrameEnd = 10 )
			if SampleMode == ok 		do (SampleMode = 3 )
				
			
			-- Sets the fraction of a frame to advance per sample
			frameStep = 1.0
			timeDisplayMode = #timeTicks
			case SampleMode of
			(
				1: (frameStep = 1)		-- 1 sample
				2: (frameStep = .5)		-- 2 samples
				3: (frameStep = .25)	-- 4 samples
				4: (frameStep = .2)		-- 5 samples
				5: (frameStep = .125)	-- 8 samples
				6: (frameStep = .1)		-- 10 samples
			)

			-- Collects objects for export
			children_arr = 	( ASSET_PublishFunctions.CollectAllChildren nodeAssetForPublish includeParent:false)			
			export_arr = 	( ASSET_PublishFunctions.FilterToClass children_arr geometryclass )
				
			-- transform them to the origin, for proper export
			nodeAssetForPublish.position = [0,0,0]
			nodeAssetForPublish.rotation = quat 0 0 0 0
			nodeAssetForPublish.scale = [1,1,1]

			-- Filters the array to only renderable geometry
			export_arr = ASSET_PublishFunctions.FilterToMeshes export_arr

			-- Prepare directories and channels
			makeDir (getFilenamePath arg_path)
			XMeshSaverUtils.SetSequenceName "c:\\"
			XMeshSaverUtils.SetSequenceName arg_path
			
			-- Prepare xmesh saver porperties
			XMeshSaverUtils.TimeStepInitialOffset = 1
			XMeshSaverUtils.TimeStepScale = .5
			XMeshSaverUtils.ThreadCount = 4
			XMeshSaverUtils.LogWindowVisible = false
			
			-- Start SaveMeshesToSequence
			disablesceneredraw()
			XMeshSaverUtils.SetSceneRenderBegin()
			XMeshSaverUtils.AcquireLicense()
			progressStart ( "please wait" )		
			for i in FrameStart to FrameEnd by frameStep do 
			(
				progressUpdate ((100.0*i/((FrameStart - FrameEnd))) * -1)
				slidertime = i	
				XMeshSaverUtils.SaveMeshesToSequence export_arr true true true
			)
			progressEnd()		
			XMeshSaverUtils.ReleaseLicense()
			XMeshSaverUtils.SetSceneRenderEnd()
			enablesceneredraw()
			
			-- write 'create.ms' the maxscript constructor for the xml loader
			exportLayerName = export_arr[1].layer.name
			
			theScriptFile = createFile ((getFilenamePath arg_path) +" Create.MS")
			format "(\nlocal theXMeshLoader = XMeshLoader()\n" to:theScriptFile
			format "local thePath = getFilenamePath (getThisScriptFilename())\n" to:theScriptFile
			format "local theXMeshLayer = LayerManager.getLayerFromName \"%\" \n" exportLayerName to:theScriptFile
			format "if theXMeshLayer == undefined do theXMeshLayer = LayerManager.newLayerFromName \"%\" \n" exportLayerName to:theScriptFile
			format "theXMeshLayer.addnode theXMeshLoader \n" to:theScriptFile
			format "theXMeshLoader.viewportSequenceID = 0 \n" to:theScriptFile
			format "theXMeshLoader.name = uniquename \"%\" \n" ((filterstring (filenamefrompath arg_path) ".")[1]) to:theScriptFile -- TACOTIME
			format "theXMeshLoader.enableViewportMesh = true \n" to:theScriptFile
			format "theXMeshLoader.displayMode = 0 \n" to:theScriptFile
			format "theXMeshLoader.displayPercent = 5.0 \n" to:theScriptFile
			format "theXMeshLoader.limitToRange = true \n" to:theScriptFile
			format "select theXMeshLoader \n" to:theScriptFile
			format "theXMeshLoader.rangeFirstFrame = % \n " (FrameStart as integer) to:theScriptFile
			format "theXMeshLoader.rangeLastFrame = % \n " (FrameEnd as integer) to:theScriptFile 
			format "theXMeshLoader.viewportSequenceID = 0 \n" to:theScriptFile
			format "theXMeshLoader.renderSequence = @\"%\" \n" ((getFilenamePath arg_path) + (getFileNameFile arg_path) + (substring ((FrameStart +10000 ) as string ) 2 10) + ".xmesh") to:theScriptFile
			format "theXMeshLoader.loadMode = 2 \n" to:theScriptFile
			format ") " to:theScriptFile
			close theScriptFile
			
			return "Success!"
		)
		Catch(return "ERROR: xmesh Publish failed")
	),

	-- Publish a xmeshAsMaxFile	
	function pub_xmeshAsMaxFile	 arg_asset arg_path arg_iniKey =
	(

			ExportAnimation = 	(execute (getinisetting (ASSET_PublishFunctions.INIget()) arg_iniKey "ExportAnimation" ))
			FrameStart = 		(execute (getinisetting (ASSET_PublishFunctions.INIget()) arg_iniKey "FrameStart" ))
			FrameEnd =			(execute (getinisetting (ASSET_PublishFunctions.INIget()) arg_iniKey "FrameEnd" ))
			SampleMode = 		(execute (getinisetting (ASSET_PublishFunctions.INIget()) arg_iniKey "SampleMode" ))
				
			if ExportAnimation == ok 	do (ExportAnimation = false )
			if FrameStart == ok 		do (FrameStart = 0 )
			if FrameEnd == ok 			do (FrameEnd = 10 )
			if SampleMode == ok 		do (SampleMode = 3 )
				
			
			-- Sets the fraction of a frame to advance per sample
			frameStep = 1.0
			timeDisplayMode = #timeTicks
			case SampleMode of
			(
				1: (frameStep = 1)		-- 1 sample
				2: (frameStep = .5)		-- 2 samples
				3: (frameStep = .25)	-- 4 samples
				4: (frameStep = .2)		-- 5 samples
				5: (frameStep = .125)	-- 8 samples
				6: (frameStep = .1)		-- 10 samples
			)

			-- Collects objects for export
			children_arr = 	( ASSET_PublishFunctions.CollectAllChildren nodeAssetForPublish includeParent:false)			
			export_arr = 	( ASSET_PublishFunctions.FilterToClass children_arr geometryclass )	
				
			-- transform them to the origin, for proper export
			nodeAssetForPublish.position = [0,0,0]
			nodeAssetForPublish.rotation = quat 0 0 0 0
			nodeAssetForPublish.scale = [1,1,1]

			-- Prepare directories and channels
			makeDir (getFilenamePath arg_path + @"data\")
			XMeshSaverUtils.SetSequenceName "c:\\"
			XMeshSaverUtils.SetSequenceName ((getFilenamePath arg_path) + @"data\" + ("data_") + (substring ((FrameStart +10000 ) as string ) 2 10) + ".xmesh")
			
			-- Prepare xmesh saver porperties
			XMeshSaverUtils.TimeStepInitialOffset = 1
			XMeshSaverUtils.TimeStepScale = .5
			XMeshSaverUtils.ThreadCount = 4
			XMeshSaverUtils.LogWindowVisible = false
			
			-- Start SaveMeshesToSequence
			disablesceneredraw()
			XMeshSaverUtils.SetSceneRenderBegin()
			XMeshSaverUtils.AcquireLicense()
			progressStart ( "please wait" )		
			for i in FrameStart to FrameEnd by frameStep do 
			(
				progressUpdate ((100.0*i/((FrameStart - FrameEnd))) * -1)
				slidertime = i	
				XMeshSaverUtils.SaveMeshesToSequence export_arr true true true
			)
			progressEnd()		
			XMeshSaverUtils.ReleaseLicense()
			XMeshSaverUtils.SetSceneRenderEnd()
			enablesceneredraw()
			
			exportLayerName = export_arr[1].layer.name
			
			-- write 'create.ms' the maxscript constructor for the xml loader
			theScriptFile = createFile ((getFilenamePath arg_path) + @"data\" +"Create.MS")
			format "(\nglobal theXMeshLoader = XMeshLoader()\n" to:theScriptFile
			format "local thePath = getFilenamePath (getThisScriptFilename())\n" to:theScriptFile
			format "local theXMeshLayer = LayerManager.getLayerFromName \"%\" \n" exportLayerName to:theScriptFile
			format "if theXMeshLayer == undefined do theXMeshLayer = LayerManager.newLayerFromName \"%\" \n" exportLayerName to:theScriptFile
			format "theXMeshLayer.addnode theXMeshLoader \n" to:theScriptFile
			format "theXMeshLoader.viewportSequenceID = 0 \n" to:theScriptFile
			format "theXMeshLoader.name = uniquename \"%\" \n" ((filterstring (filenamefrompath arg_path) ".")[1]) to:theScriptFile -- TACOTIME
			format "theXMeshLoader.enableViewportMesh = true \n" to:theScriptFile
			format "theXMeshLoader.displayMode = 0 \n" to:theScriptFile
			format "theXMeshLoader.displayPercent = 5.0 \n" to:theScriptFile
			format "theXMeshLoader.limitToRange = true \n" to:theScriptFile
			format "select theXMeshLoader \n" to:theScriptFile
			format "theXMeshLoader.rangeFirstFrame = % \n " (FrameStart as integer) to:theScriptFile
			format "theXMeshLoader.rangeLastFrame = % \n " (FrameEnd as integer) to:theScriptFile 
			format "theXMeshLoader.viewportSequenceID = 0 \n" to:theScriptFile
			format "theXMeshLoader.renderSequence = @\"%\" \n" ((getFilenamePath arg_path) + (@"data\data_") + (substring ((FrameStart +10000 ) as string ) 2 10) + ".xmesh") to:theScriptFile
			format "theXMeshLoader.loadMode = 2 \n" to:theScriptFile
			format ") " to:theScriptFile
			close theScriptFile
			
			-- Replace the original objects with .xmesh objects
			delete export_arr
			filein ((getFilenamePath arg_path) + @"data\" +"Create.MS")
			selection[1].parent = nodeAssetForPublish
			clearselection()	
			
			ASSET_PublishFunctions.pub_3dsMaxFile "asset" arg_path
	),

	-- Publish a PointCacheFile	
	function pub_PointCacheFile arg_asset arg_path =
	(

		return "Success!"
	),

	-- Publish a PointCacheAsMaxFile	
	function pub_PointCacheAsMaxFile arg_asset arg_path =
	(

		return "Success!"
	),

	-- Publish a SaveAnimationFile	
	function pub_SaveAnimationFile arg_asset arg_path =
	(

		return "Success!"
	)
)
