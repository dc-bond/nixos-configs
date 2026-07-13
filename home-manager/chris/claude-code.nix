{
  config,
  lib,
  pkgs,
  ...
}:

let
  # PreToolUse hook that parses compound bash commands (pipes, chains,
  # subshells, $(…), `…`) and auto-approves them if every segment matches
  # permissions.allow (and none match permissions.deny). Otherwise falls
  # through to Claude Code's native prompt.
  # Upstream: https://github.com/oryband/claude-code-auto-approve
  approveHook = pkgs.symlinkJoin {
    name = "claude-approve-compound-bash";
    paths = [
      (pkgs.writeShellScriptBin "approve-compound-bash" ''
        # shellcheck shell=bash
        set -uo pipefail

        if [[ "''${BASH_VERSINFO[0]}" -lt 4 || ( "''${BASH_VERSINFO[0]}" -eq 4 && "''${BASH_VERSINFO[1]}" -lt 3 ) ]]; then
          for try_bash in /opt/homebrew/bin/bash /usr/local/bin/bash /home/linuxbrew/.linuxbrew/bin/bash; do
            if [[ -x "$try_bash" ]]; then
              exec "$try_bash" "$0" "$@"
            fi
          done
          exit 0
        fi

        DEBUG=false
        readonly ALLOW_JSON='{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'

        debug() { if $DEBUG; then printf '[approve-compound] %s\n' "$*" >&2; fi; }
        approve() { printf '%s\n' "$ALLOW_JSON"; exit 0; }
        deny() {
          jq -n --arg msg "$1" '{
            hookSpecificOutput: {hookEventName:"PreToolUse", permissionDecision:"deny"},
            systemMessage: $msg
          }' >&2
          exit 2
        }

        find_git_root() {
          local toplevel git_dir git_common_dir
          toplevel=$(git rev-parse --show-toplevel 2>/dev/null) || return
          git_dir=$(git rev-parse --git-dir 2>/dev/null)
          git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
          if [[ "$git_dir" != "$git_common_dir" ]]; then
            dirname "$git_common_dir"
          else
            printf '%s\n' "$toplevel"
          fi
        }

        load_prefixes() {
          local git_root
          git_root=$(find_git_root 2>/dev/null || true)

          local files=(
            "$HOME/.claude/settings.json"
            "$HOME/.claude/settings.local.json"
          )
          if [[ -n "$git_root" ]]; then
            files+=("$git_root/.claude/settings.json" "$git_root/.claude/settings.local.json")
          else
            files+=(".claude/settings.json" ".claude/settings.local.json")
          fi

          local line
          while IFS= read -r line; do
            case "$line" in
              allow:*) allowed_prefixes+=("''${line#allow:}") ;;
              deny:*)  denied_prefixes+=("''${line#deny:}") ;;
            esac
          done < <(
            for file in "''${files[@]}"; do
              [[ -f "$file" ]] || continue
              debug "Reading prefixes from: $file"
              jq -r '
                def extract_prefix: sub("^Bash\\("; "") | sub("( \\*|\\*|:\\*)\\)$"; "") | sub("\\)$"; "");
                (.permissions.allow[]? // empty | select(startswith("Bash(")) | "allow:" + extract_prefix),
                (.permissions.deny[]?  // empty | select(startswith("Bash(")) | "deny:"  + extract_prefix)
              ' "$file" 2>/dev/null || true
            done | sort -u
          )
        }

        needs_compound_parse() {
          # shellcheck disable=SC2016
          [[ "$1" == *['|&;`']* || "$1" == *'$('* || "$1" == *'<('* || "$1" == *'>('* ]]
        }

        read -r -d ''' SHFMT_AST_FILTER << 'JQEOF' || true
        def get_part_value:
          if (type == "object" | not) then ""
          elif .Type == "Lit" then .Value // ""
          elif .Type == "DblQuoted" then
            "\"" + ([.Parts[]? | get_part_value] | join("")) + "\""
          elif .Type == "SglQuoted" then
            "'" + (.Value // "") + "'"
          elif .Type == "ParamExp" then
            "$" + (.Param.Value // "")
          elif .Type == "CmdSubst" then "$(..)"
          else ""
          end;

        def find_cmd_substs:
          if type == "object" then
            if .Type == "CmdSubst" or .Type == "ProcSubst" then .
            elif .Type == "DblQuoted" then .Parts[]? | find_cmd_substs
            elif .Type == "ParamExp" then
              (.Exp?.Word | find_cmd_substs),
              (.Repl?.Orig | find_cmd_substs),
              (.Repl?.With | find_cmd_substs)
            elif .Parts then .Parts[]? | find_cmd_substs
            else empty
            end
          elif type == "array" then .[] | find_cmd_substs
          else empty
          end;

        def get_arg_value:
          [.Parts[]? | get_part_value] | join("");

        def get_command_string:
          if .Type == "CallExpr" and .Args then
            [.Args[] | get_arg_value] | map(select(length > 0)) | join(" ")
          else empty
          end;

        def extract_commands:
          if type == "object" then
            if .Type == "CallExpr" then
              get_command_string,
              (.Args[]? | find_cmd_substs | .Stmts[]? | extract_commands),
              (.Assigns[]?.Value | find_cmd_substs | .Stmts[]? | extract_commands),
              (.Assigns[]?.Array?.Elems[]?.Value | find_cmd_substs | .Stmts[]? | extract_commands),
              (.Redirs[]?.Word | find_cmd_substs | .Stmts[]? | extract_commands)
            elif .Type == "BinaryCmd" then
              (.X | extract_commands), (.Y | extract_commands)
            elif .Type == "Subshell" or .Type == "Block" then
              (.Stmts[]? | extract_commands)
            elif .Type == "CmdSubst" then
              (.Stmts[]? | extract_commands)
            elif .Type == "IfClause" then
              (.Cond[]? | extract_commands),
              (.Then[]? | extract_commands),
              (.Else | extract_commands)
            elif .Type == "WhileClause" or .Type == "UntilClause" then
              (.Cond[]? | extract_commands), (.Do[]? | extract_commands)
            elif .Type == "ForClause" then
              (.Loop.Items[]? | find_cmd_substs | .Stmts[]? | extract_commands),
              (.Do[]? | extract_commands)
            elif .Type == "CaseClause" then
              (.Items[]?.Stmts[]? | extract_commands)
            elif .Type == "DeclClause" then
              (.Args[]?.Value | find_cmd_substs | .Stmts[]? | extract_commands),
              (.Args[]?.Array?.Elems[]?.Value | find_cmd_substs | .Stmts[]? | extract_commands)
            elif .Cmd then
              (.Cmd | extract_commands),
              (.Redirs[]?.Word | find_cmd_substs | .Stmts[]? | extract_commands)
            elif .Stmts then
              (.Stmts[] | extract_commands)
            else
              (.[] | extract_commands)
            end
          elif type == "array" then
            (.[] | extract_commands)
          else empty
          end;

        extract_commands | select(length > 0)
        JQEOF
        readonly SHFMT_AST_FILTER

        parse_compound() {
          local cmd="$1"

          if [[ "$cmd" == *"=~"* ]]; then
            cmd=$(sed -E 's/\[\[[[:space:]]*\\?![[:space:]]+(.+)[[:space:]]+=~/! [[ \1 =~/g' <<< "$cmd")
          fi

          local ast
          if ! ast=$(shfmt -ln bash -tojson <<< "$cmd" 2>/dev/null); then
            debug "shfmt parse failed"
            return 1
          fi

          local raw_commands
          raw_commands=$(jq -r "$SHFMT_AST_FILTER" <<< "$ast" 2>/dev/null) || return 1

          while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            if [[ "$line" =~ ^(env[[:space:]]+)?(/[^[:space:]]*/)?((ba)?sh)[[:space:]]+-c[[:space:]]*[\'\"](.*)[\'\"]$ ]]; then
              debug "Recursing into shell -c: ''${BASH_REMATCH[5]}"
              if ! parse_compound "''${BASH_REMATCH[5]}"; then
                printf '%s\0' "$line"
              fi
            else
              printf '%s\0' "$line"
            fi
          done <<< "$raw_commands"
        }

        strip_env_vars() {
          local full_command="$1"
          local -n out_ref=$2
          local stripped="$full_command"

          while [[ "$stripped" =~ ^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+(.*) ]]; do
            stripped="''${BASH_REMATCH[1]}"
          done

          out_ref=("$full_command")
          [[ "$stripped" != "$full_command" ]] && out_ref+=("$stripped")
        }

        matches_prefix_list() {
          local full_command="$1"
          local -n list_ref=$2
          local label="''${3:-}"

          [[ ''${#list_ref[@]} -eq 0 ]] && return 1

          local -a candidates=()
          strip_env_vars "$full_command" candidates

          for cmd in "''${candidates[@]}"; do
            for prefix in "''${list_ref[@]}"; do
              if [[ "$cmd" == "$prefix" ]] || [[ "$cmd" == "$prefix "* ]] || [[ "$cmd" == "$prefix/"* ]]; then
                debug "MATCH ($label): '$cmd' -> '$prefix'"
                return 0
              fi
            done
          done
          return 1
        }

        is_allowed() {
          local cmd="$1"
          if matches_prefix_list "$cmd" denied_prefixes "deny"; then
            return 1
          fi
          matches_prefix_list "$cmd" allowed_prefixes "allow"
        }

        all_allowed() {
          local -n cmds_ref=$1

          for cmd in "''${cmds_ref[@]}"; do
            [[ -z "$cmd" ]] && continue
            if ! is_allowed "$cmd"; then
              debug "Not all commands approved"
              return 1
            fi
          done
          return 0
        }

        any_denied() {
          local -n cmds_ref=$1
          [[ ''${#denied_prefixes[@]} -eq 0 ]] && return 1

          for cmd in "''${cmds_ref[@]}"; do
            [[ -z "$cmd" ]] && continue
            if matches_prefix_list "$cmd" denied_prefixes "deny"; then
              debug "Denied segment found: $cmd"
              return 0
            fi
          done
          return 1
        }

        main() {
          local permissions_json="" deny_json="" mode="hook"

          while [[ $# -gt 0 ]]; do
            case "$1" in
              --debug) DEBUG=true; shift ;;
              --permissions) permissions_json="$2"; shift 2 ;;
              --deny) deny_json="$2"; shift 2 ;;
              parse) mode="parse"; shift ;;
              *) shift ;;
            esac
          done

          for dep in jq shfmt; do
            if ! command -v "$dep" &>/dev/null; then
              debug "Missing $dep, falling through"
              exit 0
            fi
          done

          if [[ "$mode" == "parse" ]]; then
            local cmd
            cmd=$(cat)
            [[ -z "$cmd" ]] && exit 0
            if ! needs_compound_parse "$cmd"; then
              printf '%s\n' "$cmd"
            else
              local -a cmds=()
              mapfile -d ''' cmds < <(parse_compound "$cmd")
              for c in "''${cmds[@]}"; do
                [[ -n "$c" ]] && printf '%s\n' "$c"
              done
            fi
            exit 0
          fi

          local input command
          input=$(cat)
          command=$(jq -r '.tool_input.command // empty' <<< "$input")
          [[ -z "$command" ]] && exit 0

          debug "Command: $command"

          local -a allowed_prefixes=() denied_prefixes=()
          if [[ -n "$permissions_json" ]]; then
            local line
            while IFS= read -r line; do
              [[ -n "$line" ]] && allowed_prefixes+=("$line")
            done < <(jq -r '.[] | sub("^Bash\\("; "") | sub("( \\*|\\*|:\\*)\\)$"; "") | sub("\\)$"; "")' <<< "$permissions_json" 2>/dev/null)
            if [[ -n "$deny_json" ]]; then
              while IFS= read -r line; do
                [[ -n "$line" ]] && denied_prefixes+=("$line")
              done < <(jq -r '.[] | sub("^Bash\\("; "") | sub("( \\*|\\*|:\\*)\\)$"; "") | sub("\\)$"; "")' <<< "$deny_json" 2>/dev/null)
            fi
          else
            load_prefixes
          fi
          debug "Loaded ''${#allowed_prefixes[@]} allow, ''${#denied_prefixes[@]} deny prefixes"
          [[ ''${#allowed_prefixes[@]} -eq 0 ]] && exit 0

          if ! needs_compound_parse "$command"; then
            debug "Simple command"
            is_allowed "$command" && approve
            exit 0
          fi

          debug "Compound command"
          local -a extracted_commands=()
          mapfile -d ''' extracted_commands < <(parse_compound "$command")

          [[ ''${#extracted_commands[@]} -eq 0 || -z "''${extracted_commands[0]}" ]] && exit 0

          all_allowed extracted_commands && approve

          any_denied extracted_commands && deny "Compound command contains a denied sub-command"
          exit 0
        }

        main "$@"
      '')
    ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/approve-compound-bash \
        --prefix PATH : ${lib.makeBinPath [ pkgs.jq pkgs.shfmt pkgs.gitMinimal pkgs.coreutils ]}
    '';
  };

  settings = {
    permissions = {
      allow = [
        "Read"
        "Edit"
        "Write"
        "WebSearch"
        "WebFetch(domain:github.com)"
        "WebFetch(domain:raw.githubusercontent.com)"
        "WebFetch(domain:api.github.com)"
        "WebFetch(domain:search.nixos.org)"
        "Bash(ls *)"
        "Bash(ls)"
        "Bash(cat *)"
        "Bash(pwd)"
        "Bash(stat *)"
        "Bash(file *)"
        "Bash(wc *)"
        "Bash(find *)"
        "Bash(tree *)"
        "Bash(tree)"
        "Bash(head *)"
        "Bash(tail *)"
        "Bash(rg *)"
        "Bash(grep *)"
        "Bash(which *)"
        "Bash(readlink *)"
        "Bash(echo *)"
        "Bash(echo)"
        "Bash(printf *)"
        "Bash(sort *)"
        "Bash(uniq *)"
        "Bash(cut *)"
        "Bash(tr *)"
        "Bash(awk *)"
        "Bash(sed *)"
        "Bash(xargs *)"
        "Bash(strings *)"
        "Bash(python3 *)"
        "Bash(hostname)"
        "Bash(whoami)"
        "Bash(date)"
        "Bash(date *)"
        "Bash(uname *)"
        "Bash(id)"
        "Bash(id *)"
        "Bash(uptime)"
        "Bash(env)"
        "Bash(true)"
        "Bash(false)"
        "Bash(git status)"
        "Bash(git status *)"
        "Bash(git diff *)"
        "Bash(git log *)"
        "Bash(git show *)"
        "Bash(git branch *)"
        "Bash(git branch)"
        "Bash(git remote *)"
        "Bash(git remote)"
        "Bash(git config --get *)"
        "Bash(git add *)"
        "Bash(nix eval *)"
        "Bash(nix derivation *)"
        "Bash(nix search *)"
        "Bash(nix flake show *)"
        "Bash(nix-store --query *)"
        "Bash(nix why-depends *)"
        "Bash(systemctl --user status *)"
        "Bash(systemctl status *)"
        "Bash(journalctl *)"
        "Bash(ssh aspen *)"
        "Bash(ssh juniper *)"
        "Bash(ssh kauri *)"
        "Bash(curl * vikunja.opticon.dev *)"
      ];
      deny = [
        "Bash(rm -rf *)"
        "Bash(sudo rm *)"
        "Bash(git push --force *)"
        "Bash(git push -f *)"
        "Bash(git reset --hard *)"
        "Bash(nixos-rebuild switch *)"
        "Bash(nixos-rebuild boot *)"
      ];
      additionalDirectories = [ ];
    };
    model = "opus";
    effortLevel = "high";
    hooks = {
      PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = "${approveHook}/bin/approve-compound-bash";
              timeout = 5;
            }
          ];
        }
      ];
    };
  };

in

{
  home.file.".claude/settings.json".source =
    (pkgs.formats.json { }).generate "claude-settings.json" settings;
}