# hackernews.nvim

Browse [Hacker News](https://news.ycombinator.com) inside Neovim.

## Installation
Using [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{ 
  "gnudad/hackernews.nvim",
  dependencies = "nvim-lua/plenary.nvim",
  cmd = "HackerNews",
  keys = { { "<leader>h", [[<cmd>HackerNews<cr>]] } },
}
```

## Usage
- Open the Hacker News front page in Neovim by executing the `:HackerNews` command
