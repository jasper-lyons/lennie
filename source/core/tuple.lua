require('relative_require')

local class = require('./class')
local Map = require('./map')

return class('Tuple', Map, function (Tuple)
  function Tuple:project(attributes)
    return as(self:filter(function (k, v)
      return attributes:indexOf(k)
      -- shadowing the Tuple class here with Tuple.methods!
    end), self.class)
  end

  function Tuple:__id()
    return self:toArray():map(function (kVPair)
      local key, value = table.unpack(kVPair)
      return tostring(id(key)) .. tostring(id(value))
    end):join('')
  end

  function Tuple:__tostring()
    return '<Tuple ' .. self:toArray():map(function (kVPair)
      local key, value = table.unpack(kVPair)
      return tostring(key) .. '=' .. tostring(value)
    end):join(', ') .. '>'
  end
end)
