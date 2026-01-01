#!/usr/bin/env bash

if [[ $A_LOG == 1 ]]; then
  LOG_FILE="$HOME/agent_launcher_log.txt"
  exec 3>&1 4>&2
  trap 'exec 2>&4 1>&3' 0 1 2 3
  exec 1>$LOG_FILE.1 2>&1
else
  LOG_FILE="/dev/null"
fi

GAME_EXE="${@: -1}"
GAME_DIR=$(dirname "$GAME_EXE")
[[ -z "$A_PATH" ]] && A_PATH="$GAME_DIR"
[[ -z "$A_SCRIPTS_PATH" ]] && A_SCRIPTS_PATH="$A_PATH/data/scripts"
[[ -z "$A_DELAY" ]] && A_DELAY=5000
[[ -z "$A_ONLY" ]] && A_ONLY=0
[[ -z "$A_SKIP_HELP" ]] && A_SKIP_HELP=0
[[ -z "$A_HDR" ]] && A_HDR=0
[[ -z "$A_GAMESCOPE" ]] && A_GAMESCOPE=0
[[ -z "$A_GAMESCOPE_OPTS" ]] && A_GAMESCOPE_OPTS=""
[[ -z "$A_DOWNLOAD" ]] && A_DOWNLOAD=1
[[ -z "$A_SCRIPTS_DOWNLOAD" ]] && A_SCRIPTS_DOWNLOAD=1
[[ -z "$A_DL_URL" ]] && A_DL_URL="https://github.com/0xDC00/agent/releases/latest/download/agent-v0.1.4-win32-x64.zip"
[[ -z "$A_SCRIPTS_DL_URL" ]] && A_SCRIPTS_DL_URL="https://github.com/0xDC00/scripts/archive/refs/heads/main.zip"
[[ -z "$A_PORT" ]] && A_PORT=6677
[[ -z "$A_IP" ]] && A_IP="0.0.0.0"
[[ -z "$A_SCRIPT" ]] && exit 1

TARGET_EXE="Z:$(echo "$GAME_EXE" | sed 's/\//\\/g')"
SCRIPT_PATH="Z:$(echo "$A_SCRIPTS_PATH" | sed 's/\//\\/g')\\$A_SCRIPT"

PROTON_BIN=""
for arg in "$@"; do
    if [[ "$arg" == *"/proton" ]]; then
        PROTON_BIN="$arg"
        break
    fi
done

if [[ $A_SKIP_HELP != 1 ]]; then
cat << EOF
usage: [ENV VARS...] agent-launcher.sh %command%

Launches agent + game together + various ulility stuff

Do not end Paths with extra /

