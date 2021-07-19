local lhlh_common = require "module.lhlh_common"
local lhlh_metric_counter = require "module.lhlh_metric_counter"


local new_tab = lhlh_common.new_tab
local monitor_count = ngx.shared.monitor_count
local monitor_latency = ngx.shared.monitor_latency
local monitor_error = ngx.shared.monitor_error


local _M = new_tab(0, 15)
_M.version="0.0.1"


--query_count
function _M.query_count(self)
    lhlh_metric_counter:metric_incr(monitor_count, "query_count", 1)
end

function _M.get_query_count(self)
    return lhlh_metric_counter:metric_get(monitor_count, "query_count")
end

--latency
function _M.latency(self)
    local begin = ngx.ctx.now and tonumber(ngx.ctx.now) or 0
    local request_time = ngx.usec() - begin
    lhlh_metric_counter:metric_incr(monitor_latency, "latency", request_time)
end

function _M.get_latency(self)
    return lhlh_metric_counter:metric_get(monitor_latency, "latency")
end

--error
function _M.error_count()
    lhlh_metric_counter:metric_incr(monitor_error, "error_count", 1)
end

function _M.get_error_count(self)
   return lhlh_metric_counter:metric_get(monitor_error, "error_count")
end

-- try count
function _M.try_count(self)
    lhlh_metric_counter:metric_incr(monitor_error, "retry_count", 1)
end

function _M.get_try_count(self)
    return lhlh_metric_counter:metric_get(monitor_error, "retry_count")
end

-- moved count
function _M.moved_count(self)
    lhlh_metric_counter:metric_incr(monitor_error,  "moved_count", 1)
end

function _M.get_moved_count(self)
    return lhlh_metric_counter:metric_get(monitor_error, "moved_count")
end

-- ask count
function _M.ask_count(self)
    lhlh_metric_counter:metric_incr(monitor_error, "ask_count", 1)
end

function _M.get_ask_count(self)
    return lhlh_metric_counter:metric_get(monitor_error,  "ask_count")
end


return _M
