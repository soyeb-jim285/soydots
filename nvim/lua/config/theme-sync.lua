-- Auto-sync background from quickshell theme toggle
-- Watches ~/.cache/nvim-background for "light" or "dark"

local bg_file = vim.fn.expand("~/.cache/nvim-background")

local function sync_background()
  local f = io.open(bg_file, "r")
  if f then
    local bg = f:read("*l")
    f:close()
    if bg == "light" or bg == "dark" then
      vim.o.background = bg
    end
  end
end

-- Sync on startup
sync_background()

-- Watch the file for changes (FocusGained fires when switching back to nvim)
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
  callback = sync_background,
})

-- Also poll via timer for tmux/embedded use where FocusGained may not fire
local timer = vim.uv.new_timer()
timer:start(0, 5000, vim.schedule_wrap(sync_background))
