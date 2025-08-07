'''
#NAME:AssetSwitch_TabbedUI
#VERSION:1.0.0
#DESCRIPTION:
This is a full rewrite of the AssetSwitch tool using Python.
Creates the UI for Asset Creation, Publishing and Switching.
#SOURCE:david.almeida@makevisual.com

*****************************************************
 Tool part of MAKE's Asset Switch
 Modified by david.almeida@makevisual.com
*****************************************************
 HISTORY:
 version 1.0.0  : 07.15.2025 >> First Version
*****************************************************
'''

from PySide2 import QtCore, QtGui, QtWidgets
import qtmax
import textwrap

from pymxs import runtime as rt

# Defines a unique name for this tool/dialog to be acessed later (to avoid having two dialogs opened at the same time)
Widget_Name = "AssetSwitchUI"
AssetSwitchUI_Version = "v2.0"

# Creates a new Spinner Class to make QSpinBox behave like regular 3dsMax spinners
# Based on Spencer's solution posted on StackOverflow on this page https://stackoverflow.com/questions/20922836/increases-decreases-qspinbox-value-when-click-drag-mouse-python-pyside
class MaxSpinner(QtWidgets.QSpinBox):
	def __init__(self, parent = None): #ask why the parent has to be equal to none
		super().__init__(parent)
		self.Mouse_Start_PosY = 0
		self.Spinner_Start_Value = 0
		self.LeftButtonPressed = True

	def mousePressEvent(self, event):
		super().mousePressEvent(event)
		if event.button() == QtCore.Qt.RightButton:
			self.setContextMenuPolicy(QtCore.Qt.NoContextMenu)
			self.setValue(self.minimum())
			self.LeftButtonPressed = False
			return
		else:
			self.LeftButtonPressed = True
			self.setContextMenuPolicy(QtCore.Qt.DefaultContextMenu)
			self.Mouse_Start_PosY = event.pos().y()
			self.Spinner_Start_Value = self.value()
	def mouseMoveEvent(self, event):
		if self.LeftButtonPressed:
			self.setCursor(QtCore.Qt.SizeVerCursor)
			multiplier = 0.5
			ValueOffset = int((self.Mouse_Start_PosY - event.pos().y())*multiplier)
			self.setValue(self.Spinner_Start_Value + ValueOffset)
	def mouseReleaseEvent(self, event):
		super().mouseReleaseEvent(event)
		self.unsetCursor()



