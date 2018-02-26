-- Honukai style prompt, base on: https://github.com/AmrEldib/cmder-powerline-prompt 

 -- user name
local username = ""
 -- startSymbol in the prompt
local startSymbol = "#"
 -- prompt indicator before user's input
local promptIndicator = "→"

local function get_device_name(path)
    return string.sub(path, 1, 1)
end

-- Resets the prompt 
function honukai_prompt_filter()
    prompt = "\x1b[34m{startSymbol} "
    if user == "" then
        username = clink.get_env('username')
        prompt = "\x1b[34m{startSymbol} {user}\x1b[37m at\x1b[32m {device}\x1b[37m in "
        prompt = string.gsub(prompt, "{user}", username)
    end

    cwd = clink.get_cwd()
    device = get_device_name(cwd)
    timeStamp = os.date("%X", os.time())

    prompt = prompt.."\x1b[33m{cwd}{git}\x1b[37m [{timeStamp}]\n\x1b[34m{venv}{promptIndicator} \x1b[0m"
    prompt = string.gsub(prompt, "{startSymbol}", startSymbol)
    prompt = string.gsub(prompt, "{device}", device)
    prompt = string.gsub(prompt, "{cwd}", cwd)
    prompt = string.gsub(prompt, "{timeStamp}", timeStamp)
    clink.prompt.value = string.gsub(prompt, "{promptIndicator}", promptIndicator)
end

--- copied from clink.lua
 -- Resolves closest directory location for specified directory.
 -- Navigates subsequently up one level and tries to find specified directory
 -- @param  {string} path    Path to directory will be checked. If not provided
 --                          current directory will be used
 -- @param  {string} dirname Directory name to search for
 -- @return {string} Path to specified directory or nil if such dir not found
local function get_dir_contains(path, dirname)

    -- return parent path for specified entry (either file or directory)
    local function pathname(path)
        local prefix = ""
        local i = path:find("[\\/:][^\\/:]*$")
        if i then
            prefix = path:sub(1, i-1)
        end
        return prefix
    end

    -- Navigates up one level
    local function up_one_level(path)
        if path == nil then path = '.' end
        if path == '.' then path = clink.get_cwd() end
        return pathname(path)
    end

    -- Checks if provided directory contains git directory
    local function has_specified_dir(path, specified_dir)
        if path == nil then path = '.' end
        local found_dirs = clink.find_dirs(path..'/'..specified_dir)
        if #found_dirs > 0 then return true end
        return false
    end

    -- Set default path to current directory
    if path == nil then path = '.' end

    -- If we're already have .git directory here, then return current path
    if has_specified_dir(path, dirname) then
        return path..'/'..dirname
    else
        -- Otherwise go up one level and make a recursive call
        local parent_path = up_one_level(path)
        if parent_path == path then
            return nil
        else
            return get_dir_contains(parent_path, dirname)
        end
    end
end

-- copied from clink.lua
local function get_git_dir(path)

    -- return parent path for specified entry (either file or directory)
    local function pathname(path)
        local prefix = ""
        local i = path:find("[\\/:][^\\/:]*$")
        if i then
            prefix = path:sub(1, i-1)
        end

        return prefix
    end

    -- Checks if provided directory contains git directory
    local function has_git_dir(dir)
        return clink.is_dir(dir..'/.git') and dir..'/.git'
    end

    local function has_git_file(dir)
        local gitfile = io.open(dir..'/.git')
        if not gitfile then return false end

        local git_dir = gitfile:read():match('gitdir: (.*)')
        gitfile:close()

        return git_dir and dir..'/'..git_dir
    end

    -- Set default path to current directory
    if not path or path == '.' then path = clink.get_cwd() end

    -- Calculate parent path now otherwise we won't be
    -- able to do that inside of logical operator
    local parent_path = pathname(path)

    return has_git_dir(path)
        or has_git_file(path)
        -- Otherwise go up one level and make a recursive call
        or (parent_path ~= path and get_git_dir(parent_path) or nil)
end

---
 -- Get the status of working dir
 -- @return {bool}
---
function get_git_status()
    -- local file = io.popen("git status --no-lock-index --porcelain 2>nul")
    -- option no-lock-index is deprecated
    local file = io.popen("git --no-optional-lock status --porcelain 2>nul")
    for line in file:lines() do
        file:close()
        return false
    end
    file:close()

    return true
end

-- adopted from clink.lua
function honukai_git_prompt_filter()

    -- Symbol for git status
    local states = {
        clean = "\x1b[32m●",
        dirty = "\x1b[31m✖︎",
    }

    local git_dir = get_git_dir()
    if git_dir then
        -- if we're inside of git repo then try to detect current branch
        local branch = get_git_branch(git_dir)
        if branch then
            -- Has branch => therefore it is a git folder, now figure out status
            if get_git_status() then
                status = states.clean
            else
                status = states.dirty
            end

            clink.prompt.value = string.gsub(clink.prompt.value, "{git}", "\x1b[37m on git:".."\x1b[34m"..branch.." "..status)
            return false
        end
    end

    -- No git present or not in git file
    clink.prompt.value = string.gsub(clink.prompt.value, "{git}", "")
    return false
end

local function basename(path)
    local i = string.find(path, "[\\/:][^\\/:]*$")
    if i then
        return "["..string.sub(path, i + 1).."] "
    end
    return ""
end

function honukai_venv_prompt_filter()
    env_path = clink.get_env("VIRTUAL_ENV")
    if env_path then
        clink.prompt.value = string.gsub(clink.prompt.value, "{venv}", basename(env_path))
    else
        clink.prompt.value = string.gsub(clink.prompt.value, "{venv}", "")
    end
    return false
end

-- override the built-in filters
clink.prompt.register_filter(honukai_prompt_filter, 55)
clink.prompt.register_filter(honukai_git_prompt_filter, 60)
clink.prompt.register_filter(honukai_venv_prompt_filter, 60)
