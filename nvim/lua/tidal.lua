vim.filetype.add({ extension = { tidal = "tidal" } })

return {
	{
		"thgrund/tidal.nvim",
		dependencies = { "davidgranstrom/losc" },
		ft = "tidal",
		config = function()
			require("tidal").setup({
				boot = {
					tidal = {
						cmd = "ghci",
						args = { "-v0" },
						file = vim.fn.expand("~/tidal.hs"),
						enabled = true,
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
					sclang = {
						enabled = false,
					},
					split = "v",
				},
			})

			-- Explicit keybindings that work reliably in foot/tmux
			-- (Shift+Enter and Alt+Enter may not pass through correctly)
			vim.keymap.set("n", "<leader>e", function()
				require("tidal").send_line()
			end, { desc = "Tidal: send line", ft = "tidal" })

			vim.keymap.set("v", "<leader>e", function()
				require("tidal").send_visual()
			end, { desc = "Tidal: send selection", ft = "tidal" })

			vim.keymap.set("n", "<leader>E", function()
				require("tidal").send_block()
			end, { desc = "Tidal: send block", ft = "tidal" })

			vim.keymap.set("n", "<leader>h", function()
				require("tidal").send_hush()
			end, { desc = "Tidal: hush", ft = "tidal" })
		end,
	},
}
