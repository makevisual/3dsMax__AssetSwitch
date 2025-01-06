
ASwitch_Ver										= "2.0 Alpha"
ASwitchFile_AssetSwitch_Functions				= @"U:\Make_Tools\AssetSwitch\Release\2.0\bin\AssetSwitch_Functions.ms"
ASwitchFile_AssetSwitch_UI						= @"U:\Make_Tools\AssetSwitch\Release\2.0\bin\AssetSwitch_UI.ms"
ASwitchFile_PublishCenter_Functions 			= @"U:\Make_Tools\AssetSwitch\Release\2.0\bin\PublishCenter_Functions.ms"
ASwitchFile_PublishCenter_UI 	 				= @"U:\Make_Tools\AssetSwitch\Release\2.0\bin\PublishCenter_UI.ms"

global ASwitch_Dat								-- Item to hold all Asset Switch session Data
global ASwitch_UI 	 							-- Item to reference the Main UI
global ASwitch_UI_fun 							-- Library of functions for the Main UI
global ASwitch_fun 								-- Library of functions for the Asset Switch
global ASwitchPublish_UI 						-- Item to reference the Publish Center UI
global ASwitchPublish_UI_fun 					-- Library of functions for the Publish Center UI
global ASwitchPublish_fun 						-- Library of functions for the Publish Center

filein ASwitchFile_AssetSwitch_Functions 		-- Load the Asset Switch Functions
filein ASwitchFile_AssetSwitch_UI 				-- Load the Asset Switch UI
filein ASwitchFile_PublishCenter_Functions 		-- Load the Asset Switch Functions
filein ASwitchFile_PublishCenter_UI				-- Load the Asset Switch UI



-- THIS IS THE TESTING
ASwitch_Dat 		= ASwitch_Dat_Str()
ASwitch_Dat.ver 	= ASwitch_Ver
ASwitch_Dat.project = @"X:\Projects\Mechsplorers"