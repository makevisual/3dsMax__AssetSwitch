-- Object for holding all of the asset profiles
struct ASwitch_Assets_Str
(	
	characters 	= #(),
	effects  	= #(),
	misc  		= #(),
	objects  	= #(),
	sets  		= #()
)	

-- Object for holding indifidual asset profiles
struct ASwitch_AssetProfile_Str
(
	dir			= undefined,
	versions 	= undefined
)

-- Object for holding the current assets information
struct ASwitch_CurAsset_Str
(	
	profile	 	= undefined,
	animHandle 	= undefined
)	

-- Item to hold all Asset Switch session Data
struct ASwitch_Dat_Str
(
	ver 		= undefined,
	project		= undefined,
	assets 		= ASwitch_Assets_Str(),
	curAsset 	= undefined
)

-- Library of functions for the Asset Switch
struct ASwitch_fun
(
	function test = (print "ASwitch_fun Working!"),

	function collectAssets =
	(
		ASwitch_Dat.assets = ASwitch_Assets_Str()
	),

	function getAssetsInDir =
	(
-- 		ASwitch_Dat.project
	)

)

-- ASwitch_Dat 	= ASwitch_Dat_Str()
-- ASwitch_Dat.ver = ASwitch_Ver