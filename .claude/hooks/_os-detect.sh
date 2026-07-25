#!/usr/bin/env bash
# _os-detect.sh — Multi-OS detection for JeecgBoot harness hooks
# Source this file in any hook script: source "${CLAUDE_PROJECT_DIR}/.claude/hooks/_os-detect.sh"
# Sets: IS_MAC, IS_LINUX, IS_WSL, IS_WINDOWS, OS_NAME
# Sets portable command aliases: DATE_CMD, TMP_DIR, HAS_TIMEOUT, HAS_LSOF, HAS_PKILL

detect_os() {
  local _uname
  _uname="$(uname -s 2>/dev/null || echo "Windows")"

  case "$_uname" in
    Darwin)
      IS_MAC=true
      OS_NAME="macOS"
      ;;
    Linux)
      IS_LINUX=true
      if uname -r 2>/dev/null | grep -qi 'microsoft\|WSL'; then
        IS_WSL=true
        OS_NAME="WSL"
      else
        OS_NAME="Linux"
      fi
      ;;
    MINGW64_NT-*|MSYS_NT-*|CYGWIN_NT-*)
      IS_WINDOWS=true
      OS_NAME="Windows (Git Bash)"
      ;;
    *)
      IS_WINDOWS=true
      OS_NAME="Windows"
      ;;
  esac
}

detect_os

# Portable temporary directory
if [ -n "$TMPDIR" ] && [ -d "$TMPDIR" ]; then
  TMP_DIR="$TMPDIR"
elif [ -d /tmp ]; then
  TMP_DIR="/tmp"
elif [ -n "$TEMP" ] && [ -d "$TEMP" ]; then
  TMP_DIR="$TEMP"
else
  TMP_DIR="${CLAUDE_PROJECT_DIR:-.}/.tmp"
  mkdir -p "$TMP_DIR"
fi

# Portable command availability
HAS_TIMEOUT=false
HAS_LSOF=false
HAS_PKILL=false
command -v timeout >/dev/null 2>&1 && HAS_TIMEOUT=true
command -v lsof >/dev/null 2>&1 && HAS_LSOF=true
command -v pkill >/dev/null 2>&1 && HAS_PKILL=true

# Portable date command for formatting
if [ "$IS_MAC" = true ]; then
  # macOS/BSD date
  DATE_FMT() { date -j -f "%Y-%m-%d" "$1" "+%s" 2>/dev/null || echo "0"; }
else
  # GNU date (Linux/WSL)
  DATE_FMT() { date -d "$1" +%s 2>/dev/null || echo "0"; }
fi

# Portable port check (no lsof dependency)
port_in_use() {
  local _port="$1"
  if [ "$HAS_LSOF" = true ]; then
    lsof -i ":$_port" 2>/dev/null | grep -q LISTEN
  elif command -v ss >/dev/null 2>&1; then
    ss -tlnp 2>/dev/null | grep -q ":$_port "
  elif command -v netstat >/dev/null 2>&1; then
    netstat -tlnp 2>/dev/null | grep -q ":$_port "
  else
    # Fallback: try curl to check if something is listening
    curl -s -o /dev/null -w "%{http_code}" "http://localhost:$_port" 2>/dev/null | grep -q "200\|302\|401\|403\|404"
  fi
}

# Portable process kill by name pattern
kill_by_pattern() {
  local _pattern="$1"
  if [ "$HAS_PKILL" = true ]; then
    pkill -f "$_pattern" 2>/dev/null
  elif command -v taskkill >/dev/null 2>&1; then
    # Windows
    taskkill //F //IM "$_pattern" 2>/dev/null
  elif command -v killall >/dev/null 2>&1; then
    killall "$_pattern" 2>/dev/null
  fi
}
