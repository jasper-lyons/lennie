local Implementation = {}

function Implementation:new(try, block, wrap)
  local base = { try=try, block=block, wrap=wrap }
  setmetatable(base, self)
  self.__index = self
  return base
end

return Implementation
