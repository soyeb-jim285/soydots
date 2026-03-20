show_temp() {
  local index=$1
  local icon="$(get_tmux_option "@catppuccin_temp_icon" "")"
  local color="$(get_tmux_option "@catppuccin_temp_color" "$thm_yellow")"
  local text="$(get_tmux_option "@catppuccin_temp_text" "#(sensors 2>/dev/null | awk '/Package id 0:|Tctl:/ {gsub(/[+°C]/, \"\"); printf \"%.0f°C\", \$NF; exit}' || awk '{printf \"%.0f°C\", \$1/1000}' /sys/class/thermal/thermal_zone0/temp 2>/dev/null)")"

  local module=$( build_status_module "$index" "$icon" "$color" "$text" )

  echo "$module"
}
