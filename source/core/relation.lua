require('relative_require')

local class = require('./class')
local Array = require('./array')
local Map = require('./map')
local Tuple = require('./tuple')
local compileWithEnv = require('./compile_with_env')

return class('Relation', function ()
  function Relation:initialize(attributes, tables)
    self.attributes = attributes.class == Array and attributes or Array:new(attributes)
    self.tables = tables.class == Array and tables or Array:new(tables)
  end

  function Relation:__len()
    return #self.tables
  end

  function Relation:get(index)
    return self.tables:get(index)
  end

  function Relation:add(tuple)
    -- TODO: There should be limits on what can be added here, e.g. meets
    -- schema.
    if tuple:keys() == self.attributes then
      self.tables:push(tuple)
    else
      error('Attempting to add a tuple with the wrong set of keys', 2)
    end
  end

  function Relation:union(other)
    if self.attributes ~= other.attributes then
      error('Attempting to union relations with different attributes', 2)
    end

    return Relation:new(
      self.attributes,
      self.tables + other.tables
    )
  end

  function Relation:difference(other)
    if self.attributes ~= other.attributes then
      error('Attempting find the difference betwee relations with different attributes', 2)
    end

    return Relation:new(
      self.attributes,
      self.tables - other.tables
    )
  end

  function Relation:intersect(other)
    if self.attributes ~= other.attributes then
      error('Attempting to intersect relations with different attributes', 2)
    end

    return self:difference(self:difference(other))
  end

  function Relation:product(other)
    if #self.attributes > #(self.attributes - other.attributes) then
      error('Attempting to find the cartesian product of two relations that share attributes', 2)
    end

    return Relation:new(
      self.attributes + other.attributes,
      self.tables:reduce(function (container, tuple)
        return other.tables:reduce(function (container, otherTuple)
          return container:push(tuple:union(otherTuple))
        end, container)
      end, Array:new({}))
    )
  end

  function Relation:project(attributes)
    -- TODO: this could be formed transparently through an Array.from method
    attributes = attributes.class == Array and attributes or Array:new(attributes)

    if #(attributes - self.attributes) > 0 then
      error('Attempting to project with attributes not in ' .. self, 2)
    end

    return Relation:new(
      attributes,
      self.tables:map(function (tuple)
        return tuple:project(attributes)
      end)
    )
  end

  Relation.Proposition = class('Proposition', function ()
    function Proposition:initialize(relation, builder)
      self.relation = relation
      self.builder = builder
      self.stack = Array:new({})
    end

    function Proposition:env()
      local meta = {
        __eq = function () self.stack:push('==') end,
        __band = function () self.stack:push('and') end,
      }
      local methods = {
        like = function () self.stack:push('like') end
      }
      meta.__index = function (_, key)
        if methods[key] then
          return methods[key]
        end

        self.stack:push(Map:new({ name = key }))
        return setmetatable({}, meta)
      end
      return setmetatable({
        print = print,
        value = function (value)
          self.stack:push(Map:new({ value = value }))
          return setmetatable({}, meta)
        end
      }, meta)
    end

    function Proposition:compile(...)
      local builder = compileWithEnv(self.builder, 'builder', self:env())
      builder(...)
    end

    function Proposition:__call(tuple)
      local stack = Array:new(table.pack(table.unpack(self.stack.table)))
      local valueStack = Array:new({})

      while #stack > 0 do
        local node = stack:pop()

        if node.class == Map and node:get('value') then
          valueStack:push(node:get('value'))
        elseif node.class == Map and node:get('name') then
          valueStack:push(tuple:get(node:get('name')))
        elseif node == '==' then
          local left = valueStack:pop()
          local right = valueStack:pop()
          valueStack:push(left == right)
        elseif node == 'and' then
          local left = valueStack:pop()
          local right = valueStack:pop()
          valueStack:push(left and right)
        elseif node == 'like' then
          local left = valueStack:pop()
          local right = valueStack:pop()
          valueStack:push(left:find(right))
        end
      end

      return valueStack:pop()
    end
  end)

  function Relation:select(builder, ...)
    local proposition = Relation.Proposition:new(self, builder)

    proposition:compile(...)

    return Relation:new(
      self.attributes,
      self.tables:filter(proposition)
    )
  end

  function Relation:rename(from, to)
    assert(self.attributes:indexOf(from), 'Cannot rename attribute '..from..' as it does not exist')    

    return Relation:new(
      self.attributes:map(function (a)
        if a == from then
          return to
        else
          return a
        end
      end),
      self.tables:map(function (tuple)
        return as(tuple:toArray():map(function (kVPair)
          local key, value = table.unpack(kVPair)
          if key == from then
            return { to, value }
          end
          return kVPair
        end):toMap(), Tuple)
      end)
    )
  end
end)
