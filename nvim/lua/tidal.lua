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
		end,
	},
}
