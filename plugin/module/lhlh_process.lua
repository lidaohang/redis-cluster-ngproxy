local lhlh_common = require "module.lhlh_common"
local lhlh_proxy = require "module.lhlh_proxy"
local lhlh_redis_proto = require "module.lhlh_redis_proto"
local lhlh_redis_cluster = require "module.lhlh_redis_cluster"

local upper = string.upper
local table = table
local lower = string.lower
local tostring = tostring
local len = string.len
local pairs = pairs
local type = type

local new_tab = lhlh_common.new_tab
local _M = new_tab(0, 2)

_M._VERSION = '0.01'


local function thread_wait(self,thread_pool)
    
    local status = false
    local thread_len = #thread_pool
    local ok, rc, prefix, err

    for i = 1, thread_len do
        ok, rc, prefix, err = ngx.thread.wait(thread_pool[i])
        if ( not ok ) or rc ~= lhlh_common.LHLH_OK  then
            ngx.log(ngx.ERR, "thread.wait is failed")
            status = true
            
            for j = i + 1, thread_len do
                local _, killErr = ngx.thread.kill(thread_pool[j])
                if killErr and killErr ~= 'already waited or killed' then
                    ngx.log(ngx.ERR, killErr)
                end
            end
            break
        end
    end

    if status == true  then
        return lhlh_common.LHLH_ERROR, prefix, err
    end
    
    return lhlh_common.LHLH_OK, prefix
end


--MGET
local function multi_mget_keys(self, req_data, slotid, cmd, keys)
    
    local values, prefix, err = lhlh_redis_cluster:send_cluster_command(slotid, cmd, unpack(keys))
    if err then
        ngx.log(ngx.ERR, "send_cluster_command multi_mget_keys failed  ", err)
        return lhlh_common.LHLH_ERROR, prefix, err
    end

    for i = 1, #keys do
        for j = 2, #req_data do
            if keys[i] == req_data[j] then
                req_data[j] = {keys[i], values[i]}
                break
            end 
        end
    end

    return lhlh_common.LHLH_OK, prefix
end


--DEL,EXISTS
local function multi_keys(self, request, slotid, cmd, keys)

    local values, prefix, err = lhlh_redis_cluster:send_cluster_command(slotid, cmd, unpack(keys))
    if err then
        ngx.log(ngx.ERR, "send_cluster_command multi_keys failed  ", err)
        return lhlh_common.LHLH_ERROR, prefix, err
    end

    request.num = request.num + values
    return lhlh_common.LHLH_OK, prefix
end


--MGET
local function  redis_mget_keys(self, req_data)
    
    local argc = #req_data
    local cmd = lower(req_data[1])

    local slots =  new_tab(0, argc-1)
    local thread_pool = new_tab(argc-1, 0)

    for i = 2, argc do
        local slot = ngx.redis_slot(req_data[i])
        if slots[slot] == nil then
            slots[slot] = {}
        end
        table.insert(slots[slot], req_data[i])
    end

    local size = 0
    local thread = nil
    for k, v in pairs(slots) do
        size = size + 1
        thread = ngx.thread.spawn(multi_mget_keys, self, req_data, k, cmd, v)
        thread_pool[size] =  thread
    end

    --批量发送keys返回的结果状态
    local rc, prefix, err = thread_wait(self, thread_pool)
    if rc ~= lhlh_common.LHLH_OK then
        prefix = lhlh_common.REDIS_CLUSTER_TYPE_ERROR_REPLY
        return lhlh_redis_proto:encode(err, prefix)
    end

    local nbits = 2
    local req = new_tab(argc * 5, 0)
    req[1] = "*"..(argc-1).."\r\n"

    for i = 2, argc do
        local arg = req_data[i][2]
        if arg == ngx.null or arg == nil then
            
            req[nbits] = "$"
            req[nbits + 1] = -1
            req[nbits + 2] = "\r\n"
            
            nbits = nbits + 3
        else
            req[nbits] = "$"
            req[nbits + 1] = #arg
            req[nbits + 2] = "\r\n"
            req[nbits + 3] = arg
            req[nbits + 4] = "\r\n"

            nbits = nbits + 5
        end
    end

    return req 
