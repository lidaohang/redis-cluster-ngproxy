local lhlh_redis = require "module.lhlh_redis"
local lhlh_common = require "module.lhlh_common"
local lhlh_metric = require "module.lhlh_metric"

local tonumber = tonumber
local new_tab = lhlh_common.new_tab


local _M = new_tab(0, 2)
_M._VERSION = '0.01'


local function get_redis_link(host, port, timeout)

    local r = lhlh_redis:new()
    r:set_timeout(timeout)

    local ok, err = r:connect(host, port)
    if not ok then
        lhlh_metric:error_count()
        ngx.log(ngx.ERR, "failed to connect: ", err, " host: ", host, " port: ", port)
        return nil
    end

    return r
end


local function get_random_connection(self)
	
    local timeout = g_config["proxy_timeout"] 
    local startup_nodes = g_redis_cluster_nodes

    local max_count = 5
    math.randomseed(tostring(os.time()):reverse():sub(1, 7))
    
    for i = 1, max_count do
        local num = math.random(#startup_nodes)

        local node = startup_nodes[num]
        local r = get_redis_link(node[1], node[2], timeout)
        if r then
            local result, _, err = r:ping()
            if result == "PONG" then
                return r
            end
            r:close()
        end
    end

    return nil
end


local function get_connection_by_slot(self, slot)
    
    local timeout = g_config["proxy_timeout"] 
    local node = g_redis_cluster_slots[slot]
    
    if node == nil then
        return get_random_connection(self)
    end

    return get_redis_link(node[1], node[2], timeout)
end


local function get_connection_by_key(self, key)
    
    local timeout = g_config["proxy_timeout"] 
    local slot = ngx.redis_slot(key)
    local node = g_redis_cluster_slots[slot]

    if node == nil then
        return get_random_connection(self)
    end

    return get_redis_link(node[1], node[2], timeout)
end


local function cluster_error(self, err)

    local timeout = g_config["proxy_timeout"] 
    local err_split = lhlh_common:string_split(err, " ")
    
    if err_split[1] == "TRYAGAIN" then
        return get_random_connection(self)
    end

    if err_split[1] ~= "ASK" and err_split[1] ~= "MOVED" then
        lhlh_metric:error_count()
        return nil
    end
    
    --ASK/MOVED
    local slot = tonumber(err_split[2])
    local node_ip_port = lhlh_common:string_split(err_split[3], ":")

    local port = tonumber(node_ip_port[2])
    if port <= 0 then
        return get_random_connection(self)
    end

    local node = { node_ip_port[1], port, err_split[3]}
    if err_split[1] == "MOVED" then
        g_redis_cluster_slots[slot] = node
    
        lhlh_metric:moved_count()
    end

    local r = get_redis_link(node[1], node[2], timeout)
    if not r then
        return get_random_connection(self)
    end

    if err_split[1] == "ASK" then
        r:asking()
        
        lhlh_metric:ask_count()
    end
    
    return r
end


function _M.send_cluster_command(self, slotid, cmd, ...)
   
    local argv = {...}
    local r = nil
    local last_err = nil
    local last_prefix = nil

    local ttl = g_config["proxy_try_count"] 
    if not slotid then
        r = get_connection_by_key(self, argv[1]) 
    elseif slotid then
        r = get_connection_by_slot(self, slotid)
    else
        r = get_random_connection(self)
    end

    if not r then
        r = get_random_connection(self)
        if not r then
            return nil, lhlh_common.REDIS_CLUSTER_TYPE_ERROR_REPLY, lhlh_common.REDIS_CLUSTER_TIMEOUT_ERR
        end
    end

    local keepalive_duration = g_config["proxy_keepalive_duration"]
    local keepalive_size = g_config["proxy_keepalive_size"]
    
    for i = 0, ttl  do
        
        local result, prefix, err = r[cmd](r, ...)
        r:set_keepalive(keepalive_duration, keepalive_size)
    
        if err == nil and result ~= nil then
            if i > 0 then
                ngx.ctx.retry_count = i
            end
            return result, prefix, nil
        end
        
        last_err = err
        last_prefix = prefix

        --ngx.log(ngx.ERR, "err: ", err, " try_count:", i, " command:", argv[1])

        r = cluster_error(self, err)
        if not r then
            break
        end
    end
    
    return nil, last_prefix, last_err
end


return _M
