# Name

lua-telegraf - Lua/LuaJIT/OpenResty client writer for [Telegraf](https://github.com/influxdata/telegraf)/[InfluxDB](https://github.com/influxdata/influxdb)
or any listener compatible with [InfluxDB Line Protocol](https://docs.influxdata.com/influxdb/latest/write_protocols/line_protocol_reference/).

# Table of Contents

* [Name](#name)
* [Status](#status)
* [Description](#description)
* [Installation](#installation)
* [Synopsis](#synopsis)
    * [OpenResty](#openresty)
    * [Lua](#lua)
* [Methods](#methods)
    * [new](#new)
    * [set](#set)
    * [flush](#flush)
* [TODO](#todo)
* [Author](#author)
* [Copyright and License](#copyright-and-license)

# Status

This library is considered production ready.

# Description

This library implements writer interface for InfluxDB line protocol.
Focus is on simplicity and efficiency. Depending on runtime it will
find most suitable backend/library for constructing and writing metrics.

When run in context of OpenResty it will use cosocket API, which
ensures 100% nonblocking behavior, and nginx time primitives for
fetching cached time (no syscall involved). Support for Lua,
LuaJIT and nanosecond precision is covered by
[ljsyscall](https://github.com/justincormack/ljsyscall) library.

# Installation

Clone into your Lua module path or use opm:

```bash
  $ opm get lblasc/lua-telegraf
```

# Synopsis

## OpenResty

#### Simple (no batching)
```lua
# you do not need the following line if you installed
# module with `opm`
lua_package_path "/path/to/lua-telegraf/?.lua;;";

http {
  server {
    access_by_lua_block {
      local telegraf = require "telegraf"

      local t = telegraf.new({
        host = "127.0.0.1",
        port = 8094,
        global_tags = {
          gtag  = 1,
        },
      })

      local ok, err = t:set('test', {field = 123}, {tag = 'tagged'})
      if not ok then
        ngx.say(err)
      end
    }
  }
}
```

#### Batching

Create simple module (E.g. stats.lua) witch will use lua module caching
to preserve `lua-telegraf` instance and make it available in all phases.

```lua
local telegraf = require 'telegraf'
local t

local _M = {}

function _M.init(conf)
  t = telegraf.new(conf)
  return t
end

function _M.get()
  assert(t)
  return t
end

return _M
```

```lua
lua_package_path "/path/to/stats/module/?.lua;;";

http {
  init_worker_by_lua_block {
    local function flush_stats(premature)
      if premature then
        return
      end

      local t = require('stats').get()
      t:flush()
    end

    local flush_every = 1 -- adjust flush interval (in seconds)
    require("stats").init({
      host = "127.0.0.1",
      port = 8094,
      batch_size = 20,
      global_tags = {
        gtag  = 1,
      },
    })

    local ok, err = ngx.timer.every(flush_every, flush_stats)
    if not ok then
      ngx.log(ngx.ERR, err)
      return
    end
  }

  server {
    access_by_lua_block {
      local t = require("stats").get()

      t:set('test', {field = 123}, {tag = 'tagged'})
    }

    log_by_lua_block {
      local t = require("stats").get()

      t:set('nginx_stats', {
        request_time = ngx.now() - ngx.req.start_time()
      }, {tag = 'mytag'})
    }
  }
}
```

## Lua
```lua
local telegraf = require "telegraf"

local t = telegraf.new({
  host = "127.0.0.1",
  port = 8094,
  global_tags = {
    gtag  = 1,
  },
})

local ok, err = t:set('test', {field = 123}, {tag = 'tagged'})
if not ok then
  error(err)
end
```

# Methods

## new
`syntax: t, err = telegraf.new(options?)`

Creates telegraf instance with optional options table.

### options

#### host

*Default*: `127.0.0.1`

Sets the host address.

#### port

*Default*: `8094`

Sets the host port.

#### proto

*Default*: `udp`

Sets the protocol, for now only supported is udp.

#### precision

*Default*: `nil`

Sets the timestamp precision. Currently, `s`, `ms`, `u`, and `ns`
are supported, when precision is `nil` (default) no timestamp
will be sent as part of the line protocol message, and the
remote server will set timestamp based on the server-local clock.

#### global_tags

*Default*: `{}`

Tags that will be added to every metric. Field needs to be defined
in set of tag/value pairs.

#### batch_size

*Default*: `nil`

Preallocates batch buffer by specified size and enables batching.
Batch buffer is `table` which will exceed buffer size if not
flushed in time, flushing is manual operation. By default (`nil`)
batching is disabled and all metrics will be sent immediately.

## set
`syntax: ok, err = t:set(measurement, fields, tags?, timestamp?)`

Generates new data point, depending on options, data point is pushed
to a buffer or sent immediately.

* `measurement`: `string` denoting the measurement of the data point
* `fields`: `table` of key-value pairs denoting the field elements
* `tags` (optional): `table` of key-value pairs denoting the tag elements
* `timestamp` (optional): `number` which overrides generated or
sets timestamp with time provided in `UNIX time` format

## flush
`syntax: t:flush()`

Flushes batch buffer. If buffer is empty or not enabled method
just returns.

[Back to TOC](#table-of-contents)

# TODO

- http support

[Back to TOC](#table-of-contents)

Author
======

Luka Blašković <lblasc@znode.net>

[Back to TOC](#table-of-contents)

Copyright and License
=====================

See [LICENSE](./LICENSE)

[Back to TOC](#table-of-contents)
