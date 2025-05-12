local wezterm = require("wezterm")
local action = wezterm.action

local M = {}

M._modules = {}

M.register = function(module)
	table.insert(M._modules, module)
end

local function _list_workspaces(modules)
	local workspaces = {}
	for _, module in ipairs(modules) do
		for _, workspace in ipairs(module.list_workspaces()) do
			table.insert(workspaces, workspace)
		end
	end
  return workspaces
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
			choices = _list_workspaces(M.modules),
		}),
		pane
	)
end

return M