Environment Variables:
A_PATH: Path where agent.exe lies. (Default: $GAME_DIR)
A_SCRIPTS_PATH: Path where agent scrips lie. (Default: $GAME_DIR/data/scripts)
A_SCRIPT: Agent script to use (file name) in the A_SCRIPTS_PATH (Default: none, required)
A_DELAY: Delay after which agent hooks the game (ms). (Default: 5000)
A_ONLY: Launch agent without game. (Default: 0)
A_SKIP_HELP: Do not show this help message. (Default: 0)
A_HDR: Enable HDR compat under wayland. (Default: 0)
A_GAMESCOPE: Use gamescope to launch the game. (Default: 0)
A_GAMESCOPE_OPTS: Specify custom gamescope opts, e.g. "-W 3840 -H 2160". (Default: "")
A_DOWNLOAD: Download agent if not in location. (Default: 1)
A_DL_URL: Agent download url. (Default: https://github.com/0xDC00/agent/releases/latest/download/agent-v0.1.4-win32-x64.zip)
A_SCRIPTS_DOWNLOAD: Download agent scripts. (Default: 1)
A_SCRIPTS_DL_URL: Agent scripts download url: (Default: https://github.com/0xDC00/scripts/archive/refs/heads/main.zip)
A_PORT: Agent websocket port. (Default: 6677)
A_IP: Agent websocket host. (Default: 0.0.0.0)
EOF
fi

if [[ $A_DOWNLOAD == 1 && ! -f "$A_PATH/agent.exe" ]]; then
  echo "[$(date)] --- DOWNLOADING AGENT ---" >> "$LOG_FILE"

  agent_zip="$A_PATH/agent-win32.zip"

  echo "[$(date)]   Fetching $A_DL_URL" >> "$LOG_FILE"
  mkdir -p "$A_PATH"
  wget "$A_DL_URL" -O "$agent_zip"
  unzip "$agent_zip" -d "$A_PATH"
  rm "$agent_zip"
fi

if [[ $A_SCRIPTS_DOWNLOAD == 1 && ! -d "$A_SCRIPTS_PATH" ]]; then
  echo "[$(date)] --- DOWNLOADING A SCRIPTS ---" >> "$LOG_FILE"

  scripts_zip="$A_PATH/scripts.zip"

  echo "[$(date)]   Fetching scripts from $A_SCRIPTS_DL_URL" >> "$LOG_FILE"
  mkdir -p "$A_SCRIPTS_PATH"
  wget "$A_SCRIPTS_DL_URL" -O "$scripts_zip"
  unzip "$scripts_zip" -d "$A_PATH"
  mv -T "$A_PATH/scripts-main" "$A_SCRIPTS_PATH"
  rm "$scripts_zip"
  echo "[$(date)]   Download finished" >> "$LOG_FILE"
fi

# Patch bundle.js with ip/port
echo "[$(date)] --- PATCHING A SETTINGS ---" >> "$LOG_FILE"

# IP
sed -i -E 's/(otp_wsHost:")[^"]+(".*)/\1'"$A_IP"'\2/g' "$A_PATH/resources/app/dist/bundle.js"
# PORT
sed -i -E 's/(otp_wsPort:)[0-9]*(,)/\1'"$A_PORT"'\2/g' "$A_PATH/resources/app/dist/bundle.js"
# Clipboard off
sed -i -E 's/(otp_clipboard:)[!0-9]*(,)/\1!1\2/g' "$A_PATH/resources/app/dist/bundle.js"
# Translation off
sed -i -E 's/(opt_deepl:)[!0-9]*(,)/\1!1\2/g' "$A_PATH/resources/app/dist/bundle.js"

echo "[$(date)] --- AGENT LAUNCHER: ENVIRONMENT ---" >> "$LOG_FILE"
echo "[$(date)]   GAME_EXE=$GAME_EXE" >> "$LOG_FILE"
echo "[$(date)]   A_PATH=$A_PATH" >> "$LOG_FILE"
echo "[$(date)]   TARGET_EXE=$TARGET_EXE" >> "$LOG_FILE"
echo "[$(date)]   SCRIPT_PATH=$SCRIPT_PATH" >> "$LOG_FILE"
echo "[$(date)]   PROTON_BIN=$PROTON_BIN" >> "$LOG_FILE"
echo "[$(date)]   A_LOG=$A_LOG" >> "$LOG_FILE"
echo "[$(date)]   A_IP=$A_IP" >> "$LOG_FILE"
echo "[$(date)]   A_PORT=$A_PORT" >> "$LOG_FILE"

if [[ "$A_ONLY" = 1 ]]; then
  exec "$PROTON_BIN" run "$A_PATH/agent.exe" >> "$LOG_FILE" 2>&1
else
  echo "[$(date)] --- AGENT EXECUTING ---" >> "$LOG_FILE"
  echo "[$(date)] +   \"$PROTON_BIN\" run \\" >> "$LOG_FILE"
  echo "[$(date)] +     \"$A_PATH/agent.exe\" \\" >> "$LOG_FILE"
  echo "[$(date)] +     --target=\"$TARGET_EXE\" \\" >> "$LOG_FILE"
  echo "[$(date)] +     --script=\"$SCRIPT_PATH\" \\" >> "$LOG_FILE"
  echo "[$(date)] +     --delay=$A_DELAY" >> "$LOG_FILE"
  
  if [[ $A_GAMESCOPE == 1 ]]; then
    if [[ $A_HDR == 1 ]]; then
      export DXVK_HDR=1
      hdr_flag="--hdr-enabled"
    fi

    exec gamescope $A_GAMESCOPE_OPTS $hdr_flag -f --  "$PROTON_BIN" run "$A_PATH/agent.exe" \
        --target="$TARGET_EXE" \
        --script="$SCRIPT_PATH" \
        --delay=$A_DELAY >> "$LOG_FILE" 2>&1
  else
    if [[ $A_HDR == 1 ]]; then
      export PROTON_ENABLE_WAYLAND=1
      export PROTON_ENABLE_HDR=1
      export DXVK_HDR=1
      export ENABLE_HDR_WSI=1
    fi
    exec "$PROTON_BIN" run "$A_PATH/agent.exe" \
        --target="$TARGET_EXE" \
        --script="$SCRIPT_PATH" \
        --delay=$A_DELAY >> "$LOG_FILE" 2>&1
  fi
fi
