#!/bin/bash

# Variables
CONFIG_DIR="$HOME/.mechamancer_config"
CONFIG_TYPE="termux"
CONFIG_FILE="$CONFIG_DIR/$CONFIG_TYPE/repos.conf"
SHORTCUT="$HOME/.bin/mechm-t-git"
MAX_REPOS=5

# Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Ensure git is installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: git is not installed.${NC}"
    exit 1
fi

# Step 1: Create config directory if it doesn't exist
if [ ! -d "$CONFIG_DIR" ]; then
    echo "Creating config directory: $CONFIG_DIR"
    mkdir -p "$CONFIG_DIR"
fi

# Step 2: Create CONFIG_TYPE folder within CONFIG_DIR if it doesn't exist
if [ ! -d "$CONFIG_DIR/$CONFIG_TYPE" ]; then
    echo "Creating config type directory: $CONFIG_DIR/$CONFIG_TYPE"
    mkdir -p "$CONFIG_DIR/$CONFIG_TYPE"
fi

# Step 3: Shortcut creation (First thing done)
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

# Step 4: Load config
declare -a REPOS
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Save config
save_config() {
    echo "# Mechamancer Repositories" > "$CONFIG_FILE"
    for i in "${!REPOS[@]}"; do
        echo "REPOS[$i]=\"${REPOS[$i]}\"" >> "$CONFIG_FILE"
    done
    echo -e "${GREEN}Configuration saved.${NC}\n"
}

# Function to resolve ~ to the home directory
resolve_path() {
    echo "$1" | sed "s#^~#$HOME#"
}

# Function to add repo (supports ~ in paths)
add_repo() {
    if [ ${#REPOS[@]} -ge $MAX_REPOS ]; then
        echo -e "${RED}Maximum number of repositories reached ($MAX_REPOS). Please remove one.${NC}\n"
        return
    fi
    read -p "Enter the full path of the repository (eg: ~/storage/shared/Notes/Personal-Notes): " repo_path
    repo_path=$(resolve_path "$repo_path")
    if [ -d "$repo_path/.git" ]; then
        REPOS+=("$repo_path")
        echo -e "${GREEN}Repository added: $repo_path${NC}\n"
    else
        echo -e "${RED}Invalid repository path. Make sure it's a Git repository.${NC}\n"
    fi
}

# Remove repo
remove_repo() {
    if [ ${#REPOS[@]} -eq 0 ]; then
        echo -e "${RED}No repositories to remove.${NC}\n"
        return
    fi
    echo -e "\nSelect a repository to remove (or type 0 to exit):"
    for i in "${!REPOS[@]}"; do
        echo "$((i+1))) ${REPOS[$i]}"
    done
    echo
    read -p "Enter the number of the repository to remove: " choice
    if [[ "$choice" == "0" ]]; then
        return
    fi
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#REPOS[@]} )); then
        echo -e "${GREEN}Repository removed: ${REPOS[$choice-1]}${NC}\n"
        unset 'REPOS[choice-1]'
        REPOS=("${REPOS[@]}")
    else
        echo -e "${RED}Invalid selection.${NC}\n"
    fi
}

# Repo management menu
manage_repos() {
    while true; do
        echo -e "\nRepository Management:"
        echo "1) Add a repository"
        echo "2) Remove a repository"
        echo "3) View repositories"
        echo "4) Exit"
        echo
        read -p "Choose an option: " choice
        case $choice in
            1) add_repo ;;
            2) remove_repo ;;
            3)
                if [ ${#REPOS[@]} -eq 0 ]; then
                    echo -e "${RED}No repositories added.${NC}\n"
                else
                    echo -e "\nRepositories:"
                    for repo in "${REPOS[@]}"; do
                        echo "- $repo"
                    done
                    echo
                fi
                ;;
            4) break ;;
            *) echo -e "${RED}Invalid choice.${NC}\n" ;;
        esac
        save_config
    done
}

# Initial repo setup if none are found
if [ ${#REPOS[@]} -eq 0 ]; then
    echo -e "\nNo repositories configured."
    read -p "Do you want to add repositories now? (y/n): " add_now
    echo
    if [[ "$add_now" == "y" || "$add_now" == "Y" ]]; then
        manage_repos
    fi
    save_config
fi

# Select repository menu
select_repo() {
    while true; do
        echo -e "\nAvailable Repositories:"
        echo "0) Exit"
        for i in "${!REPOS[@]}"; do
            echo "$((i+1))) ${REPOS[$i]}"
        done
        echo
        read -p "Select a repository by number: " repo_choice
        echo
        if [[ "$repo_choice" == "0" ]]; then
            echo -e "${GREEN}Goodbye!${NC}\n"
            exit 0
        fi
        if ! [[ "$repo_choice" =~ ^[0-9]+$ ]] || [ "$repo_choice" -lt 1 ] || [ "$repo_choice" -gt "${#REPOS[@]}" ]; then
            echo -e "${RED}Invalid selection.${NC}\n"
            continue
        fi
        repo="${REPOS[$repo_choice-1]}"
        repo=$(resolve_path "$repo")
        cd "$repo" || exit
        echo -e "${GREEN}You are now in $(pwd)${NC}\n"
        break
    done
}

# Commit changes with a custom message
commit_changes() {
    git status
    echo
    read -p "Enter commit message: " commit_msg
    echo
    git add .
    git commit -m "$commit_msg"
}

# Git push
git_push() {
    git push
}

# Force pull changes
force_pull() {
    git fetch --all
    git reset --hard origin/main
}

# Main menu
while true; do
    select_repo

    while true; do
        echo -e "\nSelect a Git operation:"
        echo "1) Status (git status)"
        echo "2) Commit (add and commit)"
        echo "3) Push (git push)"
        echo "4) Pull (git pull)"
        echo "5) Force Pull (git fetch --all, git reset --hard origin/main)"
        echo "6) Log (git log --oneline)"
        echo "7) Branch (git branch)"
        echo "8) Diff (git diff)"
        echo "9) Stash (git stash)"
        echo "10) Stash Pop (git stash pop)"
        echo "11) Remote (git remote -v)"
        echo "12) Rebase (git rebase)"
        echo "13) Merge (git merge)"
        echo "14) Manage Repositories"
        echo "15) Change Repository"
        echo "0) Exit"
        echo
        read -p "Enter your choice: " git_choice
        echo

        case $git_choice in
            1) git status ;;
            2) commit_changes ;;
            3) git_push ;;
            4) git pull ;;
            5) force_pull ;;
            6) git log --oneline ;;
            7) git branch ;;
            8) git diff ;;
            9) git stash ;;
            10) git stash pop ;;
            11) git remote -v ;;
            12)
                read -p "Enter branch to rebase onto: " branch
                echo
                git rebase "$branch" ;;
            13)
                read -p "Enter branch to merge: " branch
                echo
                git merge "$branch" ;;
            14) manage_repos ;;
            15) break ;;
            0)
                echo -e "${GREEN}Goodbye!${NC}\n"
                exit 0 ;;
            *)
                echo -e "${RED}Invalid choice.${NC}\n" ;;
        esac
    done
done
