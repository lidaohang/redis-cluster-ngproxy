#ifndef DDEBUG
#define DDEBUG 0
#endif
#include "ddebug.h"


#include "ngx_stream_lua_redis_parser.h"

//static void *redis_null = NULL;

static const char *ngx_stream_lua_redis_parse_line(const char *src, const char *last, int *dst_len);
static const char * ngx_stream_lua_redis_parse_bulk(const char *src, const char *last,int *dst_len);
static int ngx_stream_lua_redis_parse_multi_bulk(lua_State *L, char **src, const char *last);
//static size_t get_num_size(size_t i);


int
ngx_stream_lua_redis_parse(lua_State *L, char **src, size_t len)
{
    char            *p;
    const char      *last;
    const char      *dst;
    int           dst_len;
    lua_Number       num;
    int              rc;

    p = *src;

    if (len == 0) {
        lua_pushliteral(L, "empty reply");
        lua_pushnumber(L, BAD_REPLY);
        return 2;
    }

    last = p + len;

    switch (*p) {
    case '+':
        p++;
        dst = ngx_stream_lua_redis_parse_line(p, last, &dst_len);

        if (dst_len == -2) {
            lua_pushliteral(L, "bad status reply");
            lua_pushnumber(L, BAD_REPLY);
            return 2;
        }

        *src += dst_len + 1 + sizeof("\r\n") - 1;

        lua_pushlstring(L, dst, dst_len);
        lua_pushnumber(L, STATUS_REPLY);
        break;

    case '-':
        p++;
        dst = ngx_stream_lua_redis_parse_line(p, last, &dst_len);

        if (dst_len == -2) {
            lua_pushliteral(L, "bad error reply");
            lua_pushnumber(L, BAD_REPLY);
            return 2;
        }

        *src += dst_len + 1 + sizeof("\r\n") - 1;

        lua_pushlstring(L, dst, dst_len);
        lua_pushnumber(L, ERROR_REPLY);
        break;

    case ':':
        p++;
        dst = ngx_stream_lua_redis_parse_line(p, last, &dst_len);

        if (dst_len == -2) {
            lua_pushliteral(L, "bad integer reply");
            lua_pushnumber(L, BAD_REPLY);
            return 2;
        }

        *src += dst_len + 1 + sizeof("\r\n") - 1;

        lua_pushlstring(L, dst, dst_len);
        num = lua_tonumber(L, -1);
        lua_pop(L, 1);

        lua_pushnumber(L, num);
        lua_pushnumber(L, INTEGER_REPLY);
        break;

    case '$':
        p++;
        dst = ngx_stream_lua_redis_parse_bulk(p, last, &dst_len);

        if (dst_len == -2) {
            lua_pushliteral(L, "bad bulk reply");
            lua_pushnumber(L, BAD_REPLY);
            return 2;
        }

        if (dst_len == -1) {
            *src = (char *) dst + sizeof("\r\n") - 1;

            /* lua_pushlightuserdata(L, redis_null); */
            lua_pushnil(L);
            lua_pushnumber(L, BULK_REPLY);
            return 2;
        }

        *src = (char *) dst + dst_len + sizeof("\r\n") - 1;

        lua_pushlstring(L, dst, dst_len);
        lua_pushnumber(L, BULK_REPLY);
        break;

    case '*':
        p++;
        rc = ngx_stream_lua_redis_parse_multi_bulk(L, &p, last);

        if (rc != PARSE_OK) {
            lua_pushliteral(L, "bad multi bulk reply");
            lua_pushnumber(L, BAD_REPLY);
            return 2;
        }

        /* rc == PARSE_OK */

        *src = (char *) p;

        lua_pushnumber(L, MULTI_BULK_REPLY);
        break;

    default:
        lua_pushliteral(L, "invalid reply");
        lua_pushnumber(L, BAD_REPLY);
        break;
    }

    return 2;
}


