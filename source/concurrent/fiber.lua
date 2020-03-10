local Fiber = {}

function Fiber:new(runner, coroutine)
  local base = { runner = runner, coroutine = coroutine }
  setmetatable(base, self)
  self.__index = self
  return base
end

return Fiber

