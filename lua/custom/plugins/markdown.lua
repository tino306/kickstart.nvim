local grip_state = {
  job = nil,
  port = 6419,
  file = nil,
}

local function is_markdown_buffer()
  local filename = vim.api.nvim_buf_get_name(0)
  local filetype = vim.bo.filetype

  return filetype == 'markdown' or filename:match '%.md$' ~= nil
end

local function open_browser(url)
  local open_cmd

  if vim.fn.has 'mac' == 1 then
    open_cmd = { 'open', url }
  elseif vim.fn.has 'unix' == 1 then
    open_cmd = { 'xdg-open', url }
  else
    vim.notify('Unsupported OS for auto-opening browser', vim.log.levels.WARN)
    return
  end

  vim.fn.jobstart(open_cmd, { detach = true })
end

local function stop_grip()
  if grip_state.job then
    vim.fn.jobstop(grip_state.job)
    grip_state.job = nil
    grip_state.file = nil
    vim.notify 'Markdown preview stopped'
  end
end

local function toggle_markdown_preview()
  if not is_markdown_buffer() then
    vim.notify('Markdown preview only works for Markdown files (*.md)', vim.log.levels.WARN)
    return
  end

  if vim.fn.executable 'grip' ~= 1 then
    vim.notify('grip is not installed or not in PATH', vim.log.levels.ERROR)
    return
  end

  local file = vim.fn.expand '%:p'

  if file == '' then
    vim.notify('Current buffer has no file path', vim.log.levels.WARN)
    return
  end

  if grip_state.job then
    stop_grip()
    return
  end

  grip_state.file = file
  grip_state.job = vim.fn.jobstart({
    'grip',
    file,
    tostring(grip_state.port),
  }, {
    detach = true,
    on_exit = function()
      grip_state.job = nil
      grip_state.file = nil
    end,
  })

  if grip_state.job <= 0 then
    grip_state.job = nil
    grip_state.file = nil
    vim.notify('Failed to start grip', vim.log.levels.ERROR)
    return
  end

  vim.defer_fn(function()
    open_browser('http://localhost:' .. grip_state.port)
  end, 500)

  vim.notify('Markdown preview started: ' .. file)
end

vim.keymap.set('n', '<leader>mp', toggle_markdown_preview, {
  desc = 'Toggle Markdown Preview (grip)',
})

local vault_path = vim.fn.expand '/Users/tino/Library/Mobile Documents/iCloud~md~obsidian/Documents/vault'

