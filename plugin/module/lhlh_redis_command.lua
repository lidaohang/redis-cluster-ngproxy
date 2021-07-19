local lhlh_common = require "module.lhlh_common"

local upper = string.upper


local new_tab = lhlh_common.new_tab
local _M = new_tab(0, 4)

_M._VERSION = '0.01'



function _M.check_cmd(self, cmd)

    if g_cmd_whitelist[upper(cmd)] == true then
        return lhlh_common.LHLH_OK
    end

    return lhlh_common.LHLH_ERROR
end


return _M
