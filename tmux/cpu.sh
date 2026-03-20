show_cpu() {
  local index=$1
  local icon="$(get_tmux_option "@catppuccin_cpu_icon" "")"
  local color="$(get_tmux_option "@catppuccin_cpu_color" "$thm_cyan")"
  local text="$(get_tmux_option "@catppuccin_cpu_text" "#(top -bn1 | grep 'Cpu(s)' | awk '{printf \"%.0f%%\", \$2+\$4}')")"

  local module=$( build_status_module "$index" "$icon" "$color" "$text" )

  echo "$module"
}
