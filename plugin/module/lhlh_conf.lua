local lhlh_ini_file = require "module.lhlh_ini_file"
local lhlh_common = require "module.lhlh_common"

local table = table
local pairs = pairs
local io_open = io.open
local tonumber = tonumber
local sub = string.sub
local find = string.find

local new_tab = lhlh_common.new_tab
local clear_tab = lhlh_common.clear_tab

local _M = new_tab(0, 4)
_M._VERSION = '0.01'


function _M.load_config(self)
    
    local path = lhlh_common.PROXY_CONFIG_PATH
    local conf, err = lhlh_ini_file:parse_file(path)
    if not conf then
        ngx.log(ngx.ERR, "failed to parse proxy.ini: ", err)
        return
    end
    g_config["proxy_timeout"] = conf["proxy"]["proxy_timeout"] and conf["proxy"]["proxy_timeout"] or 2000
    g_config["proxy_keepalive_size"] = conf["proxy"]["keepalive_size"] and conf["proxy"]["keepalive_size"] or 1000
    g_config["proxy_keepalive_duration"] = conf["proxy"]["keepalive_duration"] and conf["proxy"]["keepalive_duration"] or 20000
    g_config["proxy_try_count"] = conf["proxy"]["try_count"] and conf["proxy"]["try_count"] or 5
    g_config["proxy_cluster_id"] = conf["proxy"]["cluster_id"] and conf["proxy"]["cluster_id"] or "bj001"
    g_config["slowlog_time"] = conf["proxy"]["slowlog_time"] and conf["proxy"]["slowlog_time"] or 100
 
    local nodes = conf["proxy"]["node_list"]
    if not nodes then
        ngx.log(ngx.ERR, "failed to node_list is not empty: ")
        return
    end

    local node_list = new_tab(0, #nodes)
    
    local t = lhlh_common:string_split(nodes, ",")
    for i = 1, #t do
        local node = lhlh_common:string_split(t[i], ":")
	    table.insert(g_redis_cluster_nodes, {node[1], tonumber(node[2])}) 
    end


    local filename = conf["ip_whitelist"]["path"]
    local fp, err = io_open(filename)
    if not fp then
        ngx.log(ngx.ERR, "failed to open file: " .. (err or ""))
        return
    end
   
    clear_tab(g_ip_whitelist)
    for line in fp:lines() do
        g_ip_whitelist[line] = true
    end
    fp:close()
    
    filename = conf["cmd_whitelist"]["path"]
    fp, err = io_open(filename)
    if not fp then
        ngx.log(ngx.ERR, "failed to open file: " .. (err or ""))
        return
    end
    
    clear_tab(g_cmd_whitelist)
    for line in fp:lines() do
        g_cmd_whitelist[line] =  true
    end
    fp:close()

end

return _M

