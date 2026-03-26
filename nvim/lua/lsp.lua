return {
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				hls = {
					filetypes = { "haskell", "lhaskell", "cabal", "tidal" },
				},
			},
		},
	},
}
