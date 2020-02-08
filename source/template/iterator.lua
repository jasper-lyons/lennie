local iterator = {}

function iterator.map(iter, func)
  local array = {}
  for index, value in pairs(iter) do
    local result = func(value, index) 
    table.insert(array, result or nil)
  end
  return array
end

function iterator.filter(iter, pred)
  local array = {}
  for index, value in pairs(iter) do
    if pred(value) then
      table.insert(array, value)
    end
  end
  return array
end

function iterator.reduce(iter, func, initial)
  local result = initial
  iterator.map(iter, function (value, key)
    result = func(result, value, key) 
  end)
  return result
end

return iterator
