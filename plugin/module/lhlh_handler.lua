local lhlh_parser = require "module.lhlh_parser"
local lhlh_process = require "module.lhlh_process"
local lhlh_common = require "module.lhlh_common"
local lhlh_conf = require "module.lhlh_conf"
local lhlh_whitelist = require "module.lhlh_whitelist"
local lhlh_redis_command = require "module.lhlh_redis_command"
local lhlh_redis_slot = require "module.lhlh_redis_slot"
local lhlh_conf_version = require "module.lhlh_conf_version"


local new_tab = lhlh_common.new_tab

local _M = new_tab(0, 2)
_M._VERSION = '0.01'


function _M.handle(self, client_sock)

    local req_data, _, err = lhlh_parser:parse_req(client_sock)
    if err or req_data == nil or req_data == ngx.null then
        return lhlh_common.LHLH_ERROR
    end
    
    --refresh config
    local config_version = lhlh_conf_version:get_version()
    if lhlh_conf._VERSION ~= config_version then

	    lhlh_conf:load_config() 
    	lhlh_conf._VERSION = config_version
    end

    --refresh redis_cluster_map
    if lhlh_redis_slot._VERSION ~= config_version then
    	
        lhlh_redis_slot:cluster_nodes()
	    lhlh_redis_slot._VERSION = config_version
    end

    --ip whitelist
    local rc = lhlh_whitelist:auth()
    if rc ~= lhlh_common.LHLH_OK then
        local rsp_data = lhlh_common.REDIS_CLUSTER_NO_AUTH
       	lhlh_parser:parse_rsp(client_sock, rsp_data) 
        
        return lhlh_common.LHLH_OK
    end
  
    --command whitelist
    rc = lhlh_redis_command:check_cmd(req_data[1])
    if rc ~= lhlh_common.LHLH_OK then
        local rsp_data = lhlh_common.REDIS_CLUSTER_ILLEGAL
        lhlh_parser:parse_rsp(client_sock, rsp_data) 
        
        return lhlh_common.LHLH_OK
    end

    --redis cluster process
    ngx.ctx.now = ngx.usec()
    local rsp_data = lhlh_process:process(req_data)
    if not rsp_data then
        local rsp_data = lhlh_common.REDIS_CLUSTER_SERVER_ERR 
        lhlh_parser:parse_rsp(client_sock, rsp_data) 
	
        return lhlh_common.LHLH_OK
    end

    lhlh_parser:parse_rsp(client_sock, rsp_data) 

    return lhlh_common.LHLH_OK
end

return _M
