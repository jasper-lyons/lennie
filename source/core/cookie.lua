require('relative_require')

local class = require('./class')

return class('Cookie', function (Cookie)
  function Cookie:initialize(base)
    self.name = assert(base.name)
    self.value = assert(base.value)
  end

  function Cookie:__tostring()
    -- TODO: COokies have other attributes!
    return self.name .. '=' .. self.value
  end

  function Cookie:__eq(other)
    return self.name == other.name and self.value == other.value
  end
end)