static const char *
ngx_stream_lua_redis_parse_line(const char *src, const char *last, int *dst_len)
{
    const char  *p = src;
    int          seen_cr = 0;

    while (p != last) {

        if (*p == '\r') {
            seen_cr = 1;

        } else if (seen_cr) {
            if (*p == '\n') {
                *dst_len = p - src - 1;
                return src;
            }

            seen_cr = 0;
        }

        p++;
    }

    /* CRLF not found at all */
    *dst_len = -2;
    return NULL;
}


#define CHECK_EOF if (p >= last) goto invalid;


static const char *
ngx_stream_lua_redis_parse_bulk(const char *src, const char *last, int *dst_len)
{
    const char *p = src;
    ssize_t     size = 0;
    const char *dst;

    CHECK_EOF

    /* read the bulk size */

    if (*p == '-') {
        p++;
        CHECK_EOF

        while (*p != '\r') {
            if (*p < '0' || *p > '9') {
                goto invalid;
            }

            p++;
            CHECK_EOF
        }

        /* *p == '\r' */
        ssize_t  len = last - p;
        ssize_t  tmp_len = size + sizeof("\r\n") - 1;
        if (len < tmp_len) {
            goto invalid;
        }

        p++;

        if (*p++ != '\n') {
            goto invalid;
        }

        *dst_len = -1;
        return p - (sizeof("\r\n") - 1);
    }

    while (*p != '\r') {
        if (*p < '0' || *p > '9') {
            goto invalid;
        }

        size *= 10;
        size += *p - '0';

        p++;
        CHECK_EOF
    }

    /* *p == '\r' */

    p++;
    CHECK_EOF

    if (*p++ != '\n') {
        goto invalid;
    }

    /* read the bulk data */

    ssize_t  len = last - p;
    ssize_t  tmp_len = size + sizeof("\r\n") - 1;
    if (len < tmp_len) {
        goto invalid;
    }

    dst = p;

    p += size;

    if (*p++ != '\r') {
        goto invalid;
    }

    if (*p++ != '\n') {
        goto invalid;
    }

    *dst_len = size;
    return dst;

invalid:
    *dst_len = -2;
    return NULL;
}


static int
ngx_stream_lua_redis_parse_multi_bulk(lua_State *L, char **src, const char *last)
{
    const char      *p = *src;
    int              count = 0;
    int              i;
    int              dst_len;
    const char      *dst;

    dd("enter multi bulk parse");

    CHECK_EOF

    while (*p != '\r') {
        if (*p == '-') {

            p++;
            CHECK_EOF

            if (*p < '0' || *p > '9') {
                goto invalid;
            }

            while (*p != '\r') {
                p++;
                CHECK_EOF
            }

            count = -1;
            break;
        }

        if (*p < '0' || *p > '9') {
            dd("expecting digit, but found %c", *p);
            goto invalid;
        }

        count *= 10;
        count += *p - '0';

        p++;
        CHECK_EOF
    }

    dd("count = %d", count);

    /* *p == '\r' */

    p++;
    CHECK_EOF

    if (*p++ != '\n') {
        goto invalid;
    }

    dd("reading the individual bulks");

    if (count == -1) {

        /* lua_pushlightuserdata(L, redis_null); */
        lua_pushnil(L);

        *src = (char *) p;
        return PARSE_OK;
    }

    lua_createtable(L, count, 0);

    for (i = 1; i <= count; i++) {
        CHECK_EOF

        switch (*p) {
        case '+':
        case '-':
        case ':':
            p++;
            dst = ngx_stream_lua_redis_parse_line(p, last, &dst_len);
            break;

        case '$':
            p++;
            dst = ngx_stream_lua_redis_parse_bulk(p, last, &dst_len);
            break;

        default:
            goto invalid;
        }

        if (dst_len == -2) {
            dd("bulk %d reply parse fail for multi bulks", i);
            return PARSE_ERROR;
        }

        if (dst_len == -1) {
            lua_pushnil(L);
            p = dst + sizeof("\r\n") - 1;

        } else {
            lua_pushlstring(L, dst, dst_len);
            p = dst + dst_len + sizeof("\r\n") - 1;
        }

        lua_rawseti(L, -2, i);
    }

    *src = (char *) p;

    return PARSE_OK;

invalid:
    return PARSE_ERROR;
}
