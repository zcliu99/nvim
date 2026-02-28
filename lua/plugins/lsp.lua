local function on_attach(client, bufnr)
	-- 💡 Disable Stylua LSP (it crashes on Unicode / non-ASCII files)
	if client.name == "stylua" and client.supports_method and client:supports_method("textDocument/formatting") then
		client.server_capabilities.documentFormattingProvider = false
	end

	local opts = { buffer = bufnr }
	local grp = vim.api.nvim_create_augroup("FmtOnSave:" .. bufnr, { clear = true })
	vim.api.nvim_clear_autocmds({ group = grp, buffer = bufnr })

	vim.api.nvim_create_autocmd("BufWritePre", {
		group = grp,
		buffer = bufnr,
		callback = function()
			local bufnr = vim.api.nvim_get_current_buf()
			local ft = vim.bo[bufnr].filetype
			local clients = vim.lsp.get_clients({ bufnr = bufnr })
			local has_null = false
			for _, c in ipairs(clients) do
				if c.name == "null-ls" then
					has_null = true
				end
			end
			if has_null then
				vim.lsp.buf.format({
					bufnr = bufnr,
					async = false,
					timeout_ms = 8000,
					filter = function(c)
						return c.name == "null-ls"
					end,
				})
			else
				vim.lsp.buf.format({ async = false, timeout_ms = 8000 })
			end
		end,
		desc = "LSP/none-ls format on save",
	})

	-- Keymaps (unchanged)
	vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
	vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
	vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
	vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
	vim.keymap.set("n", "go", vim.lsp.buf.type_definition, opts)
	vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
	vim.keymap.set("n", "gs", vim.lsp.buf.signature_help, opts)
	vim.keymap.set("n", "gl", vim.diagnostic.open_float, opts)
	vim.keymap.set("n", "<F2>", vim.lsp.buf.rename, opts)

	-- F3: reindent + format (force null-ls for Lua)
	vim.keymap.set({ "n", "x" }, "<F3>", function()
		local bufnr = vim.api.nvim_get_current_buf()
		local ft = vim.bo[bufnr].filetype

		local view = vim.fn.winsaveview()
		vim.cmd("silent normal! gg=G")
		vim.fn.winrestview(view)

		local opts = { bufnr = bufnr, async = true, timeout_ms = 8000 }

		if ft == "lua" then
			opts.filter = function(c)
				return c.name == "null-ls"
			end
		end

		vim.lsp.buf.format(opts)
	end)
end

return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"nvimtools/none-ls.nvim",
		"nvim-lua/plenary.nvim",
		"jay-babu/mason-null-ls.nvim",
		-- Autocompletion
		"hrsh7th/nvim-cmp",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"saadparwaiz1/cmp_luasnip",
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-nvim-lua",
		-- Snippets
		"L3MON4D3/LuaSnip",
		"rafamadriz/friendly-snippets",
	},

	config = function()
		local lspconfig = require("lspconfig")
		local cmp_nvim_lsp = require("cmp_nvim_lsp")
		local cmp = require("cmp")
		local luasnip = require("luasnip")
		local null_ls = require("null-ls")

		-- Ensure Mason-installed tools are visible to null-ls
		local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
		if not vim.env.PATH:find(vim.pesc(mason_bin), 1, true) then
			vim.env.PATH = mason_bin .. ":" .. vim.env.PATH
		end

		local capabilities = vim.tbl_deep_extend(
			"force",
			vim.lsp.protocol.make_client_capabilities(),
			cmp_nvim_lsp.default_capabilities()
		)

		-- ======= UI =========
		vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
		vim.lsp.handlers["textDocument/signatureHelp"] =
			vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })
		vim.diagnostic.config({
			virtual_text = true,
			severity_sort = true,
			float = { style = "minimal", border = "rounded", header = "", prefix = "" },
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = "✘",
					[vim.diagnostic.severity.WARN] = "▲",
					[vim.diagnostic.severity.HINT] = "⚑",
					[vim.diagnostic.severity.INFO] = "»",
				},
			},
		})

		-- ======= none-ls setup =========
		null_ls.setup({
			-- on_attach = on_attach,
			sources = {
				null_ls.builtins.formatting.black,
				null_ls.builtins.formatting.isort,
				null_ls.builtins.formatting.stylua,
				null_ls.builtins.formatting.shfmt,
				null_ls.builtins.formatting.clang_format,
			},
		})

		-- ======= Mason setups =========
		require("mason").setup({})
		require("mason-lspconfig").setup({
			ensure_installed = { "lua_ls", "pyright", "clangd", "bashls", "ts_ls" },
			handlers = {
				-- This function runs for *all* installed servers
				function(server)
					lspconfig[server].setup({
						capabilities = capabilities,
						on_attach = on_attach,
					})
				end,
			},
		})

		require("mason-null-ls").setup({
			ensure_installed = {
				"black",
				"isort",
				"stylua",
				"shfmt",
				"clang-format",
			},
			automatic_installation = true,
		})

		-- ======= nvim-cmp =========
		require("luasnip.loaders.from_vscode").lazy_load()
		vim.opt.completeopt = { "menu", "menuone", "noselect" }

		cmp.setup({
			preselect = "item",
			completion = { completeopt = "menu,menuone,noinsert" },
			window = { documentation = cmp.config.window.bordered() },
			sources = {
				{ name = "path" },
				{ name = "nvim_lsp" },
				{ name = "buffer", keyword_length = 3 },
				{ name = "luasnip", keyword_length = 2 },
				{ name = "nvim_lsp_signature", group_index = 1 },
			},
			snippet = {
				expand = function(args)
					luasnip.lsp_expand(args.body)
				end,
			},
			formatting = {
				fields = { "abbr", "menu", "kind" },
				format = function(entry, item)
					item.menu = entry.source.name == "nvim_lsp" and "[LSP]" or ("[" .. entry.source.name .. "]")
					return item
				end,
			},
			mapping = cmp.mapping.preset.insert({
				["<CR>"] = cmp.mapping.confirm({ select = false }),
				["<C-f>"] = cmp.mapping.scroll_docs(5),
				["<C-u>"] = cmp.mapping.scroll_docs(-5),
				["<Tab>"] = cmp.mapping(function(fallback)
					local col = vim.fn.col(".") - 1
					if cmp.visible() then
						cmp.select_next_item({ behavior = "select" })
					elseif col == 0 or vim.fn.getline("."):sub(col, col):match("%s") then
						fallback()
					else
						cmp.complete()
					end
				end, { "i", "s" }),
				["<S-Tab>"] = cmp.mapping.select_prev_item({ behavior = "select" }),
				["<C-d>"] = cmp.mapping(function(fallback)
					if luasnip.jumpable(1) then
						luasnip.jump(1)
					else
						fallback()
					end
				end, { "i", "s" }),
				["<C-b>"] = cmp.mapping(function(fallback)
					if luasnip.jumpable(-1) then
						luasnip.jump(-1)
					else
						fallback()
					end
				end, { "i", "s" }),
			}),
		})
	end,

	-- ======= Export LSP ATTACH function =========
	on_attach = on_attach,
}
