struct ASwitch_UI_fun
(
	-- Sets the display and properties of the list view
	function LV_setprops sceneCheckLV =
	(
		sceneCheckLV.view 			= (dotNetClass "system.windows.forms.view").details
		sceneCheckLV.FullRowSelect 	= true													-- Set so full width of listView is selected and not just first column.
		sceneCheckLV.GridLines 		= true													-- Show lines between the items. 
		sceneCheckLV.MultiSelect 	= false													-- Set to single selection mode
		sceneCheckLV.checkboxes 	= true
		sceneCheckLV.BackColor 		= (dotNetClass "System.Drawing.Color").FromArgb 200 200 200
 		sceneCheckLV.ForeColor 		= (dotNetClass "System.Drawing.Color").FromArgb 30 30 30
		sceneCheckLV.CheckBoxes 	= true
	),

	-- Sets the width of the list view columns, and their names
	function LV_setColumns sceneCheckLV columnsAr =
	(
		sceneCheckLV.columns.add columnsAr["1"] 100
		sceneCheckLV.columns.add columnsAr["2"] 100
		sceneCheckLV.columns.add columnsAr["3"] 100
	),

	-- Sets the display and properties of the tree view
	function TV_setprops sceneCheckTV = --arg1:The scene check treeview
	(
		sceneCheckTV.CheckBoxes 	= true
		sceneCheckTV.BackColor 		= (dotNetClass "System.Drawing.Color").FromArgb 68 68 68
		sceneCheckTV.LineColor 		= (dotNetClass "System.Drawing.Color").FromArgb 30 30 30
		sceneCheckTV.ForeColor 		= (dotNetClass "System.Drawing.Color").FromArgb 200 200 200
	),

	-- Builds a progressbar ui item, to be populated with information if needed
	function UI_progress =
	(
		-- UI with two items, which are intended to be accessed and edited elswhere
		rollout waitUIrollout "" width:420 height:58
		(
			label 			lab1 	"" offset:[0,10]
			progressbar 	prog1 	offset:[0,5] width:400 height:10 value:0 color:[0,60,90]
		)

		createDialog waitUIrollout
		return waitUIrollout
	),

	-- Builds the main UI, and contains the event handlers
	function UI_main =
	(
		-- Remove any previous Scene Check windows
		try( destroyDialog ASwitch_UI )catch()

		-- Top Bar Menu Items
		rcMenu rc_MainMenu
		(
			subMenu		"Setup"
			(
				menuItem	MI_Setup1	"Set Project"
 				separator 	sep1
 				menuItem	MI_Setup2	"Open Assets Directory"
			)

			subMenu		"Asset"
			(
				menuItem	MI_Asset1	"Create Asset"
				menuItem	MI_Asset2	"Update Asset"
				menuItem	MI_Asset3	"Clear Asset from selection"
				separator 	sep2
				menuItem	MI_Asset4	"Open Asset Directory"
				menuItem	MI_Asset5	"Edit Asset Definition"
			)

			subMenu		"Help"
			(
				menuItem	MI_Help1	"Help"
				menuItem	MI_Help2	"About"
			)

			on MI_1 picked do ()
		)

		--Create the main rollout
		rollout mainUIrollout ( "Asset Switch v" + ( ASwitch_Dat.ver as string )) width:1200 height:10
		(
 			dotNetControl 	sceneCheckTV 				"system.windows.forms.treeView" pos:[0,60] 	height:200 width:250
 			dotNetControl 	sceneCheckLV 				"system.windows.forms.listView" pos:[250,0] height:200 width:949					
 			
 			-- Modify the UI items positions, when the window is resized
			on mainUIrollout resized arg do
			(
				if mainUIrollout.height < 193 then(mainUIrollout.height = 193)else()
				if mainUIrollout.height > 1000 then(mainUIrollout.height = 1000)else()
					
				sceneCheckTV.height 			= (mainUIrollout.height - 120) --80
				sceneCheckLV.height 			= (mainUIrollout.height - 40)
			)

			-- Event handler for when the UI opens
			on mainUIrollout open do
			(
   				mainUIrollout.height = 800--300  TODO: Return to previous value
			)
		)

		-- Construct the Main UI Rollout and return it
		createDialog mainUIrollout lockHeight:false lockWidth:true menu:rc_MainMenu style:#(#style_titlebar,#style_border, #style_sysmenu,#style_resizing,#style_minimizebox)	
		return mainUIrollout
	)
)

--Create the main UI, and set its position
-- ASwitch_UI = ASwitch_UI_fun.UI_main()
-- SetDialogPos ASwitch_UI [500,100]