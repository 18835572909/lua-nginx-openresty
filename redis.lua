location /lua/redis{
	default_type "text/html";
	
	content_by_lua_block{
	
		-- 引入redis
		local redis = require 'resty.redis'
		-- 创建redis对象
		local redisClient = redis:new()
		-- 设置timeout
		redisClient:set_timeout(1000)
		
		-- connect
		local ok,err = redisClient:connect('localhost',6380)
		-- 检测连接结果
		if not ok then
			ngx.say('redis connect fail!')
			return
		end
		-- 设置psw
		redisClient:auth('LOQYkOKUgUBrywjo')
		
		-- 存入数据
		ok,err = redisClient:set('lua-key','lua-value')
		if not ok then
			ngx.say('redis set fail!')
			return
		end
		
		-- 取数据
		local res,err = redisClient:get('lua-key')
		ngx.say('lua-key:'..res)
		
		-- close
		redisClient:close()
	}
}