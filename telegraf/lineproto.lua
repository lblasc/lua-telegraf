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
  local value_type = type(value)

  if value_type == 'boolean' or value_type == 'number' then
    value = tostring(value)
  elseif value_type ~= 'string' then
    return nil, 'invalid value type '..value_type
  end

  value = str_gsub(value, ',', '\\,')
  value = str_gsub(value, ' ', '\\ ')

  return value
end

local function quote_field_key(key)
  key = tostring(key)
  if not key then
    return nil, 'unable to cast '..type(key)..' to string'
  end

  key = str_gsub(key, ',', '\\,')
  key = str_gsub(key, '=', '\\=')
  key = str_gsub(key, ' ', '\\ ')

  return key
end

local function quote_field_value(value)
  local value_type = type(value)

  if value_type == 'string' then
    -- number (float or integer) checks
    if str_find(value, '^%d+i$') then
      return value
    end

    -- boolean checks
    for i=1,10 do
      if str_find(value, bool_strs[i]) then
        return value
      end
    end

    value = str_gsub(value, '"', '\\"')

    return ('"%s"'):format(value)
  elseif value_type == 'boolean' or value_type == 'number' then
    return tostring(value)
  end

  return nil, 'invalid field value type '..value_type
end

local quote_tag_key = quote_field_key

local function quote_tag_value(value)
  local value_type = type(value)
  if value_type == 'string'  or
     value_type == 'boolean' or
     value_type == 'number' then
    return quote_field_key(value)
  end

  return nil, 'invalid tag value type '..value_type
end

local function build_field_set(fields)
  if type(fields) ~= 'table' then
    return nil, 'invalid fields type, should be table'
  end

  local field_set = {}
  for key, val in pairs(fields) do
    local k, err = quote_field_key(key)
    if not k then return nil, err end
    local v, err = quote_field_value(val)
    if not v then return nil, err end

    tbl_insert(field_set, ("%s=%s"):format(k, v))
  end

  if #field_set == 0 then
    return nil, 'invalid field set, shouldn\'t be empty'
  end

  return field_set
end

local function build_tag_set(tags)
  if not tags then
    return nil
  end

  if type(tags) ~= 'table' then
    return nil, 'invalid tags type, should be table'
  end

  local tag_set = {}
  for tag, val in pairs(tags) do
    local k = quote_tag_key(tag)
    if not k then return nil, err end
    local v = quote_tag_value(val)
    if not v then return nil, err end

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
  local err

  measurement, err = quote_measurement(measurement)
  if not measurement then return nil, err end

  local field_set, err = build_field_set(fields)
  if not field_set then return nil, err end

  local tag_set, err = build_tag_set(tags)
  -- it is fine to give empty tags table, only check for errors
  if err then return nil, err end

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
