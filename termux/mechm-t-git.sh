#!/bin/bash

# Variables
CONFIG_DIR="$HOME/.mechanancer_config"
CONFIG_FILE="$CONFIG_DIR/repos.conf"
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

# Step 1: Create config directory
mkdir -p "$CONFIG_DIR"

# Step 2: Shortcut creation (First thing done)
create_shortcut() {
    mkdir -p "$HOME/.bin"
    if [ ! -f "$SHORTCUT" ]; then
	touch "$HOME/.bashrc"
        echo "Creating global shortcut 'mechm-t-git' in $HOME/.bin..."
        echo "#!/bin/bash" > "$SHORTCUT"
        echo "bash $(realpath "$0")" >> "$SHORTCUT"
        chmod +x "$SHORTCUT"
        echo -e "${GREEN}Shortcut created. You can now run the script using 'mechm-t-git' from anywhere.${NC}"
    fi

    # Ensure ~/.bin is in PATH
    if ! grep -q 'export PATH="$HOME/.bin:$PATH"' "$HOME/.bashrc"; then
        echo 'export PATH="$HOME/.bin:$PATH"' >> "$HOME/.bashrc"
    fi

    if ! grep -q 'export PATH="$HOME/.bin:$PATH"' "$HOME/.zshrc"; then
        echo 'export PATH="$HOME/.bin:$PATH"' >> "$HOME/.zshrc"
    fi

    export PATH="$HOME/.bin:$PATH"
    echo -e "${GREEN}Added '$HOME/.bin' to PATH. Restart Termux or run 'source ~/.bashrc' or 'source ~/.zshrc' to apply changes.${NC}"
}
create_shortcut

# Step 3: Load config
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
        echo -e "${RED}Maximum number of repositories reached ($MAX_REPOS).${NC}\n"
        return
    fi
    read -p "Enter the full path of the repository: " repo_path
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

# Main menu
while true; do
    select_repo

    while true; do
        echo -e "\nSelect a Git operation:"
        echo "1) Status (git status)"
        echo "2) Commit (add and commit)"
        echo "3) Push (git push)"
        echo "4) Pull (git pull)"
        echo "5) Log (git log --oneline)"
        echo "6) Branch (git branch)"
        echo "7) Diff (git diff)"
        echo "8) Stash (git stash)"
        echo "9) Stash Pop (git stash pop)"
        echo "10) Remote (git remote -v)"
        echo "11) Rebase (git rebase)"
        echo "12) Merge (git merge)"
        echo "13) Manage Repositories"
        echo "14) Change Repository"
        echo "0) Exit"
        echo
        read -p "Enter your choice: " git_choice
        echo

        case $git_choice in
            1) git status ;;
            2) commit_changes ;;
            3) git_push ;;
            4) git pull ;;
            5) git log --oneline ;;
            6) git branch ;;
            7) git diff ;;
            8) git stash ;;
            9) git stash pop ;;
            10) git remote -v ;;
            11)
                read -p "Enter branch to rebase onto: " branch
                echo
                git rebase "$branch" ;;
            12)
                read -p "Enter branch to merge: " branch
                echo
                git merge "$branch" ;;
            13) manage_repos ;;
            14) break ;;
            0)
                echo -e "${GREEN}Goodbye!${NC}\n"
                exit 0 ;;
            *)
                echo -e "${RED}Invalid choice.${NC}\n" ;;
        esac
    done
done
