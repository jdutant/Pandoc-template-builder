--[[ template-builder.lua: import partials into a template

Copyright 2023 Julien Dutant. MIT License. See LICENSE file for details.

]]

--- # Global variables

---@class Matcher A pattern / capture pair to pick up partials commands
---@field pattern function returns a pattern for a given extension
---@field capture function returns a corresponding capture pattern

---@alias MATCHERS Matcher[] 
MATCHERS = {
    -- pattern 1: $alphnum[-alphnum][_alphanum].ext()$ strings
    {
        pattern = function(ext)
            return '%$%s*[%w-_]+%'..ext..'%(%)%s*%$\n?'
        end,
        capture = function(ext)
            return '%$%s*([%w-_]+%'..ext..')%(%)%s*%$'
        end
    },
    -- pattern 2: ${alphnum[-alphnum][_alphanum].ext()} strings
    {
        pattern = function(ext)
            return '%${%s*[%w-_]+%'..ext..'%(%)%s*}\n?'
        end,
        capture = function(ext)
            return '%${%s*([%w-_]+%'..ext..')%(%)%s*}\n?'
        end
    }
}

OPTIONS = {}



-- pattern to capture partial calls
-- assumes $alphnum[-alphnum].ext()$ strings
-- take out EOF if present
PATTERN = function(ext) 
    return '%$[%w-_]+%'..ext..'%(%)%$\n?'
end
CAPTURE = function(ext)
    return '%$([%w-_]+%'..ext..')%(%)%$'
end

--- # Helper functions

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

---comment
---@param args table Lua's argument table
---@return table options map with `input_dir`, `input_file`, 
---                     `extension` and (maybe) `output` keys.
local function readCLIArgs(args)
    local opts = nil
    while #args > 0 do
        if args[1] == '-h' or args[1] == '--help' then
            io.stderr:write("Pandoc template builder. Basic Usage:\n"
            .."    lua template-builder.lua -i template.fmt\n"
            .."    pandoc lua template-builder.lua -i template.fmt -o compiled.fmt\n"
                .."Without -o flag the compiled template is printed to stdout.\n"
            )
            return {}
        elseif args[1] == '-o' and args[2] then
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
                .."Use -h or --help to print help")
            table.remove(args, 1)
        end
    end
    return opts
end

function importPartials(template)

    local result = readFile(path.join{ OPTIONS.input_dir, template })

    for _,matcher in ipairs(MATCHERS) do
        local pattern = matcher.pattern(OPTIONS.extension)
        local capture = matcher.capture(OPTIONS.extension)
        result = result:gsub( pattern, 
            function(line)
                local import = importPartials(line:match(capture))
                -- empty partials return nothing
                -- avoid duplicate EOL
                return import:match('^%s*$') and ''
                    or import:match('.*\n$') and import
                    or import .. '\n'
            end
        )
    end

    return result

end

OPTIONS = readCLIArgs(arg)
if OPTIONS.input_file then
    result = importPartials(OPTIONS.input_file)
    if OPTIONS.output then
        writeToFile(result, OPTIONS.output)
    else
        io.stdout:write(result)
    end
end
