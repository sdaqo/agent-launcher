#!/usr/bin/env bash

if [[ $AGENT_LOG == 1 ]]; then
  LOG_FILE="/tmp/agent_launcher_log.txt"
  exec 3>&1 4>&2
  trap 'exec 2>&4 1>&3' 0 1 2 3
  exec 1>$LOG_FILE.1 2>&1
else
  LOG_FILE="/dev/null"
fi


GAME_EXE="${@: -1}"
GAME_DIR=$(dirname "$GAME_EXE")
[[ -z "$AGENT_PATH" ]] && AGENT_PATH="$GAME_DIR"
[[ -z "$AGENT_SCRIPTS_PATH" ]] && AGENT_SCRIPTS_PATH="$AGENT_PATH/data/scripts"
[[ -z "$AGENT_DELAY" ]] && AGENT_DELAY=5000
[[ -z "$AGENT_ONLY" ]] && AGENT_ONLY=0
[[ -z "$AGENT_SKIP_HELP" ]] && AGENT_SKIP_HELP=0
[[ -z "$AGENT_HDR" ]] && AGENT_HDR=0
[[ -z "$AGENT_DOWNLOAD" ]] && AGENT_DOWNLOAD=1
[[ -z "$AGENT_SCRIPTS_DOWNLOAD" ]] && AGENT_SCRIPTS_DOWNLOAD=1
[[ -z "$AGENT_DL_URL" ]] && AGENT_DL_URL="https://github.com/0xDC00/agent/releases/latest/download/agent-v0.1.4-win32-x64.zip"
[[ -z "$AGENT_SCRIPTS_DL_URL" ]] && AGENT_SCRIPTS_DL_URL="https://github.com/0xDC00/scripts/archive/refs/heads/main.zip"
[[ -z "$AGENT_PORT" ]] && AGENT_PORT=6677
[[ -z "$AGENT_IP" ]] && AGENT_IP="0.0.0.0"
[[ -z "$AGENT_SCRIPT" ]] && exit 1

TARGET_EXE="Z:$(echo "$GAME_EXE" | sed 's/\//\\/g')"
SCRIPT_PATH="Z:$(echo "$AGENT_SCRIPTS_PATH" | sed 's/\//\\/g')\\$AGENT_SCRIPT"

PROTON_BIN=""
for arg in "$@"; do
    if [[ "$arg" == *"/proton" ]]; then
        PROTON_BIN="$arg"
        break
    fi
done

if [[ $AGENT_SKIP_HELP != 1 ]]; then
cat << EOF
usage: [ENV VARS...] agent-launcher.sh %command%

Launches agent + game together + various ulility stuff

Do not end Paths with extra /

