require('relative_require')

local Suspension = require('./suspension')

local Operation = {}

function Operation:new(implementations)
  local base = { implementations = implementations }
  setmetatable(base, self)
  self.__index = self
  return base
end

function Operation:perform(fiberRunner)
  for _, implementation in ipairs(self.implementations) do
    local success, value = implementation.try()
    if success then
      return implementation.wrap(value)
    end
  end

  local wrap, value = fiberRunner:suspend(function (fiber)
    local suspension = Suspension:new(fiber) 

    for _, implementation in ipairs(self.implementations) do
      implementation.block(suspension, implementation.wrap)
    end
  end)

  return wrap(value)
end

function Operation:wrap(wrapper)
  local wrapped = {}

  for _, implementation in ipairs(self.implementations) do
    table.insert(wrapped, Implementation:new(
    implementation.try,
    implementation.block,
    function (value)
      return wrapper(implementation.wrap(value))
    end
    ))
  end

  return Operation:new(wrapped)
end

return Operation
