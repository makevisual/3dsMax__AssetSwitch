'''
Demonstrates how to create a QDialog with PySide2 for use in 3ds Max.
'''
from PySide2 import QtCore
from PySide2 import QtGui
from PySide2 import QtWidgets
import qtmax
import textwrap

from pymxs import runtime as rt

# --- Define a unique name for our widget to find it later ---
WIDGET_OBJECT_NAME = "AssetSwitchWidgetUI"

class PyMaxDialog(QtWidgets.QDialog):
    """A custom floating dialog for 3ds Max."""
    def __init__(self, parent=None):
        super(PyMaxDialog, self).__init__(parent)

        # --- Set the unique object name for searching ---
        self.setObjectName(WIDGET_OBJECT_NAME)

        # Set window properties
        self.setWindowFlags(QtCore.Qt.Tool)
        self.setWindowTitle('Create New Asset')
        self.setAttribute(QtCore.Qt.WA_DeleteOnClose)
        
        #create some variables to be used across the tool
        self.CurrentProjectPath = rt.pathConfig.getCurrentProjectFolder()
        self.CurrentAssetPath = "\\Assets\\Characters\\_\\"

        # Initialize the UI
        self.initUI()
        
        # Prevent 3ds Max from stealing keyboard focus from the widget
        qtmax.DisableMaxAcceleratorsOnFocus(self, True)


    def initUI(self):
        """Builds the user interface for the widget."""
        # Create the main vertical layout for the entire dialog
        main_layout = QtWidgets.QVBoxLayout()

        # --- Project Selection Group ---
        project_group_box = QtWidgets.QGroupBox("Project")
        project_group_layout = QtWidgets.QVBoxLayout()

        # --- Asset Info Group ---
        asset_info_group_box = QtWidgets.QGroupBox("Asset Information")
        asset_info_group_layout = QtWidgets.QVBoxLayout()

        # --- Create Asset Group ---
        create_asset_group_box = QtWidgets.QGroupBox("Create Asset")
        create_asset_group_layout = QtWidgets.QVBoxLayout()

        # Button to select a path
        project_set_folder_btn = QtWidgets.QPushButton("Choose Project folder")
        project_set_folder_btn.setToolTip("Select the root directory of the current project")
        project_set_folder_btn.clicked.connect(self.OpenFolder)
        project_group_layout.addWidget(project_set_folder_btn)

        # Label for the path
        self.project_path_label = QtWidgets.QLabel("No folder selected")
        #self.project_path_label.setWordWrap(True)
        self.project_path_label.setAlignment(QtCore.Qt.AlignCenter)
        self.project_path_label.setStyleSheet("border: 1px solid gray; padding: 2px;")
        project_group_layout.addWidget(self.project_path_label)
        
        # Set the layout for the PROJECT group box and add it to the main layout
        project_group_box.setLayout(project_group_layout)
        main_layout.addWidget(project_group_box)

        # Combo box to select the asset type

        self.category_combobox = QtWidgets.QComboBox()
        self.category_combobox.addItems(["Characters","Effects","Misc","Objects","Sets"])
        self.category_combobox.setCurrentIndex(0)
        self.category_combobox.currentIndexChanged.connect(self.on_category_combobox_changed)
        asset_info_group_layout.addWidget(self.category_combobox)

        # Asset tag for the new asset

        asset_tag_layout = QtWidgets.QHBoxLayout()
        asset_tag_label = QtWidgets.QLabel("Asset Tag:")
        asset_tag_layout.addWidget(asset_tag_label)
        self.asset_tag_text_field = QtWidgets.QLineEdit()
        self.asset_tag_text_field.setPlaceholderText("e.g., DCA, ADE")
        self.asset_tag_text_field.setFixedWidth(150)
        self.asset_tag_text_field.setMaxLength(3)
        self.asset_tag_text_field.textChanged.connect(self.on_asset_tag_changed)
        asset_tag_layout.addWidget(self.asset_tag_text_field)
        asset_info_group_layout.addLayout(asset_tag_layout)

        # Asset name for the new asset

        asset_name_layout = QtWidgets.QHBoxLayout()
        asset_name_label = QtWidgets.QLabel("Asset Name:")
        asset_name_layout.addWidget(asset_name_label)
        asset_name_text_field = QtWidgets.QLineEdit()
        asset_name_text_field.setPlaceholderText("e.g., AaronDabelow")
        asset_name_text_field.textChanged.connect(self.on_asset_name_changed)
        asset_name_layout.addWidget(asset_name_text_field)
        asset_info_group_layout.addLayout(asset_name_layout)

        # Set the layout for the ASSET INFORMATION group box and add it to the main layout
        asset_info_group_box.setLayout(asset_info_group_layout)
        main_layout.addWidget(asset_info_group_box)

        # Button for creating the new asset

        create_asset_button = QtWidgets.QPushButton("Create Asset")
        create_asset_group_layout.addWidget(create_asset_button)

        # Label to see the current asset folder structure

        self.asset_path_label = QtWidgets.QLabel(self.CurrentAssetPath)
        self.asset_path_label.setAlignment(QtCore.Qt.AlignCenter)
        self.asset_path_label.setStyleSheet("border: 1px solid gray; padding: 2px;")
        create_asset_group_layout.addWidget(self.asset_path_label)


        # Set the layout for the CREATE ASSET group box and add it to the main layout
        create_asset_group_box.setLayout(create_asset_group_layout)
        main_layout.addWidget(create_asset_group_box)

        # --- Horizontal Button Layout ---
