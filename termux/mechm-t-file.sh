#!/bin/bash

# Variables
SHORTCUT="$HOME/.bin/mechm-t-file"
TERMUX_ROOT="/data/data/com.termux/files"
HOME_DIR="$HOME"
SDCARD_DIR="/sdcard"

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

# Shortcut creation
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

# Core functions
show_header() {
    clear
    echo -e "${BLUE}Termux File Manager${NC}"
    echo -e "Current path: ${YELLOW}$current_dir${NC}"
    echo "----------------------------------------"
}

list_contents() {
    local dir="$current_dir"
    local items=()
    
    # Add parent directory
    if [[ "$dir" != "$TERMUX_ROOT" && "$dir" != "/" ]]; then
        echo "0) .. (parent directory)"
    fi

    # List directories first
    local i=1
    while IFS= read -r -d $'\0' item; do
        if [[ -d "$item" ]]; then
            items+=("$item")
            echo -e "${GREEN}$i) $(basename "$item")/${NC}"
            ((i++))
        fi
    done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null | sort -z)

    # List files
    while IFS= read -r -d $'\0' item; do
        if [[ -f "$item" ]]; then
            items+=("$item")
            echo -e "$i) $(basename "$item")"
            ((i++))
        fi
    done < <(find "$dir" -mindepth 1 -maxdepth 1 -type f -print0 2>/dev/null | sort -z)

    echo "----------------------------------------"
    echo -e "${RED}q) Quit${NC}"
    echo -e "${YELLOW}b) Back to main menu${NC}"
}

select_target() {
    local target_type="$1"
    while true; do
        show_header
        list_contents
        
        read -p "Select ${target_type} or navigate: " choice
        
        case $choice in
            0)
                current_dir=$(dirname "$current_dir")
                ;;
            q|Q)
                echo "Exiting..."
                exit 0
                ;;
            b|B)
                return 1
                ;;
            [0-9]*)
                local items=()
                while IFS= read -r -d $'\0' item; do
                    items+=("$item")
                done < <(find "$current_dir" -mindepth 1 -maxdepth 1 -print0 2>/dev/null | sort -z)
                
                if [[ $choice -le ${#items[@]} ]]; then
                    selected="${items[$((choice-1))]}"
                    
                    if [[ -d "$selected" ]]; then
                        if [[ "$target_type" == "folder" ]]; then
                            read -p "Operate on this folder or enter it? (o/e): " decision
                            if [[ "$decision" == [oO] ]]; then
                                target_path="$selected"
                                return 0
                            else
                                current_dir="$selected"
                            fi
                        else
                            current_dir="$selected"
                        fi
                    else
                        if [[ "$target_type" == "file" ]]; then
                            target_path="$selected"
                            return 0
                        else
                            echo -e "${RED}Selected item is a file, but operation requires folder!${NC}"
                            sleep 2
                        fi
                    fi
                else
                    echo -e "${RED}Invalid selection!${NC}"
                    sleep 1
                fi
                ;;
            *)
                echo -e "${RED}Invalid input!${NC}"
                sleep 1
                ;;
        esac
    done
}

main_menu() {
    while true; do
        show_header
        echo -e "${GREEN}1) Browse Termux storage"
        echo "2) Browse Home directory"
        echo "3) Browse SD Card"
        echo "4) File operations"
        echo -e "${RED}0) Exit${NC}"
        
        read -p "Select option: " main_choice
        
        case $main_choice in
            1) current_dir="$TERMUX_ROOT"; select_target "folder" ;;
            2) current_dir="$HOME_DIR"; select_target "folder" ;;
            3) current_dir="$SDCARD_DIR"; select_target "folder" ;;
            4) file_operations ;;
            0) exit 0 ;;
            *) echo -e "${RED}Invalid option!${NC}"; sleep 1 ;;
        esac
    done
}

file_operations() {
    while true; do
        show_header
        echo -e "${GREEN}1) Copy"
        echo "2) Move"
        echo "3) Delete"
        echo "4) Rename"
        echo -e "${YELLOW}5) Back to main menu${NC}"
        
        read -p "Select operation: " op_choice
        
        case $op_choice in
            1) handle_operation "copy" ;;
            2) handle_operation "move" ;;
            3) handle_operation "delete" ;;
            4) handle_operation "rename" ;;
            5) return ;;
            *) echo -e "${RED}Invalid operation!${NC}"; sleep 1 ;;
        esac
    done
}

handle_operation() {
    local operation="$1"
    
    # Ask for file/folder type first
    while true; do
        show_header
        echo -e "Operation: ${BLUE}${operation}${NC}"
        echo "1) File"
        echo "2) Folder"
        read -p "Select target type: " type_choice
        
        case $type_choice in
            1) operation_type="file"; break ;;
            2) operation_type="folder"; break ;;
            *) echo -e "${RED}Invalid choice!${NC}"; sleep 1 ;;
        esac
    done

    case $operation in
        "copy") perform_copy_move "copy" ;;
        "move") perform_copy_move "move" ;;
        "delete") perform_delete ;;
        "rename") perform_rename ;;
    esac
}

perform_copy_move() {
    local operation="$1"
    
    # Select source
    echo -e "\n${BLUE}Select source ${operation_type}:${NC}"
    if select_target "$operation_type"; then
        local source="$target_path"
    else
        return
    fi

    # Select destination
    echo -e "\n${BLUE}Select destination directory:${NC}"
    if select_target "folder"; then
        local dest="$target_path"
    else
        return
    fi

    # Confirmation
    read -p $'\e[31mConfirm ${operation} "${source}" to "${dest}"? (y/n): \e[0m' confirm
    if [[ "$confirm" == [yY] ]]; then
        case $operation in
            "copy") cp -rv "$source" "$dest" ;;
            "move") mv -v "$source" "$dest" ;;
        esac
        echo -e "${GREEN}Operation completed!${NC}"
    else
        echo -e "${YELLOW}Operation cancelled${NC}"
    fi
    sleep 2
}

perform_delete() {
    echo -e "\n${BLUE}Select ${operation_type} to delete:${NC}"
    if select_target "$operation_type"; then
        local target="$target_path"
        read -p $'\e[31mPERMANENTLY DELETE "${target}"? (y/n): \e[0m' confirm
        if [[ "$confirm" == [yY] ]]; then
            rm -rvf "$target" && echo -e "${GREEN}Deleted successfully!${NC}" || echo -e "${RED}Deletion failed!${NC}"
        else
            echo -e "${YELLOW}Deletion cancelled${NC}"
        fi
    fi
    sleep 2
}

perform_rename() {
    echo -e "\n${BLUE}Select ${operation_type} to rename:${NC}"
    if select_target "$operation_type"; then
        local target="$target_path"
        show_header
        echo -e "Current name: ${YELLOW}$(basename "$target")${NC}"
        read -p "Enter new name: " new_name
        if [[ -n "$new_name" ]]; then
            read -p $'\e[31mConfirm rename to "${new_name}"? (y/n): \e[0m' confirm
            if [[ "$confirm" == [yY] ]]; then
                mv -v "$target" "$(dirname "$target")/$new_name" && echo -e "${GREEN}Renamed successfully!${NC}" || echo -e "${RED}Rename failed!${NC}"
            else
                echo -e "${YELLOW}Rename cancelled${NC}"
            fi
        else
            echo -e "${RED}Invalid name!${NC}"
        fi
    fi
    sleep 2
}

# Start
main_menu