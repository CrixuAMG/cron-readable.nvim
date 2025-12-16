local M = {}

local ns = vim.api.nvim_create_namespace("cron_readable")

-- A cron field: starts with * or digit, OR is a 3-letter day/month name
local CRON_PATTERN_6 = "([%*%?%d][%S]*%s+[%*%?%d][%S]*%s+[%*%?%d][%S]*%s+[%*%?%d%a][%S]*%s+[%*%?%d%a][%S]*%s+[%*%?%d%a][%S]*)"
local CRON_PATTERN_5 = "([%*%?%d][%S]*%s+[%*%?%d][%S]*%s+[%*%?%d][%S]*%s+[%*%?%d%a][%S]*%s+[%*%?%d%a][%S]*)"

local DAYS = {
  ["0"]   = "Sunday",
  ["1"]   = "Monday",
  ["2"]   = "Tuesday",
  ["3"]   = "Wednesday",
  ["4"]   = "Thursday",
  ["5"]   = "Friday",
  ["6"]   = "Saturday",
  ["7"]   = "Sunday",
  ["SUN"] = "Sunday",
  ["MON"] = "Monday",
  ["TUE"] = "Tuesday",
  ["WED"] = "Wednesday",
  ["THU"] = "Thursday",
  ["FRI"] = "Friday",
  ["SAT"] = "Saturday",
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

local function is_wildcard(v)
  return v == "*" or v == "?"
end

local function humanize(cron)
  local sec, min, hour, dom, mon, dow

  -- Try 6-field cron first (with seconds)
  sec, min, hour, dom, mon, dow =
    cron:match("^(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)$")

  -- Fall back to 5-field cron (without seconds)
  if not sec then
    min, hour, dom, mon, dow =
      cron:match("^(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)$")
  end

  if not min then return nil end

  local h, m = tonumber(hour), tonumber(min)

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

  -- Every N hours
  local hour_step = hour:match("^%*/(%d+)$")
  if min == "0" and hour_step then
    return "Every " .. hour_step .. " hours"
  end

  -- Weekly (dom can be * or ?)
  if not is_wildcard(dow) and is_wildcard(dom) then
    local day = DAYS[dow:upper()]
    if day and h and m then
      return string.format("Every %s at %02d:%02d", day, h, m)
    end
  end

  -- Daily at time (dom, mon, dow can be * or ?)
  if is_wildcard(dom) and is_wildcard(mon) and is_wildcard(dow) then
    if h and m then
      return string.format("Every day at %02d:%02d", h, m)
    end
  end

  return nil
end

local function update(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i, line in ipairs(lines) do
    -- Try 6-field first, then 5-field
    local cron = line:match(CRON_PATTERN_6) or line:match(CRON_PATTERN_5)
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