#        dummy_button_layout = QtWidgets.QHBoxLayout()
#        dummy_btn_1 = QtWidgets.QPushButton("Button 1")
#        dummy_btn_1.clicked.connect(self.ButtonClicked1)
#        dummy_button_layout.addWidget(dummy_btn_1)
        
#        dummy_btn_2 = QtWidgets.QPushButton("...")
#        dummy_btn_2.setFixedWidth(30)
#        dummy_btn_2.clicked.connect(self.ButtonClicked2)
#        dummy_button_layout.addWidget(dummy_btn_2)
        
        # Add the horizontal layout to the main layout
#        main_layout.addLayout(dummy_button_layout)

        # --- Text Input Section ---
#        label_textfield = QtWidgets.QLabel("Text Field:")
#        main_layout.addWidget(label_textfield)

        # Text field (QLineEdit) for user input
#        self.user_text_field = QtWidgets.QLineEdit()
#        self.user_text_field.setPlaceholderText("e.g., asset_name_001")
#        main_layout.addWidget(self.user_text_field)
        
        # Set the final layout for the dialog
        self.setLayout(main_layout)
        
        # Set the initial size of the dialog
        self.setFixedSize(250, 255)

    def on_asset_tag_changed(self, text):
        current_mouse_pos = (self.asset_tag_text_field.cursorPosition())
        self.asset_tag_text_field.blockSignals(True)
        self.asset_tag_text_field.setText(text.upper())
        self.asset_tag_text_field.blockSignals(False)
        self.asset_tag_text_field.setCursorPosition(current_mouse_pos)
        self.asset_path_label_renamer(3, True, self.asset_tag_text_field.text())

    def on_asset_name_changed(self, text):
        self.asset_path_label_renamer(3, False, text)

    def on_category_combobox_changed(self, index):
        selected_item = self.category_combobox.currentText()
        print(f"Selected: {selected_item} (Index: {index})")
        self.asset_path_label_renamer(2, True, selected_item)
        print (self.size())

    def Truncate_Text(self, path, MaxSize):
        """Helper method to shorten a path for display in the UI."""
        # If the path is smaler than MaxSize characters, return as it is
        if len(path) <= MaxSize:
            return path
        # Set the start of the string to be 8 characters long
        stringStart = path[:8]
        stringEnd = path[-(MaxSize - len(stringStart) - 3):]
        return f"{stringStart}...{stringEnd}"




    def asset_path_label_renamer(self, index, beforeUnderscore, text):
        label_parts = self.CurrentAssetPath.split("\\")

        # if the user changed the CATEGORY Combo Box
        if index == 2:
            label_parts[index] = text
        # if the user changed the TAG or NAME asset QLineEdit text fields
        else:
            target_part = label_parts[index]
            underscore_index = (label_parts[index]).find("_")
            # if the user changed the TAG text field
            if beforeUnderscore:
                label_parts[index] = text + (label_parts[index])[underscore_index:]
            # if the user changed the NAME text field
            else:
                label_parts[index] = (label_parts[index])[:1 + underscore_index] + text
        self.CurrentAssetPath = "\\".join(label_parts)
        self.asset_path_label.setText(self.Truncate_Text(self.CurrentAssetPath, 37))
        #self.asset_path_label.setToolTip(self.CurrentAssetPath)
        
        self.asset_path_label.setToolTip("\n".join(textwrap.wrap((self.CurrentAssetPath), 50)))

    def ButtonClicked2(self):
        """Prints a message when Button 2 is clicked."""
        print('Button 2 Clicked')
        self.category_combobox.clear()
        self.category_combobox.addItems(["1a","2X","Misc","Objects","Sets"])
        return

    def ButtonClicked1(self):
        """Prints a message when Button 1 is clicked."""
        print('Button 1 Clicked')
        self.category_combobox.clear()
        self.category_combobox.addItems(["Characters","FX","Misc","Objects","Sets"])
        print (self.size())
        return


    def OpenFolder(self):
        """Opens a file dialog to select a folder and updates the path label."""
        start_path = self.CurrentProjectPath
        folder_path = QtWidgets.QFileDialog.getExistingDirectory(self, "Select a Folder", start_path)

        if folder_path:
            folder_path = folder_path.replace('/','\\')
            print(f"Selected path: {folder_path}")
            self.CurrentProjectPath = folder_path
            display_path = self.Truncate_Text(folder_path, 40)
            self.project_path_label.setText(display_path)
            # --- SET THE TOOLTIP TO THE FULL PATH ---
            #self.project_path_label.setToolTip(folder_path)
            self.project_path_label.setToolTip("\n".join(textwrap.wrap(folder_path, 50)))
            print (self.CurrentProjectPath)

def main():
    """
    Main function to initialize and show the QDialog.
    It closes any existing instances before creating a new one.
    """
    # Get the 3ds Max main window as a QWidget
    main_window = qtmax.GetQMaxMainWindow()

    # --- Search for existing instances of the widget ---
    existing_widgets = main_window.findChildren(QtWidgets.QDialog, WIDGET_OBJECT_NAME)

    # --- Loop through and close any found widgets ---
    for widget in existing_widgets:
        print(f"Closing existing instance: {widget}")
        widget.close()
    
    # Create an instance of our custom dialog
    w = PyMaxDialog(parent=main_window)
    w.show()

if __name__ == '__main__':
    main()
