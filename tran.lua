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
    local ID = 1  
    local arrs = {}  
    for i = 2, #alls, 1 do  
        -- 一行中，每一列的内容,第一位为ID  
        local content = split(alls[i], ",")  
        ID = tonumber(content[1])  
        --保存ID，以便遍历取用，原来遍历可以使用in pairs来执行，所以这个不需要了  
        --table.insert(arrs, i-1, ID)  
        arrs[ID] = {}  
        -- 以标题作为索引，保存每一列的内容，取值的时候这样取：arrs[1].Title  
        for j = 1, #titles, 1 do  
            arrs[ID][titles[j]] = content[j]  
        end  
    end  
    return arrs  
end  


local arr = loadCsvFile('./MarketData_Year_2015.csv')

for k1,v1 in ipairs(arr) do
	for k2,v2 in ipairs(v1) do
	end	
end
