# cron-readable.nvim

A Neovim plugin that displays human-readable descriptions of cron expressions as virtual text.

## Features

- Automatically detects cron expressions in YAML files
- Shows human-readable descriptions as virtual text at the end of lines
- Supports common cron patterns:
  - Every minute/N minutes
  - Hourly schedules
  - Daily schedules with specific times
  - Weekly schedules with day-of-week
- Updates in real-time as you edit

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "crixuamg/cron-readable.nvim",
  config = function()
    require("cron-readable").setup()
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "crixuamg/cron-readable.nvim",
  config = function()
    require("cron-readable").setup()
  end,
}
```

## Configuration

```lua
require("cron-readable").setup({
  pattern = { "*.yaml", "*.yml" }, -- File patterns to match
  filename = nil, -- Optional: specific filename to match
})
```

### Options

- `pattern` (table): File patterns where the plugin should be active (default: `{ "*.yaml", "*.yml" }`)
- `filename` (string, optional): Specific filename to match. If set, only files with this exact name will show cron descriptions

## Usage

The plugin automatically activates when you open YAML files. Cron expressions will show human-readable descriptions as virtual text:

```yaml
# Example crontab entries
schedule:
  backup: "0 2 * * *"     # 󰣞 Every day at 02:00
  cleanup: "*/15 * * * *"  # 󰣞 every 15 minutes
  weekly: "0 9 * * 1"     # 󰣞 Every Monday at 09:00
```

## Supported Cron Patterns

- `* * * * *` - Every minute
- `*/N * * * *` - Every N minutes
- `0 * * * *` - Every hour
- `M H * * *` - Every day at H:M
- `M H * * D` - Every weekday D at H:M

## Requirements

- Neovim 0.7+

## License

MIT
