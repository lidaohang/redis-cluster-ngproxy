local lhlh_common = require "module.lhlh_common"

local new_tab = lhlh_common.new_tab


local _M = new_tab(0, 6)
_M.version="0.0.1"


function _M.metric_incr(self, dict,  name ,value)
    local res, err = dict:incr(name, value)
    if not res or err == "not found" then
        local ok, err = dict:set(name, value)
        if err then
            ngx.log(ngx.ERR, "failed to moitor incr ", err)
        end
    end
end


function _M.metric_get(self, dict, name)
    local res = dict:get(name)
    if not res then
        return 0
    end
    
    return res
end

return _M
