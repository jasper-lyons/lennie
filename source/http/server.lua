require('relative_require')

local socket = require('socket')
local Request = require('./request')
local Response = require('./response')
local FiberRunner = require('../concurrent/fiber_runner')
local Channel = require('../concurrent/channel')
-- a simple server framework that works on the basis of
-- handler(state, request) -> new_state, response
--
-- state - a table with lots of state in it
-- request - a table with info about the request
-- response - a table with a status, headers and body

local function asyncServer(runner, port)
  local server, err = socket.bind("*", port)
  if err then error(err) end
  server:settimeout(0)
  local sink = Channel:new(runner)

  runner:spawn(function ()
    while true do
      local client, err = server:accept()

      if client then
        sink:put({ client })
      else
        runner:yield()
      end
    end
  end)

  return sink
end

local function asyncClient(runner, client)
  local base = {}
  local sink = Channel:new(runner)

  runner:spawn(function (amount)
    while true do
      local line, err = client:receive(amount)

      if err == 'closed' then break end

      sink:put({ line, err })
      runner:yield()
    end
  end)

  function base:receive(amount)
    return sink:get(amount)
  end

  function base:send(data)
    return client:send(data)
  end

  function base:close()
    return client:close()
  end

  return base
end

Server = {}

function Server:new(base)
  base = base or {
    state={},
    middlewares={Server.notFound}
  }
  base.fiberRunner = base.fiberRunner or FiberRunner:new()
  setmetatable(base, self)
  self.__index = self
  return base
end

function Server:handle(request)
  for index, middleware in pairs(self.middlewares) do
    local state, response = middleware(self.state, request)
    self.state = state

    if getmetatable(response) == Response then
      return response
    elseif response then
      request = response
    end
  end

  -- What error should be this? 404 not found?
  return Response:new({
    status = 500,
    headers = {},
    body = "500 An Error Occurred"
  })
end


function Server:run(port)
  local server, err = socket.bind("*", port)
  if err then error(err) end
  server:settimeout(0)

  self.fiberRunner:spawn(function ()
    local server = asyncServer(self.fiberRunner, 8000)

    while true do
      local syncClient = server:get()
      local client = asyncClient(self.fiberRunner, syncClient)

      self.fiberRunner:spawn(function ()
        local req, err = Request.fromSocket(client)

        if err then
          client:send(tostring(Response:new({
            status = 500,
            headers = {},
            body = "500 " .. err
          })))
        else
          local response = self:handle(req)
          client:send(tostring(response))
          print(req.method, req.path, req.parameters, 'HTTP/'..req.http_version, response.status)
        end

        client:close()
      end)
    end
  end)

  while true do self.fiberRunner:run() end
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
