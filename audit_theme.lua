-- audit_theme.lua
--
-- Usage (run from the plugin's repo root):
--   nvim --headless -c "lua dofile('audit_theme.lua')" -c "qa"
--
-- What it does:
--   1. Dumps every highlight group Neovim currently knows about (live groups —
--      run this AFTER opening real buffers / triggering LSP+completion+etc,
--      since plugins like blink.cmp only register their groups lazily).
--   2. Loads your ACTUAL engine.theme module (not a text/regex parse) to get
--      the real set of group names your theme defines.
--   3. Flags duplicate key definitions in theme.lua (second one silently wins).
--   4. Flags likely typo'd group names (defined, but not matching any live
--      or known name, within edit-distance 2).
--   5. For every genuinely missing group, generates a heuristic draft line
--      based on naming patterns already established in your file.
--
-- Output: writes theme.draft.lua in the current directory. Nothing is
-- auto-merged into theme.lua — review the draft and paste in what you want.

local plugin_root = vim.fn.getcwd()
vim.opt.runtimepath:append(plugin_root)

-- ---------- small helpers ----------

local function levenshtein(a, b)
  local la, lb = #a, #b
  local d = {}
  for i = 0, la do
    d[i] = { [0] = i }
  end
  for j = 0, lb do
    d[0][j] = j
  end
  for i = 1, la do
    for j = 1, lb do
      local cost = (a:sub(i, i) == b:sub(j, j)) and 0 or 1
      d[i][j] = math.min(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + cost)
    end
  end
  return d[la][lb]
end

-- ---------- 1. live highlight groups ----------

local function live_group_names()
  local groups = vim.api.nvim_get_hl(0, {})
  local names = {}
  for name, _ in pairs(groups) do
    table.insert(names, name)
  end
  return names
end

-- ---------- 2. actual defined groups, via require (not regex) ----------

local function defined_group_names()
  package.loaded['engine.theme'] = nil
  package.loaded['engine.colors'] = nil
  package.loaded['engine.config'] = nil

  local config = require('engine.config')
  local theme = require('engine.theme')
  local hi = theme.setup(config.schema)

  local names = {}
  for name, _ in pairs(hi.base) do
    table.insert(names, name)
  end
  for name, _ in pairs(hi.plugins) do
    table.insert(names, name)
  end
  return names
end

-- ---------- 3. duplicate key literals in the raw source ----------

local function find_duplicate_keys(path)
  local counts = {}
  for line in io.lines(path) do
    local bare = line:match('^%s*([%w_]+)%s*=%s*{')
    local bracketed = line:match("^%s*%[['\"]([%w_@%.]+)['\"]%]%s*=%s*{")
    local key = bare or bracketed
    if key then
      counts[key] = (counts[key] or 0) + 1
    end
  end
  local dupes = {}
  for k, c in pairs(counts) do
    if c > 1 then
      table.insert(dupes, string.format('%s (%dx)', k, c))
    end
  end
  table.sort(dupes)
  return dupes
end

-- ---------- 4. likely typos ----------

local function find_typos(defined, live)
  local live_set = {}
  for _, n in ipairs(live) do
    live_set[n] = true
  end

  local typos = {}
  for _, name in ipairs(defined) do
    if not live_set[name] then
      for _, live_name in ipairs(live) do
        if math.abs(#name - #live_name) <= 2 then
          local dist = levenshtein(name, live_name)
          if dist > 0 and dist <= 2 then
            table.insert(typos, string.format('%-40s looks like it should be %s (edit distance %d)', name, live_name, dist))
            break
          end
        end
      end
    end
  end
  table.sort(typos)
  return typos
end

-- ---------- 5. heuristic draft generator ----------
-- Order matters: first matching rule wins.

local RULES = {
  { pat = "Kind([%u][%w]*)$", tpl = function(n, cap)
    return string.format("%s = { link = 'CmpItemKind%s' }, -- guessed: matches existing CmpItemKind%s", n, cap, cap)
  end },
  { pat = 'Deprecated', tpl = function(n)
    return string.format('%s = { fg = c.fg_gutter, style = Styles.Strikethrough }, -- guessed: deprecated-style convention', n)
  end },
  { pat = 'Error', tpl = function(n)
    return string.format("%s = { link = 'DiagnosticError' }, -- guessed: name contains Error", n)
  end },
  { pat = 'Warn', tpl = function(n)
    return string.format("%s = { link = 'DiagnosticWarn' }, -- guessed: name contains Warn", n)
  end },
  { pat = 'Info', tpl = function(n)
    return string.format("%s = { link = 'DiagnosticInfo' }, -- guessed: name contains Info", n)
  end },
  { pat = 'Hint', tpl = function(n)
    return string.format("%s = { link = 'DiagnosticHint' }, -- guessed: name contains Hint", n)
  end },
  { pat = '[Mm]enu$', tpl = function(n)
    return string.format('%s = { fg = c.fg0, bg = c.bg1 }, -- guessed: popup menu, bg1 for float contrast', n)
  end },
  { pat = '[Dd]oc$', tpl = function(n)
    return string.format('%s = { fg = c.fg0, bg = c.bg1 }, -- guessed: doc/float popup', n)
  end },
  { pat = 'Border$', tpl = function(n)
    return string.format('%s = { fg = c.fg_gutter, bg = c.bg1 }, -- guessed: border convention', n)
  end },
  { pat = 'Separator$', tpl = function(n)
    return string.format('%s = { fg = c.fg_gutter }, -- guessed: separator convention', n)
  end },
}

local function guess_definition(name)
  for _, rule in ipairs(RULES) do
    local cap = name:match(rule.pat)
    if cap then
      return rule.tpl(name, cap)
    end
  end
  return string.format('%s = { fg = c.fg0 }, -- TODO: no rule matched, needs manual review', name)
end

-- ---------- run ----------

local live = live_group_names()
local defined = defined_group_names()

local defined_set = {}
for _, n in ipairs(defined) do
  defined_set[n] = true
end

local missing = {}
for _, n in ipairs(live) do
  if not defined_set[n] then
    table.insert(missing, n)
  end
end
table.sort(missing)

local dupes = find_duplicate_keys('lua/engine/theme.lua')
local typos = find_typos(defined, live)

local out = {}
table.insert(out, '-- theme audit report')
table.insert(out, string.format('-- live groups: %d, defined groups: %d, missing: %d', #live, #defined, #missing))
table.insert(out, '')
table.insert(out, '-- possible duplicate keys in theme.lua (2nd definition silently wins over 1st):')
for _, d in ipairs(dupes) do
  table.insert(out, '--   ' .. d)
end
table.insert(out, '')
table.insert(out, "-- possible typo'd group names (defined, but no live/known match):")
for _, t in ipairs(typos) do
  table.insert(out, '--   ' .. t)
end
table.insert(out, '')
table.insert(out, '-- draft definitions for genuinely missing groups (REVIEW BEFORE PASTING IN):')
for _, n in ipairs(missing) do
  table.insert(out, '    ' .. guess_definition(n))
end

vim.fn.writefile(out, 'theme.draft.lua')
print(string.format('wrote theme.draft.lua: %d missing, %d dupes, %d possible typos', #missing, #dupes, #typos))
