local wezterm = require("wezterm")
local action = wezterm.action

local M = {}

local fd = "fd"
local rootPath = os.getenv("HOME") .. "/code"

M._list_workspaces = function()
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
		return
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

M._on_workspace_selected = function(pane)
	return function(window, _, id, label)
		if not id and not label then
			wezterm.log_info("Cancelled")
		else
			wezterm.log_info("Switching to workspace: " .. label .. " (cwd=" .. id .. ")")
			window:perform_action(
				action.SwitchToWorkspace({
					name = label,
					spawn = { cwd = id },
				}),
				pane
			)
		end
	end
end

M.select = function(window, pane)
	window:perform_action(
		action.InputSelector({
			action = wezterm.action_callback(M._on_workspace_selected(pane)),
			fuzzy = true,
			title = wezterm.format({
				{ Attribute = { Intensity = "Bold" } },
				{ Foreground = { AnsiColor = "Blue" } },
				{ Text = "Workspace selector" },
			}),
			fuzzy_description = wezterm.format({
				{ Attribute = { Intensity = "Bold" } },
				{ Foreground = { AnsiColor = "Blue" } },
				{ Text = "▶ " },
			}),
			choices = M:_list_workspaces(),
		}),
		pane
	)
end

return M
