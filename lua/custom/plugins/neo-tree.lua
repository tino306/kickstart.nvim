return {
  {
    'nvim-neo-tree/neo-tree.nvim',
    lazy = true,
    keys = {
      {
        '<leader>tf',
        function()
          vim.cmd 'Neotree toggle'
          vim.cmd 'vertical resize 30'
        end,
        desc = 'Neotree toggle',
      },
      {
        '<tab>',
        function()
          local neo_tree_focused = vim.bo.filetype == 'neo-tree'
          if neo_tree_focused then
            vim.cmd 'wincmd p'
          else
            vim.cmd 'Neotree filesystem focus'
          end
        end,
      },
    },
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
      'MunifTanjim/nui.nvim',
    },
  },
}
