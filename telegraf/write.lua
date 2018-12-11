-- TODO: implement http, fallback to luasocket
local S = require 'syscall'
local t = S.types.t

local _M = {}

function _M.send(host, port, data)
  if type(data) ~= 'string' then return nil end

  local s, err = S.socket("inet", "dgram")
  if not s then error("cannot open socket") end
  local sa = t.sockaddr_in(port, host)

  local n = s:sendto(data, #data, 0, sa)

  s:close()
end

return _M
