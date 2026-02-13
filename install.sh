#!/usr/bin/env bash
# Install with:
#   brew install jadnohra/tap/smux
# Or without brew:
#   curl -sSL https://raw.githubusercontent.com/jadnohra/smux/main/install.sh | bash
set -euo pipefail

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
DIM='\033[2m'
NC='\033[0m'

INSTALL_DIR="/usr/local/bin"

# Fall back to ~/bin if no write access to /usr/local/bin
if [[ ! -w "$INSTALL_DIR" ]]; then
    INSTALL_DIR="$HOME/bin"
    mkdir -p "$INSTALL_DIR"
fi

echo -e "${CYAN}Installing smux...${NC}"

cat > "$INSTALL_DIR/smux" << 'SMUX_SCRIPT'
#!/usr/bin/env bash
# smux — simple tmux
set -euo pipefail

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
DIM='\033[2m'
RED='\033[1;31m'
BOLD='\033[1m'
NC='\033[0m'

get_sessions() {
    tmux ls -F '#{session_name}|#{session_windows}|#{session_attached}|#{session_created}' 2>/dev/null
}

format_session() {
    local line="$1" index="$2"
    local name windows attached created
    IFS='|' read -r name windows attached created <<< "$line"
    local date
    date=$(date -r "$created" '+%b %d %H:%M' 2>/dev/null || date -d "@$created" '+%b %d %H:%M' 2>/dev/null || echo "?")
    local status
    if [[ "$attached" -gt 0 ]]; then
        status="${GREEN}● attached${NC}"
    else
        status="${DIM}○ detached${NC}"
    fi
    local win_label="window"
    [[ "$windows" -gt 1 ]] && win_label="windows"
    echo -e "  ${BOLD}[$index]${NC} ${CYAN}$name${NC}  —  $windows $win_label  $status  ${DIM}($date)${NC}"
}

