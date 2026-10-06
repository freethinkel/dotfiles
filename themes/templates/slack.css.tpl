/* Slack web client (app.slack.com), loaded by the slack/ extension.
   Slack's light and dark modes both get this palette: the gray ramp runs
   background -> foreground, which drives the sidebar/window ("theme-*") tokens,
   and the semantic tokens below cover the message pane. */
:root, .sk-client-theme--light, .sk-client-theme--dark, .sk-client-theme--light-inverted-sidebar {
  --dt_color-plt-gray-0: {{ background_rgb }} !important;
  --dt_color-plt-gray-5: {{ mix3_rgb }} !important;
  --dt_color-plt-gray-10: {{ mix8_rgb }} !important;
  --dt_color-plt-gray-20: {{ mix16_rgb }} !important;
  --dt_color-plt-gray-30: {{ mix30_rgb }} !important;
  --dt_color-plt-gray-40: {{ mix40_rgb }} !important;
  --dt_color-plt-gray-50: {{ mix50_rgb }} !important;
  --dt_color-plt-gray-60: {{ mix60_rgb }} !important;
  --dt_color-plt-gray-70: {{ mix70_rgb }} !important;
  --dt_color-plt-gray-80: {{ mix80_rgb }} !important;
  --dt_color-plt-gray-90: {{ mix90_rgb }} !important;
  --dt_color-plt-gray-100: {{ foreground_rgb }} !important;

  --dt_color-base-pry: {{ background }} !important;
  --dt_color-base-sec: {{ background }} !important;
  --dt_color-base-ter: {{ mix8 }} !important;
  --dt_color-base-inv-pry: {{ foreground }} !important;
  --dt_color-base-hgl-1: color-mix(in srgb, {{ accent }} 15%, {{ background }}) !important;
  --dt_color-base-hgl-2: color-mix(in srgb, {{ color2 }} 15%, {{ background }}) !important;
  --dt_color-base-hgl-3: color-mix(in srgb, {{ color3 }} 15%, {{ background }}) !important;
  --dt_color-base-imp: color-mix(in srgb, {{ color1 }} 15%, {{ background }}) !important;
  --dt_color-base-inv-hgl-1: {{ accent }} !important;
  --dt_color-base-inv-hgl-2: {{ color2 }} !important;
  --dt_color-base-inv-hgl-3: {{ color3 }} !important;
  --dt_color-base-inv-imp: {{ color1 }} !important;
  --dt_color-base-modal: color-mix(in srgb, {{ background }} 60%, transparent) !important;
  --dt_color-base-pry-hover: color-mix(in srgb, {{ foreground }} 8%, transparent) !important;
  --dt_color-base-pry-pressed: color-mix(in srgb, {{ foreground }} 18%, transparent) !important;
  --dt_color-base-sec-hover: color-mix(in srgb, {{ foreground }} 8%, transparent) !important;
  --dt_color-base-sec-pressed: color-mix(in srgb, {{ foreground }} 18%, transparent) !important;

  --dt_color-surf-pry: color-mix(in srgb, {{ foreground }} 6%, transparent) !important;
  --dt_color-surf-sec: color-mix(in srgb, {{ foreground }} 25%, transparent) !important;
  --dt_color-surf-hgl-1: color-mix(in srgb, {{ accent }} 25%, transparent) !important;
  --dt_color-surf-hgl-2: color-mix(in srgb, {{ color2 }} 30%, transparent) !important;
  --dt_color-surf-hgl-3: color-mix(in srgb, {{ color3 }} 18%, transparent) !important;
  --dt_color-surf-imp: color-mix(in srgb, {{ color1 }} 25%, transparent) !important;
  --dt_color-surf-inv: color-mix(in srgb, {{ foreground }} 18%, transparent) !important;

  --dt_color-ctr-pry: {{ mix3 }} !important;
  --dt_color-ctr-sec: {{ mix3 }} !important;

  --dt_color-content-pry: {{ foreground }} !important;
  --dt_color-content-sec: {{ mix70 }} !important;
  --dt_color-content-ter: {{ mix50 }} !important;
  --dt_color-content-hgl-1: {{ accent }} !important;
  --dt_color-content-hgl-2: {{ color2 }} !important;
  --dt_color-content-hgl-3: {{ color3 }} !important;
  --dt_color-content-imp: {{ color1 }} !important;
  --dt_color-content-inv-pry: {{ background }} !important;
  --dt_color-content-inv-sec: {{ mix16 }} !important;

  --dt_color-otl-pry: {{ mix50 }} !important;
  --dt_color-otl-sec: color-mix(in srgb, {{ foreground }} 35%, transparent) !important;
  --dt_color-otl-ter: color-mix(in srgb, {{ foreground }} 15%, transparent) !important;
  --dt_color-otl-hgl-1: {{ accent }} !important;
  --dt_color-otl-hgl-1-sec: color-mix(in srgb, {{ accent }} 20%, transparent) !important;
  --dt_color-otl-hgl-2: {{ color2 }} !important;
  --dt_color-otl-hgl-3: {{ color3 }} !important;
  --dt_color-otl-imp: {{ color1 }} !important;

  /* sidebar: the window tint Slack's own theme picker sets */
  --dt_color-theme-base-pry: {{ background }} !important;
  --dt_color-theme-surf-pry: transparent !important;
  --dt_color-theme-surf-sec: color-mix(in srgb, {{ foreground }} 7%, transparent) !important;
  --dt_color-theme-surf-ter: color-mix(in srgb, {{ background }} 85%, transparent) !important;
  --dt_color-theme-surf-inv-pry: color-mix(in srgb, {{ foreground }} 13%, transparent) !important;
  --dt_color-theme-surf-inv-sec: color-mix(in srgb, {{ background }} 90%, transparent) !important;
  --dt_color-theme-surf-inv-ter: color-mix(in srgb, {{ foreground }} 8%, transparent) !important;

  /* legacy tokens, "r, g, b" */
  --sk_primary_foreground: {{ foreground_rgb }} !important;
  --sk_primary_background: {{ background_rgb }} !important;
  --sk_inverted_foreground: {{ background_rgb }} !important;
  --sk_inverted_background: {{ foreground_rgb }} !important;
  --sk_foreground_max: {{ foreground_rgb }} !important;
  --sk_foreground_high: {{ foreground_rgb }} !important;
  --sk_foreground_mid: {{ foreground_rgb }} !important;
  --sk_foreground_low: {{ foreground_rgb }} !important;
  --sk_foreground_soft: {{ foreground_rgb }} !important;
  --sk_foreground_min: {{ foreground_rgb }} !important;
  --sk_foreground_max_solid: {{ mix70_rgb }} !important;
  --sk_foreground_high_solid: {{ mix50_rgb }} !important;
  --sk_foreground_mid_solid: {{ mix30_rgb }} !important;
  --sk_foreground_low_solid: {{ mix16_rgb }} !important;
  --sk_foreground_soft_solid: {{ mix8_rgb }} !important;
  --sk_foreground_min_solid: {{ mix3_rgb }} !important;
  --sk_highlight: {{ accent_rgb }} !important;
  --sk_highlight_hover: {{ accent_rgb }} !important;
  --sk_highlight_accent: {{ accent_rgb }} !important;
  --sk_secondary_highlight: {{ color3_rgb }} !important;
}
