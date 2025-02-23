#!/bin/bash

SHORTCUT="$HOME/.bin/mechm-update"

# Ensure git is installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: git is not installed.${NC}"
    exit 1
fi

# Shortcut creation (First thing done)
create_shortcut() {
    if [ ! -f "$SHORTCUT" ]; then
    mkdir -p "$HOME/.bin"
	touch "$HOME/.bashrc"
        echo "Creating global shortcut 'mechm-t-git' in $HOME/.bin..."
        echo "#!/bin/bash" > "$SHORTCUT"
        echo "bash $(realpath "$0")" >> "$SHORTCUT"
        chmod +x "$SHORTCUT"
        echo -e "${GREEN}Shortcut created. You can now run the script using 'mechm-t-git' from anywhere.${NC}"

    # Ensure ~/.bin is in PATH
    if ! grep -q 'export PATH="$HOME/.bin:$PATH"' "$HOME/.bashrc"; then
        echo 'export PATH="$HOME/.bin:$PATH"' >> "$HOME/.bashrc"
    fi

    if ! grep -q 'export PATH="$HOME/.bin:$PATH"' "$HOME/.zshrc"; then
        echo 'export PATH="$HOME/.bin:$PATH"' >> "$HOME/.zshrc"
    fi

    export PATH="$HOME/.bin:$PATH"
    echo -e "${GREEN}Added '$HOME/.bin' to PATH. Restart Termux or run 'source ~/.bashrc' or 'source ~/.zshrc' to apply changes.${NC}"
    fi
}
create_shortcut

cd $HOME/mechamancer

git fetch --all

git reset --hard origin/main

chmod +x update.sh

chmod +x install.sh

./install.sh