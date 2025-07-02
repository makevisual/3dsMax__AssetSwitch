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
	function CreateFolderStructureINI INIRootFolder=
	(
		print "Entrou tb"
		setINISetting INIRootFolder "folders" "folder01" @"Build"
		setINISetting INIRootFolder "folders" "folder02" @"Build\Layout"
		setINISetting INIRootFolder "folders" "folder03" @"Build\Model"
		setINISetting INIRootFolder "folders" "folder04" @"Build\Rig"
		setINISetting INIRootFolder "folders" "folder05" @"Build\Sculpt"
		setINISetting INIRootFolder "folders" "folder06" @"Build\Shade"
		setINISetting INIRootFolder "folders" "folder07" @"Cache"
		setINISetting INIRootFolder "folders" "folder08" @"Comp"
		setINISetting INIRootFolder "folders" "folder09" @"Image_Sequences"
		setINISetting INIRootFolder "folders" "folder10" @"Publish"
		setINISetting INIRootFolder "folders" "folder11" @"Publish\Material"
		setINISetting INIRootFolder "folders" "folder12" @"References"
		setINISetting INIRootFolder "folders" "folder13" @"References\Mesh"
		setINISetting INIRootFolder "folders" "folder14" @"Renders"
		setINISetting INIRootFolder "folders" "folder15" @"Surfaces"
		setINISetting INIRootFolder "folders" "folder16" @"Surfaces\Substance"

	),
	function InitializeFolderStrucure AssetFolder =
	(
		MyDir = (pathConfig.removePathLeaf (pathConfig.removePathLeaf (getSourceFileName())))
		print MyDir
		FoldersINIFile = (MyDir + @"\" + "AssetSwitch_FolderStructure.ini")
		if NOT (doesFileExist FoldersINIFile) do
		(
			CreateFolderStructureINI FoldersINIFile
		)
		FolderStructure = #()
		FolderStructure = for NewFolders in (getINISetting FoldersINIFile "folders") collect (getINISetting FoldersINIFile "folders" NewFolders)
		for Folder in FolderStructure do
		(
			makedir (AssetFolder + Folder)
		)
	)
)