function require_relative(relative_lib)
  local current_dir = debug.getinfo(2).source:match("@(.*/).*.lua")
  local lib_path = relative_lib:match("^(.+)/.-$")
  local lib_name = relative_lib:match("/?([^/]+)$")

  local old_path = package.path
  package.path = package.path .. ';' .. current_dir .. (lib_path or "") .. "?.lua"
  local required_module = require(lib_name)
  package.path = old_path
  return required_module
end

return require_relative
