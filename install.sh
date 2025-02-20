#!/bin/bash

# Ask the user for the folder
read -p "Enter the folder path where you want to make the scripts executable: " folder

# Check if the folder exists
if [ -d "$folder" ]; then
    # Find and make all scripts in the folder and subfolders executable
    find "$folder" -type f -name "*.sh" -exec chmod +x {} \;
    echo "All .sh scripts in $folder and its subfolders are now executable."
else
    echo "The folder $folder does not exist."
fi
