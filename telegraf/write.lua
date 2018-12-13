-- TODO: implement http, fallback to luasocket
local S_ok, S = pcall(require, 'syscall')

local type = type

local t
if S_ok then
  t = S.types.t
end

local _M = {}

local function write_udp(msg, host, port)
  if not S_ok then error('socket not available, install ljsyscall') end

  local s, err = S.socket("inet", "dgram")
  if not s then return nil, "cannot open socket" end
  local sa = t.sockaddr_in(port, host)

  s:sendto(msg, #msg, 0, sa)
  s:close()

  return true
end

local function ngx_write_udp(msg, host, port)
  local sock = ngx.socket.udp()

  local ok, err = sock:setpeername(host, port)
  if not ok then
    sock:close()
    return nil, err
  end

  local ok, err = sock:send(msg)
  if not ok then
    sock:close()
    return nil, err
  end

  sock:close()

  return true
end


function _M.send(msg, host, port)
  if type(msg) ~= 'string' then return nil end

  if ngx then
    return ngx_write_udp(msg, host, port)
  end

  return write_udp(msg, host, port)
end

return _M
