local reserved = { ':', '/', '?', '#', '[', ']', '@', '!', '$', '&', '\'', 
  '(', ')', '*', '+', ',', ';', '=', ' ' }
local toEncode = {}

for _, characters in pairs(reserved) do
  toEncode[string.byte(characters)] = true
end

local function encode(string)
  local result = ''

  for index = 1,#string do
    if toEncode[string:byte(index)] then
      result = result .. ('%%%02X'):format(string:byte(index))
    else
      result = result .. string:sub(index, index)
    end
  end

  return result
end

local function decode(encoded)
  return encoded:gsub("%%(%x%x)", function (hexValue)
    return string.char(tonumber(hexValue, 16))
  end)
end

return {
  encode = encode,
  decode = decode
}
