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

from pymxs import runtime as rt

# Defines a unique name for this tool/dialog to be acessed later (to avoid having two dialogs opened at the same time)
Widget_Name = "AssetSwitchUI"
AssetSwitchUI_Version = "v2.0"

class AssetSwitchDialog(QtWidgets.QDialog):
	def __init__(self, parent = None):
		# If there is not parent
		if parent is None:
			# Gets the 3ds Max main window as the parent
			parent = qtmax.GetQMaxMainWindow()
			
		# This line runs the setup's original source code (the "__init__" constructor) of the parent class (QtWidgets.QDialog) of the AssetSwitchDialog
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
		self.setFixedSize(364, 200)

		# Builds the UI
		self.UI_Builder()

		# Prevent 3ds Max from stealing keyboard focus from the widget
		qtmax.DisableMaxAcceleratorsOnFocus(self, True)

	# The UI builder function, called to create and draw the UI elements
	def UI_Builder(self):

		# Defines the main layout of the widget to be of vertical type (meaning two main rows in this case)
		Main_Layout = QtWidgets.QVBoxLayout(self)
		# Defines the margins to be 2 pixels all around in regard to the main window's edges
		Main_Layout.setContentsMargins(2, 2, 2, 2)

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
			width:120px;
			color: lightgray;
			}
			QListWidget::item:hover {
			color: #FFFFFF;
			background-color: #333333
			}
			QListWidget::item:selected {
			background-color: #444444;
			color: #FFFFFF;
			/*border-top: 4px solid #444444;*/
			}
		""")
		# Since we created a QListWidget we also need to create specific items to populate it
		# Creates the Items of the tabbed list
		Create_Tab = QtWidgets.QListWidgetItem("Create")
		Create_Tab.setTextAlignment(QtCore.Qt.AlignCenter)
		Publish_Tab = QtWidgets.QListWidgetItem("Publish")
		Publish_Tab.setTextAlignment(QtCore.Qt.AlignCenter)
		Switch_Tab = QtWidgets.QListWidgetItem("Switch")
		Switch_Tab.setTextAlignment(QtCore.Qt.AlignCenter)

		self.Top_Panel.addItem(Create_Tab)
		self.Top_Panel.addItem(Publish_Tab)
		self.Top_Panel.addItem(Switch_Tab)

		self.Main_Content = QtWidgets.QStackedWidget()

		Create_Page = self._Create_Page()
		Publish_Page = self._Publish_Page()
		Switch_Page = self._Switch_Page()

		self.Main_Content.addWidget(Create_Page)
		self.Main_Content.addWidget(Publish_Page)
		self.Main_Content.addWidget(Switch_Page)

		# Connects the Top_Panel tabs to the Main_Content QStackedWidget, and everytime the Tab is changed
		# its signal is sent as the current index for the Main_Content QStackedWidget.
		self.Top_Panel.currentRowChanged.connect(self.Main_Content.setCurrentIndex)

		# Sets the first tab to be selected at launch to be tab 0 (the first one)
		self.Top_Panel.setCurrentRow(0)

		#Adds the Top_Panel QListWidget() to the Main_Layout's QVBoxLayout
		Main_Layout.addWidget(self.Top_Panel)

		#Adds the Main_Content QListWidget() to the Main_Layout's QVBoxLayout
		Main_Layout.addWidget(self.Main_Content)

	def _Create_Page(self):
		# Creates a QWidget instance to hold the UI elements
		Page = QtWidgets.QWidget()
		# Creates a QVBoxLayout (vertical) layout based on the default QWidget to house the UI elements to be created
		Layout = QtWidgets.QVBoxLayout(Page)
		Label = QtWidgets.QLabel("Create Page")
		Label.setAlignment(QtCore.Qt.AlignCenter)
		Layout.addWidget(Label)
		return Page
	def _Publish_Page(self):
		# Creates a QWidget instance to hold the UI elements
		Page = QtWidgets.QWidget()
		# Creates a QVBoxLayout (vertical) layout based on the default QWidget to house the UI elements to be created
		Layout = QtWidgets.QVBoxLayout(Page)
		Label = QtWidgets.QLabel("Publish Page")
		Label.setAlignment(QtCore.Qt.AlignCenter)
		Layout.addWidget(Label)
		return Page
	def _Switch_Page(self):
		# Creates a QWidget instance to hold the UI elements
		Page = QtWidgets.QWidget()
		# Creates a QVBoxLayout (vertical) layout based on the default QWidget to house the UI elements to be created
		Layout = QtWidgets.QVBoxLayout(Page)
		Label = QtWidgets.QLabel("Switch Page")
		Label.setAlignment(QtCore.Qt.AlignCenter)
		Layout.addWidget(Label)
		return Page

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
