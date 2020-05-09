local describe = require('lennie.lspec')

require('relative_require')

local class = require('../../source/core/class')

describe('class', function (it)
  it('should return a new instance of Class', function ()
    local Test = class('Test')
    assert(Test.class == Class)
  end)

  it('should set the parent of a class', function ()
    local Test = class('Test', Class)
    assert(Test.parent == Class)
  end)
  local a = function () end

  it('should pass methods table into class body ', function ()
    local testMethods = nil
    local Test = class('Test', function (methods)
      testMethods = methods
    end)
    assert(Test.methods == testMethods)
  end)

  it('should pass class to the class body', function ()
    local capturedTest = nil
    local Test = class('Test', function (methods, Test)
      capturedTest = Test
    end)
    assert(Test == capturedTest)
  end)

  it('should make a proxy object available with the name of the class', function ()
    local proxy = nil
    local Test = class('Test', function ()
      proxy = Test
    end)
    assert(proxy.new == Test.new)
    assert(proxy.class == Test.class)
  end)
end)
