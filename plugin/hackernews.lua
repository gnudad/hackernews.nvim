local curl = require("plenary.curl")
-- https://github.com/TiagoDanin/htmlEntities-for-lua
local htmlEntities = require('htmlEntities')

local function bprintf(s, ...)
  local data = s
  if arg ~= nil then
    data = string.format(s, ...)
  end
  local start = -1
  if vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == "" then
    -- Write to first line of empty buffer
    start = 0
  end
  vim.opt_local.modifiable = true
  vim.api.nvim_buf_set_lines(0, start, -1, false, { data })
  vim.opt_local.modifiable = false
end

vim.filetype.add({
  extension = {
    hackernews = "hackernews",
  },
})

local function open_home()
  vim.cmd("edit home.hackernews")
  vim.opt_local.wrap = false
  bprintf("┌───┐")
  bprintf("│ Y │ Hacker News (news.ycombinator.com)")
  bprintf("└───┘")
  bprintf("")
  local r = curl.get("https://api.hackerwebapp.com/news")
  local items = vim.fn.json_decode(r.body)
  for i, item in ipairs(items) do
    if item.type == "link" then
      bprintf("%2s. %s (%s) [%s]", i, item.title, item.domain, item.url)
      bprintf("    %d points by %s %s | %d comments [%d]",
              item.points, item.user, item.time_ago, item.comments_count, item.id)
      bprintf("")
    elseif item.type == "ask" then
      bprintf("%2s. %s [https://news.ycombinator.com/%s]", i, item.title, item.url)
      bprintf("    %d points by %s %s | %d comments [%d]",
              item.points, item.user, item.time_ago, item.comments_count, item.id)
      bprintf("")
    elseif item.type == "job" then
      bprintf("%2s. %s (%s) [%s]", i, item.title, item.domain, item.url)
      bprintf("    %s [%d]", item.time_ago, item.id)
      bprintf("")
    else
      vim.notify("Unknown HackerNews item type: " .. item.type)
    end
  end
end

local function render_comment(comment)
  local pad = string.rep(" ", 2 * comment.level)
  bprintf("%s%s %s", pad, comment.user, comment.time_ago)
  local content = comment.content:gsub("^<p>", ""):gsub("<p>", "\n \n")
  for s in content:gmatch("[^\n]+") do
    bprintf("%s%s", pad, htmlEntities.decode(s))
  end
  bprintf("")
  for _, child in ipairs(comment.comments) do
    render_comment(child)
  end
end

local function open_item(id)
  vim.cmd("edit " .. id .. ".hackernews")
  vim.opt_local.wrap = true
  vim.opt_local.breakindent = true
  local r = curl.get("https://api.hackerwebapp.com/item/" .. id)
  local item = vim.fn.json_decode(r.body)
  bprintf(item.title)
  bprintf("%d points by %s %s | %d comments",
          item.points, item.user, item.time_ago, item.comments_count)
  bprintf("")
  for _, comment in ipairs(item.comments) do
    render_comment(comment)
  end
end

vim.api.nvim_create_user_command("HackerNews", function(args)
  if #args == 0 then
    open_home()
  else
    open_item(args[1])
  end
end, { desc = "Browser Hacker News inside Neovim", nargs = "?" })

vim.api.nvim_create_augroup("HackerNews", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = "HackerNews",
  pattern = "hackernews",
  callback = function()
    vim.api.nvim_set_hl(0, "HNTitle", { fg = "#ff6600", bold = true })
    vim.cmd.syntax([[match HNTitle /^┌.*$/]])
    vim.cmd.syntax([[match HNTitle /^│.*$/]])
    vim.cmd.syntax([[match HNTitle /^└.*$/]])

    local Normal = vim.api.nvim_get_hl(0, { name = "Normal" })
    vim.api.nvim_set_hl(0, "HNConceal", { fg = Normal.bg })
    vim.cmd.syntax([[match HNConceal /\s\[http.\+\]$/]])
    vim.cmd.syntax([[match HNConceal /\s\[[0-9]\{3,}\]$/]])

    vim.api.nvim_set_hl(0, "HNComment", { link = "Comment" })
    vim.cmd.syntax([[match HNComment /[0-9]\+ points by .* \(ago\|comments\)/]])
    vim.cmd.syntax([[match HNComment /^\s*\w\+ [0-9an]\+ \w\+ ago$/]])


    local bufnr = vim.api.nvim_get_current_buf()

    -- Open link/item
    vim.keymap.set("n", "o", function()
      vim.cmd([[normal V"hy"]])
      local line = vim.fn.getreg("h")
      local link = string.match(line, "%[(.*)%]")
      if not link then
        vim.notify("No HackerNews link found on current line")
        return
      end
      if not string.match(link, "^[0-9]+$") then
        os.execute("open " .. link)
        return
      end
      open_item(link)
    end, { buffer = bufnr })

    -- Close hackernews buffer
    vim.keymap.set("n", "gq", [[<cmd>bwipeout!<cr>]], { buffer = bufnr})
  end,
})
