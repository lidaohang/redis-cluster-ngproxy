
local lhlh_common = require "module.lhlh_common"

local io_open = io.open
local new_tab = lhlh_common.new_tab
local _M = new_tab(0, 2)

_M._VERSION = '0.01'


function _M.auth(self)
    local                   addr
    
    addr = ngx.var.remote_addr
    
    if g_ip_whitelist[addr] == true then
        return lhlh_common.LHLH_OK
    end

    return lhlh_common.LHLH_ERROR
end

return _M
