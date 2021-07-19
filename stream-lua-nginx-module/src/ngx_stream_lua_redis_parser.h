#ifndef _NGX_STREAM_LUA_REDIS_PARSER_H_INCLUDED_
#define _NGX_STREAM_LUA_REDIS_PARSER_H_INCLUDED_

#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#include "ngx_stream_lua_common.h"

enum {
    BAD_REPLY           = 0,
    STATUS_REPLY        = 1,
    ERROR_REPLY         = 2,
    INTEGER_REPLY       = 3,
    BULK_REPLY          = 4,
    MULTI_BULK_REPLY    = 5
};


enum {
    PARSE_OK    = 0,
    PARSE_ERROR = 1
};


int
ngx_stream_lua_redis_parse(lua_State *L, char **src, size_t len);

#endif /* _NGX_STREAM_LUA_REDIS_PARSER_H_INCLUDED_ */

