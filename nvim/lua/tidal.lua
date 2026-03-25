return {
	{
		"thgrund/tidal.nvim",
		dependencies = { "davidgranstrom/losc" },
		ft = "tidal",
		opts = {
			boot = {
				tidal = {
					cmd = "ghci",
					args = { "-v0" },
					file = vim.fn.expand("~/tidal.hs"),
					enabled = true,
				},
				sclang = {
					enabled = false,
				},
				split = "v",
			},
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
}
