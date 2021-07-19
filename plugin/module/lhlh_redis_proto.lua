local lhlh_common = require "module.lhlh_common"

local sub = string.sub
local byte = string.byte
local null = ngx.null
local type = type
local tonumber = tonumber
local tostring = tostring

local new_tab = lhlh_common.new_tab
local _M = new_tab(0, 4)

_M._VERSION = '0.01'


function _M.decode(self, sock, request)
    local line, err = sock:receive()
    if not line or line == "" then
        if err and err == "timeout" then
            ngx.log(ngx.WARN, "receive failed: ", err)
        end
        return nil, 0, err
    end

    local prefix = byte(line)

    if prefix == lhlh_common.REDIS_CLUSTER_TYPE_BULK_REPLY  then    -- char '$'
        
        local size = tonumber(sub(line, 2))
        if size < 0 then
            return null, prefix
        end

        local data, err = sock:receive(size)
        if not data then
            if err == "timeout" then
            	ngx.log(ngx.WARN, "receive failed: ", err)
            end
            return nil, prefix, err
        end

        local dummy, err = sock:receive(2) -- ignore CRLF
        if not dummy then
            return nil, prefix, err
        end

        return data, prefix

    elseif prefix == lhlh_common.REDIS_CLUSTER_TYPE_STATUS_REPLY  then    -- char '+'

        return sub(line, 2), prefix

    elseif prefix == lhlh_common.REDIS_CLUSTER_TYPE_MULTI_BULK_REPLY  then -- char '*'
        local n = tonumber(sub(line, 2))

        if n < 0 then
            return null, prefix
        end

        local vals = new_tab(n, 0);
        local nvals = 0
        for i = 1, n do
            local res, err = self:decode(sock, request)
            if res then
                nvals = nvals + 1
                vals[nvals] = res

            elseif res == nil then
                return nil, prefix, err

            else
                -- be a valid redis error value
                nvals = nvals + 1
                vals[nvals] = {false, err}
            end
        end

        return vals, prefix

    elseif prefix == lhlh_common.REDIS_CLUSTER_TYPE_INTEGER_REPLY  then    -- char ':'
        return tonumber(sub(line, 2)), prefix

    elseif prefix == lhlh_common.REDIS_CLUSTER_TYPE_ERROR_REPLY  then    -- char '-'

        return false, prefix, sub(line, 2)

    else
        return nil, prefix,  "unkown prefix: \"" .. prefix .. "\""
    end
end


function _M.encode(self, args, prefix)
    local                               nargs
    local                               req
    local                               nbits
    local                               arg

    if prefix == lhlh_common.REDIS_CLUSTER_TYPE_BULK_REPLY  then    -- char '$'
        nbits = 1
        arg = args
        if arg == ngx.null or arg == nil then
            req = new_tab(3, 0)
            req[nbits] = "$"
            req[nbits + 1] = -1
            req[nbits + 2] = "\r\n"
        
        else
            req = new_tab(5, 0)
            req[nbits] = "$"
            req[nbits + 1] = #arg
            req[nbits + 2] = "\r\n"
            req[nbits + 3] = arg
            req[nbits + 4] = "\r\n"

        end
    
    elseif prefix == lhlh_common.REDIS_CLUSTER_TYPE_STATUS_REPLY  then    -- char '+'
        req = new_tab(3, 0)
        req[1] = "+"
        req[2] = args
        req[3] = "\r\n"

    elseif prefix == lhlh_common.REDIS_CLUSTER_TYPE_MULTI_BULK_REPLY  then -- char '*'
        nargs = #args
        req = new_tab(nargs * 5 + 1, 0)
        req[1] = "*" .. nargs .. "\r\n"
        nbits = 2

        for i = 1, nargs do
            local arg = args[i]
            if arg == ngx.null or arg == nil then
                
                req[nbits] = "$"
                req[nbits + 1] = -1
                req[nbits + 2] = "\r\n"
                
                nbits = nbits + 3
            else
                req[nbits] = "$"
                req[nbits + 1] = #arg
                req[nbits + 2] = "\r\n"
                req[nbits + 3] = arg
                req[nbits + 4] = "\r\n"

                nbits = nbits + 5
            end
        end

    elseif prefix == lhlh_common.REDIS_CLUSTER_TYPE_INTEGER_REPLY  then    -- char ':'
        req = new_tab(3, 0)
        req[1] = ":"
        req[2] = tostring(args)
        req[3] = "\r\n"

    elseif prefix == lhlh_common.REDIS_CLUSTER_TYPE_ERROR_REPLY  then    -- char '-'
        req = new_tab(3, 0)
        req[1] = "-"
        req[2] = args
        req[3] = "\r\n"
    end
    
    return req
end


return _M
