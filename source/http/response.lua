Response = {}
function Response:new(base)
  base = base or { status=404, headers={}, body="Not Found" }
  setmetatable(base, self)
  self.__index = self
  return base
end

function Response:toString()
  local raw = "HTTP/1.1 " .. self.status .. "\r\n"
  for key, value in ipairs(self.headers) do
    raw = raw .. key .. ": " .. value .. "\r\n"
  end
  return raw .. "\r\n" .. self.body
end

return Response
