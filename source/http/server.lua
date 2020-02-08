local socket = require('socket')
local Request = require('web.request')
local Response = require('web.response')
-- a simple server framework that works on the basis of
-- handler(state, request) -> new_state, response
--
-- state - a table with lots of state in it
-- request - a table with info about the request
-- response - a table with a status, headers and body

Server = {}
function Server:new(base)
  base = base or { state={}, middlewares={Server.notFound} }
  setmetatable(base, self)
  self.__index = self
  return base
end

function Server:run(port)
  server = socket.bind("*", port)

  while 1 do
    local client = server:accept()
    local req, err = Request.fromSocket(client)

    if err then
      client:send("HTTP/1.0 500\r\n\r\nInternal Server Error")
    end

    for _, middleware in pairs(self.middlewares) do
      local state, res = middleware(self.state, req)
      self.state = state

      if getmetatable(res) == Response then
        client:send(res:toString())
        break
      else
        req = res
      end
    end
    client:close()
  end
end

function Server:addMiddleware(middleware)
  table.insert(self.middlewares, middleware)
end

function Server.notFound(state, req)
  host = req.headers['Host'] or ''
  return state, Response:new({
    status=404,
    headers={},
    body=host .. req.path .. " not found!"
  })
end

return Server
