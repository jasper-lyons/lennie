require('relative_require')

local describe = require('lennie.lspec')
local Relation = require('../../source/core/relation')
local Tuple = require('../../source/core/tuple')
local Array = require('../../source/core/array')

describe('Relation', function (it, describe)
  local idName = { 'id', 'name' }
  local placeLocation = { 'place', 'location' }

  local a = Relation:new(idName, {
    Tuple:new({ id=0, name='r1-test' }),
    Tuple:new({ id=1, name='r1-test' })
  })
  local b = Relation:new(idName, {
    Tuple:new({ id=0, name='r2-test' }),
    Tuple:new({ id=1, name='r1-test' })
  })
  local c = Relation:new(placeLocation, {
    Tuple:new({ place='Barnes', location='London' }),
    Tuple:new({ place='Kingston', location='London '})
  })

  describe(':union(other)', function (it)
    it('should combine the tuples from self and other', function ()
      local union = a:union(b)
      assert(#union == 4)
    end)
  end)  

  describe(':difference(other)', function (it)
    it('should return tuples in relation a that are not in relation b', function ()
      local difference = a:difference(b)
      assert(#difference == 1)
      assert(difference.tables:get(1) == a.tables:get(1))
    end)
  end)

  describe(':intersect(other)', function (it)
    it('should return the tulples that are in both a and b', function ()
      local intersection = a:intersect(b)
      assert(#intersection == 1)
      assert(intersection.tables:get(1) == a.tables:get(2))
    end)
  end)

  describe(':product(other)', function (it)
    it('should return the cartesian product of relations in a and b as flat tuples', function ()
      local product = a:product(c)
      assert(#product == #a * #c)
    end)
  end)

  describe(':project(attributes)', function (it)
    it('should return tuples from relations with only the set of asstributes listed', function ()
      local projection = a:project({ 'id' })
      assert(#projection == 2)
      assert(#projection.attributes == 1)
      assert(projection.tables:get(1) == Tuple:new({ id=0 }))
    end)
  end)

  describe(':selection(builder)', function (it)
    it('should return tuples matching the provided proposition', function ()
      local selected = a:select(function ()
        return id == value(1)
      end)
      assert(#selected == 1)
      assert(selected.tables:get(1):get('id') == 1)
    end)
  end)

  describe(':rename(from, to)', function (it)
    it('should change the name of attributes in the relation and it\'s tuples', function ()
      local renamed = a:rename('id', 'uuid')
      assert(#renamed == 2)
      assert(renamed.attributes == Array:new({ 'uuid', 'name' }))
      assert(renamed.tables:get(1):get('uuid') == a.tables:get(1):get('id'))
    end)
  end)
end)
