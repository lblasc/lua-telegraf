local telegraf = require 'telegraf'

local t = telegraf.new({
  global_tags = {
    [1]  = 123,
    gtag = 'asd',
    gtag2 = 1,
    gtag3 = true,
  },
})

t:set('test', {field = 123}, {tag = 'tag1'})
