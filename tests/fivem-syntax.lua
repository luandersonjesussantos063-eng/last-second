local p=io.popen("find fivem/resources -name '*.lua' -type f")
for path in p:lines() do assert(loadfile(path)) end
p:close()
print('All FiveM Lua files compile')
