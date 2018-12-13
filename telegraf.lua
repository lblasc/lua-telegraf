local lp = require 'telegraf.lineproto'
local ts = require 'telegraf.timestamp'
local w  = require 'telegraf.write'

local _M = {}
_M._VERSION = '1.0.0'
local mt = {__index = _M}

function _M.new(options)
  options = options or {}

  local o = {
    host        = options.host or '127.0.0.1',
    port        = options.port or 8086,
    global_tags = options.global_tags or {},
--    batch       = options.batch or false,
    precision   = options.precision or 'ns',
  }

  return setmetatable(o, mt)
end

function _M.set(self, measurement, fields, tags, timestamp)
  measurement = tostring(measurement)
  if type(measurement) ~= 'string' then
    return nil
  end

  if type(fields) ~= 'table' then
    return nil
  end

  local merged_tags = self.global_tags
  if type(tags) == 'table' then
    for t, v in pairs(tags) do
      merged_tags[t] = v
    end
  end

  timestamp = timestamp or ts.now(self.precision)

  local msg = lp.build_str(measurement, fields, merged_tags, timestamp)
  if not msg then return nil end

  w.send(msg, self.host, self.port)
end

return _M
