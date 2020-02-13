Response = {}

function Response:new(base)
  base = base or { status=404, headers={}, body="Not Found" }
  setmetatable(base, self)
  self.__index = self
  return base
end

function Response:__tostring()
  local raw = "HTTP/1.1 " .. tostring(self.status) .. "\r\n"
  for key, value in pairs(self.headers) do
    raw = raw .. tostring(key) .. ": " .. tostring(value) .. "\r\n"
  end
  return raw .. "\r\n" .. tostring(self.body)
end

return Response
