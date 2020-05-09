require('relative_require')

local class = require('./class')

-- avoid circular require by using a place holder and lazily requireing
local Array = nil

function id(object)
  if type(object) == 'table' then
    local metatable = getmetatable(object)
    if metatable then
      local __id = rawget(metatable, '__id')
      if __id then
        return __id(object)
      end
    end
  end

  return object
end

-- # The Algebra of Maps
-- I see no reason that the Map type couldn't have a set of operations
-- defined for it similar to Tuples in relational algebra but adjusted
-- to make sense for the usecase of maps. The main reason for this is 
-- for me to a justification for the api I provide for a map object, not
-- only driven by usage but by a coherent interpretation of the object
--
-- We can look at what is required from a Map to create the set of
-- operations taht define our algrbra-liek structure! (FYI, I'm just
-- reading wikipedia about Albegras right now so my terminology will
-- be WAY off, but I will learn :) ).
--
-- Map.new(Table<k=v> T)
--    { Map<k=v> | k=v in T }
--
-- Map.union(Map<a=b> A, Map<c=d> B, Function(k, a ,b) resolve)
--    { Map<k=v> |
--      k=v in A and k not in B:keys()
--      or
--      k=v in B and k not in A:key()
--      or
--      k=v in { resolve(k, c, d) | k=c in A, k=d in B } }
--
-- Map.difference
--
-- Map.intersection
--
local Map = class('Map', function ()
  function Map:initialize(table)
    self.table = {}

    for key, value in pairs(table) do
      self:set(key, value)
    end
  end

  function Map:set(key, value)
    if id(key) == nil then
      error('Potential key '..tostring(key)..' should have an id that isn\'t nil', 2)
    end

    self.table[id(key)] =  { key, value }
    return self
  end

  function Map:get(key)
    local keyValuePair = self.table[id(key)]
    if keyValuePair then
      return keyValuePair[2]
    end
  end

  function Map:toArray()
    local container = {}
    for _, keyValuePair in pairs(self.table) do
      table.insert(container, keyValuePair)
    end
    -- lazily require to avoid circular require
    Array = Array or require('./array')
    return Array:new(container)
  end

  function Map:map(transformer)
    return self:toArray():map(function (kVPair, index)
      local key, value = table.unpack(kVPair)
      return transformer(key, value, index)
    end):toMap()
  end

  function Map:filter(predicate)
    return self:toArray():filter(function (kVPair, index)
      local key, value = table.unpack(kVPair)
      return predicate(key, value, index)
    end):toMap()
  end

  -- Map.union(Map<a=b> A, Map<c=d> B, Function(k, a ,b) resolve)
  --    { Map<k=v> |
  --      k=v in A and k not in B:keys()
  --      or
  --      k=v in B and k not in A:key()
  --      or
  --      k=v in { resolve(k, c, d) | k=c in A, k=d in B } }
  function Map:union(other, resolve)
    resolve = resolve or function (key, selfValue, otherValue) return selfValue end

    return (self:keys() + other:keys()):reduce(function (container, key)
      local selfValue, otherValue = self:get(key), other:get(key)
      if selfValue and otherValue then
        return container:set(key, resolve(key, selfValue, otherValue))
      else
        return container:set(key, selfValue or otherValue)
      end
    end, Map:new({}))
  end
  -- Map.merge = Map.union
  Map.merge = Map.union

  function Map:ids()
    local ids = {}
    for id, _ in pairs(self.table) do
      table.insert(ids, id)
    end
    -- lazily require to avoid circular require
    Array = Array or require('./array')
    return Array:new(ids)
  end

  function Map:keys()
    local keys = {}
    for hash, keyValuePair in pairs(self.table) do
      table.insert(keys, keyValuePair[1])
    end
    -- lazily require to avoid circular require
    Array = Array or require('./array')
    return Array:new(keys)
  end

  function Map:values()
    local values = {}
    for hash, keyValuePair in pairs(self.table) do
      table.insert(values, keyValuePair[2])
    end
    -- lazily require to avoid circular require
    Array = Array or require('./array')
    return Array:new(values)
  end

  function Map:__eq(other)
    if self:ids() ~= other:ids() then
      return false
    end
    return true
  end

  function Map:__tostring()
    if #self:ids() == 0 then
      return '{ }'
    else
      return '{ ' .. self:toArray():map(function (kVPair)
        return tostring(kVPair[1]) .. '=' .. tostring(kVPair[2])
      end):join(', ') .. ' }'
    end
  end

  function Map:__id()
    return self.table
  end
end)

return Map
