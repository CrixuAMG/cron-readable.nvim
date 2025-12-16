local M = {}

local ns = vim.api.nvim_create_namespace("cron_readable")

-- match 5-field cron
local CRON_PATTERN = "(%S+%s+%S+%s+%S+%s+%S+%s+%S+)"

local DAYS = {
  ["0"] = "Sunday",
  ["1"] = "Monday",
  ["2"] = "Tuesday",
  ["3"] = "Wednesday",
  ["4"] = "Thursday",
  ["5"] = "Friday",
  ["6"] = "Saturday",
  ["7"] = "Sunday",
}

local function field_desc(value, unit)
  if value == "*" then
    return "every " .. unit
  end

  local step = value:match("^%*/(%d+)$")
  if step then
    return "every " .. step .. " " .. unit .. "s"
  end

  if value:match("^%d+$") then
    return "at " .. value
  end

  return nil
end

local function humanize(cron)
  local min, hour, dom, mon, dow =
    cron:match("^(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)$")

  if not min then return nil end

  -- Every minute
  if min == "*" and hour == "*" then
    return "Every minute"
  end

  -- Every N minutes
  if min:match("^%*/%d+$") and hour == "*" then
    return field_desc(min, "minute")
  end

  -- Hourly
  if min == "0" and hour == "*" then
    return "Every hour"
  end

  -- Daily at time
  if dom == "*" and mon == "*" and dow == "*" then
    return string.format("Every day at %02d:%02d", tonumber(hour), tonumber(min))
  end

  -- Weekly
  if dow ~= "*" and dom == "*" then
    local day = DAYS[dow]
    if day then
      return string.format(
        "Every %s at %02d:%02d",
        day,
        tonumber(hour),
        tonumber(min)
      )
    end
  end

  return nil
end

local function update(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i, line in ipairs(lines) do
    local cron = line:match(CRON_PATTERN)
    if cron then
      local text = humanize(cron)
      if text then
        vim.api.nvim_buf_set_extmark(bufnr, ns, i - 1, 0, {
          virt_text = { { "󰣞 " .. text, "Comment" } },
          virt_text_pos = "eol",
        })
      end
    end
  end
end

function M.setup(opts)
  opts = opts or {}
  local pattern = opts.pattern or { "*.yaml", "*.yml" }
  local filename = opts.filename -- optional

  vim.api.nvim_create_autocmd(
    { "BufEnter", "BufWritePost", "TextChanged" },
    {
      pattern = pattern,
      callback = function(args)
        if filename and vim.fn.expand("%:t") ~= filename then
          return
        end
        update(args.buf)
      end,
    }
  )
end

return M
