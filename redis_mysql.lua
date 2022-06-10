--[[
 author: renhuibo
 date: 2022.06.10
--]]

# nginx的http中添加
http{
	# 全局引入lua模块
	init_by_lua_block{
		cjson = require "cjson"
		mysql = require "mysql"
		redis = require "redis"
	}
}

# nginx的server中添加
location /lua/test{
	default_type "text/html";
	charset utf-8;
	
	# 文件方式引入lua脚本
	content_by_lua_file lua/*.lua;
}


-- 连接redis
local function redis_connect()
	local redis_client = redis:new()
	local ok,err = redis_client.connect('127.0.0.1',6379)
	
	if not ok then	
		ngx.say('redis connect fail!',err)
		return
	end
	
	redis_client:auth('LOQYkOKUgUBrywjo')
	redis_client:set_timeout(1000)
	return redis_client
end	

-- 连接mysql
local function mysql_connect()
	local db = mysql:new()
	local ok,err = db:connect{
		host='127.0.0.1',
		port=3306,
		user='root',
		password='yZcAtpyAplHElK9w',
		database='itstack',
		max_packet_size=100,
		compact_arrays=false
	}
	
	if not ok then
		ngx.say('mysql connect fail!',err)
		return
	end
	
	db:set_timeout(1000)
	return db
end

-- mysql的curd
local function mysql_jdbc(db,sql)
	local res,err,errcode,sqlstate = db:query(sql)
	local res_json = cjson.encode(res)
	return res_json
end

-- 关闭资源	
local function close_all(db,redis_client)
	db:close()
	redis_client:close()
end

-- redis.get(key)
local function redis_get(key,redis_client)
	local res,err = redis_client:get(key)
	if not res then
		ngx.say('redis get fail!</br>',err)
		return
	end
	
	if res == ngx.null then
	   ngx.say('redis get null!</br>')
	   return ngx.null
	end
	
	local res_json = cjson.encode(res)
	ngx.say('redis value:</br>'..res_json..'</br>')	
	return res_json
end

-- mysql: findById
local function mysql_get_id(id,db,redis_client)
	local sql = 'SELECT * FROM user WHERE id = '..id
	local res_db = mysql_jdbc(db,sql)
	ngx.say('查询DB</br>'..res_db..'</br>')
	local redis_key_id = redis_key_prefix..id
	redis_client:set(redis_key_id,res_db)
	close_all(db,redis_client)
end
	
-- 业务处理
local function id_to_user(id)
	local redis_client = redis_connect()
	local redis_key_id = redis_key_prefix..id
	
	local redis_value = redis_get(redis_key_id,redis_client)
	if redis_value == ngx.null then
		mysql_get_id(id,mysql_connect(),redis_client)	
	else 
		redis_client:close()
	end
end

-- 调用lua脚本
redis_key_prefix = 'LUA#'
id = ngx.req.get_uri_args()['id']
id_to_user(id)
	
	
		






	
		