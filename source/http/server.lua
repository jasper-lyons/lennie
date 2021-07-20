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
  if err then return nil, err end
  local sink = Channel:new(runner)

  runner:spawn(function ()
    while true do
      -- block when there are no other tasks in the queue because
      -- we can and it saves the busy wait.
      if #runner.queue > 0
      then server:settimeout(0)
      else server:settimeout(nil) end

      local client, err = server:accept()

      if client then
        sink:put(client)
      end

      runner:yield()
    end
  end)

  return sink
end

local function asyncClient(runner, client)
  local channel = Channel:new(runner)

  runner:spawn(function ()
    while true do
      local amount = channel:get()

      local line, err = client:receive(amount)
      if err == 'closed' then break end

      channel:put(line, err)
      runner:yield()
    end
  end)

  function channel:receive(amount)
    channel:put(amount)
    return channel:get()
  end

  function channel:send(data)
    return client:send(data)
  end

  function channel:close()
    return client:close()
  end

  return channel 
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
        local status, result = xpcall(function ()
          return response:withRenderedBody()
        end, function (err)
          return Response:new({
            status = 500,
            headers = {},
            body = tostring(err)
          })
        end)

        return result
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

function Server:run(port, ready)
  self.fiberRunner:spawn(function ()
    local server, err = asyncServer(self.fiberRunner, port)

    while true do
      local syncClient = server:get()
      local client = asyncClient(self.fiberRunner, syncClient)

      self.fiberRunner:spawn(function ()
        local req, err = Request.fromSocket(client)
        local response = nil

        if not err then
          response = self:handle(req)
        else
          response = Response:new({
            status = 500,
            headers = {},
            body = tostring(err)
          })
        end

        client:send(result.responseString)
        print(req.method, req.path, req.parameters, 'HTTP/'..req.http_version, result.response.status)
        client:close()
      end)
    end
  end)

  -- tell the caller that we're ready to go!
  ready(self)

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
