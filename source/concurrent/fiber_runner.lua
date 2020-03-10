require('relative_require')

local Fiber = require('./fiber')

local FiberRunner = {}

function FiberRunner:new()
  local base = { current = nil, queue = {} }
  setmetatable(base, self)
  self.__index = self
  return base
end

function FiberRunner:schedule(task)
  table.insert(self.queue, task)
end

function FiberRunner:run()
  local queue = self.queue
  self.queue = {}
  for _, task in ipairs(queue) do
    task()
  end
end

function FiberRunner:spawn(func, ...)
  local args = table.pack(...)
  local fiber = Fiber:new(self, coroutine.create(function ()
    local status, message = xpcall(func, debug.traceback, table.unpack(args))

    if not status then
      print('Error running fiber: ' .. debug.traceback(message))
    end

    return status, message
  end))

  self:schedule(function ()
    self:resume(fiber)
  end)

  return fiber
end

function FiberRunner:resume(fiber, ...)
  self.current = fiber
  local ok, err = coroutine.resume(fiber.coroutine, ...)
  self.current = nil
end

function FiberRunner:suspend(reschedule)
  reschedule(self.current)
  return coroutine.yield()
end

function FiberRunner:yield()
  return self:suspend(function (fiber)
    self:schedule(function ()
      self:resume(fiber)
    end)
  end)
end

return FiberRunner
