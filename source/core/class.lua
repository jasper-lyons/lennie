require('relative_require')

local compileWithEnv = require('./compile_with_env')

local function getlocal(fn, index)
  local index = index + 1
  local name, value = debug.getlocal(fn, index)
  if name then return index, name, value end
end

local function locals(fn)
  return getlocal, fn, 0
end

-- self could be a variable name defined elsewhere in the closure but if
-- it is the first then it is likely to be an argument to the function.
--
-- This will break for functions defined like:
-- function (...)
--   local self = <something...>
-- end
local function definedWithColon(fn)
  local name, value = debug.getlocal(fn, 1)
  return name == 'self'
end

-- manually route calls to meta functions as lua uses
-- rawget(getmetatable(instance) or {}, event)
-- to get functions form meta tables. This means that
-- the __index of the metatables' metatable isn't used
-- to track down the right event. Instead it just returns
-- nil [http://www.lua.org/manual/5.1/manual.html#2.8]
-- We get around this by giving all objects the same metatable
-- which implements all meta methods.
function metaFactory(name)
  return function(self, other)
    if self.class.methods[name] then
      return self.class.methods[name](self, other)
    end
  end
end

local metatable = {
  __id = metaFactory('__id'),
  __tostring = metaFactory('__tostring'),
  __eq = metaFactory('__eq'),
  __lt = metaFactory('__lt'),
  __le = metaFactory('__le'),
  __add = metaFactory('__add'),
  __sub = metaFactory('__sub'),
  __len = metaFactory('__len'),
  __call = metaFactory('__call'),
  __index = function (self, method)
    if self.class == _ENV.Class then
      return self.parent and self.parent[method]
    else
      return self.class.methods[method]
    end
  end
}

Class = {
  name = "Class",
  parent = Object,
  methods = {
    __tostring = function (self)
      return self.name
    end,
    __id = function (self) return self end,
    __lt = function (self, other)
      return self.parent and (self.parent == other or self.parent < other)
    end,
    __le = function (self, other)
      return self == other or (self.parent and self.parent < other)
    end,
    __eq = function (self, other)
      return self.name == other.name
    end
  },
}
Class.class = Class
setmetatable(Class, metatable)

Object = {
  class = Class,
  name = "Object",
  parent = false,
  methods = {
    __tostring = function (self)
      local string = '<' .. tostring(self.class)
      for key, value in pairs(self) do
        string = string .. ' ' .. tostring(key) .. '=' .. tostring(value)
      end
      string = string .. '>'
      return string
    end,
    __id = function (self) return self end,
  }
}
setmetatable(Object, metatable)
setmetatable(Object.methods, { __index = Class.methods })

local classes = {}

function class(name, parent, body)
  if not parent then
    parent = Object
  end

  if type(parent) == 'function' and not body then
    body = parent
    parent = Object
  end

  local class = {
    class = Class,
    name = name,
    parent = parent,
    methods = {},
  }

  -- is a Class
  setmetatable(class, metatable)
  setmetatable(class.methods, { __index = parent.methods })

  class.new = function (self, ...)
    local instance = { class = class }
    -- inherits from
    setmetatable(instance, metatable)

    if class.methods.initialize then
      instance:initialize(...)
    end

    return instance 
  end

  -- if a body is present then we change it's env so that references
  -- to class point to proxyObject. proxyObject pretends to the class
  -- object. When a key is looked up on proxyObject we first check for
  -- a method with that name and then fall back to looking on the class
  -- object. When assigning a key, if it is a method it is attached to
  -- class.method else it is attached to class. This is all to allow 
  -- users to transparently do both:
  --
  --  ```
  --  function Class:method(arg1)
  --    ...
  --  end
  --
  --  Class.something = {}
  --  ```
  --
  -- without breaking the class system. Otherwise they would need to do:
  --  ```
  --  class('Name', Parent, function (methods, Name)
  --    function methods:method(arg1)
  --      ...
  --    end
  --
  --    Name.something = {}
  --  end)
  --  ```
  --
  --  The later is more explicit and relies on less magic, but sometimes we
  --  need a little magic.
  if body then
    local proxyObj = {}
    proxyObj = setmetatable({ }, {
      __index = function (self, key)
        return class.methods[key] or class[key]
      end,
      __newindex = function (self, key, value)
        if type(value) == 'function' and definedWithColon(value) then
          class.methods[key] = value
        else
          -- should check it's not { class, name, parent, methods }!
          class[key] = value
        end
      end
    })
    local env = { [name] = proxyObj }
    body = compileWithEnv(body, tostring(class) .. '.body', env)

    body(class.methods, class)
  end

  return class
end

-- lua modules don't support multiple return values so has to be global
-- until I adapt modules to support multiple returns
function as(instance, class)
  if instance.class < class or class < instance.class then
    instance.class = class
    return instance
  else
    error('Only instances in the inheritance chain of '..class..' can be cast to an instance of '..class, 2)
  end
end

return class
