local curl = require("plenary.curl")

vim.api.nvim_create_user_command("HackerNews", function()
  vim.cmd("edit HackerNews")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {
    "┌───┐",
    "│ Y │ Hacker News (news.ycombinator.com)",
    "└───┘",
    "",
  })
  local r = curl.get("https://api.hackerwebapp.com/news")
  local items = vim.fn.json_decode(r.body)
  for i, item in ipairs(items) do
    if item.type == "link" then
      vim.api.nvim_buf_set_lines(0, -1, -1, false, {
        string.format("%2s. %s (%s) [%s]", i, item.title, item.domain, item.url),
        string.format("%3s %d points by %s %s | %d comments [%d]",
          "", item.points, item.user, item.time_ago, item.comments_count, item.id
        ),
        "",
      })
    elseif item.type == "job" then
      vim.api.nvim_buf_set_lines(0, -1, -1, false, {
        string.format("%2s. %s (%s) [%s]", i, item.title, item.domain, item.url),
        string.format("%3s %s [%d]", "", item.time_ago, item.id),
        "",
      })
    else
      vim.notify("Unknown HackerNews item type: " .. item.type)
    end
  end
end, {})

vim.api.nvim_create_augroup("HackerNews", { clear = true })

vim.api.nvim_create_autocmd("BufNewFile", {
  group = "HackerNews",
  pattern = "HackerNews",
  callback = function()
    vim.bo.filetype = "HackerNews"

    vim.api.nvim_set_hl(0, "HNTitle", { fg = "#ff6600", bold = true })
    vim.cmd.syntax([[match HNTitle /^┌.*$/]])
    vim.cmd.syntax([[match HNTitle /^│.*$/]])
    vim.cmd.syntax([[match HNTitle /^└.*$/]])

    local Normal = vim.api.nvim_get_hl(0, { name = "Normal" })
    ---@diagnostic disable-next-line: undefined-field
    vim.api.nvim_set_hl(0, "HNConceal", { ctermfg = Normal.ctermbg, fg = Normal.bg })
    vim.cmd.syntax([[match HNConceal /\s\[http.\+\]$/]])
    vim.cmd.syntax([[match HNConceal /\s\[[0-9]\{3,}\]$/]])

    vim.cmd.syntax([[match Comment /^\s*[0-9]\{1,2}\.\s/]])
    vim.cmd.syntax([[match Comment /\s(\S\+\.\S\+)/]])
    vim.cmd.syntax([[match Comment /^\s\{3}.*\(ago\|comments\)/]])
  end,
})
