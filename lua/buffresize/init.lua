local BuffResize = {}

-- Configuration variables
BuffResize.config = {
	enabled = true,
	notify = true,
	ignored_filetypes = { "neo-tree", "lazy", "mason", "toggleterm", "telescope" },
	keys = {
		toggle_resize = "<leader>rw",
		toggle_plugin = "<leader>re",
	},
	notification_icon = "\u{fb96}", -- 
	notification_enable_msg = "Buffresize enabled",
	notification_disable_msg = "Buffresize disabled",
	expanded_width = 70,
	collapsed_width = 25,
}

-- State variables
BuffResize.state = {
	resized_buffers = {},
}

-- Helper function to show notifications
local function notify(msg, level)
	if BuffResize.config.notify then
		vim.notify(msg, level or vim.log.levels.WARN, { icon = BuffResize.config.notification_icon })
	end
end

-- Function to check if a buffer should be ignored based on filetype
local function is_ignored()
	local filetype = vim.bo.filetype
	for _, ft in ipairs(BuffResize.config.ignored_filetypes) do
		if filetype == ft then
			return true
		end
	end
	return false
end

-- Function to resize the focused window
local function resize_window()
	if not BuffResize.config.enabled then
		notify(BuffResize.config.notification_disable_msg, vim.log.levels.WARN)
		return
	end

	if is_ignored() then
		return
	end

	local win_id = vim.api.nvim_get_current_win()
	local width = vim.api.nvim_win_get_width(win_id)

	if width <= BuffResize.config.collapsed_width then
		vim.api.nvim_win_set_width(win_id, BuffResize.config.expanded_width)
		BuffResize.state.resized_buffers[win_id] = true
	elseif BuffResize.state.resized_buffers[win_id] then
		vim.api.nvim_win_set_width(win_id, BuffResize.config.collapsed_width)
		BuffResize.state.resized_buffers[win_id] = nil
	end
end

-- Function to reset the plugin state
local function reset_resized_buffers()
	BuffResize.state.resized_buffers = {}
end

-- Toggle the plugin on or off
function BuffResize.toggle_plugin()
	BuffResize.config.enabled = not BuffResize.config.enabled
	local msg = BuffResize.config.enabled and BuffResize.config.notification_enable_msg
		or BuffResize.config.notification_disable_msg
	notify(msg, vim.log.levels.WARN)
end

-- Toggle resize logic on demand
function BuffResize.toggle_resize()
	resize_window()
end

-- Setup function to initialize the plugin
function BuffResize.setup(config)
	BuffResize.config = vim.tbl_extend("force", BuffResize.config, config or {})

	-- Keybindings
	vim.api.nvim_set_keymap(
		"n",
		BuffResize.config.keys.toggle_resize,
		":lua require('buffresize').toggle_resize()<CR>",
		{ noremap = true, silent = true }
	)

	vim.api.nvim_set_keymap(
		"n",
		BuffResize.config.keys.toggle_plugin,
		":lua require('buffresize').toggle_plugin()<CR>",
		{ noremap = true, silent = true }
	)

	-- Autocommand to handle focus changes
	vim.api.nvim_create_autocmd("WinEnter", {
		callback = function()
			if BuffResize.config.enabled and not is_ignored() then
				resize_window()
			end
		end,
	})

	vim.api.nvim_create_autocmd("WinLeave", {
		callback = function()
			reset_resized_buffers()
		end,
	})
end

return BuffResize
