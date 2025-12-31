# agent-launcher
Automatically download, and attach [Agent](https://github.com/0xDC00/agent) to Steam games on Linux Systems.

This is a private public repo, I will not be answering issues accepting prs etc. You will have to edit the script on your own. This is very specific to my own configuration, please adjust accordingly.

```
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
```

## Nix

Use this to add it to your nix config:

```nix
{ pkgs, lib, ... }:
let
  agent-launcher = pkgs.stdenv.mkDerivation rec {
    version = "x.x"; # Replace with current release version
    name = "agent-launcher";
    src = pkgs.fetchFromGitHub {
      owner = "sdaqo";
      repo = "agent-launcher";
      rev = "v${version}";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Replace with correct hash
    };

    nativeBuildInputs = [ pkgs.makeWrapper ];
    runtimeInputs = with pkgs; [
      wget
      bash
      unzip
    ];

    installPhase = ''
      runHook preInstall

      install -Dm755 agent-launcher.sh $out/bin/agent-launcher.sh

      wrapProgram $out/bin/agent-launcher.sh \
        --prefix PATH : ${lib.makeBinPath runtimeInputs}

      runHook postInstall
    '';
  };
in 
{
  programs.steam = {
    enable = true;
    extraPackages = with pkgs; [
      agent-launcher # Add it to extra packages
    ];
  };
}
```
