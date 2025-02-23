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

# Core functions
show_header() {
    clear
    echo -e "${BLUE}Termux File Manager${NC}"
    echo -e "Current path: ${YELLOW}$(pwd)${NC}"
    echo "----------------------------------------"
}

list_contents() {
    local dir="$1"
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

browse_directory() {
    local current_dir="${1:-$TERMUX_ROOT}"
    
    while true; do
        show_header
        list_contents "$current_dir"
        
        read -p "Select item or action: " choice
        
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
                        current_dir="$selected"
                    else
                        echo -e "Selected file: ${YELLOW}$selected${NC}"
                        return 0
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
            1) browse_directory "$TERMUX_ROOT" ;;
            2) browse_directory "$HOME_DIR" ;;
            3) browse_directory "$SDCARD_DIR" ;;
            4) file_operations ;;
            0) exit 0 ;;
            *) echo -e "${RED}Invalid option!${NC}"; sleep 1 ;;
        esac
    done
}

file_operations() {
    show_header
    echo -e "${GREEN}1) Copy file"
    echo "2) Move file"
    echo "3) Delete file"
    echo "4) Create directory"
    echo -e "${YELLOW}5) Back to main menu${NC}"
    
    read -p "Select operation: " op_choice
    
    case $op_choice in
        1) perform_operation "copy" ;;
        2) perform_operation "move" ;;
        3) delete_file ;;
        4) create_directory ;;
        5) return ;;
        *) echo -e "${RED}Invalid operation!${NC}"; sleep 1 ;;
    esac
}

perform_operation() {
    local operation=$1
    browse_directory && src_file="$selected"
    browse_directory && dest_dir="$selected"
    
    case $operation in
        "copy")
            cp -r "$src_file" "$dest_dir" && echo -e "${GREEN}File copied successfully!${NC}" || echo -e "${RED}Copy failed!${NC}"
            ;;
        "move")
            mv "$src_file" "$dest_dir" && echo -e "${GREEN}File moved successfully!${NC}" || echo -e "${RED}Move failed!${NC}"
            ;;
    esac
    sleep 2
}

delete_file() {
    browse_directory && file_to_delete="$selected"
    read -p "Are you sure you want to delete '$file_to_delete'? (y/n): " confirm
    [[ "$confirm" == [yY] ]] && rm -rf "$file_to_delete" && echo -e "${GREEN}Deleted successfully!${NC}" || echo -e "${YELLOW}Deletion cancelled${NC}"
    sleep 2
}

create_directory() {
    read -p "Enter directory name: " dir_name
    mkdir -p "$dir_name" && echo -e "${GREEN}Directory created!${NC}" || echo -e "${RED}Creation failed!${NC}"
    sleep 2
}

# Start
main_menu