# Creates the AssetSwitchDialog Class, based on the QDialog parent Class
class AssetSwitchDialog(QtWidgets.QDialog):
	PROGRESS_BAR_DEFAULT_COLOR = "#0078D7"
	PROGRESS_BAR_SUCCESS_COLOR = "#1C6940"
	PROGRESS_BAR_FAILURE_COLOR = "#7B0A18"
	PUBLISH_PROGRESSBAR_STYLESHEET = """
		QProgressBar {{ max-height: 16px; font: 11px; border: none; background-color: #2B2B2B; }}
		QProgressBar::chunk {{ background-color: {chunk_color}; }}
	"""
	def __init__(self, parent = None):
		# If there is no parent
		if parent is None:
			# Gets the 3ds Max main window as the parent
			parent = qtmax.GetQMaxMainWindow()
			
		# This line runs the setup's original source code (the "__init__" constructor) of the parent class (QtWidgets.QDialog) of the AssetSwitchDialog to initialize it
		super().__init__(parent)

		# Sets the dialog to be of "tool" type, making it simpler (no "?" icon) and cleaner
		self.setWindowFlags(QtCore.Qt.Tool)

		# Sets an attribute that ensures the dialog is deleted and its memory used free after it is closed.
		self.setAttribute(QtCore.Qt.WA_DeleteOnClose)

		# Sets the dialog title
		self.setWindowTitle(f"Asset Switch {AssetSwitchUI_Version}")

		# Sets the ObjectName of this Dialog, so we can reliably check to have only one instance open at a time
		self.setObjectName(Widget_Name)

		# Sets an initial size
		self.setFixedSize(320, 250)

		# Some variables (Instance Attributes) to be used across the Instanced AssetSwitchDialog Class
		self.Create_ProjectPath = rt.pathConfig.getCurrentProjectFolder()
		self.Create_Category_Items = ["Characters", "Effects", "Misc", "Objects", "Sets"]
		self.Create_AssetPath = "\\Assets\\Characters\\_\\"

		# Builds the UI
		self.UI_Builder()

		# Prevent 3ds Max from stealing keyboard focus from the widget
		qtmax.DisableMaxAcceleratorsOnFocus(self, True)

	def UI_Resizer(self, Index):
		match Index:
			case 0: # Create Tab selected
				self.setFixedSize(325, 250)
			case 1: # Publish Tab selected
				self.setFixedSize(325, 520)
			case 2: # Switch Tab selected
				self.setFixedSize(325, 300)

	# The UI builder function, called to create and draw the UI elements
	def UI_Builder(self):

		# Defines the main layout of the widget to be of vertical type (meaning two main rows in this case)
		Main_Layout = QtWidgets.QVBoxLayout(self)
		# Defines the margins to be 2 pixels all around in regard to the main window's edges
		Main_Layout.setContentsMargins(2, 2, 2, 2)
		#Main_Layout.setSpacing(0)

		# Tabbed Navigation
		# Creates a QListWidget to hold the tabs
		self.Top_Panel = QtWidgets.QListWidget()
		# Sets the flow of the list to be from left to right (so it is horizontal)
		self.Top_Panel.setFlow(QtWidgets.QListView.LeftToRight)
		# Sets the Top_Panel height to be fixed at the specified number of pixels
		self.Top_Panel.setFixedHeight(30)

		self.Top_Panel.setStyleSheet("""
			QListWidget {
			background: #2B2B2B;
			border: none;
			outline:0;
			font: 13px;
			}
			QListWidget::item {
			width:105;
			color: lightgray;
			border-right: 1px solid #444444;
			border-left: 1px solid #444444;
			}
			QListWidget::item:hover {
			color: #FFFFFF;
			background-color: #333333
			}
			QListWidget::item:selected {
			background-color: #444444;
			color: #FFFFFF;
			border-bottom: 4px solid #444444;
			}
		""")
		# Since we created a QListWidget we also need to create specific items to populate it
		# Creates the Items (tabs) of the tabbed list and then sets the text alignment of such Items (tabs) to be centered (both vertically and horizontally)
		Create_Tab = QtWidgets.QListWidgetItem("Create")
		Create_Tab.setTextAlignment(QtCore.Qt.AlignCenter)
		Publish_Tab = QtWidgets.QListWidgetItem("Publish")
		Publish_Tab.setTextAlignment(QtCore.Qt.AlignCenter)
		Switch_Tab = QtWidgets.QListWidgetItem("Switch")
		Switch_Tab.setTextAlignment(QtCore.Qt.AlignCenter)

		# Adds each created Item (tab) to the Top_Panel
		self.Top_Panel.addItem(Create_Tab)
		self.Top_Panel.addItem(Publish_Tab)
		self.Top_Panel.addItem(Switch_Tab)

		# Creates a Stacked Widget (QStackedWidget) to hold the UI elements that will populate each "Page" when a tab from the Top_Panel is selected
		self.Main_Content = QtWidgets.QStackedWidget()

		# Creates the "Pages" for the Main_Content QStackedWidget by calling a function that will create the UI for each "page"
		Create_Page = self._Create_Page()
		Publish_Page = self._Publish_Page()
		Switch_Page = self._Switch_Page()

		# Adds each "Page" to the Main_Content QStackedWidget
		self.Main_Content.addWidget(Create_Page)
		self.Main_Content.addWidget(Publish_Page)
		self.Main_Content.addWidget(Switch_Page)




		#self.Main_Content.setStyleSheet("""
		#	QStackedWidget > QWidget {
		#	border-right: 1px solid #222222;
		#	border-left: 1px solid #222222;
		#	border-bottom: 1px solid #222222;
		#	}
		#""")








		# Connects the Top_Panel tabs to the Main_Content QStackedWidget, and everytime the Tab is changed
		# its signal is sent as the current index for the Main_Content QStackedWidget.
		self.Top_Panel.currentRowChanged.connect(self.Main_Content.setCurrentIndex)

		self.Top_Panel.currentRowChanged.connect(self.UI_Resizer)

		# Sets the first tab to be selected at launch to be tab 0 (the first one)
		self.Top_Panel.setCurrentRow(1)

		#Adds the Top_Panel QListWidget() to the Main_Layout's QVBoxLayout
		Main_Layout.addWidget(self.Top_Panel)

		#Adds the Main_Content QStackedWidget() to the Main_Layout's QVBoxLayout
		Main_Layout.addWidget(self.Main_Content)





	# Function run when the tool is launched to build and return the "Create" page that is shown when the "Create" tab from the Top_Panel is selected
	def _Create_Page(self):
		# Creates a QWidget instance
		Page = QtWidgets.QWidget()
		# Creates a QVBoxLayout (vertical) layout based on the default QWidget to house the UI elements to be created
		Layout = QtWidgets.QVBoxLayout(Page)
		# Creates a Label to populate and sets its text
		#Label = QtWidgets.QLabel("Create Page")
		# Adds the label to the Layout QVBoxLayout widget and aligns the label to the center of the Layout
		#Layout.addWidget(Label, alignment=QtCore.Qt.AlignCenter)

		# Creates the Project groupbox
		Project_GroupBox = QtWidgets.QGroupBox("Project")
		Project_GroupBox_Layout = QtWidgets.QVBoxLayout(Project_GroupBox)

		# Button to select a folder
		Project_Button = QtWidgets.QPushButton("Choose Project Folder")
		Project_Button.setToolTip("Select the root directory of the current project")
		Project_Button.clicked.connect(self.OpenFolder_Function)

		# Label to display the selected folder path
		self.Project_Label = QtWidgets.QLabel("No folder selected", alignment = QtCore.Qt.AlignCenter, styleSheet = "border: 1px solid gray; padding: 2px;")

		# Adds the Project Button and the Project Label to the Project Layout
		Project_GroupBox_Layout.addWidget(Project_Button)
		Project_GroupBox_Layout.addWidget(self.Project_Label)

		# Creates the Asset Information groupbox
		AssetInfo_GroupBox = QtWidgets.QGroupBox("Asset Information")
		AssetInfo_GroupBox_Layout = QtWidgets.QVBoxLayout(AssetInfo_GroupBox)

		# Creates and configures the Category Combobox (Dropdownlist)
		self.Asset_Category_ComboBox = QtWidgets.QComboBox()
		self.Asset_Category_ComboBox.addItems(self.Create_Category_Items)
		self.Asset_Category_ComboBox.setToolTip("Select the Asset's Category")
		# This LAMBDA function grabs the signal that is connected (in this case, the name of the selected Asset_Category of the ComboBox)
		# and allows to call the Asset_Label_Renamer_Function adding to it more than just one variable
		self.Asset_Category_ComboBox.currentTextChanged.connect(
			lambda Selected_Category: self.Asset_Label_Renamer_Function(Selected_Category, self.Asset_Tag_TextField.text(), self.Asset_Name_TextField.text()))

		# Creates a new Layout to house the next QLineEdit (text field entries) in a horizontal layout
		Create_Category_Layout = QtWidgets.QHBoxLayout()

		# Creates and configures the Asset Tag QLineEdit (text field)
		self.Asset_Tag_TextField = QtWidgets.QLineEdit()
		self.Asset_Tag_TextField.setToolTip("Type a 3 letter Asset Tag")
		self.Asset_Tag_TextField.setFixedWidth(80)
		self.Asset_Tag_TextField.setMaxLength(3)
		self.Asset_Tag_TextField.setPlaceholderText("Asset Tag")
		self.Asset_Tag_TextField.textChanged.connect(self.Tag_Change_Function)

		# Creates and configures the Asset Name QLineEdit (text field)
		self.Asset_Name_TextField = QtWidgets.QLineEdit()
		self.Asset_Name_TextField.setToolTip("Type the Asset's Name")
		self.Asset_Name_TextField.setPlaceholderText("Asset Name")
		# This LAMBDA function grabs the signal that is connected (in this case, the entered text on the Asset_Name's QLineEdit)
		# and allows to call the Asset_Label_Renamer_Function adding to it more than just one variable
		self.Asset_Name_TextField.textChanged.connect(
			lambda Entered_Name: self.Asset_Label_Renamer_Function(self.Asset_Category_ComboBox.currentText(), self.Asset_Tag_TextField.text(), Entered_Name))

		# Adds the Tag and Name QLineEdit (text field) to the Create_Category_Layout
		Create_Category_Layout.addWidget(self.Asset_Tag_TextField)
		Create_Category_Layout.addWidget(self.Asset_Name_TextField)

		# Adds the Asset_Category_ComboBox widget to the AssetInfo_GroupBox_Layout
		AssetInfo_GroupBox_Layout.addWidget(self.Asset_Category_ComboBox)
		# Adds the Create_Category_Layout layout to the AssetInfo_GroupBox_Layout
		AssetInfo_GroupBox_Layout.addLayout(Create_Category_Layout)

		#Creates the Create Asset groupbox
		CreateAsset_GroupBox = QtWidgets.QGroupBox("Create Asset")
		CreateAsset_GroupBox_Layout = QtWidgets.QVBoxLayout(CreateAsset_GroupBox)

		Asset_Create_Button = QtWidgets.QPushButton("Create Asset")

		self.Asset_Create_Label = QtWidgets.QLabel(self.Create_AssetPath, alignment = QtCore.Qt.AlignCenter, styleSheet = "border: 1px solid gray; padding: 2px;")



		CreateAsset_GroupBox_Layout.addWidget(Asset_Create_Button)
		CreateAsset_GroupBox_Layout.addWidget(self.Asset_Create_Label)

		Layout.addWidget(Project_GroupBox)
		Layout.addWidget(AssetInfo_GroupBox)
		Layout.addWidget(CreateAsset_GroupBox)
		return Page









































	def _Publish_Page(self):
		# Creates a QWidget instance to hold the UI elements
		Page = QtWidgets.QWidget()
		# Creates a QVBoxLayout (vertical) layout based on the default QWidget to house the UI elements to be created
		Layout = QtWidgets.QVBoxLayout(Page)

		# 3dsMax File Group
		Max_GroupBox = QtWidgets.QGroupBox("3dsMax File")
		Max_GroupBox.setCheckable(True)
		Max_GroupBox_Layout = QtWidgets.QVBoxLayout(Max_GroupBox)
		Max_GroupBox_Version_Layout = QtWidgets.QHBoxLayout()
		#Max_Label_Version = QtWidgets.QLabel("Version:")
		Max_Version_TextField = QtWidgets.QLineEdit("ver")
		Max_Version_TextField.setFixedSize(50, 20)
		Max_Version_TextField.setToolTip("Prefix for published 3dsMax file")

		Max_Version_Spinner = MaxSpinner()
		Max_Version_Spinner.setFixedHeight(18)
		Max_Version_Spinner.setMinimum(1)
		Max_Version_Spinner.setMaximum(999)
		Max_Version_Spinner.setToolTip("Version number for published 3dsMax file")

		Max_Options_Button = QtWidgets.QPushButton("Options")
		Max_Options_Button.setFixedSize(50, 20)
		Max_Options_Button.setToolTip("3dsMax publishing options")

		Max_GroupBox_Version_Layout.addWidget(Max_Version_TextField)
		Max_GroupBox_Version_Layout.addWidget(Max_Version_Spinner)
		Max_GroupBox_Version_Layout.addStretch()
		Max_GroupBox_Version_Layout.addWidget(Max_Options_Button)
		Max_Path_Label = QtWidgets.QLabel("Default\\Max\\Path", alignment = QtCore.Qt.AlignCenter, styleSheet = "border: 1px solid gray; padding: 2px; max-height: 12px;")
		Max_GroupBox_Layout.addLayout(Max_GroupBox_Version_Layout)
		Max_GroupBox_Layout.addWidget(Max_Path_Label)

		# Animation File Group
		Animation_GroupBox = QtWidgets.QGroupBox("Animation File")
		Animation_GroupBox.setCheckable(True)
		Animation_GroupBox_Layout = QtWidgets.QVBoxLayout(Animation_GroupBox)
		Animation_GroupBox_Version_Layout = QtWidgets.QHBoxLayout()
		#Animation_Label_Version = QtWidgets.QLabel("Version:")

		Animation_Version_TextField = QtWidgets.QLineEdit("ver")
		Animation_Version_TextField.setFixedSize(50, 20)
		Animation_Version_TextField.setToolTip("Prefix for published Animation file")

		Animation_Version_Spinner = MaxSpinner()
		Animation_Version_Spinner.setFixedHeight(18)
		Animation_Version_Spinner.setMinimum(1)
		Animation_Version_Spinner.setMaximum(999)
		Animation_Version_Spinner.setToolTip("Version number for published Animation file")

		Animation_Options_Button = QtWidgets.QPushButton("Options")
		Animation_Options_Button.setFixedSize(50, 20)
		Animation_Options_Button.setToolTip("Animation publishing options")

		Animation_GroupBox_Version_Layout.addWidget(Animation_Version_TextField)
		Animation_GroupBox_Version_Layout.addWidget(Animation_Version_Spinner)
		Animation_GroupBox_Version_Layout.addStretch()
		Animation_GroupBox_Version_Layout.addWidget(Animation_Options_Button)
		Max_Path_Label = QtWidgets.QLabel("Default\\Animation\\Path", alignment = QtCore.Qt.AlignCenter, styleSheet = "border: 1px solid gray; padding: 2px; max-height: 12px;")
		Animation_GroupBox_Layout.addLayout(Animation_GroupBox_Version_Layout)
		Animation_GroupBox_Layout.addWidget(Max_Path_Label)

		# Material File Group
		Material_GroupBox = QtWidgets.QGroupBox("Material File")
		Material_GroupBox.setCheckable(True)
		Material_GroupBox_Layout = QtWidgets.QVBoxLayout(Material_GroupBox)
		Material_GroupBox_Version_Layout = QtWidgets.QHBoxLayout()
		#Material_Label_Version = QtWidgets.QLabel("Version:")
		Material_Version_TextField = QtWidgets.QLineEdit("ver")
		Material_Version_TextField.setFixedSize(50, 20)
		Material_Version_TextField.setToolTip("Prefix for published Material file")

		Material_Version_Spinner = MaxSpinner()
		Material_Version_Spinner.setFixedHeight(18)
		Material_Version_Spinner.setMinimum(1)
		Material_Version_Spinner.setMaximum(999)
		Material_Version_Spinner.setToolTip("Version number for published Material file")

		Material_Options_Button = QtWidgets.QPushButton("Options")
		Material_Options_Button.setFixedSize(50, 20)
		Material_Options_Button.setToolTip("Material publishing options")

		Material_GroupBox_Version_Layout.addWidget(Material_Version_TextField)
		Material_GroupBox_Version_Layout.addWidget(Material_Version_Spinner)
		Material_GroupBox_Version_Layout.addStretch()
		Material_GroupBox_Version_Layout.addWidget(Material_Options_Button)
		#Material_GroupBox_Version_Layout.addStretch()
		Max_Path_Label = QtWidgets.QLabel("Default\\Material\\Path", alignment = QtCore.Qt.AlignCenter, styleSheet = "border: 1px solid gray; padding: 2px; max-height: 12px;")
		Material_GroupBox_Layout.addLayout(Material_GroupBox_Version_Layout)
		Material_GroupBox_Layout.addWidget(Max_Path_Label)

		# VrayMesh File Group
		VRayMesh_GroupBox = QtWidgets.QGroupBox("VRayMesh File")
		VRayMesh_GroupBox.setCheckable(True)
		VRayMesh_GroupBox_Layout = QtWidgets.QVBoxLayout(VRayMesh_GroupBox)
		VRayMesh_GroupBox_Version_Layout = QtWidgets.QHBoxLayout()
		#VRayMesh_Label_Version = QtWidgets.QLabel("Version:")
		VRayMesh_Version_TextField = QtWidgets.QLineEdit("ver")
		VRayMesh_Version_TextField.setFixedSize(50, 20)
		VRayMesh_Version_TextField.setToolTip("Prefix for published VRayMesh file")

		VRayMesh_Version_Spinner = MaxSpinner()
		VRayMesh_Version_Spinner.setFixedHeight(18)
		VRayMesh_Version_Spinner.setMinimum(1)
		VRayMesh_Version_Spinner.setMaximum(999)
		VRayMesh_Version_Spinner.setToolTip("Version number for published VRayMesh file")

		VRayMesh_Options_Button = QtWidgets.QPushButton("Options")
		VRayMesh_Options_Button.setFixedSize(50, 20)
		VRayMesh_Options_Button.setToolTip("VRayMesh publishing options")

		VRayMesh_GroupBox_Version_Layout.addWidget(VRayMesh_Version_TextField)
		VRayMesh_GroupBox_Version_Layout.addWidget(VRayMesh_Version_Spinner)

		VRayMesh_GroupBox_Version_Layout.addStretch()
		VRayMesh_GroupBox_Version_Layout.addWidget(VRayMesh_Options_Button)
		Max_Path_Label = QtWidgets.QLabel("Default\\VRayMesh\\Path", alignment = QtCore.Qt.AlignCenter, styleSheet = "border: 1px solid gray; padding: 2px; max-height: 12px;")
		VRayMesh_GroupBox_Layout.addLayout(VRayMesh_GroupBox_Version_Layout)
		VRayMesh_GroupBox_Layout.addWidget(Max_Path_Label)

		# VrayMeshParts File Group
		VRayMeshParts_GroupBox = QtWidgets.QGroupBox("VRayMeshParts File")
		VRayMeshParts_GroupBox.setCheckable(True)
		VRayMeshParts_GroupBox_Layout = QtWidgets.QVBoxLayout(VRayMeshParts_GroupBox)
		VRayMeshParts_GroupBox_Version_Layout = QtWidgets.QHBoxLayout()
		#VRayMeshParts_Label_Version = QtWidgets.QLabel("Version:")
		VRayMeshParts_Version_TextField = QtWidgets.QLineEdit("ver")
		VRayMeshParts_Version_TextField.setFixedSize(50, 20)
		VRayMeshParts_Version_TextField.setToolTip("Prefix for published VRayMeshParts file")

		VRayMeshParts_Version_Spinner = MaxSpinner()
		VRayMeshParts_Version_Spinner.setFixedHeight(18)
		VRayMeshParts_Version_Spinner.setMinimum(1)
		VRayMeshParts_Version_Spinner.setMaximum(999)
		VRayMeshParts_Version_Spinner.setToolTip("Version number for published VRayMeshParts file")
		
		VRayMeshParts_GroupBox_Version_Layout.addWidget(VRayMeshParts_Version_TextField)
		VRayMeshParts_GroupBox_Version_Layout.addWidget(VRayMeshParts_Version_Spinner)
		VRayMeshParts_GroupBox_Version_Layout.addStretch()
		Max_Path_Label = QtWidgets.QLabel("Default\\VRayMeshParts\\Path", alignment = QtCore.Qt.AlignCenter, styleSheet = "border: 1px solid gray; padding: 2px; max-height: 12px;")
		VRayMeshParts_GroupBox_Layout.addLayout(VRayMeshParts_GroupBox_Version_Layout)
		VRayMeshParts_GroupBox_Layout.addWidget(Max_Path_Label)

		Layout.addWidget(Max_GroupBox)
		Layout.addWidget(Animation_GroupBox)
		Layout.addWidget(Material_GroupBox)
		Layout.addWidget(VRayMesh_GroupBox)
		Layout.addWidget(VRayMeshParts_GroupBox)
		#Label = QtWidgets.QLabel("Publish Page")
		#Layout.addWidget(Label, alignment=QtCore.Qt.AlignCenter)


		Publish_GroupBox = QtWidgets.QGroupBox("Publish Settings")
		Publish_GroupBox_Layout = QtWidgets.QVBoxLayout(Publish_GroupBox)

		Publish_Label = QtWidgets.QLabel("Label Inside GroupBox!", alignment = QtCore.Qt.AlignCenter, styleSheet = "border: 1px solid gray; padding: 2px; min-height: 12px;")
		Publish_Button = QtWidgets.QPushButton("Publish (N) Assets")
		self.Publish_ProgressBar = QtWidgets.QProgressBar(alignment = QtCore.Qt.AlignCenter)
		self.Publish_ProgressBar.setFormat("Status: ready %p%")
		self.Publish_ProgressBar.reset()
		self.Publish_ProgressBar.valueChanged.connect(self.Publish_ProgressBar_Update_Function)
		self.Publish_ProgressBar.setValue(90)
		#Publish_Status_GroupBox = QtWidgets.QLabel("Status: ready", alignment = QtCore.Qt.AlignCenter, styleSheet = "max-height: 12px; font: 11px; background: #334052;padding-bottom: 2px;")
		Publish_Button.setFixedSize(301, 40)






		Publish_GroupBox_Layout.addWidget(Publish_Label)
		Publish_GroupBox_Layout.addWidget(Publish_Button, alignment=QtCore.Qt.AlignCenter)
		Publish_GroupBox_Layout.addWidget(self.Publish_ProgressBar)
		#Publish_GroupBox_Layout.addWidget(Publish_Status_GroupBox)

		Layout.addWidget(Publish_GroupBox)
		return Page

































	def Publish_ProgressBar_Update_Function(self, Value):
		match Value:
			case 0:
				self.Publish_ProgressBar.setFormat("Status: ready")
				Publish_StyleSheet = self.PUBLISH_PROGRESSBAR_STYLESHEET.format(chunk_color = self.PROGRESS_BAR_DEFAULT_COLOR)
			case 100:
				self.Publish_ProgressBar.setFormat("Status: done")
				Publish_StyleSheet = self.PUBLISH_PROGRESSBAR_STYLESHEET.format(chunk_color = self.PROGRESS_BAR_SUCCESS_COLOR)
			case _:
				self.Publish_ProgressBar.setFormat("Status: %p%")
				Publish_StyleSheet = self.PUBLISH_PROGRESSBAR_STYLESHEET.format(chunk_color = self.PROGRESS_BAR_DEFAULT_COLOR)
		self.Publish_ProgressBar.setStyleSheet(Publish_StyleSheet)






	def Asset_Label_Renamer_Function(self, Category_Part, Tag_Part, Name_Part):
		self.Create_AssetPath = f"\\Assets\\{Category_Part}\\{Tag_Part}_{Name_Part}"
		self.Asset_Create_Label.setText(self.Create_AssetPath)

	def Tag_Change_Function(self, Text):
		Cursor_Position = self.Asset_Tag_TextField.cursorPosition()
		self.Asset_Tag_TextField.blockSignals(True)
		self.Asset_Tag_TextField.setText(Text.upper())
		self.Asset_Tag_TextField.blockSignals(False)
		self.Asset_Tag_TextField.setCursorPosition(Cursor_Position)
		self.Asset_Label_Renamer_Function(self.Asset_Category_ComboBox.currentText(), self.Asset_Tag_TextField.text(), self.Asset_Name_TextField.text())

	def _Switch_Page(self):
		# Creates a QWidget instance to hold the UI elements
		Page = QtWidgets.QWidget()
		# Creates a QVBoxLayout (vertical) layout based on the default QWidget to house the UI elements to be created
		Layout = QtWidgets.QVBoxLayout(Page)
		Label = QtWidgets.QLabel("Switch Page")
		Layout.addWidget(Label, alignment=QtCore.Qt.AlignCenter)
		return Page


	def Truncate_Text_Function(self, Text, MaxSize):
		"""Helper method to shorten a path for display in the UI."""
		 # If the path is smaler than MaxSize characters, return as it is
		if len(Text) <= MaxSize:
			return Text
		 # Set the start of the string to be 8 characters long
		stringStart = Text[:8]
		stringEnd = Text[-(MaxSize - len(stringStart) - 3):]
		return f"{stringStart}...{stringEnd}"





	def OpenFolder_Function(self):
		Start_Path = self.Create_ProjectPath
		Project_Path = QtWidgets.QFileDialog.getExistingDirectory(self, "Select a folder", Start_Path)
		if Project_Path:
			Project_Path = Project_Path.replace('/','\\')
			print(f"Selected Folder:{Project_Path}")
			self.Create_ProjectPath = Project_Path
			Disply_Path = self.Truncate_Text_Function(Project_Path, 55)
			self.Project_Label.setText(Disply_Path)
			self.Project_Label.setToolTip("\n".join(textwrap.wrap(Project_Path, 50)))





# Function to close any running instance of the AssetSwitch Dialog and launch a new one
def AssetSwitch_Lauch():
	# Creates a reference to 3dsMax's main window
	main_window = qtmax.GetQMaxMainWindow()
	# Collects all the dialogs that are children of 3dsMax and has the name defined by the variable "Widget_Name"
	existing_dialogs = main_window.findChildren(QtWidgets.QDialog, Widget_Name)
	# Checks if the list collected has any elements
	if existing_dialogs:
		# Cycles through all dialogs found
		for dialog in existing_dialogs:
			# Close each dialog and, since we added the "self.setAttribute(QtCore.Qt.WA_DeleteOnClose)" it will also free up memory
			dialog.close()
	# Creating a Global Variable that will hold the dialog instance so it is not garbage collected (and deleted) by Qt after the function ends
	global AssetSwitchDialog_Instance
	# Creates a new instance of the AssetSwitch Dialog
	AssetSwitchDialog_Instance = AssetSwitchDialog()
	# Launches the new instance
	AssetSwitchDialog_Instance.show()
# Script entry point, checks is the script is being run by the user or being imported by another script
if __name__ == '__main__':
	# If it is being run by the user, launches the script
	AssetSwitch_Lauch()
