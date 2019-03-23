local telegraf = require 'telegraf'

local t = telegraf.new({
  precision = 's',
  batch_size = 20,
  global_tags = {
    [1]  = 123,
    gtag = 'asd',
    gtag2 = 1,
    gtag3 = true,
  },
})

for i=1,10 do
  t:set('test-'..i, {field = 123 + i}, {gtag = 'tag1'})
  t:set('test2-'..i, {field = 123 + i }, {tag2 = 'tag1'})
end

t:flush()
