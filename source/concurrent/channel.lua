require('relative_require')

local Queue = require('./queue')
local Operation = require('./operation')
local Implementation = require('./implementation')

local Channel = {}

function Channel:new(fiberRunner)
  local base = { fiberRunner = fiberRunner, getQueue = Queue:new(), putQueue = Queue:new() } 
  setmetatable(base, self)
  self.__index = self
  return base
end

function Channel:putFactory(value)
  return Operation:new({
    Implementation:new(
    function ()
      self.getQueue:removeStale(function (entry)
        return not entry.suspension:isWaiting()
      end)

      if self.getQueue:isEmpty() then
        return false, nil
      else
        local remote = self.getQueue:pop()
        remote.suspension:complete(self.fiberRunner, remote.wrap, value)
        return true, nil
      end
    end,
    function (suspension, wrap)
      self.putQueue:removeStale(function (entry)
        return not entry.suspension:isWaiting()
      end)

      self.putQueue:push({
        suspension = suspension,
        wrap = wrap,
        value = value
      })
    end,
    callback or function (value)
      return value
    end
    )
  })
end

function Channel:getFactory(args)
  return Operation:new({
    Implementation:new(
    function ()
      self.putQueue:removeStale(function (entry)
        return not entry.suspension:isWaiting()
      end)

      if self.putQueue:isEmpty() then
        return false, nil
      else
        local remote = self.putQueue:pop()
        remote.suspension:complete(self.fiberRunner, remote.wrap, table.unpack(args or {}))
        return true, remote.value
      end
    end,
    function (suspension, wrap)
      self.getQueue:removeStale(function (entry)
        return not entry.suspension:waiting()
      end)

      self.getQueue:push({
        suspension = suspension,
        wrap = wrap
      })
    end,
    function (value)
      return value
    end
    )
  })
end

function Channel:put(args)
  return self:putFactory(args):perform(self.fiberRunner)
end

function Channel:get()
  return self:getFactory():perform(self.fiberRunner)
end

return Channel
