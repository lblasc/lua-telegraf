-- influxdb line protocol
-- original source: https://github.com/p0pr0ck5/lua-resty-influx/blob/master/lib/resty/influx/lineproto.lua

local str_gsub    = string.gsub
local str_find    = string.find
local tbl_cat     = table.concat
local tbl_insert  = table.insert

local bool_strs = { '^t$', '^T$', '^true$', '^True$', '^TRUE$', '^f$', '^F$', '^false$', '^False$', '^FALSE$' }

-- quoting routines based on
-- https://docs.influxdata.com/influxdb/v1.0/write_protocols/line_protocol_reference/
--
local function quote_measurement(value)
  value = str_gsub(value, ',', '\\,')
  value = str_gsub(value, ' ', '\\ ')

  return value
end

local function quote_field_key(key)
  key = str_gsub(key, ',', '\\,')
  key = str_gsub(key, '=', '\\=')
  key = str_gsub(key, ' ', '\\ ')

  return key
end

local quote_tag = quote_field_key

local function quote_field_value(value)
  local value_type = type(value)

  -- number (float or integer) checks
  if value_type ~= 'string' or str_find(value, '^%d+i$') then
    return tostring(value)
  end

  if value_type == 'boolean' then
    return tostring(value)
  end

  -- boolean checks
  for i = 1, 10 do
    if str_find(value, bool_strs[i]) then
      return value
    end
  end

  value = str_gsub(value, '"', '\\"')
  return ('"%s"'):format(value)
end

local function build_field_set(fields)
  if type(fields) ~= 'table' then
    return nil
  end

  local field_set = {}
  for key, val in pairs(fields) do
    local k = quote_field_key(tostring(key))
    local v = quote_field_value(val)

    tbl_insert(field_set, ("%s=%s"):format(k, v))
  end

  if #field_set == 0 then
    return nil
  end

  return field_set
end

local function build_tag_set(tags)
  if type(tags) ~= 'table' then
    return nil
  end

  local tag_set = {}
  for tag, val in pairs(tags) do
    local k = quote_tag(tostring(tag))
    local v = quote_tag(tostring(val))

    tbl_insert(tag_set, ("%s=%s"):format(k, v))
  end

  if #tag_set == 0 then
    return nil
  end

  return tag_set
end

local _M = {}
_M.version = "0.3"

function _M.build_str(measurement, fields, tags, timestamp)
  measurement = quote_measurement(measurement)

  local field_set = build_field_set(fields)
  if not field_set then return nil end
  local tag_set   = build_tag_set(tags)

  if timestamp then
    if tag_set then
      return ("%s,%s %s %s"):format(measurement,
                                    tbl_cat(tag_set, ','),
                                    tbl_cat(field_set, ','),
                                    timestamp)
    end

    return ("%s %s %s"):format(measurement,
                               tbl_cat(field_set, ','),
                               timestamp)
  end

  if tag_set then
    return ("%s,%s %s"):format(measurement,
                               tbl_cat(tag_set, ','),
                               tbl_cat(field_set, ','))
  end

  return ("%s %s"):format(measurement,
                          tbl_cat(field_set, ','))


end

return _M
