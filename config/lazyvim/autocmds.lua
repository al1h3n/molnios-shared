vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    -- Forces floating windows to have a solid background color
    local bg_color = "#282828" -- Adjust this to match your gruvbox contrast
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = bg_color })
    vim.api.nvim_set_hl(0, "FloatBorder", { bg = bg_color })
  end,
})