local curl = require("plenary.curl")
local decode = require("htmlEntities").decode
local htmlparser = require("htmlparser")

local M = {}

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
  data = decode(data)
  if data then
    vim.api.nvim_buf_set_lines(0, start, -1, false, { data })
  end
end

function M.home()
  vim.cmd("edit home.hackernews")
  vim.opt_local.wrap = false
  bprintf("┌───┐")
  bprintf("│ Y │ Hacker News (news.ycombinator.com)")
  bprintf("└───┘")
  local r = curl.get("https://news.ycombinator.com")
  local root = htmlparser.parse(r.body)
  local item_id, title, url, domain, points, user, age, comments
  local athing = false
  local i = 0
  for _, tr in ipairs(root("table table tr")) do
    if tr.classes[1] == "athing" then
      item_id = tr.id
      title = tr("span.titleline > a")[1]:getcontent()
      url = tr("span.titleline > a")[1].attributes['href']
      domain = url:match("://([^/]+)")
      athing = true
      i = i + 1
    elseif next(tr.classes) == nil and athing then
      points = tr("span.score")
      if #points > 0 then points = points[1]:getcontent() end
      user = tr("a.hnuser")
      if next(user) ~= nil then user = user[1]:getcontent() end
      age = tr("span.age > a")[1]:getcontent()
      comments = tr("span.subline > a[href*='item']")
      if next(comments) ~= nil then comments = comments[1]:getcontent() end
      local subline = string.format(
        "%3s %s by %s %s | %s [%s]",
        "", points, user, age, comments, item_id
      )
      if #points == 0 then subline = string.format("%3s %s", "", age) end
      bprintf("%2s. %s (%s) [%s]", i, title, domain, url)
      bprintf(subline)
      bprintf("")
      athing = false
    else
      athing = false
    end
  end
  vim.bo.modifiable = false
  vim.bo.buftype = "nofile"
end

function M.item(item_id)
  vim.cmd("edit " .. item_id .. ".hackernews")
  vim.opt_local.wrap = true
  vim.opt_local.breakindent = true
  local r = curl.get("https://news.ycombinator.com/item?id=" .. item_id)
  local root = htmlparser.parse(r.body, 100000)
  local title = root("span.titleline > a")[1]:getcontent()
  local url = root("span.titleline > a")[1].attributes["href"]
  local domain = url:match("://([^/]+)")
  local points = root("span.score")[1]:getcontent()
  local user = root("span.subline > a.hnuser")[1]:getcontent()
  local age = root("span.age > a")[1]:getcontent()
  local comments = root("span.subline > a[href^='item']")[1]:getcontent()
  bprintf("%s (%s) [%s]", title, domain, url)
  bprintf(
    "%s by %s %s | %s [https://news.ycombinator.com/item?id=%s]",
    points, user, age, comments, item_id
  )
  bprintf("")

  for _, tr in ipairs(root("table.comment-tree tr.comtr")) do
    local indent = string.rep(" ", 2 * tonumber(tr("td.ind")[1].attributes["indent"]))
    item_id = tr.id
    user = tr("a.hnuser")[1]:getcontent()
    age = tr("span.age > a")[1]:getcontent()
    local comment = tr("div.commtext")
    if next(comment) ~= nil then
      comment = comment[1]:getcontent()
      bprintf("%s%s %s [%s]", indent, user, age, item_id)
      for line in comment:gmatch("[^\r\n]+") do
        bprintf("%s%s", indent, line)
      end
      bprintf("")
    end
  end

  vim.bo.modifiable = false
  vim.bo.buftype = "nofile"
end

local function open(external)
  if external == nil then external = false end
  vim.cmd([[normal V"hy"]])
  local line = vim.fn.getreg("h")
  local link = string.match(line, "%[(.*)%]")
  if not link then
    vim.noify("No HackerNews Link found on current line.")
    return
  end
  if not string.match(link, "^[0-9]+$") then
    os.execute("open " .. link)
    return
  end
  if external then
    os.execute("open https://news.ycombinator.com/item?id=" .. link)
    return
  end
  M.item(link)
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "hackernews",
  callback = function()
    vim.keymap.set("n", "o", open, { buffer = true })
    vim.keymap.set("n", "O", function() open(true) end, { buffer = true })
  end,
})

return M
