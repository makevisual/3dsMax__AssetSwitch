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

global nodeAsset = undefined  					-- The target node
global switchObjectsHandleArray = undefined 	-- The objects selected when a switch is performed (used for fetching)

global FN_DoSwitch_Type
global FN_Callback_SelectionChange
global FN_setup_Initalize

global ASSET_Functions
global ASSET_FolderStructure

versionNumber = "1.7.0"
(local 

	AssetSwitchDirectory = (pathConfig.removePathLeaf (getSourceFileName()))
	global PublishCenterExecutable = AssetSwitchDirectory +  @"\bin\PublishCenter.ms"

	filein (AssetSwitchDirectory + @"\bin\PublishModulesStruct.ms")
	filein (AssetSwitchDirectory + @"\bin\AssetSwitchFunctions.ms")
	filein (AssetSwitchDirectory + @"\bin\AssetSwitchFolderStructure.ms")
	filein (AssetSwitchDirectory + @"\bin\AssetSwitchUI.ms")
)
