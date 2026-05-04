--- @since 25.5.31

local get_cwd = ya.sync(function()
	return tostring(cx.active.current.cwd)
end)

local function get_git_toplevel()
	local command =
		Command("git")
			:arg("rev-parse")
			:arg("--show-toplevel")
			:cwd(get_cwd())
	local output = command:output()
	if not output then
		return nil
	end

	if output.status.code == 0 then
		local destination = output.stdout:gsub("[\n\r]", "") .. "/"
		return destination
	else
		return nil
	end
end

return {
	entry = function()
		local destination = get_git_toplevel()
		ya.dbg(destination)
		if destination then
			local target = Url(destination)
			ya.emit("cd", { target })
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
