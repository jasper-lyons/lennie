-- This is an object that encapsulates the state of a string scanner. It
-- allows a users to:
-- * scan(pattern) -> before, match, line
--    pattern -> a valid lua pattern.
--    before -> the text between the end of the last scan and the text that
--              matches the pattern.
--    match -> the text that matches the scan.
--    line -> the number of new lines between the begining of the string and
--            the current match.
local StringScanner = {}

function StringScanner:new(content)
  base = { content=content, position=1, line=1 }
  setmetatable(base, self)
  self.__index = self
  return base
end

function StringScanner:position()
  return self.position
end

-- finished() -> finished
--    finished -> a boolean indicating that the current position of the
--                scanner is at the end of the string.
function StringScanner:finished()
  return self.position > self.content:len()
end

function StringScanner:find(pattern)
  local begin, finish = string.find(self.content, pattern, self.position)

  if begin then
    return true
  else
    return false
  end
end

-- scan(pattern) -> before, match, line
--    pattern -> a valid lua pattern.
--    before -> the text between the end of the last scan and the text that
--              matches the pattern.
--    match -> the text that matches the scan.
--    line -> the number of new lines between the begining of the string and
--            the current match.
function StringScanner:scan(pattern)
  local begin, finish = string.find(self.content, pattern, self.position)

  if begin then
    for new_line in string.gmatch(self.content:sub(self.position, finish - 1), "\n") do
      self.line = self.line + 1 
    end

    local before = self.content:sub(self.position, begin - 1)
    self.position = begin

    local match = self.content:sub(self.position, finish)
    self.position = finish + 1

    return before, match, self.line
  else
    return nil, nil, nil
  end
end

return StringScanner
