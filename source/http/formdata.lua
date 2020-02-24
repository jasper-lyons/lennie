require('relative_require')

require('../extension/string')

local formdata = {
  tostring = function (object)
    local container = {}

    for key, value in pairs(object) do
      table.insert(container, key .. '=' .. value)
    end

    return table.concat(container, '&')
  end,
  parse = function (string)
    local container = {}

    for _, pairString in pairs(string:split('&')) do
      local key, value = table.unpack(pairString:split('='))
      container[key] = value
    end

    return container
  end
}

return formdata
