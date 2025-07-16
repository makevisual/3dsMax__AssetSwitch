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
	def __init__(self, parent=None):
		#If there is not parent
		if parent == None:
			# Gets the 3ds Max main window as the parent
			parent = qtmax.GetQMaxMainWindow()
		super().__init__(parent)
		# Sets the dialog to be of "tool" type, making it simpler (no "?" icon) and cleaner
		self.setWindowFlags(QtCore.Qt.Tool)
		# Sets the dialog title
		self.setWindowTitle(f"Asset Switch {AssetSwitchUI_Version}")
		# Sets the ObjectName of this Dialog, so we can reliably check to have only one instance open at a time
		self.setObjectName(Widget_Name)
		# Sets an initial size
		self.resize(400, 200)

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
			# Close each dialog
			dialog.close()
			# Flags them to delete and free memory when QT garbages collect
			dialog.deleteLater()
	# Creates a new instance of the AssetSwitch Dialog
	AssetSwitchDialog_Instance = AssetSwitchDialog()
	# Launches the new instance
	AssetSwitchDialog_Instance.show()
# Script entry point, checks is the script is being run by the user or being imported by another script
if __name__ == '__main__':
	# If it is being run by the user, launches the script
	AssetSwitch_Lauch()
