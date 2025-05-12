local wezterm = require("wezterm")

local M = {}

local fd = "fd"
local rootPath = os.getenv("HOME") .. "/code"

M.list_workspaces = function()
	local projects = {}

	local success, stdout, stderr = wezterm.run_child_process({
		fd,
		"-HI",
		"-td",
		"^.git$",
		"--max-depth=4",
		rootPath,
	})

	if not success then
		wezterm.log_error("Failed to run fd: " .. stderr)
		return {}
	end

	for line in stdout:gmatch("([^\n]*)\n?") do
		local workdir = line:gsub("/.git/$", "")
		local label = workdir:gsub(rootPath .. "/", "")
		table.insert(projects, {
			label = wezterm.format({
				{ Foreground = { AnsiColor = "Yellow" } },
				{ Text = " " },
				{ Foreground = { Color = "#bac2de" } },
				{ Text = " " .. tostring(label) },
			}),
			id = tostring(workdir),
		})
	end

	return projects
end

return M
