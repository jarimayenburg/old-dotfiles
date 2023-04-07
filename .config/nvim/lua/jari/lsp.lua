local M = {}

function M.on_attach(_, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end

  -- LSP signatures as you type
  require('lsp_signature').on_attach()

  -- Enable jdtls commands
  require('jdtls.setup').add_commands()

  -- Disable LSP for Helm charts (which mess up yamlls)
  if vim.bo[bufnr].buftype ~= "" or vim.bo[bufnr].filetype == "helm" then
    vim.diagnostic.disable()
  end

  -- Mappings.
  local opts = { noremap=true, silent=true }

  -- See `:help vim.lsp.*` for documentation on any of the below functions
  buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', '<super>k', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<leader>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  buf_set_keymap('n', '<leader>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  buf_set_keymap('n', '<leader>e', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<leader>q', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)
  buf_set_keymap("n", "<leader>f", "<cmd>lua vim.lsp.buf.format({ async = true })<CR>", opts)

  -- Run source.organizeImports on save for Golang files
  vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = { "*.go" },
      callback = function()
          local params = vim.lsp.util.make_range_params(nil, vim.lsp.util._get_offset_encoding())
          params.context = { only = {"source.organizeImports"} }

          local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 3000)
          for _, res in pairs(result or {}) do
              for _, r in pairs(res.result or {}) do
                  if r.edit then
                      vim.lsp.util.apply_workspace_edit(r.edit, vim.lsp.util._get_offset_encoding())
                  else
                      vim.lsp.buf.execute_command(r.command)
                  end

                  vim.cmd 'undojoin'
              end
          end
      end,
  })

  -- Enable autoformatting for some filetypes
  vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = { "*.go" },
      callback = function ()
          vim.lsp.buf.formatting_sync(nil, 100)
      end
  })
end

function M.setup()
  local lsp = require('lspconfig')

  local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())

  local cmd = vim.cmd
  local opt = vim.opt
  local g = vim.g

  -- Auto completion
  cmd 'inoremap <expr> <Tab>   pumvisible() ? "\\<C-n>" : "\\<Tab>"'
  cmd 'inoremap <expr> <S-Tab> pumvisible() ? "\\<C-p>" : "\\<S-Tab>"'

  opt.completeopt = "menuone,noinsert,noselect"
  g.completion_matching_strategy_list = {"exact", "substring", "fuzzy"}

  -- Java
  -- Disabled because it doesn't work with Bazel. Now using JDT.ls in ftplugin.

  -- Python
  lsp.pyright.setup{ on_attach = M.on_attach, capabilities = capabilities }

  -- Typescript
  lsp.tsserver.setup{ on_attach = M.on_attach, capabilities = capabilities  }

  -- Rust
  lsp.rust_analyzer.setup{
    on_attach = M.on_attach,
    capabilities = capabilities,
    settings = {
      ["rust-analyzer"] = {
        imports = {
          granularity = {
            group = "module"
          },
          prefix = "self"
        },
        cargo = {
          buildScripts = {
            enable = true
          }
        },
        procMacro = {
          enable = true
        },
      }
    }
  }

  -- Haskell
  lsp.hls.setup{ on_attach = M.on_attach, capabilities = capabilities  }

  -- Go
  lsp.gopls.setup{ on_attach = M.on_attach, capabilities = capabilities }

  -- YAML
  lsp.yamlls.setup{ on_attach = M.on_attach, capabilities = capabilities  }

  local sumneko_root_path = '/home/jari/Programs/lua-language-server'
  local sumneko_binary = sumneko_root_path.."/bin/Linux/lua-language-server"

  local runtime_path = vim.split(package.path, ';')
  table.insert(runtime_path, "lua/?.lua")
  table.insert(runtime_path, "lua/?/init.lua")

  lsp.sumneko_lua.setup {
    on_attach = M.on_attach,
    capabilities = capabilities,
    cmd = {sumneko_binary, "-E", sumneko_root_path .. "/main.lua"};
    settings = {
      Lua = {
        runtime = {
          -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
          version = 'LuaJIT',
          -- Setup your lua path
          path = runtime_path,
        },
        diagnostics = {
          -- Get the language server to recognize the `vim` global
          globals = {'vim'},
        },
        workspace = {
          -- Make the server aware of Neovim runtime files
          library = vim.api.nvim_get_runtime_file("", true),
        },
        -- Do not send telemetry data containing a randomized but unique identifier
        telemetry = {
          enable = false,
        },
      },
    },
  }

  -- Bash
  lsp.bashls.setup{ on_attach = M.on_attach, capabilities = capabilities }

  -- PHP
  lsp.intelephense.setup{ on_attach = M.on_attach, capabilities = capabilities }
end

return M
