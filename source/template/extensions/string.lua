local require_relative = require('source/template/require_relative')
local StringScanner = require_relative('string_scanner')

function string.split(str, delimiter)
  parser = StringScanner:new(str)

  local array = {}
  while parser:find(delimiter) do
    local before, match, line = parser:scan(delimiter)
    table.insert(array, { before, line })
  end

  if not parser:finished() then
    local before, match, line = parser:scan('.*')
    table.insert(array, { match, line })
  end

  return array
end
