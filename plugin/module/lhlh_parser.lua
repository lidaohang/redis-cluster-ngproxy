local lhlh_redis_proto = require "module.lhlh_redis_proto"
local lhlh_common = require "module.lhlh_common"
local lhlh_metric = require "module.lhlh_metric"

local new_tab = lhlh_common.new_tab

local _M = new_tab(0, 2)

_M._VERSION = '0.01'


function _M.parse_req(self, client_sock)

    local res, _, err  = lhlh_redis_proto:decode(client_sock)
    if err then
        return res, nil, err
    end

    return res
end


function _M.parse_rsp(self, client_sock, rsp_data)
    local ok, err = client_sock:send(rsp_data)
    if not ok then
       ngx.log(ngx.ERR, "server: failed to send:", err)
    end

    lhlh_metric:query_count()
    lhlh_metric:latency()

    return lhlh_common.LHLHOK
end





return _M
