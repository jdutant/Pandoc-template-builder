--[[ template-builder.lua: import partials into a template

Copyright 2023 Julien Dutant. MIT License. See LICENSE file for details.

]]

-- pattern to capture partial calls
-- assumes $alphnum[-alphnum].ext()$ strings
-- take out EOF if present
PATTERN = function(ext) 
    return '%$[%w-_]+%'..ext..'%(%)%$\n?'
end
CAPTURE = function(ext)
    return '%$([%w-_]+%'..ext..')%(%)%$'
end

---message: send message to std_error
---comment
---@param type 'INFO'|'WARNING'|'ERROR'
---@param text string error message
function message (type, text)
    local PANDOC_STATE = PANDOC_STATE or { verbosity = 'ERROR' }
    local level = {INFO = 0, WARNING = 1, ERROR = 2}
    if level[type] == nil then type = 'ERROR' end
    if level[PANDOC_STATE.verbosity] <= level[type] then
        io.stderr:write('[' .. type .. '] Template builder: ' 
            .. text .. '\n')
    end
end

path = pandoc.path
local function fileExists(filepath)
    local f = io.open(filepath, 'r')
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

---readFile: read file as string.
---@param filepath string file path
---@return string contents or empty string if failure
function readFile(filepath)
	local contents
	local f = io.open(filepath, 'r')
	if f then 
		contents = f:read('a')
		f:close()
	end
	return contents or ''
end

---writeToFile: write string to file.
---@param contents string file contents
---@param filepath string file path
---@return nil | string status error message
function writeToFile(contents, filepath)
  local f = io.open(filepath, 'w')
	if f then 
	  f:write(contents)
	  f:close()
  else
    return 'File not found'
  end
end

local function readCLIArgs(args)
    local opts = nil
    while #args > 0 do
        if args[1] == '-o' and args[2] then
            opts = opts and opts or {}
            opts.output = args[2]
            table.remove(args, 1)
            table.remove(args, 1)
        elseif args[1] == '-i' and args[2] then
            if not fileExists(args[2]) then
                message('ERROR', "File "..args[2].." not found.")
            else
                opts = opts and opts or {}
                opts.input_dir = path.directory(args[2])
                opts.input_file = path.filename(args[2])
                _, opts.extension = path.split_extension(args[2])
            end
            table.remove(args, 1)
            table.remove(args, 1)
        else
            message('WARNING', "Bad argument "..args[1]..".\n"
                .."Syntax: -i source.file -o output.file")
            table.remove(args, 1)
        end
    end
    return opts
end

function importPartials(template)

    return readFile(path.join{ options.input_dir, template }):gsub(
        options.pattern,
        function(partial_line)
            local import = importPartials(partial_line:match(
                options.capture
            ))
            -- empty partials return nothing
            return import:match('^%s*$') and '' 
                or import:match('.*\n$') and import
                or import .. '\n'
        end
    )
    
end

options = readCLIArgs(arg)
options.pattern = PATTERN(options.extension)
options.capture = CAPTURE(options.extension)
result = importPartials(options.input_file)
if options.output then
    writeToFile(result, options.output)
else
    io.stdout:write(result)
end
