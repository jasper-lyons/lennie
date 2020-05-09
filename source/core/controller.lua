require('relative_require')

local class = require('./class')

return class('Controller', function (methods, class)

  function class:getHandlerFor(...)
    local args = table.pack(...)
    local funcName = table.remove(args, 1)
    local Klass = self
    return function (...)
      local instance = Klass:new(table.unpack(args))
      return instance[funcName](instance, ...)
    end
  end

  function methods:ok(body, headers)
    headers = headers or { }

    return Response:new({
      status = 200,
      headers = headers,
      body = body
    })
  end

  function methods:redirect(location, headers)
    headers = headers or { }
    headers['Location'] = location

    return Response:new({
      status = 302,
      headers = headers,
      body = 'Moved to ' .. location
    })
  end

  function methods:forbidden()
    return Response:new({
      status = 403,
      headers = { },
      body = '403 Forbidden'
    })
  end

end)
