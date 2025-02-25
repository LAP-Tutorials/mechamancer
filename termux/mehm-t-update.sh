#!/bin/bash

# Variables
SHORTCUT="$HOME/.bin/mechm-t-update"

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

echo "updating termux..."
sleep 1

apt update && apt upgrade -y
pkg update && pkg upgrade -y

echo "termux updated successfully."
sleep 1
exit