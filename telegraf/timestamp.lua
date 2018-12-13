local S_ok, S = pcall(require, 'syscall')
local os_time = os.time

local tostring, type = tostring, type

local _M = {}

local function clock_realtime()
    if not S_ok then error('resolution not available, install ljsyscall') end
    local timespec = S.clock_gettime("realtime")

    return timespec
end

function _M.now(precision)
  if type(precision) ~= 'string' then return nil end

  if precision == 'ns' then
    local timespec = clock_realtime()

    return ('%d'):format(timespec.sec * 1000000000 + timespec.nsec)

  elseif precision == 'u' then
    local timespec = clock_realtime()

    return ('%d'):format(timespec.sec * 1000000 + timespec.nsec * 0.001)

  elseif precision == 'ms' then
    if ngx then
      return tostring(ngx.now() * 1000)
    end
    local timespec = clock_realtime()

    return ('%d'):format(timespec.sec * 1000 + timespec.nsec * 0.000001)

  elseif precision == 's' then
    if ngx then
      return tostring(ngx.time())
    end

    return tostring(os_time())
  end

  return nil
end

return _M
