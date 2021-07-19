local lhlh_common = require "module.lhlh_common"

local new_tab = lhlh_common.new_tab
local config = ngx.shared.config


local _M = new_tab(0, 6)
_M.version="0.0.1"


function _M.get_version(self)
    local res = config:get("config_version")
    if not res then
        return self:set_version()
    end 
    
    return res
end

function _M.set_version(self)
    local version = ngx.localtime()
    local ok, err = config:set("config_version", version)
    if err then
        ngx.log(ngx.ERR, "failed to config_set_version set", key, ": ", err)
    end
end

return _M
