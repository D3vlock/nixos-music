vim.keymap.set("n", "<leader>t", function()
	local line = vim.fn.getline(".")
	vim.fn.system("tmux send-keys -t :.+ '" .. line .. "' Enter")
end)

vim.keymap.set("n", "<leader>T", function()
	local file = vim.fn.expand("%")
	vim.fn.system("tmux send-keys -t :.+ ':script " .. file .. "' Enter")
end)

vim.api.nvim_create_autocmd("BufWritePost", {
	pattern = "*.tidal",
	callback = function()
		local file = vim.fn.expand("%")
		vim.fn.system("tmux send-keys -t :.+ ':script " .. file .. "' Enter")
	end,
})

vim.keymap.set("n", "<leader>h", function()
	vim.fn.system("tmux send-keys -t :.+ 'hush' Enter")
end)
