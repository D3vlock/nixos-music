local tidal_pane = vim.env.TIDAL_TMUX_PANE or "music:0.1"

vim.keymap.set("n", "<leader>t", function()
	local line = vim.fn.getline(".")
	vim.fn.system("tmux send-keys -t '" .. tidal_pane .. "' '" .. line .. "' Enter")
end)

vim.keymap.set("n", "<leader>T", function()
	local file = vim.fn.expand("%")
	vim.fn.system("tmux send-keys -t '" .. tidal_pane .. "' ':script " .. file .. "' Enter")
end)

vim.api.nvim_create_autocmd("BufWritePost", {
	pattern = "*.tidal",
	callback = function()
		local file = vim.fn.expand("%")
		vim.fn.system("tmux send-keys -t '" .. tidal_pane .. "' ':script " .. file .. "' Enter")
	end,
})

vim.keymap.set("n", "<leader>h", function()
	vim.fn.system("tmux send-keys -t '" .. tidal_pane .. "' 'hush' Enter")
end)

return {
	{
		"thgrund/tidal.nvim",
		dependencies = { "davidgranstrom/losc" },
		config = function()
			require("tidal").setup()
		end,
	},
}
