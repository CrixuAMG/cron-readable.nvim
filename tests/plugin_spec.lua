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

local busted = require("busted")
local cron_readable = require("cron-readable")
local internals = cron_readable._internals

busted.describe("Cron Readable Plugin", function()
  busted.describe("humanize", function()
    -- 6-field cron expressions (with seconds)
    busted.it("should parse daily at specific time (6-field)", function()
      assert.are.equal("Every day at 07:00", internals.humanize("0 0 7 * * *"))
      assert.are.equal("Every day at 08:00", internals.humanize("0 0 8 * * *"))
      assert.are.equal("Every day at 00:00", internals.humanize("0 0 0 * * *"))
    end)

    busted.it("should parse hourly (6-field)", function()
      assert.are.equal("Every hour", internals.humanize("0 0 * * * *"))
    end)

    busted.it("should parse every N minutes (6-field)", function()
      assert.are.equal("every 10 minutes", internals.humanize("0 */10 * * * *"))
      assert.are.equal("every 5 minutes", internals.humanize("0 */5 * * * *"))
    end)

    busted.it("should parse every N hours (6-field)", function()
      assert.are.equal("Every 3 hours", internals.humanize("0 0 */3 * * *"))
      assert.are.equal("Every 6 hours", internals.humanize("0 0 */6 * * *"))
    end)

    busted.it("should parse weekly with day name (6-field)", function()
      assert.are.equal("Every Sunday at 00:00", internals.humanize("0 0 0 ? * SUN"))
      assert.are.equal("Every Monday at 09:00", internals.humanize("0 0 9 ? * MON"))
    end)

    busted.it("should parse weekly with day number (6-field)", function()
      assert.are.equal("Every Sunday at 00:00", internals.humanize("0 0 0 ? * 0"))
      assert.are.equal("Every Monday at 09:00", internals.humanize("0 0 9 ? * 1"))
    end)

    -- 5-field cron expressions (without seconds)
    busted.it("should parse daily at specific time (5-field)", function()
      assert.are.equal("Every day at 07:00", internals.humanize("0 7 * * *"))
      assert.are.equal("Every day at 08:00", internals.humanize("0 8 * * *"))
    end)

    busted.it("should parse hourly (5-field)", function()
      assert.are.equal("Every hour", internals.humanize("0 * * * *"))
    end)

    busted.it("should parse every N minutes (5-field)", function()
      assert.are.equal("every 5 minutes", internals.humanize("*/5 * * * *"))
    end)

    busted.it("should parse every minute (5-field)", function()
      assert.are.equal("Every minute", internals.humanize("* * * * *"))
    end)

    busted.it("should parse weekly with day number (5-field)", function()
      assert.are.equal("Every Sunday at 00:00", internals.humanize("0 0 * * 0"))
    end)
  end)

  busted.describe("pattern matching", function()
    local function match_cron(line)
      return line:match(internals.CRON_PATTERN_6) or line:match(internals.CRON_PATTERN_5)
    end

    busted.it("should match cron in YAML schedule line", function()
      assert.are.equal("0 0 7 * * *", match_cron("        schedule: 0 0 7 * * *"))
      assert.are.equal("0 0 0 ? * SUN", match_cron("        schedule: 0 0 0 ? * SUN"))
      assert.are.equal("0 */10 * * * *", match_cron("        schedule: 0 */10 * * * *"))
    end)

    busted.it("should not match non-cron lines", function()
      assert.is_nil(match_cron("        name: artemis-brand-module"))
      assert.is_nil(match_cron("        executor: shell"))
    end)
  end)

  busted.describe("is_wildcard", function()
    busted.it("should return true for * and ?", function()
      assert.is_true(internals.is_wildcard("*"))
      assert.is_true(internals.is_wildcard("?"))
    end)

    busted.it("should return false for other values", function()
      assert.is_false(internals.is_wildcard("0"))
      assert.is_false(internals.is_wildcard("SUN"))
    end)
  end)
end)
