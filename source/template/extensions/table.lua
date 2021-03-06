require('relative_require')

local iterator = require('../iterator')

table.merge = table.merge or function(t1, t2)
  return iterator.reduce(t2, function (reciever, value, key)
    if type(reciever[key]) == "table" then
      reciever[key] = table.merge(reciever[key], value)
    else
      reciever[key] = value
    end
    return reciever
  end, t1)
end


