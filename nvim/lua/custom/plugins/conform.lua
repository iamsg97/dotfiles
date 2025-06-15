return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>f",
			function()
				require("conform").format({ async = true, lsp_format = "fallback" })
			end,
			mode = "",
			desc = "[F]ormat buffer",
		},
	},
	config = function()
		local conform = require("conform")

		conform.setup({
			notify_on_error = false,
			format_on_save = function(bufnr)
				local disable_filetypes = { c = true, cpp = true }
				if disable_filetypes[vim.bo[bufnr].filetype] then
					return nil
				else
					return {
						timeout_ms = 500,
						lsp_format = "fallback",
					}
				end
			end,
			formatters_by_ft = {
				lua = { "stylua" },
				javascript = { "prettier", stop_after_first = true },
				typescript = { "prettier", stop_after_first = true },
				javascriptreact = { "prettier", stop_after_first = true },
				typescriptreact = { "prettier", stop_after_first = true },
				json = { "prettier", stop_after_first = true },
				html = { "prettier", stop_after_first = true },
				css = { "prettier", stop_after_first = true },
				scss = { "prettier", stop_after_first = true },
				markdown = { "prettier", stop_after_first = true },
				yaml = { "prettier", stop_after_first = true },
			},
			formatters = {
				prettier = {
					args = function(self, ctx)
						local args = { "--stdin-filepath", "$FILENAME" }
						
						-- Check for project-level prettier config files
						local project_configs = {
							".prettierrc",
							".prettierrc.json",
							".prettierrc.js",
							".prettierrc.mjs",
							".prettierrc.cjs",
							".prettierrc.yaml",
							".prettierrc.yml",
							"prettier.config.js",
							"prettier.config.mjs",
							"prettier.config.cjs",
						}
						
						local project_config_found = false
						local cwd = vim.fn.getcwd()
						
						-- Look for project config in current working directory and parent directories
						local function find_config(dir)
							for _, config_file in ipairs(project_configs) do
								local config_path = dir .. "/" .. config_file
								if vim.fn.filereadable(config_path) == 1 then
									return config_path
								end
							end
							-- Also check package.json for prettier config
							local package_json = dir .. "/package.json"
							if vim.fn.filereadable(package_json) == 1 then
								local content = vim.fn.readfile(package_json)
								local json_str = table.concat(content, "\n")
								if string.find(json_str, '"prettier"') then
									return package_json
								end
							end
							return nil
						end
						
						-- Traverse up the directory tree to find config
						local current_dir = cwd
						while current_dir ~= "/" do
							local config_path = find_config(current_dir)
							if config_path then
								project_config_found = true
								break
							end
							current_dir = vim.fn.fnamemodify(current_dir, ":h")
						end
						
						-- If no project config found, use global config
						if not project_config_found then
							local global_config = vim.fn.expand("~/.prettierrc.json")
							if vim.fn.filereadable(global_config) == 1 then
								table.insert(args, 1, "--config")
								table.insert(args, 2, global_config)
							end
						end
						
						return args
					end,
				},
			},
		})
	end,
}
