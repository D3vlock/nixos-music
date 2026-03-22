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
		ft = "tidal",
		config = function()
			require("tidal").setup({
				boot = {
					tidal = {
						highlight = {
							type = "osc",
							events = {
								osc = {
									ip = "127.0.0.1",
									port = 6013,
								},
							},
						},
					},
				},
			})

			-- Start the highlight listener for .tidal files since we
			-- launch tidal externally via tmux instead of :TidalLaunch
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "tidal",
				once = true,
				callback = function()
					local ok, highlight = pcall(require, "tidal.highlighting")
					if ok and highlight.start then
						highlight.start({
							type = "osc",
							events = { osc = { ip = "127.0.0.1", port = 6013 } },
						})
					end
				end,
			})
		end,
	},
}
