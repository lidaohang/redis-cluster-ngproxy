local lhlh_redis = require "module.lhlh_redis"
local lhlh_common = require "module.lhlh_common"

local sub = string.sub
local find = string.find
local char = string.char
local tonumber = tonumber
local new_tab = lhlh_common.new_tab

local _M = new_tab(0, 2)
_M._VERSION = '0.02'

lhlh_redis.add_commands("cluster")


local function get_redis_link(host, port, timeout)
    local r = lhlh_redis:new()

    r:set_timeout(timeout)
    
    local ok, err = r:connect(host, port)
    if not ok then
        ngx.log(ngx.ERR, "failed to connect: ", err, " host: ", host, " port: ", port)
        return nil
    end

    return r
end


local function update_cluster_nodes(self, results, node)
	
    local lines = lhlh_common:string_split(results, char(10), 1000)
    
    for line_index = 1, #lines do
        local line = lines[line_index]
        local fields = lhlh_common:string_split(line, " ")
        if #fields > 1 then
            local addr_str = fields[2]
            local addr = nil

            if addr_str == ":0" then
                addr = { node[1], tonumber(node[2]) }
            else
               local host_port = lhlh_common:string_split(addr_str, ":", 2)
               addr = { host_port[1], tonumber(host_port[2]) }
    	       g_redis_cluster_nodes[#(g_redis_cluster_nodes) + 1] = addr 
            end
             
            for slot_index = 9, #fields do
                local slot = fields[slot_index]

                if not slot then 
                    break 
                end
                        
                if sub(slot, 1, 1) ~= "[" then
                    local range = lhlh_common:string_split(slot, "-", 2)
                    local first = tonumber(range[1])
                    local last = first
                    if #range >= 2 then
                        last = tonumber(range[2])
                    end

                    for ind = first, last do
                        g_redis_cluster_slots[ind] = addr
                    end
                end
            end
        end
    end
end


function _M.cluster_nodes(self)

    local timeout = g_config["proxy_timeout"] 
    local node_list = g_redis_cluster_nodes 
    local keepalive_duration = g_config["proxy_keepalive_duration"]
    local keepalive_size = g_config["proxy_keepalive_size"]

    for i = 1, #node_list do
        local node = node_list[i]
        local r = get_redis_link(node[1], node[2], timeout)
        if  r then
            local results, _, err = r:cluster("nodes")

	        if not results then
	            r:close()
	        else 
                update_cluster_nodes(self, results, node)
                r:set_keepalive(keepalive_duration, keepalive_size)
	            break
	        end
        end
    end

end


return _M
