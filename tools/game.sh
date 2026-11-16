#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-/home/jaco/.local/bin/godot4}"
COMMAND="${1:-run}"
if [[ $# -gt 0 ]]; then shift; fi
case "$COMMAND" in
  editor|run)
    # Keep development settings and saves local; regression tests use a separate slot.
    export XDG_CONFIG_HOME="$PROJECT_DIR/work/config"
    export XDG_CACHE_HOME="$PROJECT_DIR/work/cache"
    export XDG_DATA_HOME="$PROJECT_DIR/work/player-data"
    mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME"
    if [[ "$COMMAND" == editor ]]; then
      export XDG_DATA_HOME="$PROJECT_DIR/work/engine-data"
      mkdir -p "$XDG_DATA_HOME/godot"
      if [[ ! -e "$XDG_DATA_HOME/godot/export_templates" && -d "$HOME/.local/share/godot/export_templates" ]]; then
        ln -s "$HOME/.local/share/godot/export_templates" "$XDG_DATA_HOME/godot/export_templates"
      fi
      exec "$GODOT_BIN" --editor --path "$PROJECT_DIR" "$@"
    fi
    exec "$GODOT_BIN" --path "$PROJECT_DIR" "$@"
    ;;
  verify|export|test) exec python3 "$PROJECT_DIR/tools/verify.py" "$COMMAND" "$@" ;;
  audit) exec python3 "$PROJECT_DIR/tools/audit_content.py" "$@" ;;
  *) echo 'Usage: tools/game.sh {editor|run|verify|export|test|audit}' >&2; exit 2 ;;
esac
