--[[

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

]] --

-- Repository checks for CI. Run from the repository root with Lua 5.4: lua5.4 .github/scripts/check-repository.lua
-- Checks the manifest against the files in the repository, and the license header of every Lua and TypeScript file.

local HEADER_LINES = {
    '',
    '    ug-template - https://github.com/ugcore-project',
    '    Copyright (C) 2026 UgCore Framework & Contributors',
    '    Licensed under the GNU General Public License. See LICENSE for details.',
    '',
}

local LUA_HEADER = '--[[\n' .. table.concat(HEADER_LINES, '\n') .. '\n]] --\n\n'
local TS_HEADER = '/*\n' .. table.concat(HEADER_LINES, '\n') .. '\n*/\n\n'

-- Never sent to clients: server code, owner config, tests, CI, web sources.
local SERVER_ONLY = {
    '^server/',
    '^config%.lua$',
    '^config%.example%.lua$',
    '^tests/',
    '^%.github/',
    '^skills/',
    '^web/src/',
    '^web/node_modules/',
}

local SCRIPT_DIRECTIVES = {
    shared_script = 'shared', shared_scripts = 'shared',
    server_script = 'server', server_scripts = 'server',
    client_script = 'client', client_scripts = 'client',
    file = 'files', files = 'files',
}

---@type string[]
local errors = {}

---@param message string
---@param ... any
local function fail(message, ...)
    errors[#errors + 1] = message:format(...)
end

---Tracked and untracked files, without ignored ones, with forward slashes.
---@return string[]
local function listFiles()
    local pipe = assert(io.popen('git ls-files --cached --others --exclude-standard'))
    local files = {}

    for line in pipe:lines() do
        files[#files + 1] = line
    end

    pipe:close()

    if #files == 0 then
        fail('git ls-files listed no files. Run the check from the repository root.')
    end

    return files
end

---@param pattern string FiveM glob: `*` within a folder name, `**` as a whole segment for any number of folders
---@param path string
---@return boolean
local function globMatch(pattern, path)
    local patternParts, pathParts = {}, {}

    for part in pattern:gmatch('[^/]+') do
        patternParts[#patternParts + 1] = part
    end

    for part in path:gmatch('[^/]+') do
        pathParts[#pathParts + 1] = part
    end

    ---@param segment string
    ---@return string
    local function toLuaPattern(segment)
        local escaped = segment:gsub('[%^%$%(%)%%%.%[%]%+%-%?]', '%%%0')

        return '^' .. escaped:gsub('%*', '[^/]*') .. '$'
    end

    ---@param i integer
    ---@param j integer
    ---@return boolean
    local function match(i, j)
        if i > #patternParts then
            return j > #pathParts
        end

        local segment = patternParts[i]

        if segment == '**' then
            for k = j, #pathParts + 1 do
                if match(i + 1, k) then
                    return true
                end
            end

            return false
        end

        return j <= #pathParts and pathParts[j]:find(toLuaPattern(segment)) ~= nil and match(i + 1, j + 1)
    end

    return match(1, 1)
end

---@return table<string, string[]> entries by directive group, plus `version` and `ui_page`
local function readManifest()
    local manifest = { shared = {}, server = {}, client = {}, files = {}, version = {}, ui_page = {} }

    local env = setmetatable({}, {
        __index = function(_, directive)
            return function(value)
                local group = SCRIPT_DIRECTIVES[directive]
                    or (directive == 'version' and 'version')
                    or (directive == 'ui_page' and 'ui_page')

                if not group then
                    return
                end

                for _, entry in ipairs(type(value) == 'table' and value or { value }) do
                    table.insert(manifest[group], entry)
                end
            end
        end,
    })

    local chunk = assert(loadfile('fxmanifest.lua', 't', env))

    chunk()

    return manifest
end

---@param files string[]
---@param pattern string
---@return string[]
local function matching(files, pattern)
    local found = {}

    for _, path in ipairs(files) do
        if globMatch(pattern, path) then
            found[#found + 1] = path
        end
    end

    return found
end

---@param path string
---@return boolean
local function isServerOnly(path)
    for _, pattern in ipairs(SERVER_ONLY) do
        if path:find(pattern) then
            return true
        end
    end

    return false
end

---@param path string
---@return string
local function read(path)
    local handle = io.open(path, 'rb')
    local content = handle and handle:read('a') or ''

    if handle then
        handle:close()
    end

    return (content:gsub('\r\n', '\n'))
end

local files = listFiles()
local exists = {}

for _, path in ipairs(files) do
    exists[path] = true
end

local manifest = readManifest()

-- web/dist is built by CI and git-ignored, so entries under it are not checked against the file list.
---@param entry string
---@return boolean
local function isBuildOutput(entry)
    return entry:find('^web/dist/') ~= nil
end

-- The owner config is generated on the first start and MUST NOT be committed.
if exists['config.lua'] then
    fail('config.lua is committed. It is the owner file: ship config.example.lua instead')
end

-- Every listed script and file exists. FXServer warns about patterns that match nothing.
for _, group in ipairs({ 'shared', 'server', 'client', 'files' }) do
    for _, entry in ipairs(manifest[group]) do
        if entry:sub(1, 1) ~= '@' and not isBuildOutput(entry) then
            local found = entry:find('*', 1, true) and matching(files, entry) or (exists[entry] and { entry } or {})

            if #found == 0 then
                fail('fxmanifest.lua: %s entry "%s" matches no file', group, entry)
            end

            if group == 'files' or group == 'client' or group == 'shared' then
                for _, path in ipairs(found) do
                    if isServerOnly(path) then
                        fail('fxmanifest.lua: %s entry "%s" sends the server-only file %s to clients', group, entry, path)
                    end
                end
            end
        end
    end
end

for _, page in ipairs(manifest.ui_page) do
    if not isBuildOutput(page) then
        fail('fxmanifest.lua: ui_page "%s" MUST point to web/dist', page)
    end
end

if #manifest.version ~= 1 or not tostring(manifest.version[1]):find('^%d+%.%d+%.%d+$') then
    fail('fxmanifest.lua: version MUST be MAJOR.MINOR.PATCH')
end

-- Every Lua file and every web source file starts with the license header and one blank line.
for _, path in ipairs(files) do
    local header = nil

    if path:find('%.lua$') then
        header = LUA_HEADER
    elseif path:find('^web/src/.+%.tsx?$') then
        header = TS_HEADER
    end

    if header and read(path):sub(1, #header) ~= header then
        fail('%s does not start with the license header', path)
    end
end

for _, message in ipairs(errors) do
    print('Error: ' .. message)
end

print(('%d file(s) checked, %d error(s).'):format(#files, #errors))
os.exit(#errors == 0 and 0 or 1)
