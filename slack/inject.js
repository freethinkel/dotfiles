// theme.css is rewritten by bin/theme-apply: refetch it whenever the window gets focus
const link = document.createElement('link');
link.rel = 'stylesheet';
const load = () => { link.href = chrome.runtime.getURL('theme.css') + '?' + Date.now(); };
load();
document.documentElement.append(link);
addEventListener('focus', load);

// the PWA title bar takes the manifest's aubergine unless the page names a colour
const meta = document.createElement('meta');
meta.name = 'theme-color';
link.addEventListener('load', () => {
  meta.content = getComputedStyle(document.documentElement).getPropertyValue('--dt_color-base-pry').trim();
  document.head?.append(meta);
});
