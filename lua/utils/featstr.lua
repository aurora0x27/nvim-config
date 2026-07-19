--------------------------------------------------------------------------------
--- Feature String (FeatStr) DSL
---
--- FeatStr is a tiny declarative language used to enable or disable named
--- features. It is primarily intended for command-line flags and configuration
--- overrides.
---
--- Grammar:
---
---     featstr := item ("," item)*
---
---     item :=
---         NAME        -- enable feature
---       | "+" NAME    -- explicitly enable feature
---       | "-" NAME    -- disable feature
---       | "full"      -- initialize with schema defaults
---       | "none"      -- initialize with inverted schema defaults
---
--- Example:
---
---     lsp,ts,-plg
---     none,+lsp,+ts
---     full,-fmt,-plg
---
--- Result:
---
---     parse() returns a feature mask:
---
---         {
---             lsp = true,
---             fmt = false,
---             ts = false,
---             plg = false,
---         }
--------------------------------------------------------------------------------
local M = {}

--- Feat string parser
---
--- String: `+foo,-bar,baz` means enable foo,baz and disable bar
--- keyword `full` means use full default options, `none` means
--- use the *not* of default options.
---
---@param feat_s string feat string
---@param defaults table<string, boolean> schema table
---@param on_error? fun(msg: string)
---@return table masked result
function M.parse(feat_s, defaults, on_error)
  local mask = {}
  on_error = on_error or function(_) end
  for feat_item in string.gmatch(feat_s, '([^,]+)') do
    feat_item = vim.trim(feat_item)
    local first_char = feat_item:sub(1, 1)
    if feat_item == 'full' then
      for k, v in pairs(defaults) do
        mask[k] = v
      end
    elseif feat_item == 'none' then
      for k, v in pairs(defaults) do
        mask[k] = not v
      end
    else
      local feat_name = (first_char == '+' or first_char == '-')
          and feat_item:sub(2)
        or feat_item
      if type(defaults[feat_name]) == 'nil' then
        on_error(string.format('Unknown feature: %s', feat_name))
      else
        if first_char == '+' then
          mask[feat_name] = true
        elseif first_char == '-' then
          mask[feat_name] = false
        else
          mask[feat_name] = true
        end
      end
    end
  end
  return mask
end

return M
