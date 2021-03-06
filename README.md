### redis cluster proxy

#### 说明
基于redis cluster-3.x开发的proxy，目前支持大部分指令，其他指令后续完善开发中


#### 安装方式
```
cd data-lhlh-ngproxy
./install.sh
```


##### 测试

```
redis-cli -p 8015 set abc 123
OK

redis-cli -p 8015 get abc
"123"
```



#### 支持的指令
- PING
- EXISTS
- PERSIST
- PTTL
- TTL
- TYPE
- DUMP
- DECR
- GET
- INCR
- STRLEN
- HGETALL
- HKEYS
- HLEN
- HVALS
- LLEN
- LPOP
- RPOP
- SCARD
- SMEMBERS
- SPOP
- ZCARD
- PFCOUNT
- EXPIRE
- EXPIREAT
- PEXPIRE
- PEXPIREAT
- APPEND
- DECRBY
- GETBIT
- GETSET
- INCRBY
- INCRBYFLOAT
- SETNX
- HEXISTS
- HGET
- LINDEX
- LPUSHX
- RPUSHX
- SISMEMBER
- ZRANK
- ZREVRANK
- ZSCORE
- GETRANGE
- PSETEX
- SETBIT
- SETEX
- SETRANGE
- HINCRBY
- HINCRBYFLOAT
- HSET
- HSETNX
- LRANGE
- LREM
- LSET
- LTRIM
- ZCOUNT
- ZLEXCOUNT
- ZINCRBY
- ZREMRANGEBYLEX
- ZREMRANGEBYRANK
- ZREMRANGEBYSCORE
- LINSERT
- SORT
- BITCOUNT
- BITPOS
- SET
- HDEL
- HMGET
- HMSET
- HSCAN
- LPUSH
- RPUSH
- SADD
- SREM
- SRANDMEMBER
- SSCAN
- PFADD
- ZADD
- ZRANGE
- ZRANGEBYSCORE
- ZREM
- ZREVRANGE
- ZRANGEBYLEX
- ZREVRANGEBYLEX
- ZREVRANGEBYSCORE
- ZSCAN
- MGET
- MSET
- DEL
- PROXY

#### 多key操作指令
- mget,mset 会进行拆解，如果是同一个slot就作为一组mget发起一次网络请求
