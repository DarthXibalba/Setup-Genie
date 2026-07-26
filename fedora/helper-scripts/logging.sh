#!/usr/bin/env bash
# =========================
# Colorized logging helpers
# =========================

log_color() {
    local message="$1"
    local color="$2"

    local reset="\033[0m"
    local code=""

    case "$color" in
        red)     code="\033[0;31m" ;;
        green)   code="\033[0;32m" ;;
        yellow)  code="\033[0;33m" ;;
        blue)    code="\033[0;34m" ;;
        purple)  code="\033[0;35m" ;;
        cyan)    code="\033[0;36m" ;;
        bold)    code="\033[1m" ;;
        *)       code="$reset" ;;
    esac

    echo -e "${code}${message}${reset}"
}

log_step()    { log_color "==> $*" blue; }
log_info()    { log_color "[INFO]    $*" cyan; }
log_warn()    { log_color "[WARN]    $*" yellow; }
log_error()   { log_color "[ERROR]   $*" red; }
log_success() { log_color "[SUCCESS] $*" green; }
