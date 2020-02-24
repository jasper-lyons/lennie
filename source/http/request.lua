require('relative_require')
local socket = require('socket')
local formdata = require('./formdata')

Request = {}

function Request:new(base)
  base = base or { }
  setmetatable(base, self)
  self.__index = self
  return base
end

function readStatus(client)
  local status_line, err = client:receive()
  if err then return nil, err end

  -- FIXME: won't work with parameters!
  local method, path, params, http_version = status_line:
    match("^([A-Z]+)%s([/%%0-9a-z.-]*)%??([a-z0-9&=]*)%sHTTP/([0-9.]*)$")
  -- TODO: logging shouldn't happen here, should use a separate logging middleware
  print(method, path, params, http_version)
  return method, path, params, http_version, err
end

function readHeaders(client)
  local headers = {}
  repeat
    local line, err = client:receive()
    if err then return nil, err end

    local key, value = line:match("^([^:]+):%s(.*)$")
    if key then
      headers[key] = value
    end
  until line == ''

  return headers, err
end

function readBody(client, contentLength)
  local body, err = client:receive(contentLength)
  return body, err
end

function Request.fromSocket(client)
  local method, path, params, version, err = readStatus(client)
  if err then return nil, err end

  local headers, err = readHeaders(client)
  if err then return nil, err end

  local body = ''
  if headers['Content-Length'] then
    body, err = readBody(client, tonumber(headers['Content-Length']))
  end
  if err then return nil, err end

  return Request:new({
    method=method,
    path=path,
    params=formdata.parse(params),
    http_version=version,
    headers=headers,
    body=body
  })
end

return Request
