-- qmlls (qtdeclarative 6.11) deadlocks on the LSP shutdown request whenever
-- the client advertises workspace.didChangeWatchedFiles.dynamicRegistration
-- (which user.lsp capabilities do): after registering its file watchers, it
-- enters its "stopping" state without ever sending the shutdown response, so
-- Neovim never issues `exit` and the process — and its inline diagnostics —
-- linger until a second `:lsp stop` escalates to a force-kill (the retried
-- shutdown errors with "Method called on stopping Language Server", which
-- triggers rpc.terminate()). Escalate to force-stop after a grace period
-- instead; qmlls holds no on-disk state, so terminating it is safe.
vim.lsp.config('qmlls', {
  exit_timeout = 500,
})

vim.lsp.enable('qmlls')
