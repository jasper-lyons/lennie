local Suspension = {}

function Suspension:new(fiber)
  local base = { fiber = fiber, waiting = true }
  setmetatable(base, self)
  self.__index = self
  return base
end

function Suspension:isWaiting()
  return self.waiting
end

function Suspension:complete(runner, wrap, ...)
  assert(self.waiting)
  self.waiting = false

  local args = table.pack(...)
  runner:schedule(function ()
    runner:resume(self.fiber, wrap, table.unpack(args))
  end)
end

return Suspension
