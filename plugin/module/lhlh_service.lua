local lhlh_handler = require "module.lhlh_handler"
local lhlh_common = require "module.lhlh_common"

local function cleanup()
    ngx.exit(0)
end
local client_sock, err = ngx.req.socket(true)
if err then
    ngx.log(ngx.ERR, "ngx.req.socket: ", err)
    ngx.exit(0)
end

local ok, err = ngx.on_abort(cleanup)
if err then
    ngx.log(ngx.ERR, "failed to register the on_abort callback: ",err)
    ngx.exit(0)
end

while not ngx.worker.exiting()  do

    local rc = lhlh_handler:handle(client_sock)
    if rc ~= lhlh_common.LHLH_OK then
	    break
    end

end

cleanup()
