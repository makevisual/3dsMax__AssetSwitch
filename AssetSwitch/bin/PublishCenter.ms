global ASSET_PublishCenterRollout
--global ASSET_PublishFunctions
global ASSET_PublishOptions
global nodeAssetForPublish
global nodeAssetHandle = nodeAsset.inode.handle
global assetName


(local 

	AssetSwitchDirectory = (pathConfig.removePathLeaf (getSourceFileName()))

	--filein (AssetSwitchDirectory + @"\PublishModulesStruct.ms")
	filein (AssetSwitchDirectory + @"\PublishCenterUI.ms")
)