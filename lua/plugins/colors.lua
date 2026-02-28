local function enable_transparency()
	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
end

return {
	{
		"folke/tokyonight.nvim",
		--        config = function()
		--            vim.cmd.colorscheme "tokyonight"
		--            enable_transparency()
		--        end
	},
	{
		"nvim-lualine/lualine.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		opts = {
			theme = "tokyonight",
		},
	},
	-- {
	-- 	"catppuccin/nvim",
	-- 	name = "catppuccin",
	-- 	priority = 1000,
	-- 	opt = {},
	-- 	config = function()
	-- 		vim.cmd.colorscheme("catppuccin")
	-- 		require("catppuccin").setup({
	-- 			custom_highlights = function()
	-- 				return {
	-- 					-- DiffChange = { fg = "#BD93F9" },
	-- 					-- DiffDelete = { fg = "#FF5555" },
	-- 					netrwMarkFile = { guibg = "#FF5555" },
	-- 				}
	-- 			end,
	-- 		})
	-- 	end,
	-- },
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		config = function()
			require("catppuccin").setup({
				flavour = "mocha", -- Ensure mocha is forced
				custom_highlights = function(colors)
					return {
						-- Brighter line numbers (Inactive)
						LineNr = { fg = colors.overlay2 },
						-- Brightest line number (Active/Current)
						CursorLineNr = { fg = colors.lavender, style = { "bold" } },

						-- Your existing highlights
						netrwMarkFile = { bg = "#FF5555" },
					}
				end,
			})
			vim.cmd.colorscheme("catppuccin")
		end,
	},
}
