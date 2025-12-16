#!/usr/bin/env lua
-- Simple test runner for cron-readable plugin
-- Run with: lua tests/run_tests.lua

package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua'

_G.vim = {
  api = {
    nvim_create_namespace = function(_) return 1 end,
    nvim_buf_clear_namespace = function(_, _, _, _) end,
    nvim_buf_get_lines = function(_, _, _, _) return {} end,
    nvim_buf_set_extmark = function(_, _, _, _, _) end,
    nvim_create_autocmd = function(_, _) end,
  },
  fn = {
    expand = function(_) return "" end,
  },
}

local cron_readable = require("cron-readable")
local internals = cron_readable._internals

local passed = 0
local failed = 0

local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    print("✓ " .. name)
    passed = passed + 1
  else
    print("✗ " .. name)
    print("  " .. tostring(err))
    failed = failed + 1
  end
end

local function eq(expected, actual)
  if expected ~= actual then
    error(string.format("Expected '%s' but got '%s'", tostring(expected), tostring(actual)))
  end
end

print("=== Humanize Tests ===\n")

-- 6-field cron expressions (with seconds)
test("daily at 07:00 (6-field)", function()
  eq("Every day at 07:00", internals.humanize("0 0 7 * * *"))
end)

test("daily at 08:00 (6-field)", function()
  eq("Every day at 08:00", internals.humanize("0 0 8 * * *"))
end)

test("daily at 00:00 (6-field)", function()
  eq("Every day at 00:00", internals.humanize("0 0 0 * * *"))
end)

test("hourly (6-field)", function()
  eq("Every hour", internals.humanize("0 0 * * * *"))
end)

test("every 10 minutes (6-field)", function()
  eq("every 10 minutes", internals.humanize("0 */10 * * * *"))
end)

test("every 3 hours (6-field)", function()
  eq("Every 3 hours", internals.humanize("0 0 */3 * * *"))
end)

test("weekly Sunday with name (6-field)", function()
  eq("Every Sunday at 00:00", internals.humanize("0 0 0 ? * SUN"))
end)

test("weekly Monday with name (6-field)", function()
  eq("Every Monday at 09:00", internals.humanize("0 0 9 ? * MON"))
end)

test("weekly Sunday with number (6-field)", function()
  eq("Every Sunday at 00:00", internals.humanize("0 0 0 ? * 0"))
end)

-- 5-field cron expressions (without seconds)
test("daily at 07:00 (5-field)", function()
  eq("Every day at 07:00", internals.humanize("0 7 * * *"))
end)

test("hourly (5-field)", function()
  eq("Every hour", internals.humanize("0 * * * *"))
end)

test("every 5 minutes (5-field)", function()
  eq("every 5 minutes", internals.humanize("*/5 * * * *"))
end)

test("every minute (5-field)", function()
  eq("Every minute", internals.humanize("* * * * *"))
end)

test("weekly Sunday (5-field)", function()
  eq("Every Sunday at 00:00", internals.humanize("0 0 * * 0"))
end)

print("\n=== Pattern Matching Tests ===\n")

local function match_cron(line)
  return line:match(internals.CRON_PATTERN_6) or line:match(internals.CRON_PATTERN_5)
end

test("match cron in YAML line (6-field)", function()
  eq("0 0 7 * * *", match_cron("        schedule: 0 0 7 * * *"))
end)

test("match cron with ? (6-field)", function()
  eq("0 0 0 ? * SUN", match_cron("        schedule: 0 0 0 ? * SUN"))
end)

test("match cron with step (6-field)", function()
  eq("0 */10 * * * *", match_cron("        schedule: 0 */10 * * * *"))
end)

test("should not match name line", function()
  eq(nil, match_cron("        name: artemis-brand-module"))
end)

test("should not match executor line", function()
  eq(nil, match_cron("        executor: shell"))
end)

print("\n=== is_wildcard Tests ===\n")

test("* is wildcard", function()
  eq(true, internals.is_wildcard("*"))
end)

test("? is wildcard", function()
  eq(true, internals.is_wildcard("?"))
end)

test("0 is not wildcard", function()
  eq(false, internals.is_wildcard("0"))
end)

test("SUN is not wildcard", function()
  eq(false, internals.is_wildcard("SUN"))
end)

print(string.format("\n=== Results: %d passed, %d failed ===", passed, failed))

os.exit(failed > 0 and 1 or 0)
