show_gpu() {
  local index=$1
  local icon="$(get_tmux_option "@catppuccin_gpu_icon" "󰢮")"
  local color="$(get_tmux_option "@catppuccin_gpu_color" "$thm_green")"
  local text="$(get_tmux_option "@catppuccin_gpu_text" "#(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | awk '{printf \"%s%%\", \$1}' || echo 'N/A')")"

  local module=$( build_status_module "$index" "$icon" "$color" "$text" )

  echo "$module"
}
