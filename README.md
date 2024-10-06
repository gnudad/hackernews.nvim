# hackernews.nvim

Browse [Hacker News](https://news.ycombinator.com) inside Neovim.

## Installation
Using [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{ 
  "gnudad/hackernews.nvim",
  dependencies = "nvim-lua/plenary.nvim",
  cmd = "HackerNews", -- Lazy load
}
```

## Usage
- Open the Hacker News front page in Neovim by executing the `:HackerNews` command

## Thanks
* https://github.com/msva/lua-htmlparser
* https://github.com/nvim-lua/plenary.nvim
