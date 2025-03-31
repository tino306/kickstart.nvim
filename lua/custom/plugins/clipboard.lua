-- For init.lua
if vim.fn.has('wsl') == 1 then
  vim.g.clipboard = {
    name = 'wsl-clipboard',
    copy = {
      ['+'] = 'clip.exe',
      ['*'] = 'clip.exe',
    },
    paste = {
      ['+'] = 'powershell.exe Get-Clipboard',
      ['*'] = 'powershell.exe Get-Clipboard',
    },
    cache_enabled = 0,
  }
end
return {}
