local lhlh_common = require "module.lhlh_common"
local lhlh_metric = require "module.lhlh_metric"
local lhlh_redis_proto = require "module.lhlh_redis_proto"
local lhlh_conf_version = require "module.lhlh_conf_version"


local upper = string.upper
local new_tab = lhlh_common.new_tab
local _M = new_tab(0, 2)

_M._VERSION = '0.01'


local function proxy_count(self)
    local prefix = lhlh_common.REDIS_CLUSTER_TYPE_INTEGER_REPLY
    return lhlh_redis_proto:encode(lhlh_metric:get_query_count(), prefix)
end


local function proxy_error(self)
    local prefix = lhlh_common.REDIS_CLUSTER_TYPE_INTEGER_REPLY
    return lhlh_redis_proto:encode(lhlh_metric:get_error_count(), prefix)
end


local function proxy_moved(self)
    local prefix = lhlh_common.REDIS_CLUSTER_TYPE_INTEGER_REPLY
    return lhlh_redis_proto:encode(lhlh_metric:get_moved_count(), prefix)
end


local function proxy_ask(self)
    local prefix = lhlh_common.REDIS_CLUSTER_TYPE_INTEGER_REPLY
    return lhlh_redis_proto:encode(lhlh_metric:get_ask_count(), prefix)
end


local function proxy_reload(self)
    lhlh_conf_version:set_version()

    local prefix = lhlh_common.REDIS_CLUSTER_TYPE_STATUS_REPLY
    return lhlh_redis_proto:encode("OK", prefix)
end


local function proxy_latency(self)
    local prefix = lhlh_common.REDIS_CLUSTER_TYPE_INTEGER_REPLY
    return lhlh_redis_proto:encode(lhlh_metric:get_latency(), prefix)
end

local function proxy_version(self)

    local prefix = lhlh_common.REDIS_CLUSTER_TYPE_BULK_REPLY
    return lhlh_redis_proto:encode(self._VERSION, prefix)
end

local proxy_cmds =  {
    ["LATENCY"] = proxy_latency,
    ["COUNT"] = proxy_count,
    ["ERROR"] = proxy_error,
    ["MOVED"] = proxy_moved,
    ["ASK"] = proxy_ask, 
    ["RELOAD"] = proxy_reload,
    ["VERSION"] = proxy_version
}


function _M.process(self, req_data)

    local cmd = req_data[2]

    local handler = proxy_cmds[upper(cmd)]
    if handler == nil then
        return lhlh_common.REDIS_CLUSTER_ILLEGAL 
    end

    return handler(self)
end


return _M
