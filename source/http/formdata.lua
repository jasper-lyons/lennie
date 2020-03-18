require('relative_require')

require('../extension/string')
local PercentEncoding = require('./percent_encoding')

local formdata = {
  tostring = function (object)
    local container = {}

    for key, value in pairs(object) do
      table.insert(container, PercentEncoding.encode(key) .. '=' .. PercentEncoding.encode(value))
    end

    return table.concat(container, '&')
  end,

  parse = function (string)
    local container = {}

    for _, pairString in pairs(string:split('&')) do
      local key, value = table.unpack(pairString:split('='))
      container[PercentEncoding.decode(key)] = PercentEncoding.decode(value)
    end

    return container
  end
}

return formdata
