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

globalASSET_Functions

versionNumber = 1.3

filein @"U:\Make_Tools\AssetSwitch\Release\1.3\bin\AssetSwitchFunctions.ms"
filein @"U:\Make_Tools\AssetSwitch\Release\1.3\bin\AssetSwitchUI.ms"