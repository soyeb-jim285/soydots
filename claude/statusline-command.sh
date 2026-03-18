#!/usr/bin/env bash
# Claude Code status line script

input=$(cat)

# --- Extract fields ---
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // ""')
dir=$(basename "$cwd")
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
input_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
output_tokens=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
session=$(echo "$input" | jq -r '.session_name // empty')
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')

# --- ANSI Colors (will appear dimmed in the status line) ---
reset="\033[0m"
bold="\033[1m"
dim="\033[2m"

fg_cyan="\033[36m"
fg_blue="\033[34m"
fg_green="\033[32m"
fg_yellow="\033[33m"
fg_magenta="\033[35m"
fg_red="\033[31m"
fg_white="\033[37m"
fg_gray="\033[90m"

# --- Build segments ---

# Directory segment
dir_segment="${fg_yellow}${dir}${reset}"

# Model segment
model_segment="${fg_magenta}${model}${reset}"

# Context segment
if [ -n "$used" ]; then
  # Color context bar based on usage
  used_int=${used%.*}
  if [ "$used_int" -ge 90 ] 2>/dev/null; then
    ctx_color="$fg_red"
  elif [ "$used_int" -ge 70 ] 2>/dev/null; then
    ctx_color="$fg_yellow"
  else
    ctx_color="$fg_green"
  fi
  # Build a mini bar (10 chars wide)
  filled=$(( (used_int + 9) / 10 ))
  empty=$(( 10 - filled ))
  bar="${ctx_color}"
  for i in $(seq 1 $filled); do bar="${bar}█"; done
  bar="${bar}${fg_gray}"
  for i in $(seq 1 $empty); do bar="${bar}░"; done
  bar="${bar}${reset}"
  ctx_segment="${bar} ${ctx_color}${used_int}%${reset}"
else
  ctx_segment="${fg_gray}no ctx${reset}"
fi

# Lines added/removed segment
lines_segment="${fg_green}+${lines_added} ${fg_red}-${lines_removed}${reset}"

# Tokens segment (format large numbers with k suffix)
fmt_tokens() {
  local n=$1
  if [ "$n" -ge 1000 ] 2>/dev/null; then
    printf "%s.%sk" "$(( n / 1000 ))" "$(( (n % 1000) / 100 ))"
  else
    printf "%s" "$n"
  fi
}
tokens_segment="${fg_cyan}$(fmt_tokens "$input_tokens")${fg_gray}/${fg_cyan}$(fmt_tokens "$output_tokens")${reset}"

# Optional vim mode segment
vim_segment=""
if [ -n "$vim_mode" ]; then
  if [ "$vim_mode" = "NORMAL" ]; then
    vim_segment=" ${fg_blue}[N]${reset}"
  else
    vim_segment=" ${fg_green}[I]${reset}"
  fi
fi

# Optional session name segment
session_segment=""
if [ -n "$session" ]; then
  session_segment=" ${fg_gray}\"${session}\"${reset}"
fi

# --- Compose the status line ---
# Format: [user@host] [dir]  model  ctx-bar xx%  [vim] [session]

printf "${fg_gray}~/${reset}%b" "$dir_segment"
printf "  ${fg_gray}⬡${reset} %b" "$model_segment"
printf "  ${fg_gray}ctx:${reset} %b" "$ctx_segment"
printf "  %b" "$lines_segment"
printf "  ${fg_gray}tok:${reset} %b" "$tokens_segment"
printf "%b" "$vim_segment"
printf "%b" "$session_segment"
printf "\n"
