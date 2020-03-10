local Queue = {}

function Queue:new()
  local base = {}
  setmetatable(base, self)
  self.__index = self
  return base
end

function Queue:isEmpty()
  return #self == 0
end

function Queue:peek()
  return self[1]
end

function Queue:pop()
  return table.remove(self, 1)
end

function Queue:push(value)
  self[#self + 1] = value
end

function Queue:removeStale(predicate)
  local index = 1
  while index <= #self do
    if predicate(self[index]) then
      table.remove(self, index)
    else
      index = index + 1
    end
  end
end

return Queue
