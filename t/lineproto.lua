local lp = require 'telegraf.lineproto'

print("TEST: measurement")
do
  local str, err = lp.build_str({'test'}, {value = 1})
  assert(err)
end

do
  local str, err = lp.build_str(123)
  assert(err)
end

do
  local str, err = lp.build_str(123, {value = 1})
  assert(str == '123 value=1')
end

do
  local str = lp.build_str('foo bar', {value = 1})
  assert(str == 'foo\\ bar value=1')
end

do
  local str = lp.build_str('foo,bar', {value = 1})
  assert(str == 'foo\\,bar value=1')
end

print("TEST: fields")
do
  local str, err = lp.build_str('foo', {value = {z = 1}})
  assert(err)
end

do
  local str = lp.build_str('foo', {[1] = 'a'})
  assert(str == 'foo 1="a"')
end

do
  local str, err = lp.build_str('foo', {val1 = function() end})
  assert(err)
end

do
  local str = lp.build_str('foo', {['val\\, ='] = 1})
  assert(str == 'foo val\\\\,\\ \\==1')
end

print("TEST: tags")
do
  local str = lp.build_str('foo', {value = 1}, {tag = {}})
  assert(str == 'foo value=1')
end

do
  local str, err = lp.build_str('foo', {value = 1}, 'bar')
  assert(err)
end

do
  local str = lp.build_str('foo', {value = 1}, {[1] = 123, ['foo ,='] = 'b *\\,'})
  assert(str == 'foo,foo\\ \\,\\==b\\ *\\\\,,1=123 value=1')
end

print("TEST: timestamp")
do
  local str, err = lp.build_str('foo', {value = 1}, nil, "123456789")
  assert(str == 'foo value=1 123456789')
end

do
  local str, err = lp.build_str('foo', {value = 1}, nil, 123456789)
  assert(str == 'foo value=1 123456789')
end
