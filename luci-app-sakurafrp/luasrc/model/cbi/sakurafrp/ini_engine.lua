module("luci.model.cbi.sakurafrp.ini_engine", package.seeall)

function load(fileName)
    assert(type(fileName) == 'string', 'Parameter "fileName" must be a string.');
    local file = assert(io.open(fileName, 'r'), 'Error loading file : ' .. fileName);
    local data = {};
    local section;
    for line in file:lines() do
        line = string.gsub(line, " = ", "=")
        local tempSection = line:match('^%[([^%[%]]+)%]$');
        if(tempSection)then
            section = tonumber(tempSection) and tonumber(tempSection) or tempSection;
            data[section] = data[section] or {};
        end
        local param, value = line:match('^([%w|_]+)%s-=%s-(.+)$');
        if(param and value ~= nil)then
            if(tonumber(value))then
                value = tonumber(value);
            elseif(value == 'true')then
                value = true;
            elseif(value == 'false')then
                value = false;
            end
            if(tonumber(param))then
                param = tonumber(param);
            end
            data[section][param] = value;
        end
    end
    file:close();
    return data;
end

function save(fileName, data)
    assert(type(fileName) == 'string', 'Parameter "fileName" must be a string.');
    assert(type(data) == 'table', 'Parameter "data" must be a table.');
    local file = assert(io.open(fileName, 'w+b'), 'Error loading file :' .. fileName);
    local contents = '';
    for section, param in pairs(data) do
        contents = contents .. ('[%s]\n'):format(section);
        for key, value in pairs(param) do
            contents = contents .. ('%s = %s\n'):format(key, tostring(value));
        end
        contents = contents .. '\n';
    end
    file:write(contents);
    file:close();
end

function ReadIni(IniPath,Section,Key)
    local data=load(IniPath)
    return data[Section][Key]
end

function WriteIni(IniPath,Section,Key,Value)
    local data=load(IniPath)
    data[Section][Key]=Value
    save(IniPath, data)
end