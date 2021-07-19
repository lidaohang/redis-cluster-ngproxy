
local find = string.find
local sub = string.sub

local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end

ok, clear_tab = pcall(require, "table.clear")
if not ok then
    clear_tab = function (tab)
	for k, _ in pairs(tab) do
            tab[k] = nil
        end
    end
end

local _M = new_tab(0, 6)
_M.version="0.0.1"
_M.new_tab = new_tab
_M.clear_tab = clear_tab

--[[ /******************************************
--    *状态
--        *
--        ******************************************/ --]]
_M.LHLH_OK = 0
_M.LHLH_ERROR = -1

--[[ /******************************************
--    *集群状态
--        *
--        ******************************************/ -
--        -]]
_M.REDIS_CLUSTER_ILLEGAL = "-ERR ILLEGAL CMD\r\n"
_M.REDIS_CLUSTER_NO_AUTH = "-ERR NO AUTH\r\n"
_M.REDIS_CLUSTER_SERVER_ERR = "-ERR SERVER INTERNAL\r\n"
_M.REDIS_CLUSTER_TIMEOUT_ERR = "ERR REDIS TIMEOUT"


_M.REDIS_CLUSTER_TYPE_INTEGER_REPLY = 58
_M.REDIS_CLUSTER_TYPE_ERROR_REPLY = 45
_M.REDIS_CLUSTER_TYPE_STATUS_REPLY = 43
_M.REDIS_CLUSTER_TYPE_BULK_REPLY = 36
_M.REDIS_CLUSTER_TYPE_MULTI_BULK_REPLY = 42


_M.PROXY_CONFIG_PATH = "/home/lhlh/data-lhlh-ngproxy/conf/ngproxy.ini"



function _M.string_split(self, str, delim, max)
    if str == nil or delim == nil then
        return nil 
    end 

    if max == nil or max <= 0 then
        max = 1000
    end 

    local t = new_tab(max, 0)
    local index = 1 
    local start = 1 
    for i = 1, max do
        local last, delim_last = find(str, delim, start, true)
        if last == nil or delim_last == nil then
            break
        end 

        t[i] = sub(str, start, last - 1)
        start = delim_last + 1 
        index = i + 1 
    end 
    t[index] = sub(str, start)
    return t
end




return _M
