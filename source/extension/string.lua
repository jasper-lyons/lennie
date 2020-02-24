function string.split(self, delimiter)
  local array = {}

  for part in (self .. delimiter):gmatch('([^'..delimiter..']*)'..delimiter) do
    table.insert(array, part)
  end

  return array
end
