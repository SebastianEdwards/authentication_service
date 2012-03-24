namespace, key, attributes = KEYS[1], KEYS[2], KEYS[3]
if key == "" then key = redis.call('incr', namespace .. ":latest_id"); end
redis.call('set', namespace .. ":" .. key, attributes)
return key