vim.opt_local.conceallevel = 2
vim.keymap.set('n', '<leader>on', ':ObsidianNew<CR>', { desc = 'Obsidian: new note' })
vim.keymap.set('n', '<leader>oo', ':ObsidianQuickSwitch<CR>', { desc = 'Obsidian: open / switch note' })
vim.keymap.set('n', '<leader>os', ':ObsidianSearch<CR>', { desc = 'Obsidian: search notes' })
vim.keymap.set('n', '<leader>ot', ':ObsidianToday<CR>', { desc = "Obsidian: open today's note" })
vim.keymap.set('n', '<leader>oy', ':ObsidianYesterday<CR>', { desc = "Obsidian: open yesterday's note" })
vim.keymap.set('n', '<leader>or', ':ObsidianRename<CR>', { desc = 'Obsidian: rename note' })
vim.keymap.set('n', '<leader>ol', ':ObsidianLinkNew<CR>', { desc = 'Obsidian: link to new note' })
vim.keymap.set('n', '<leader>op', ':ObsidianPasteImg<CR>', { desc = 'Obsidian: paste image' })
vim.keymap.set('n', '<leader>od', function()
  vim.cmd('e' .. vim.fn.fnameescape(vault_path))
end, { desc = 'Obsidian: open vault in directory editor' })
return {
  -- obsidian.nvim
  {
    'epwalsh/obsidian.nvim',
    version = '*',
    lazy = false,
    ft = 'markdown',
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    opts = {
      workspaces = {
        {
          name = '00_vault',
          path = vault_path,
        },
      },
      ui = { enable = false },
      templates = {
        folder = '99_assets/templates',
      },
      daily_notes = {
        -- Optional, if you keep daily notes in a separate directory.
        folder = '00_daily-notes',
        -- Optional, if you want to change the date format for the ID of daily notes.
        date_format = '%Y-%m-%d',
        -- Optional, if you want to change the date format of the default alias of daily notes.
        alias_format = '%B %-d, %Y',
        -- Optional, default tags to add to each new daily note created.
        default_tags = { 'daily-notes' },
        -- Optional, if you want to automatically insert a template from your template directory like 'daily.md'
        template = 'daily.md',
      },
      -- Optional, completion of wiki links, local markdown links, and tags using nvim-cmp.
      completion = {
        -- Set to false to disable completion.
        nvim_cmp = true,
        -- Trigger completion at 2 chars.
        min_chars = 3,
      },
      -- Where to put new notes. Valid options are
      --  * "current_dir" - put new notes in same directory as the current buffer.
      --  * "notes_subdir" - put new notes in the default notes subdirectory.
      -- new_notes_location = "notes_subdir",
      picker = {
        -- Set your preferred picker. Can be one of 'telescope.nvim', 'fzf-lua', or 'mini.pick'.
        name = 'telescope.nvim',
        -- Optional, configure key mappings for the picker. These are the defaults.
        -- Not all pickers support all mappings.
        note_mappings = {
          -- Create a new note from your query.
          new = '<C-x>',
          -- Insert a link to the selected note.
          insert_link = '<C-l>',
        },
        tag_mappings = {
          -- Add tag(s) to current note.
          tag_note = '<C-x>',
          -- Insert a tag at the current location.
          insert_tag = '<C-l>',
        },
      },
      -- Specify how to handle attachments.
      attachments = {
        img_folder = '99_assets',

        -- Optional, customize the default name or prefix when pasting images via `:ObsidianPasteImg`.
        ---@return string
        img_name_func = function()
          -- Prefix image names with timestamp.
          return string.format('%s-', os.time())
        end,

        -- A function that determines the text to insert in the note when pasting an image.
        -- It takes two arguments, the `obsidian.Client` and an `obsidian.Path` to the image file.
        -- This is the default implementation.
        ---@param client obsidian.Client
        ---@param path obsidian.Path the absolute path to the image file
        ---@return string
        img_text_func = function(client, path)
          path = client:vault_relative_path(path) or path
          return string.format('![%s](%s)', path.name, path)
        end,
      },
      -- Optional, customize how note IDs are generated given an optional title.
      ---@param title string|?
      ---@return string
      note_id_func = function(title)
        -- Create note IDs in a Zettelkasten format with a timestamp and a suffix.
        -- In this case a note with the title 'My new note' will be given an ID that looks
        -- like '1657296016-my-new-note', and therefore the file name '1657296016-my-new-note.md'
        local suffix = ''
        if title ~= nil then
          -- If title is given, transform it into valid file name.
          suffix = title:gsub(' ', '-'):gsub('[^A-Za-z0-9-]', ''):lower()
        else
          -- If title is nil, just add 4 random uppercase letters to the suffix.
          for _ = 1, 4 do
            suffix = suffix .. string.char(math.random(65, 90))
          end
        end
        return tostring(os.time()) .. '-' .. suffix
      end,
    },
    mappings = {
      -- Overrides the 'gf' mapping to work on markdown/wiki links within your vault.
      ['gf'] = {
        action = function()
          return require('obsidian').util.gf_passthrough()
        end,
        opts = { noremap = false, expr = true, buffer = true },
      },
      -- Toggle check-boxes.
      ['<leader>ch'] = {
        action = function()
          return require('obsidian').util.toggle_checkbox()
        end,
        opts = { buffer = true },
      },
      -- Smart action depending on context, either follow link or toggle checkbox.
      ['<cr>'] = {
        action = function()
          return require('obsidian').util.smart_action()
        end,
        opts = { buffer = true, expr = true },
      },
    },
  },
  -- {
  --   'MeanderingProgrammer/render-markdown.nvim',
  --   dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' }, -- if you use the mini.nvim suite
  --   ---@module 'render-markdown'
  --   ---@type render.md.UserConfig
  --   opts = {
  --     bullet = { icons = { '*', '>', '>', '>' } },
  --     latex = { enabled = false },
  --   },
  -- },
}
