require('relative_require')

local socket = require 'socket'
local FiberRunner = require('./source/concurrent/fiber_runner')
local Channel = require('./source/concurrent/channel')

local fibers = FiberRunner:new()

function server()
  local sink = Channel:new(fibers)
  local server = socket.bind('*', 8000)
  server:settimeout(0)

  fibers:spawn(function ()
    while true do
      local client, err = server:accept()

      if client then
        sink:put(client)
      elseif err == 'timeout' then
        fibers:yield()
      end
    end
  end)

  return sink 
end

function recieve(client)
  local sink = Channel:new(fibers)
  client:settimeout(0)

  fibers:spawn(function ()
    local err = ''
    while err ~= 'closed' do
      local line, err = client:receive()

      if line then
        sink:put(line)
      elseif err == 'timeout' then
        fibers:yield()
      end
    end
  end)

  return sink
end


local channels = { ['default'] = {} }
local commands = {
  { '^/name (.+)$', function (sender, message, name)
    sender.name = name
    sender.connection:send('Name set to: ' .. name .. '.\n')
  end },
  { '^/join (.+)$', function (sender, message, channelName)
    local channel = channels[channelName] or {}
    table.insert(channel, sender)
    channels[channelName] = channel
    sender.channel = channel
    sender.connection:send('Joined channel: ' .. channelName .. '.\n')
    sender.connection:send(#channel .. 'people are currently active.\n')
  end },
  { '^.*$', function (sender, message)
    for _, client in ipairs(sender.channel) do
      if client.connection ~= sender.connection then
        client.connection:send(sender.name .. ': ' .. message .. '\n')
      end
    end
  end }
}

local done = false
fibers:spawn(function ()
  local source = server()
  local err = nil

  while true do
    local connection = source:get()
    connection:settimeout(0)

    fibers:spawn(function ()
      local client = {
        name = '',
        connection = connection,
        channel = channels['default']
      }
      table.insert(channels['default'], client)

      local line = ''
      local err = nil
      while err ~= 'closed' do
        line, err = connection:receive()

        if line then
          print(client.name .. ':' .. line)

          for index = 1, #commands do
            local pattern, command = table.unpack(commands[index])
            local matches = table.pack(line:match(pattern))

            if #matches > 0 then
              command(client, line, table.unpack(matches))
              break
            end
          end
        else
          fibers:yield()
        end
      end

      connection:send('Bye!\r\n')
      connection:close()
    end)
  end
end)

while not done do fibers:run() end
