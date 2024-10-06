local hackernews = require("hackernews")

vim.api.nvim_create_user_command("HackerNews", function()
	hackernews.home()
end, { desc = "Browse Hacker News inside Neovim" })

vim.filetype.add({
  extension = {
    hackernews = "hackernews",
  },
})
