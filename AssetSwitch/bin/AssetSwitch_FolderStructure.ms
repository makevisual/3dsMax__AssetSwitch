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
	function InitializeFolderStrucure AssetFolder =
	(
		MyDir = (pathConfig.removePathLeaf (pathConfig.removePathLeaf (getSourceFileName())))
		FoldersINIFile = (MyDir + @"\" + "AssetSwitch_Config.ini")
		FolderStructure = #()
		FolderStructure = for NewFolders in (getINISetting FoldersINIFile "folders") collect (getINISetting FoldersINIFile "folders" NewFolders)
		for Folder in FolderStructure do
		(
			makedir (AssetFolder + Folder)
		)
	)
)