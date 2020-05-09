local Template = require('lennie.template')
require('lennie.extension.string')

require('relative_require')
local class = require('./class')

local separator = package.config:sub(1, 1)

local function cammelToSnake(cammelString)
  return cammelString:gsub('([A-Za-z]?)(%u)', function (pre, capital)
    if pre == '' then
      return string.lower(capital)
    else
      return pre .. '_' .. string.lower(capital)
    end
  end)
end

local function classToFile(classString)
  classString = classString:gsub('%.', separator)
  return cammelToSnake(classString)
end

return class('View', function ()
  function View:getTemplate()
    local viewDirectory = self.class.viewDirectory or '.'
    self.template = self.template
      or Template:new(viewDirectory .. separator ..
                      classToFile(tostring(self.class)) .. '.html.elua')
    return self.template
  end

  function View:__tostring()
    local template = self:getTemplate()
    return template:render(self)
  end
end)
