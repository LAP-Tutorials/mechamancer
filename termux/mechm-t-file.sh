#!/bin/bash

# Variables
SHORTCUT="$HOME/.bin/mechm-t-file"

# Step 1: Shortcut creation
create_shortcut() {
    if [ ! -f "$SHORTCUT" ]; then
        mkdir -p "$HOME/.bin"
        touch "$HOME/.bashrc"
        echo "Creating global shortcut 'mechm-t-file' in $HOME/.bin..."
        echo "#!/bin/bash" > "$SHORTCUT"
        echo "bash $(realpath "$0")" >> "$SHORTCUT"
        chmod +x "$SHORTCUT"
        echo "Shortcut created. Use 'mechm-t-file' to run the script."

        # Ensure ~/.bin is in PATH
        if ! grep -q 'export PATH="$HOME/.bin:$PATH"' "$HOME/.bashrc" 2>/dev/null; then
            echo 'export PATH="$HOME/.bin:$PATH"' >> "$HOME/.bashrc"
        fi
        if ! grep -q 'export PATH="$HOME/.bin:$PATH"' "$HOME/.zshrc" 2>/dev/null; then
            echo 'export PATH="$HOME/.bin:$PATH"' >> "$HOME/.zshrc"
        fi
        export PATH="$HOME/.bin:$PATH"
        echo "Added '$HOME/.bin' to PATH. Restart Termux or run 'source ~/.bashrc' or 'source ~/.zshrc' to apply changes."
    fi
}

create_shortcut

# Step 2: File browser using ls
browse_path() {
    local current_dir="$1"
    while true; do
        clear
        echo "Current directory: $current_dir"
        echo "0) Go up one directory"
        echo "q) Cancel operation"
        echo

        # List files and folders using ls
        mapfile -t entries < <(ls -Ap "$current_dir" 2>/dev/null)

        if [ ${#entries[@]} -eq 0 ]; then
            echo "No files/folders found here."
        else
            for i in "${!entries[@]}"; do
                printf "%s) %s\n" "$((i+1))" "${entries[$i]}"
            done
        fi

        echo
        read -p "Choose a number or option: " choice
        echo

        if [[ "$choice" == "q" ]]; then
            echo "Browsing cancelled."
            return 1
        elif [[ "$choice" == "0" ]]; then
            if [ "$current_dir" != "/" ] && [ "$current_dir" != "$HOME" ]; then
                current_dir="$(dirname "$current_dir")"
            fi
            continue
        fi

        if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
            echo "Invalid choice. Press Enter to continue..."
            read
            continue
        fi

        if [ "$choice" -lt 1 ] || [ "$choice" -gt "${#entries[@]}" ]; then
            echo "Invalid selection. Press Enter to continue..."
            read
            continue
        fi

        local selected="${entries[$((choice-1))]}"
        local selected_path="$current_dir/$selected"

        if [[ "$selected" == */ ]]; then
            # Folder selected
            echo "Folder selected: $selected_path"
            read -p "Do you want to perform the operation on this folder? (y/n): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                echo "$selected_path"
                return 0
            else
                # Go deeper into the folder
                current_dir="$selected_path"
            fi
        else
            # File selected
            echo "File selected: $selected_path"
            read -p "Press 'y' to select this file, or 'n' to cancel: " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                echo "$selected_path"
                return 0
            fi
        fi
    done
}

# Step 3: Utility Functions
copy_item() { cp -r "$1" "$2" && echo "Copied successfully."; }
move_item() { mv "$1" "$2" && echo "Moved successfully."; }
remove_item() { rm -rf "$1" && echo "Removed successfully."; }
rename_item() { mv "$1" "$2" && echo "Renamed successfully."; }

# Step 4: Main Loop
while true; do
    clear
    echo "========== Mechm File Manager =========="
    echo "Select an operation:"
    echo "1) Copy"
    echo "2) Move"
    echo "3) Remove"
    echo "4) Rename"
    echo "0) Exit"
    echo "======================================="
    echo
    read -p "Enter choice: " operation
    echo

    case "$operation" in
        1) op_name="Copy" ;;
        2) op_name="Move" ;;
        3) op_name="Remove" ;;
        4) op_name="Rename" ;;
        0) echo "Goodbye!"; exit 0 ;;
        *) echo "Invalid choice. Press Enter to continue..."; read; continue ;;
    esac

    # Step 5: File or Folder
    clear
    echo "Operation: $op_name"
    echo "Are you performing the operation on a file or a folder?"
    echo "1) File"
    echo "2) Folder"
    read -p "> " file_or_folder
    echo

    # Step 6: Source Path
    clear
    echo "Do you know the path of the $([ "$file_or_folder" == "1" ] && echo "file" || echo "folder")? (y/n)"
    read -p "> " knows_path
    echo

    if [[ "$knows_path" == "y" || "$knows_path" == "Y" ]]; then
        read -p "Enter the absolute path: " source_path
    else
        echo "Where do you want to start browsing?"
        echo "1) / (root)"
        echo "2) ~ (home)"
        read -p "> " start_choice
        echo

        if [ "$start_choice" == "1" ]; then
            source_path=$(browse_path "/")
        else
            source_path=$(browse_path "$HOME")
        fi

        if [ -z "$source_path" ]; then
            echo "No item selected. Press Enter to continue..."
            read
            continue
        fi
    fi

    if [ ! -e "$source_path" ]; then
        echo "Invalid path. Press Enter to continue..."
        read
        continue
    fi

    # Validate that the selected item matches the user's file/folder choice
    if [ "$file_or_folder" == "1" ] && [ ! -f "$source_path" ]; then
        echo "Selected item is not a file. Press Enter to continue..."
        read
        continue
    fi
    if [ "$file_or_folder" == "2" ] && [ ! -d "$source_path" ]; then
        echo "Selected item is not a folder. Press Enter to continue..."
        read
        continue
    fi

    # Step 7: Destination Path (if needed)
    if [ "$operation" == "1" ] || [ "$operation" == "2" ]; then
        read -p "Enter the destination path: " destination_path
        if [ -z "$destination_path" ]; then
            echo "No destination provided. Press Enter to continue..."
            read
            continue
        fi
    elif [ "$operation" == "4" ]; then
        read -p "Enter the new name or path: " destination_path
        if [ -z "$destination_path" ]; then
            echo "No new name provided. Press Enter to continue..."
            read
            continue
        fi
    fi

    # Step 8: Perform Operation
    case "$operation" in
        1) copy_item "$source_path" "$destination_path" ;;
        2) move_item "$source_path" "$destination_path" ;;
        3) remove_item "$source_path" ;;
        4) rename_item "$source_path" "$destination_path" ;;
    esac

    echo
    read -p "Press Enter to continue..." dummy
done