return {
	-- Use system-installed language servers (Mason can't run dynamically linked
	-- binaries on NixOS), so tell Mason not to auto-install them.
	{
		"williamboman/mason.nvim",
		opts = {
			ensure_installed = {},
		},
	},
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				hls = {
					filetypes = { "haskell", "lhaskell", "cabal", "tidal" },
					mason = false,
				},
				lua_ls = {
					mason = false,
				},
			},
		},
	},
}
