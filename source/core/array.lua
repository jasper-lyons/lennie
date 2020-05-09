require('relative_require')

local class = require('./class')

local Map = Map or require('./map')

local Array = class('Array', function ()
  function Array.from(object)
    if type(object) ~= 'table' then
      return error('Only tables can become Arrays', 2)
    end

    if object.class and object.class.new == Array.new then
      return object
    else
      return Array:new(object)
    end
  end

  function Array:initialize(t)
    self.table = t
    self:generateReverseIndex()
  end

  -- we don't use any array methods here as this method is called in
  -- :initialize(t) so calls will end up recursive.
  function Array:generateReverseIndex()
    -- allow removals from the array to be gc'd
    self.reverseIndex = Map:new({})
    for index, value in ipairs(self.table) do
      local indicies = self.reverseIndex:get(value) or {}
      table.insert(indicies, index)
      self.reverseIndex:set(value, indicies)
    end
  end

  function Array:indexOf(value)
    return self.reverseIndex:get(value)
  end

  function Array:get(index)
    return self.table[index]
  end

  function Array:push(value)
    table.insert(self.table, value)
    -- this could be less costly
    self:generateReverseIndex()
    return self
  end

  function Array:pop()
    local result = table.remove(self.table, 1)
    self:generateReverseIndex()
    return result
  end

  function Array:reduce(reducer, initial)
    local startIndex = 1
    
    if not initial then
      initial = self.table[1]
      startIndex = 2
    end

    for index = startIndex, #self.table do
      initial = reducer(initial, self.table[index], index)
    end

    return initial
  end


  function Array:map(transformer)
    return self:reduce(function (container, value)
      return container:push(transformer(value))
    end, Array:new({}))
  end

  function Array:filter(predicate)
    return self:reduce(function (container, value)
      return predicate(value) and container:push(value) or container
    end, Array:new({}))
  end

  function Array:join(separator)
    if #self == 0 then
      return ''
    elseif #self == 1 then
      return tostring(self.table[1])
    end

    return self:reduce(function (previous, value)
      return tostring(previous) .. separator .. tostring(value)
    end)
  end

  function Array:toMap()
    return self:reduce(function (container, kVPair)
      local key, value = table.unpack(kVPair)

      if key and value then
        return container:set(key, value)
      else
        return container
      end
    end, Map:new({}))
  end

  function Array:__add(other)
    return self:reduce(Array.push, other:reduce(Array.push, Array:new({})))
  end

  function Array:__sub(other)
    return self:filter(function (value) return not other:indexOf(value) end)
  end

  function Array:__eq(other)
    if #self.table ~= #other.table then
      return false
    end

    for _, value in ipairs(self.table) do
      if not other:indexOf(value) then
        return false
      end
    end

    for _, value in pairs(other.table) do
      if not self:indexOf(value) then
        return false
      end
    end

    return true
  end

  function Array:__len()
    return #self.table
  end

  function Array:__tostring()
    if self.table then
      return '[ ' .. self:join(', ') .. ' ]'
    else
      return '[]'
    end
  end
end)

return Array
