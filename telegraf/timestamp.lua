-- TODO: handle multiple precisions, fallback to lua standard os.time()
local S = require 'syscall'

local _M = {}

function _M.now(precision)
  local timespec = S.clock_gettime("realtime")

  -- get nanosecond time in uint64_t and remove ULL from string
  local ns = string.sub(tostring(timespec.sec * 1000000000ULL + timespec.nsec), 0, -4)

  return ns
end

return _M
