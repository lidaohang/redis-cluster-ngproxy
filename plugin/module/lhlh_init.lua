local lhlh_conf = require "module.lhlh_conf"
local lhlh_common = require "module.lhlh_common"
local lhlh_conf_version = require "module.lhlh_conf_version"

local new_tab = lhlh_common.new_tab

g_config = new_tab(0, 20)
g_ip_whitelist = new_tab(0, 20)
g_cmd_whitelist = new_tab(0, 120)
g_redis_cluster_slots = new_tab(16384, 0)
g_redis_cluster_nodes = new_tab(0, 500)


local function init()

    local config_version = lhlh_conf_version:get_version()
    
    lhlh_conf:load_config() 
    lhlh_conf._VERSION = config_version
end

init()
