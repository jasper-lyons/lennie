local socket = require('socket')

Request = {}
function Request:new(base)
  base = base or { path="" }
  setmetatable(base, self)
  self.__index = self
  return base
end

function readStatus(client)
  local status_line, err = client:receive()
  local method, path, http_version = status_line:
    match("^([A-Z]+)%s([/%%0-9a-z.-]*)%sHTTP/([0-9.]*)$")
  print(method, path, http_version)
  return method, path, http_version, err
end

function readHeaders(client)
  local headers = {}
  repeat
    local line, err = client:receive()
    if err then return nil, err end
    local key, value = line:
      match("^([^:]+):%s(.*)$")
    if key then
      headers[key] = value
    end
  until line == '' or err
  return headers, err
end

function readBody(client, contentLength)
  local body, err = client:receive(contentLength)
  return body, err
end

function Request.fromSocket(client)
  local method, path, version, err = readStatus(client)
  local headers, err = readHeaders(client)
  local body = ''
  if headers['Content-Length'] then
    body, err = readBody(client, tonumber(headers['Content-Length']))
  end

  return Request:new({
    method=method,
    path=path,
    http_version=version,
    headers=headers,
    body=body
  })
end

return Request
