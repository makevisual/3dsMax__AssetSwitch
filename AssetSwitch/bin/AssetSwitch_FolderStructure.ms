/*
#NAME:AssetSwitch_FolderStructure
#VERSION:1.0.0
#INSTRUCTIONS:
Creates the Folder Strucure needed for creating Assets
#SOURCE:david.almeida@makevisual.com

--*****************************************************
-- Tool part of Asset Switch
-- Modified by david.almeida@makevisual.com
--*****************************************************
-- HISTORY:
--- version 1.0.0  : 07.02.2025 >> First Version
--*****************************************************
*/
struct ASSET_FolderStructure
(
	DefaultFolderStructure = 
	#(
		#("Build", "Layout", "Model", "Rig", "Sculpt", "Shade"),
		"Cache",
		"Comp",
		"Image_Sequences",
		#("Publish", "Material"),
		#("References", "Mesh", "xref"),
		"Renders",
		#("Surfaces", "Substance")
	),
	function CreateFolders Folder RootFolder =
	(
		if (classof Folder == array) then
		(
			for i in 1 to Folder.count do
			(
				if i == 1 then
				(
					makedir (RootFolder + Folder[1])
				)
				else
				(
					CreateFolders (Folder[i]) (RootFolder + Folder[1] + @"\")
				)
			)
		)
		else
		(
			makedir (RootFolder + Folder)
		)
	),
	function InitializeFolderStrucure AssetFolder =
	(
		FolderStructure = (ASSET_FolderStructure()).DefaultFolderStructure
		for MainItems in FolderStructure do
		(
			CreateFolders MainItems AssetFolder
		)
		--CreateFolders MainItems AssetFolder
	)
)