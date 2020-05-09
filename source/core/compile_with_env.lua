local function getupvalue(fn, index)
  local index = index + 1
  local name, value = debug.getupvalue(fn, index)
  if name then return index, name, value end
end

local function upvalues(fn)
  return getupvalue, fn, 0
end

local function findenv(fn)
  for index, name, value in upvalues(fn) do
    if name == '_ENV' then return index, value end
  end
end 

local function setenv(fn, env)
  debug.setupvalue(fn, findenv(fn), env)
  return fn
end

function compileWithEnv(fn, name, env)
  if not getmetatable(env) then
    local _, oldEnv = findenv(fn)
    if oldEnv then
      setmetatable(env, { __index = oldEnv, __newindex = oldEnv })
    end
  end

  local compiled = load(string.dump(fn), name, 'b', env)

  for index, name, value in upvalues(fn) do
    if name ~= '_ENV' then
      debug.upvaluejoin(compiled, index, fn, index)
    end
  end

  return compiled
end

return compileWithEnv
