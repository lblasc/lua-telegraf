local lp = require 'telegraf.lineproto'
local ts = require 'telegraf.timestamp'
local w  = require 'telegraf.write'

local pairs = pairs
local ipairs = ipairs
local table = table
local type = type
local tonumber = tonumber
local setmetatable = setmetatable

local ok, new_tab = pcall(require, 'table.new')
if not ok or type(new_tab) ~= 'function' then
  new_tab = function(narr, nrec) return {} end
end

local ok, clear_tab = pcall(require, 'table.clear')
if not ok then
  clear_tab = function (tab)
    for k, _ in pairs(tab) do
      tab[k] = nil
    end
  end
end

local _M = {}
_M._VERSION = '1.1.1'
local mt = {__index = _M}

function _M.new(options)
  options = options or {}

  local o = {
    host        = options.host or '127.0.0.1',
    port        = tonumber(options.port) or 8086,
    global_tags = options.global_tags or false,
    batch_size  = tonumber(options.batch_size) or false,
    precision   = options.precision   or false,
  }

  if o.batch_size then
    o.__buffer = new_tab(o.batch_size, 0)
  end

  -- Small optimization for comparing tags in
  -- :set() method (pairs is not JIT compiled, yet).
  if o.global_tags then
    local tag_names = {}
    for t, _ in pairs(o.global_tags) do
      table.insert(tag_names, t)
    end

    o.__global_tag_names = tag_names
  end

  return setmetatable(o, mt)
end

function _M.flush(self)
  local buffer = self.__buffer
  if not buffer or #buffer == 0 then
    return nil
  end

  w.send(table.concat(buffer, '\n'), self.host, self.port)
  clear_tab(buffer)
end

function _M.set(self, measurement, fields, tags, timestamp)

  local global_tags = self.global_tags
  if global_tags then
    if type(tags) == 'table' then
      for _, t in ipairs(self.__global_tag_names) do
        -- add non-existent tags from global_tags table
        if tags[t] == nil then
          tags[t] = global_tags[t]
        end
      end
    else
      tags = global_tags
    end
  end

  timestamp = timestamp or ts.now(self.precision)

  local msg, err = lp.build_str(measurement, fields, tags, timestamp)
  if not msg then return nil, err end

  if self.batch_size then
    table.insert(self.__buffer, msg)
    return
  end

  w.send(msg, self.host, self.port)
end

return _M