Environment Variables:
AGENT_PATH: Path where agent.exe lies. (Default: $GAME_DIR)
AGENT_SCRIPTS_PATH: Path where agent scrips lie. (Default: $GAME_DIR/data/scripts)
AGENT_SCRIPT: Agent script to use (file name) in the AGENT_SCRIPTS_PATH (Default: none, required)
AGENT_DELAY: Delay after which agent hooks the game (ms). (Default: 5000)
AGENT_ONLY: Launch agent without game. (Default: 0)
AGENT_SKIP_HELP: Do not show this help message. (Default: 0)
AGENT_HDR: Enable HDR compat under wayland. (Default: 0)
AGENT_DOWNLOAD: Download agent if not in location. (Default: 1)
AGENT_DL_URL: Agent download url. (Default: https://github.com/0xDC00/agent/releases/latest/download/agent-v0.1.4-win32-x64.zip)
AGENT_SCRIPTS_DOWNLOAD: Download agent scripts. (Default: 1)
AGENT_SCRIPTS_DL_URL: Agent scripts download url: (Default: https://github.com/0xDC00/scripts/archive/refs/heads/main.zip)
AGENT_PORT: Agent websocket port. (Default: 6677)
AGENT_IP: Agent websocket host. (Default: 0.0.0.0)
EOF
fi

if [[ $AGENT_DOWNLOAD == 1 && ! -f "$AGENT_PATH/agent.exe" ]]; then
  echo "[$(date)] --- DOWNLOADING AGENT ---" >> "$LOG_FILE"

  agent_zip="$AGENT_PATH/agent-win32.zip"

  echo "[$(date)]   Fetching $AGENT_DL_URL" >> "$LOG_FILE"
  mkdir -p "$AGENT_PATH"
  wget "$AGENT_DL_URL" -O "$agent_zip"
  unzip "$agent_zip" -d "$AGENT_PATH"
  rm "$agent_zip"
fi

if [[ $AGENT_SCRIPTS_DOWNLOAD == 1 && ! -d "$AGENT_SCRIPTS_PATH" ]]; then
  echo "[$(date)] --- DOWNLOADING AGENT SCRIPTS ---" >> "$LOG_FILE"

  scripts_zip="$AGENT_PATH/scripts.zip"

  echo "[$(date)]   Fetching scripts from $AGENT_SCRIPTS_DL_URL" >> "$LOG_FILE"
  mkdir -p "$AGENT_SCRIPTS_PATH"
  wget "$AGENT_SCRIPTS_DL_URL" -O "$scripts_zip"
  unzip "$scripts_zip" -d "$AGENT_PATH"
  mv -T "$AGENT_PATH/scripts-main" "$AGENT_SCRIPTS_PATH"
  rm "$scripts_zip"
  echo "[$(date)]   Download finished" >> "$LOG_FILE"
fi

# Patch bundle.js with ip/port
echo "[$(date)] --- PATCHING AGENT SETTINGS ---" >> "$LOG_FILE"

# IP
sed -i -E 's/(otp_wsHost:")[^"]+(".*)/\1'"$AGENT_IP"'\2/g' "$AGENT_PATH/resources/app/dist/bundle.js"
# PORT
sed -i -E 's/(otp_wsPort:)[0-9]*(,)/\1'"$AGENT_PORT"'\2/g' "$AGENT_PATH/resources/app/dist/bundle.js"
# Clipboard off
sed -i -E 's/(otp_clipboard:)[!0-9]*(,)/\1!1\2/g' "$AGENT_PATH/resources/app/dist/bundle.js"
# Translation off
sed -i -E 's/(opt_deepl:)[!0-9]*(,)/\1!1\2/g' "$AGENT_PATH/resources/app/dist/bundle.js"

echo "[$(date)] --- AGENT LAUNCHER: ENVIRONMENT ---" >> "$LOG_FILE"
echo "[$(date)]   GAME_EXE=$GAME_EXE" >> "$LOG_FILE"
echo "[$(date)]   AGENT_PATH=$AGENT_PATH" >> "$LOG_FILE"
echo "[$(date)]   TARGET_EXE=$TARGET_EXE" >> "$LOG_FILE"
echo "[$(date)]   SCRIPT_PATH=$SCRIPT_PATH" >> "$LOG_FILE"
echo "[$(date)]   PROTON_BIN=$PROTON_BIN" >> "$LOG_FILE"
echo "[$(date)]   AGENT_LOG=$AGENT_LOG" >> "$LOG_FILE"
echo "[$(date)]   AGENT_IP=$AGENT_IP" >> "$LOG_FILE"
echo "[$(date)]   AGENT_PORT=$AGENT_PORT" >> "$LOG_FILE"

if [[ "$AGENT_ONLY" = 1 ]]; then
  exec "$PROTON_BIN" run "$AGENT_PATH/agent.exe" >> "$LOG_FILE" 2>&1
else
  if [[ $AGENT_HDR == 1 ]]; then
    export PROTON_ENABLE_WAYLAND=1
    export PROTON_ENABLE_HDR=1
    export DXVK_HDR=1
    export ENABLE_HDR_WSI=1
  fi

  echo "[$(date)] --- AGENT EXECUTING ---" >> "$LOG_FILE"
  echo "[$(date)] +   \"$PROTON_BIN\" run \\" >> "$LOG_FILE"
  echo "[$(date)] +     \"$AGENT_PATH/agent.exe\" \\" >> "$LOG_FILE"
  echo "[$(date)] +     --target=\"$TARGET_EXE\" \\" >> "$LOG_FILE"
  echo "[$(date)] +     --script=\"$SCRIPT_PATH\" \\" >> "$LOG_FILE"
  echo "[$(date)] +     --delay=$AGENT_DELAY" >> "$LOG_FILE"

  exec "$PROTON_BIN" run "$AGENT_PATH/agent.exe" \
      --target="$TARGET_EXE" \
      --script="$SCRIPT_PATH" \
      --delay=$AGENT_DELAY >> "$LOG_FILE" 2>&1
fi