pick_session() {
    local prompt="${1:-Reattach to}"
    local sessions=()
    while IFS= read -r line; do
        sessions+=("$line")
    done <<< "$(get_sessions)"
    if [[ ${#sessions[@]} -eq 0 ]]; then
        return 1
    fi
    echo ""
    for i in "${!sessions[@]}"; do
        format_session "${sessions[$i]}" "$((i + 1))"
    done
    echo ""
    local choice
    read -rp "$(echo -e "${BOLD}$prompt [1-${#sessions[@]}]: ${NC}")" choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#sessions[@]} )); then
        echo "${sessions[$((choice - 1))]}" | cut -d'|' -f1
    else
        echo ""
    fi
}

cmd_list() {
    local sessions
    sessions=$(get_sessions) || true
    if [[ -z "$sessions" ]]; then
        echo -e "${DIM}No sessions running.${NC}"
        return
    fi
    local i=1
    while IFS= read -r line; do
        format_session "$line" "$i"
        ((i++))
    done <<< "$sessions"
}

cmd_list_and_attach() {
    local sessions
    sessions=$(get_sessions) || true
    if [[ -z "$sessions" ]]; then
        echo -e "${DIM}No sessions running.${NC} Use ${CYAN}smux new${NC} to start one."
        return
    fi
    local count
    count=$(echo "$sessions" | wc -l | tr -d ' ')
    if [[ "$count" -eq 1 ]]; then
        local name attached
        IFS='|' read -r name _ attached _ <<< "$sessions"
        if [[ "$attached" -eq 0 ]]; then
            echo -e "${DIM}Reattaching to${NC} ${CYAN}$name${NC}${DIM}...${NC}"
            tmux attach -t "$name"
            return
        fi
    fi
    local chosen
    chosen=$(pick_session "Reattach to")
    if [[ -n "$chosen" ]]; then
        tmux attach -t "$chosen"
    else
        echo -e "${RED}Cancelled.${NC}"
    fi
}

cmd_new() {
    local name="${1:-}"
    local host="${2:-}"
    if [[ -z "$name" ]]; then
        echo -e "${RED}Usage:${NC} smux new ${DIM}name${NC} [${DIM}user@host${NC}]"
        exit 1
    fi
    if tmux has-session -t "$name" 2>/dev/null; then
        echo -e "${RED}Session '$name' already exists.${NC} Use: ${CYAN}smux attach $name${NC}"
        exit 1
    fi
    if [[ -n "$host" ]]; then
        echo -e "${DIM}Connecting to${NC} ${CYAN}$host${NC} ${DIM}as session${NC} ${CYAN}$name${NC}${DIM}...${NC}"
        tmux new-session -s "$name" "ssh $host"
    else
        tmux new-session -s "$name"
    fi
}

cmd_attach() {
    local name="${1:-}"
    if [[ -n "$name" ]]; then
        if ! tmux has-session -t "$name" 2>/dev/null; then
            echo -e "${RED}No session named '$name'.${NC}"
            exit 1
        fi
        tmux attach -t "$name"
    else
        cmd_list_and_attach
    fi
}

cmd_kill() {
    local sessions
    sessions=$(get_sessions) || true
    if [[ -z "$sessions" ]]; then
        echo -e "${DIM}No sessions to kill.${NC}"
        return
    fi
    local chosen
    chosen=$(pick_session "Kill session")
    if [[ -n "$chosen" ]]; then
        tmux kill-session -t "$chosen"
        echo -e "${GREEN}Killed${NC} ${CYAN}$chosen${NC}"
    else
        echo -e "${RED}Cancelled.${NC}"
    fi
}

cmd_kill_all() {
    local sessions
    sessions=$(get_sessions) || true
    if [[ -z "$sessions" ]]; then
        echo -e "${DIM}Nothing to kill.${NC}"
        return
    fi
    local count
    count=$(echo "$sessions" | wc -l | tr -d ' ')
    read -rp "$(echo -e "${RED}Kill all $count sessions? [y/N]: ${NC}")" confirm
    if [[ "$confirm" =~ ^[yY]$ ]]; then
        tmux kill-server
        echo -e "${GREEN}All sessions killed.${NC}"
    else
        echo -e "${RED}Cancelled.${NC}"
    fi
}

cmd_help() {
    echo -e "${CYAN}smux${NC} — simple tmux"
    echo ""
    echo -e "  ${BOLD}smux new ${DIM}name${NC}              new session with a name"
    echo -e "  ${BOLD}smux new ${DIM}name user@host${NC}  new session that SSHs into host"
    echo -e "  ${BOLD}smux ls${NC}                       list sessions"
    echo -e "  ${BOLD}smux attach${NC}                   pick a session to reattach"
    echo -e "  ${BOLD}smux attach ${DIM}name${NC}             reattach to a session by name"
    echo -e "  ${BOLD}smux kill${NC}                     pick a session to kill"
    echo -e "  ${BOLD}smux kill-all${NC}         kill all sessions"
    echo -e "  ${BOLD}smux help${NC}             this message"
    echo ""
    echo -e "  ${DIM}Inside tmux: Ctrl+B then d to detach${NC}"
}

case "${1:-}" in
    "")        cmd_help ;;
    new)       shift; cmd_new "${1:-}" "${2:-}" ;;
    ls|list)   cmd_list ;;
    attach)    shift; cmd_attach "${1:-}" ;;
    kill)      cmd_kill ;;
    kill-all)  cmd_kill_all ;;
    help|-h|--help)   cmd_help ;;
    *)
        echo -e "${RED}Unknown command:${NC} $1"
        echo -e "Run ${CYAN}smux help${NC} for usage."
        exit 1
        ;;
esac
SMUX_SCRIPT

chmod +x "$INSTALL_DIR/smux"

# Check if INSTALL_DIR is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo -e "\033[1;33mNote:\033[0m Add this to your shell config (~/.bashrc or ~/.zshrc):"
    echo ""
    echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
    echo ""
fi

echo -e "${GREEN}✓ smux installed to ${INSTALL_DIR}/smux${NC}"
echo -e "${DIM}Run 'smux help' to get started.${NC}"
