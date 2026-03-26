return {
	{
		"L3MON4D3/LuaSnip",
		ft = "tidal",
		config = function()
			local ls = require("luasnip")
			local s = ls.snippet
			local t = ls.text_node
			local i = ls.insert_node

			ls.add_snippets("tidal", {
				-- Basic patterns
				s("d1", {
					t('d1 $ sound "'),
					i(1, "bd sn"),
					t('"'),
					i(0),
				}),
				s("d2", {
					t('d2 $ sound "'),
					i(1, "bd sn"),
					t('"'),
					i(0),
				}),
				s("sil", { t("silence") }),

				-- Drum patterns
				s("four", {
					t('sound "'),
					i(1, "bd"),
					t('*4"'),
					i(0),
				}),
				s("rock", {
					t('sound "bd sn:2 bd [sn:2 bd]"'),
					i(0),
				}),
				s("hat", {
					t('sound "hh*8" # gain 0.8'),
					i(0),
				}),

				-- Structure / pattern transformers
				s("ev", {
					t("every "),
					i(1, "4"),
					t(" ("),
					i(2, "fast 2"),
					t(") $ "),
					i(0),
				}),
				s("some", {
					t("sometimes ("),
					i(1, "# speed 2"),
					t(") $ "),
					i(0),
				}),
				s("jux", {
					t("jux ("),
					i(1, "rev"),
					t(") $ "),
					i(0),
				}),
				s("chunk", {
					t("chunk "),
					i(1, "4"),
					t(" ("),
					i(2, "hurry 2"),
					t(") $ "),
					i(0),
				}),
				s("stk", {
					t("stack ["),
					i(1),
					t({ "", "  , " }),
					i(2),
					t({ "", "]" }),
					i(0),
				}),
				s("cat", {
					t("cat ["),
					i(1),
					t({ "", "  , " }),
					i(2),
					t({ "", "]" }),
					i(0),
				}),

				-- Effects
				s("gn", {
					t("# gain "),
					i(1, "0.8"),
					i(0),
				}),
				s("sp", {
					t("# speed "),
					i(1, "1"),
					i(0),
				}),
				s("pan", {
					t("# pan "),
					i(1, "0.5"),
					i(0),
				}),
				s("del", {
					t("# delay "),
					i(1, "0.5"),
					t(" # delaytime "),
					i(2, "0.25"),
					t(" # delayfeedback "),
					i(3, "0.4"),
					i(0),
				}),
				s("rev", {
					t("# room "),
					i(1, "0.5"),
					t(" # sz "),
					i(2, "0.8"),
					i(0),
				}),
				s("lpf", {
					t("# lpf "),
					i(1, "1000"),
					t(" # lpq "),
					i(2, "0.2"),
					i(0),
				}),
				s("hpf", {
					t("# hpf "),
					i(1, "400"),
					t(" # hpq "),
					i(2, "0.2"),
					i(0),
				}),
				s("vow", {
					t("# vowel \""),
					i(1, "a e i"),
					t('"'),
					i(0),
				}),
				s("shp", {
					t("# shape "),
					i(1, "0.5"),
					i(0),
				}),
				s("crsh", {
					t("# crush "),
					i(1, "4"),
					i(0),
				}),

				-- Time / speed
				s("fast", {
					t("fast "),
					i(1, "2"),
					t(" $ "),
					i(0),
				}),
				s("slow", {
					t("slow "),
					i(1, "2"),
					t(" $ "),
					i(0),
				}),
				s("hur", {
					t("hurry "),
					i(1, "2"),
					t(" $ "),
					i(0),
				}),

				-- Mini-notation helpers
				s("eu", {
					t("e("),
					i(1, "3"),
					t(","),
					i(2, "8"),
					t(")"),
					i(0),
				}),
				s("rnd", {
					t("# speed (range "),
					i(1, "0.5"),
					t(" "),
					i(2, "2"),
					t(" rand)"),
					i(0),
				}),

				-- Multi-line do block
				s("do", {
					t({ "do", "  " }),
					i(1, 'd1 $ sound "bd sn"'),
					t({ "", "  " }),
					i(2, 'd2 $ sound "hh*4"'),
					i(0),
				}),

				-- Transitions
				s("xt", {
					t("xfadeIn "),
					i(1, "1"),
					t(" "),
					i(2, "4"),
					t(" $ "),
					i(0),
				}),
				s("cl", {
					t("clutchIn "),
					i(1, "1"),
					t(" "),
					i(2, "4"),
					t(" $ "),
					i(0),
				}),

				-- Note / scale
				s("note", {
					t('# note "'),
					i(1, "0 3 7"),
					t('"'),
					i(0),
				}),
				s("scale", {
					t('# note (scale "'),
					i(1, "minor"),
					t('" "'),
					i(2, "0 1 2 3"),
					t('")'),
					i(0),
				}),

				-- Continuous patterns
				s("sine", {
					t("# "),
					i(1, "gain"),
					t(" (range "),
					i(2, "0.5"),
					t(" "),
					i(3, "1"),
					t(" sine)"),
					i(0),
				}),
			})

			-- Tab to expand/jump forward, Shift-Tab to jump back
			vim.keymap.set({ "i", "s" }, "<Tab>", function()
				if ls.expand_or_jumpable() then
					ls.expand_or_jump()
				else
					vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
				end
			end, { silent = true })

			vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
				if ls.jumpable(-1) then
					ls.jump(-1)
				end
			end, { silent = true })
		end,
	},
}
