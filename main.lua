--- @since 25.5.31

local get_cwd = ya.sync(function()
	return tostring(cx.active.current.cwd)
end)

--- @param args table<string, string>
--- @param cwd string
--- @return string[]|nil
local function run_with(args, cwd)
	local output = Command("git")
		:arg(args)
		:cwd(cwd)
		:output()
	if not output or not output.status.success then
		return nil
	end

	ya.dbg(output.stdout)

	local result = {}
	local text = output.stdout:gsub("\r\n", "\n"):gsub("\r", "\n")
	for line in text:gmatch("([^\n]*)\n") do
		table.insert(result, line)
	end

	ya.dbg(result)

	return result
end

local function get_git_toplevel()
	local cwd = get_cwd()

	local output = run_with({
		"rev-parse",
		"--is-bare-repository",
		"--is-inside-git-dir",
		"--git-dir",
		"--show-cdup",
	}, cwd)
	if not output then
		return nil
	end

	local is_bare_repo = output[1] == "true"
	local is_git_dir = output[2] == "true"
	local git_dir = output[3]
	local relative_up = output[4]

	if is_bare_repo then
		return nil
	end

	if is_git_dir then
		local path = Url(git_dir)
		return path.parent
	end

	return Url(relative_up)
end

return {
	entry = function()
		local destination = get_git_toplevel()
		ya.dbg(tostring(destination))
		if destination then
			ya.emit("cd", { destination })
		else
			ya.notify({
				title = "Could not change directory!",
				content = "You are not in a git repository.",
				timeout = 3,
				level = "error",
			})
		end
	end,
}
