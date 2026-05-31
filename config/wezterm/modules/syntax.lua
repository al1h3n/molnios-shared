local settings = {
  freetype_interpreter_version = 40,
  hide_tab_bar_if_only_one_tab = true,
  -- text_min_contrast_ratio = 1, -- If you have issues with contrast, high values make prompts look awful.
  unicode_version = 17, -- Find in unicode.org/releases
  warn_about_missing_glyphs = false,
  window_close_confirmation = 'NeverPrompt',
}

for k, v in pairs(settings) do
  config[k] = v
end