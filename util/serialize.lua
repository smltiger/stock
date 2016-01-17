function serialize(filename, o)  
	file = io.open(filename, 'w')
	assert(file)

	_serialize(file, o)
end

local function _serialize(file, o)
	if type(o) == 'number' then
		file:write(o)
	elseif type(o) == 'string' then
		file:write(string.format("%q",o))
	elseif type(o) == 'table' then
		file:write('{\n')
		for k,v in pairs(o) do
			file:write(' ', k, ' = ')
			serialize(v)
			file:write(',\n')
		end
		file:write('}\n')
	else
		error('cannot serialize a '..type(o))
	end
	file:close()
end  


function unserialize(lua)  
    local t = type(lua)  
    if t == "nil" or lua == "" then  
        return nil  
    elseif t == "number" or t == "string" or t == "boolean" then  
        lua = tostring(lua)  
    else  
        error("can not unserialize a " .. t .. " type.")  
    end  
    lua = "return " .. lua  
    local func = loadstring(lua)  
    if func == nil then  
        return nil  
    end  
    return func()  
end  
