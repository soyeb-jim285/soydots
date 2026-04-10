return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      -- Flavour is set dynamically by vim.o.background
      -- dark -> mocha, light -> latte
      background = {
        light = "latte",
        dark = "mocha",
      },
      transparent_background = true,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
