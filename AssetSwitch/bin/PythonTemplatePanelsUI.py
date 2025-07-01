'''
Demonstrates how to create a QDialog with PySide2 for use in 3ds Max,
featuring a side panel for navigation and a main area that changes content.
'''
from PySide2 import QtCore
from PySide2 import QtGui
from PySide2 import QtWidgets
import qtmax

from pymxs import runtime as rt

# --- Define a unique name for our widget to find it later ---
WIDGET_OBJECT_NAME = "AssetSwitchTabPanel"

class PyMaxDialog(QtWidgets.QDialog):
    """A custom floating dialog for 3ds Max with a side panel."""
    def __init__(self, parent=None):
        super(PyMaxDialog, self).__init__(parent)

        # --- Set the unique object name for searching ---
        self.setObjectName(WIDGET_OBJECT_NAME)

        # Set window properties
        self.setWindowFlags(QtCore.Qt.Tool)
        self.setWindowTitle('Asset Switch')
        self.setAttribute(QtCore.Qt.WA_DeleteOnClose)
        
        # Initialize the UI
        self.initUI()
        
        # Prevent 3ds Max from stealing keyboard focus from the widget
        qtmax.DisableMaxAcceleratorsOnFocus(self, True)


    def initUI(self):
        """Builds the user interface for the widget."""
        # --- 1. Main Horizontal Layout ---
        # The main layout is now horizontal to hold the side panel and content area.
        main_layout = QtWidgets.QHBoxLayout(self) # Set layout directly on the dialog
        main_layout.setContentsMargins(2, 2, 2, 2) # Remove spacing around the window edges

        # --- 2. Side Panel (Navigation) ---
        # A QListWidget is perfect for a vertical list of selectable items.
        self.side_panel = QtWidgets.QListWidget()
        self.side_panel.setFixedWidth(120) # Give the side panel a fixed width
        
        # Add items to the side panel
        self.side_panel.addItem("Asset Creation")
        self.side_panel.addItem("Asset Publishing")
        self.side_panel.addItem("Asset Switch")
        
        # Apply a stylesheet for a modern look
        self.side_panel.setStyleSheet("""
            QListWidget {
                background-color: #3C3C3C;
                border: none;
                color: white;
                font-size: 13px;
                outline: 0;
            }
            QListWidget::item {
                padding: 10px;
            }
            QListWidget::item:selected {
                background-color: #5A94F6; /* A highlight color for the selected item */
                color: white;
            }
        """)
        main_layout.addWidget(self.side_panel)


        # --- 3. Main Content Area (Stacked Pages) ---
        # A QStackedWidget holds multiple "pages" (widgets) and shows one at a time.
        self.main_content = QtWidgets.QStackedWidget()
        main_layout.addWidget(self.main_content)

        # --- 4. Create the different UI pages ---
        # Each page is its own widget. Here, they are created by helper methods.
        page1 = self._create_page_one()
        page2 = self._create_page_two()
        page3 = self._create_page_three()
        
        # Add the pages to the stacked widget. The order matters!
        self.main_content.addWidget(page1) # Index 0
        self.main_content.addWidget(page2) # Index 1
        self.main_content.addWidget(page3) # Index 2

        # --- 5. Connect the side panel to the main content ---
        # This is the key part: when the selected row changes in the side panel,
        # it calls the setCurrentIndex method on the stacked widget, changing the visible page.
        self.side_panel.currentRowChanged.connect(self.main_content.setCurrentIndex)
        
        # Start with the first item selected
        self.side_panel.setCurrentRow(0)
        
        # Set the initial size of the dialog
        self.resize(600, 400)

    # --- Helper methods to create the content for each page ---
    def _create_page_one(self):
        """Creates the UI for the 'Asset Creation' page."""
        page = QtWidgets.QWidget()
        layout = QtWidgets.QVBoxLayout(page)
        
        label = QtWidgets.QLabel("Asset Creation Page")
        label.setAlignment(QtCore.Qt.AlignCenter)
        label.setStyleSheet("font-size: 20px; font-weight: bold;")
        
        button = QtWidgets.QPushButton("Create a New Asset")
        
        layout.addWidget(label)
        layout.addWidget(button)
        layout.addStretch() # Pushes content to the top
        return page

    def _create_page_two(self):
        """Creates the UI for the 'Asset Publishing' page."""
        page = QtWidgets.QWidget()
        layout = QtWidgets.QVBoxLayout(page)
        
        label = QtWidgets.QLabel("Asset Publishing Page")
        label.setAlignment(QtCore.Qt.AlignCenter)
        label.setStyleSheet("font-size: 20px; font-weight: bold;")
        
        checkbox = QtWidgets.QCheckBox("Publish to server")
        
        layout.addWidget(label)
        layout.addWidget(checkbox)
        layout.addStretch()
        return page

    def _create_page_three(self):
        """Creates the UI for the 'Settings' page."""
        page = QtWidgets.QWidget()
        layout = QtWidgets.QVBoxLayout(page)
        
        label = QtWidgets.QLabel("Settings Page")
        label.setAlignment(QtCore.Qt.AlignCenter)
        label.setStyleSheet("font-size: 20px; font-weight: bold;")
        
        layout.addWidget(label)
        layout.addStretch()
        return page


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
