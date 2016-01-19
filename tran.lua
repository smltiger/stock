require 'torch'

function split(str, reps)  
    local resultStrsList = {};  
    string.gsub(str, '[^' .. reps ..']+', function(w) table.insert(resultStrsList, w) end );  
    return resultStrsList;  
end  
  
--一行一行取用数据  
local function getRowContent(file)  
    local content;  
    local check = false  
    local count = 0  
    while true do  
        local t = file:read()  
        if not t then  
            if count == 0 then  
                check = true  
            end  
        break  
    end  
  
    if not content then  
        content = t  
    else  
        content = content..t  
    end  
  
    local i = 1  
    while true do    
        local index = string.find(t, "\"", i)    
        if not index then break end    
            i = index + 1    
            count = count + 1    
        end    
  
        if count % 2 == 0 then   
            check = true   
            break   
        end    
    end    
  
    if not check then    
        assert(1~=1)   
    end  
    --返回去掉空格的一行数据,还有方法没看明白，以后再修改  
    return content and (string.gsub(content, " ", ""))  
end  
  
function loadCsvFile(filePath)  
    -- 读取文件  
    local alls = {}  
    local file = io.open(filePath, "r")  
    while true do  
        local line = getRowContent(file)  
        if not line then  
            break  
        end  
        table.insert(alls, line)  
    end  
    --[[ 从第2行开始保存（第一行是标题，后面的行才是内容） 用二维数组保存：arr[ID][属性标题字符串] ]]  
    local titles = split(alls[1], ",")  
    local arrs = {}  
    for i = 2, #alls, 1 do  
        -- 一行中，每一列的内容,第一位为ID  
        local content = split(alls[i], ",")  
        arrs[i-1] = {}  
        -- 以标题作为索引，保存每一列的内容，取值的时候这样取：arrs[1].Title  
        for j = 1, #titles, 1 do  
            arrs[i-1][j] = content[j]  
        end  
    end  
    return arrs  
end  

--(t2-b2)/(t1-b1)分3种情况:<1,1-2,>2
--趋势分7种情况: b2>t1, b1+(t1-b1)/2 < b2 < t1, b1<b2<b1+(t1-b1)/2, b1+(t1-b1)/2<t2<t1,b1<t2<b1+(t1-b1)/2, t2<b1, t2>t1&b2<b1
--转换结果为: 1,2,3,4,5,6,7,8,9,0,a,b,c,d,e,f,g,h,i,j,k
function tranTrend(t1,b1,t2,b2)
	if type(t1) == 'string' then
		t1 = tonumber(t1)
	end
	if type(b1) == 'string' then
		b1 = tonumber(b1)
	end
	if type(t2) == 'string' then
		t2 = tonumber(t2)
	end
	if type(b2) == 'string' then
		b2 = tonumber(b2)
	end

	local con1,ret
	if t1-b1 == 0 then
		con1 = 0
	else
		con1 = (t2-b2)/(t1-b1)
	end

	if con1 < 1 then
		if b2 >= t1 then
			ret = '1'
		elseif b2 >= b1+(t1-b1)/2  and b2 <= t1 then
			ret = '2'
		elseif b2 >= b1 and b2 <= b1+(t1-b1)/2 then
			ret = '3'
		elseif t2 >= b1+(t1-b1)/2 and t2 <= t1 then
			ret = '4'
		elseif t2 >= b1 and t2 <= b1+(t1-b1)/2 then
			ret = '5'
		elseif t2 <= b1 then
			ret = '6'
		elseif t2>=t1 and b2<=b1 then
			ret = '7'
		else
			print('unmatched',t1,b1,t2,b2)
		end
	elseif con1 >=1 and con1 <=2 then
		if b2 >= t1 then
			ret = '8'
		elseif b2 >= b1+(t1-b1)/2  and b2 <= t1 then
			ret = '9'
		elseif b2 >= b1 and b2 <= b1+(t1-b1)/2 then
			ret = '0'
		elseif t2 >= b1+(t1-b1)/2 and t2 <= t1 then
			ret = 'a'
		elseif t2 >= b1 and t2 <= b1+(t1-b1)/2 then
			ret = 'b'
		elseif t2 <= b1 then
			ret = 'c'
		elseif t2>=t1 and b2<=b1 then
			ret = 'd'
		else
			print('unmatched',t1,b1,t2,b2)
		end
	elseif con1 >2 then
		if b2 >= t1 then
			ret = 'e'
		elseif b2 >= b1+(t1-b1)/2  and b2 <= t1 then
			ret = 'f'
		elseif b2 >= b1 and b2 <= b1+(t1-b1)/2 then
			ret = 'g'
		elseif t2 >= b1+(t1-b1)/2 and t2 <= t1 then
			ret = 'h'
		elseif t2 >= b1 and t2 <= b1+(t1-b1)/2 then
			ret = 'i'
		elseif t2 <= b1 then
			ret = 'j'
		elseif t2>=t1 and b2<=b1 then
			ret = 'k'
		else
			print('unmatched',t1,b1,t2,b2)
		end
	else
		print('con1 unmatched',t1,b1,t2,b2)
	end

	return ret
end


local arr = loadCsvFile(arg[1])
local t1,b1,t2,b2
local history = {}
local i = 1

--field dim: 
--2-date,5-open,6-high,7-low,8-close or
--1-date,4-open,5-high,6-low,7-close
for k1,v1 in ipairs(arr) do
	if #v1 == 13 then
		t1 = v1[6]
		b1 = v1[7]
		io.write('3')
		history[i] = {1,tonumber(v1[2]),tonumber(v1[5]),tonumber(v1[6]),tonumber(v1[7]),tonumber(v1[8]),'3'}
	else
		t2 = v1[5]
		b2 = v1[6]
		local state_char = tranTrend(t1,b1,t2,b2)
		io.write(state_char)
		t1 = t2
		b1 = b2
		history[i] = {0,tonumber(v1[1]),tonumber(v1[4]),tonumber(v1[5]),tonumber(v1[6]),tonumber(v1[7]),state_char}
	end
	i = i + 1
end

torch.save('data/stock/history.t7', history)
