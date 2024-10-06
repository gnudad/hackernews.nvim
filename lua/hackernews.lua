local curl = require("plenary.curl")
local htmlparser = require("htmlparser")

local M = {}

function M.home()
  vim.cmd("edit home.hackernews")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {
    "┌───┐",
    "│ Y │ Hacker News (news.ycombinator.com)",
    "└───┘",
    "",
  })
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
      comments = tr("a[href*='item']")
      if next(comments) ~= nil then comments = comments[1]:getcontent() end
      local subline = string.format(
        "%3s %s by %s %s | %s [%s]",
        "", points, user, age, comments, item_id
      )
      if #points == 0 then subline = string.format("%3s %s", "", age) end
      vim.api.nvim_buf_set_lines(0, -1, -1, false, {
        string.format("%2s. %s (%s) [%s]", i, title, domain, url),
        subline, "",
      })
      athing = false
    else
      athing = false
    end
  end
end

return M