end


--DEL, EXISTS
local function  redis_multi_keys(self, req_data)

    local argc = #req_data
    local cmd = req_data[1]

    local slots =  new_tab(0, argc-1)
    local thread_pool = new_tab(argc-1, 0)

    for i = 2, argc do
        local slot = ngx.redis_slot(req_data[i])
        if slots[slot] == nil then
            slots[slot] = {}
        end
        table.insert(slots[slot], req_data[i])
    end
    
    local size = 0
    local thread = nil
    
    local request = new_tab(0, 1)
    request.num = 0

    for k, v in pairs(slots) do
        size = size + 1
        thread = ngx.thread.spawn(multi_keys, self, request, k, cmd, v)
        thread_pool[size] =  thread
    end

    --批量发送keys返回的结果状态
    local rc, prefix, err = thread_wait(self, thread_pool)
    if rc ~= lhlh_common.LHLH_OK then
        prefix = lhlh_common.REDIS_CLUSTER_TYPE_ERROR_REPLY
        return lhlh_redis_proto:encode(err, prefix)
    end

    return lhlh_redis_proto:encode(request.num, prefix)
end


--MSET
local function multi_kvs(self, slotid, cmd, kvs)
    
    local res, prefix, err = lhlh_redis_cluster:send_cluster_command(slotid, cmd, unpack(kvs))
    if  err then
        ngx.log(ngx.ERR, "send_cluster_command multi_kvs failed  ", err)
        return lhlh_common.LHLH_ERROR, prefix, err
    end

    return lhlh_common.LHLH_OK, prefix
end


--MSET
local function  redis_kvs(self, req_data)
    
    local cmd = req_data[1]
    local argc = #req_data
    
    local slots = new_tab(0, argc-1)
    local thread_pool = new_tab(argc-1, 0)

    for i = 2, argc do
        if i % 2 == 0 then
            local slot = ngx.redis_slot(req_data[i])
            
            if slots[slot] == nil then
                slots[slot] = {}
            end
            table.insert(slots[slot], req_data[i])
            table.insert(slots[slot], req_data[i+1])
        end
    end
    
    local size = 0
    local thread = nil

    for k, v in pairs(slots) do
        size = size + 1
        thread = ngx.thread.spawn(multi_kvs, self, k, cmd, v)
        thread_pool[size] = thread
    end

    --批量发送keys返回的结果状态
    local rc, prefix, err = thread_wait(self, thread_pool)
    if rc ~= lhlh_common.LHLH_OK then
        prefix = lhlh_common.REDIS_CLUSTER_TYPE_ERROR_REPLY
        return lhlh_redis_proto:encode(err, prefix)
    end

    return lhlh_redis_proto:encode("OK", prefix)
end

--one key cmds
local function redis_key(self, req_data)
   
    local resp, prefix, err = lhlh_redis_cluster:send_cluster_command(nil, req_data[1], unpack(req_data, 2))
    if err then
        ngx.log(ngx.ERR, err)
	    
        prefix = lhlh_common.REDIS_CLUSTER_TYPE_ERROR_REPLY
        return lhlh_redis_proto:encode(err,prefix )
    end

    return lhlh_redis_proto:encode(resp, prefix)
end


local function proxy_key(self, req_data)
    return lhlh_proxy:process(req_data)
end


local redis_cmds =  {
    ["MGET"] = redis_mget_keys,
    ["DEL"] = redis_multi_keys,
    ["EXISTS"] = redis_multi_keys,
    ["MSET"] = redis_kvs, 
    ["PROXY"] = proxy_key
}


function _M.process(self, req_data)

    local handler = redis_cmds[upper(req_data[1])]
    if handler == nil then
        --one key cmds
        return redis_key(self, req_data)
    end

    return handler(self, req_data)
end


return _M
