
/*
 * Copyright (C) Xiaozhe Wang (chaoslawful)
 * Copyright (C) Yichun Zhang (agentzh)
 */


#ifndef DDEBUG
#define DDEBUG 0
#endif
#include "ddebug.h"


#include "ngx_stream_lua_time.h"
#include "ngx_stream_lua_util.h"


static int ngx_stream_lua_ngx_today(lua_State *L);
static int ngx_stream_lua_ngx_time(lua_State *L);
static int ngx_stream_lua_ngx_now(lua_State *L);
static int ngx_stream_lua_ngx_localtime(lua_State *L);
static int ngx_stream_lua_ngx_utctime(lua_State *L);
static int ngx_stream_lua_ngx_update_time(lua_State *L);


static int
ngx_stream_lua_ngx_today(lua_State *L)
{
    time_t                   now;
    ngx_tm_t                 tm;
    u_char                   buf[sizeof("2010-11-19") - 1];

    now = ngx_time();
    ngx_gmtime(now + ngx_cached_time->gmtoff * 60, &tm);

    ngx_sprintf(buf, "%04d-%02d-%02d", tm.ngx_tm_year, tm.ngx_tm_mon,
                tm.ngx_tm_mday);

    lua_pushlstring(L, (char *) buf, sizeof(buf));

    return 1;
}


static int
ngx_stream_lua_ngx_localtime(lua_State *L)
{
    ngx_tm_t                 tm;

    u_char buf[sizeof("2010-11-19 20:56:31") - 1];

    ngx_gmtime(ngx_time() + ngx_cached_time->gmtoff * 60, &tm);

    ngx_sprintf(buf, "%04d-%02d-%02d %02d:%02d:%02d", tm.ngx_tm_year,
                tm.ngx_tm_mon, tm.ngx_tm_mday, tm.ngx_tm_hour, tm.ngx_tm_min,
                tm.ngx_tm_sec);

    lua_pushlstring(L, (char *) buf, sizeof(buf));

    return 1;
}


static int
ngx_stream_lua_ngx_time(lua_State *L)
{
    lua_pushnumber(L, (lua_Number) ngx_time());

    return 1;
}


static int
ngx_stream_lua_ngx_now(lua_State *L)
{
    ngx_time_t              *tp;

    tp = ngx_timeofday();

    lua_pushnumber(L, (lua_Number) (tp->sec + tp->msec / 1000.0L));

    return 1;
}

static int
ngx_stream_lua_ngx_usec(lua_State *L)
{
    struct timeval          tv;
    //ngx_time_t             *tp;
    ngx_usec_int_t          us;

    ngx_gettimeofday(&tv);
    us = (ngx_usec_int_t) ((1000 * tv.tv_sec * 1000) + (tv.tv_usec / 1000)) + tv.tv_usec;

    //tp = ngx_timeofday();
    //us = (ngx_usec_int_t) ((1000 * tp->sec * 1000) + (tp->usec / 1000)) + tp->usec;

    lua_pushnumber(L, (lua_Number) us);

    return 1;
}


static int
ngx_stream_lua_ngx_update_time(lua_State *L)
{
    ngx_time_update();
    return 0;
}


static int
ngx_stream_lua_ngx_utctime(lua_State *L)
{
    ngx_tm_t       tm;
    u_char         buf[sizeof("2010-11-19 20:56:31") - 1];

    ngx_gmtime(ngx_time(), &tm);

    ngx_sprintf(buf, "%04d-%02d-%02d %02d:%02d:%02d", tm.ngx_tm_year,
                tm.ngx_tm_mon, tm.ngx_tm_mday, tm.ngx_tm_hour, tm.ngx_tm_min,
                tm.ngx_tm_sec);

    lua_pushlstring(L, (char *) buf, sizeof(buf));

    return 1;
}


void
ngx_stream_lua_inject_time_api(lua_State *L)
{
    lua_pushcfunction(L, ngx_stream_lua_ngx_utctime);
    lua_setfield(L, -2, "utctime");

    lua_pushcfunction(L, ngx_stream_lua_ngx_time);
    lua_setfield(L, -2, "get_now_ts"); /* deprecated */

    lua_pushcfunction(L, ngx_stream_lua_ngx_localtime);
    lua_setfield(L, -2, "get_now"); /* deprecated */

    lua_pushcfunction(L, ngx_stream_lua_ngx_localtime);
    lua_setfield(L, -2, "localtime");

    lua_pushcfunction(L, ngx_stream_lua_ngx_time);
    lua_setfield(L, -2, "time");

    lua_pushcfunction(L, ngx_stream_lua_ngx_now);
    lua_setfield(L, -2, "now");

    lua_pushcfunction(L, ngx_stream_lua_ngx_usec);
    lua_setfield(L, -2, "usec");


    lua_pushcfunction(L, ngx_stream_lua_ngx_update_time);
    lua_setfield(L, -2, "update_time");

    lua_pushcfunction(L, ngx_stream_lua_ngx_today);
    lua_setfield(L, -2, "get_today"); /* deprecated */

    lua_pushcfunction(L, ngx_stream_lua_ngx_today);
    lua_setfield(L, -2, "today");
}


#ifndef NGX_LUA_NO_FFI_API
double
ngx_stream_lua_ffi_now(void)
{
    ngx_time_t              *tp;

    tp = ngx_timeofday();

    return tp->sec + tp->msec / 1000.0;
}


long
ngx_stream_lua_ffi_time(void)
{
    return (long) ngx_time();
}
#endif /* NGX_LUA_NO_FFI_API */
