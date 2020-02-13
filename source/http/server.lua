local socket = require('socket')
local Request = require('lennie.http.request')
local Response = require('lennie.http.response')
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

function Server:handle(request)
  for _, middleware in pairs(self.middlewares) do
    local state, response = middleware(self.state, request)
    self.state = state

    if getmetatable(response) == Response then
      return response
    else
      request = response
    end
  end

  return Response:new({
    status = 500,
    headers = {},
    body = "500 Not Implemented"
  })
end

function Server:run(port)
  server = socket.bind("*", port)

  while 1 do
    local client = server:accept()
    local req, err = Request.fromSocket(client)

    if err then
      client:send(tostring(Response:new({
        status = 500,
        headers = {},
        body = "500 Not Implemented"
      })))
    end

    client:send(tostring(self:handle(req)))
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
