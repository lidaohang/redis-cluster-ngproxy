local lhlh_redis_command = require "module.lhlh_redis_command"
local lhlh_redis_proto = require "module.lhlh_redis_proto"
local lhlh_common = require "module.lhlh_common"

local tcp = ngx.socket.tcp
local type = type
local pairs = pairs
local unpack = unpack
local setmetatable = setmetatable
local rawget = rawget
--local error = error


local new_tab = lhlh_common.new_tab
local _M = new_tab(0, 54)

_M._VERSION = '0.26'


local common_cmds = {
    "get",      "set",          "mget",     "mset",
    "del",      "incr",         "decr",                 -- Strings
    "llen",     "lindex",       "lpop",     "lpush",
    "lrange",   "linsert",                              -- Lists
    "hexists",  "hget",         "hset",     "hmget",
    --[[ "hmset", ]]            "hdel",                 -- Hashes
    "smembers", "sismember",    "sadd",     "srem",
    "sdiff",    "sinter",       "sunion",               -- Sets
    "zrange",   "zrangebyscore", "zrank",   "zadd",
    "zrem",     "zincrby",                              -- Sorted Sets
    "auth",     "eval",         "expire",   "script",
    "sort"                                              -- Others
}


local sub_commands = {
    "subscribe", "psubscribe"
}


local unsub_commands = {
    "unsubscribe", "punsubscribe"
}


local mt = { __index = _M }


function _M.new(self)
    local sock, err = tcp()
    if not sock then
        return nil, err
    end
    return setmetatable({ _sock = sock, _subscribed = false }, mt)
end


function _M.set_timeout(self, timeout)
    local sock = rawget(self, "_sock")
    if not sock then
        return nil, "not initialized"
    end

    return sock:settimeout(timeout)
end


function _M.connect(self, ...)
    local sock = rawget(self, "_sock")
    if not sock then
        return nil, "not initialized"
    end

    self._subscribed = false

    return sock:connect(...)
end


function _M.set_keepalive(self, ...)
    local sock = rawget(self, "_sock")
    if not sock then
        return nil, "not initialized"
    end

    if rawget(self, "_subscribed") then
        return nil, "subscribed state"
    end

    return sock:setkeepalive(...)
end


function _M.get_reused_times(self)
    local sock = rawget(self, "_sock")
    if not sock then
        return nil, "not initialized"
    end

    return sock:getreusedtimes()
end


local function close(self)
    local sock = rawget(self, "_sock")
    if not sock then
        return nil, "not initialized"
    end

    return sock:close()
end
_M.close = close


local function _do_cmd(self, ...)
    local args = {...}

    local sock = rawget(self, "_sock")
    if not sock then
        return nil, "not initialized"
    end


    local req = lhlh_redis_proto:encode(args, lhlh_common.REDIS_CLUSTER_TYPE_MULTI_BULK_REPLY)

    local reqs = rawget(self, "_reqs")
    if reqs then
        reqs[#reqs + 1] = req
        return
    end
    
    local bytes, err = sock:send(req)
    if not bytes then
        return nil, 0, err
    end

    local data, prefix, err = lhlh_redis_proto:decode(sock)
    if err == "timeout" then
        close(self)
    end

    return data, prefix, err
end


local function _check_subscribed(self, res)
    if type(res) == "table"
       and (res[1] == "unsubscribe" or res[1] == "punsubscribe")
       and res[3] == 0
   then
        self._subscribed = false
    end
end


for i = 1, #common_cmds do
    local cmd = common_cmds[i]

    _M[cmd] =
        function (self, ...)
            return _do_cmd(self, cmd, ...)
        end
end


for i = 1, #sub_commands do
    local cmd = sub_commands[i]

    _M[cmd] =
        function (self, ...)
            self._subscribed = true
            return _do_cmd(self, cmd, ...)
        end
end


for i = 1, #unsub_commands do
    local cmd = unsub_commands[i]

    _M[cmd] =
        function (self, ...)
            local res, err = _do_cmd(self, cmd, ...)
            _check_subscribed(self, res)
            return res, err
        end
end


function _M.hmset(self, hashname, ...)
    if select('#', ...) == 1 then
        local t = select(1, ...)

        local n = 0
        for k, v in pairs(t) do
            n = n + 2
        end

        local array = new_tab(n, 0)

        local i = 0
        for k, v in pairs(t) do
            array[i + 1] = k
            array[i + 2] = v
            i = i + 2
        end
        -- print("key", hashname)
        return _do_cmd(self, "hmset", hashname, unpack(array))
    end

    -- backwards compatibility
    return _do_cmd(self, "hmset", hashname, ...)
end


function _M.init_pipeline(self, n)
    self._reqs = new_tab(n or 4, 0)
end


function _M.cancel_pipeline(self)
    self._reqs = nil
end


function _M.commit_pipeline(self)
    local reqs = rawget(self, "_reqs")
    if not reqs then
        return nil, "no pipeline"
    end

    self._reqs = nil

    local sock = rawget(self, "_sock")
    if not sock then
        return nil, "not initialized"
    end

    local bytes, err = sock:send(reqs)
    if not bytes then
        return nil, err
    end

    local nvals = 0
    local nreqs = #reqs
    local vals = new_tab(nreqs, 0)
    for i = 1, nreqs do
        local res, _, err = lhlh_redis_proto:decode(sock)
        if res then
            nvals = nvals + 1
            vals[nvals] = res

        elseif res == nil then
            if err == "timeout" then
                close(self)
            end
            return nil, err

        else
            -- be a valid redis error value
            nvals = nvals + 1
            vals[nvals] = {false, err}
        end
    end

    return vals
end


function _M.array_to_hash(self, t)
    local n = #t
    -- print("n = ", n)
    local h = new_tab(0, n / 2)
    for i = 1, n, 2 do
        h[t[i]] = t[i + 1]
    end
    return h
end


-- this method is deperate since we already do lazy method generation.
function _M.add_commands(...)
    local cmds = {...}
    for i = 1, #cmds do
        local cmd = cmds[i]
        _M[cmd] =
            function (self, ...)
                return _do_cmd(self, cmd, ...)
            end
    end
end


setmetatable(_M, {__index = function(self, cmd)
    local method =
        function (self, ...)
            return _do_cmd(self, cmd, ...)
        end

    -- cache the lazily generated method in our
    -- module table
    _M[cmd] = method
    return method
end})


return _M
