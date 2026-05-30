local settings = {
  freetype_interpreter_version = 40,
  hide_tab_bar_if_only_one_tab = true,
  warn_about_missing_glyphs = false,
  window_close_confirmation = 'NeverPrompt',
}

for k, v in pairs(settings) do
  config[k] = v
end