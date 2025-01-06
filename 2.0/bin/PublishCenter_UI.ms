struct ASwitchPublish_UI_fun
(
	function UI_main =
	(
		try( destroyDialog ASwitchPublish_UI )catch()

		rollout mainUIrollout_pub ( "Publish Center v" + ( ASwitch_Dat.ver as string )) width:500 height:100
		(
			label lab1 "test"
		)

		createDialog mainUIrollout_pub lockHeight:false lockWidth:true --menu:rc_MainMenu style:#(#style_titlebar,#style_border, #style_sysmenu,#style_resizing,#style_minimizebox)	
		return mainUIrollout_pub
	)
)

-- ASwitchPublish_UI = ASwitchPublish_UI_fun.UI_main()