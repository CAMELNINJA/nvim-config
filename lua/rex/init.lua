-- Neovim <-> Rex integration built on the `rex` CLI.
--
-- Features:
--   * run commands / send text in a "runner" pane next to the editor
--   * load the runner's output into the quickfix list
--   * <C-h/j/k/l> moves between Neovim windows and Rex panes
--   * open files in a new Rex pane with their own nvim
--
-- Everything is a no-op outside Rex (REX_SESSION / REX_BLOCK unset).
local M = {}

local session = vim.env.REX_SESSION
local block = vim.env.REX_BLOCK

local state = { runner = nil, last_cmd = nil }

M.config = {
  runner = { split = "below", ratio = 30 },
  -- default test command per filetype for <leader>rt
  test_cmds = {
    go = "go test ./...",
    rust = "cargo test",
    python = "pytest",
    javascript = "npm test",
    typescript = "npm test",
  },
}

function M.active()
  return session ~= nil and block ~= nil
end

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "rex" })
end

---Run `rex <args>` synchronously. Returns the completed process.
---@param args string[]
---@param stdin? string
local function rex(args, stdin)
  local cmd = vim.list_extend({ "rex" }, args)
  return vim.system(cmd, { text = true, stdin = stdin }):wait(5000)
end

local function ensure_active()
  if not M.active() then
    notify("Not running inside Rex", vim.log.levels.WARN)
    return false
  end
  return true
end

local function runner_alive()
  if not state.runner then
    return false
  end
  return rex({ "capture", "-s", session, "-b", state.runner }).code == 0
end

---Return the runner pane, creating a shell pane next to the editor if needed.
---@return string|nil
function M.runner()
  if not ensure_active() then
    return nil
  end
  if runner_alive() then
    return state.runner
  end
  local opts = M.config.runner
  local res = rex({
    "split", "-s", session, "-b", block,
    "--split=" .. opts.split, "--ratio", tostring(opts.ratio),
    "--focus=false", "--label", "nvim-runner",
    "-c", vim.fn.getcwd(), "--json",
  })
  if res.code ~= 0 then
    notify("Failed to create runner pane: " .. (res.stderr or ""), vim.log.levels.ERROR)
    return nil
  end
  local ok, data = pcall(vim.json.decode, res.stdout)
  if not ok or not data.block_ids or not data.block_ids[1] then
    notify("Unexpected output from `rex split`", vim.log.levels.ERROR)
    return nil
  end
  state.runner = data.block_ids[1]
  return state.runner
end

---Type `text` into the runner shell and press Enter.
function M.send(text)
  local runner = M.runner()
  if not runner then
    return
  end
  rex({ "send", "-s", session, "-b", runner }, text)
  rex({ "send-key", "-s", session, "-b", runner, "enter" })
end

---Run a shell command in the runner pane.
function M.run(cmd)
  if not cmd or cmd == "" then
    return
  end
  state.last_cmd = cmd
  M.send(cmd)
end

function M.rerun()
  if not state.last_cmd then
    notify("Nothing to rerun", vim.log.levels.WARN)
    return
  end
  M.run(state.last_cmd)
end

function M.prompt()
  vim.ui.input({ prompt = "Rex run: ", default = state.last_cmd or "" }, M.run)
end

function M.test()
  local cmd = M.config.test_cmds[vim.bo.filetype]
  if cmd then
    M.run(cmd)
  else
    M.prompt()
  end
end

---Send the current line, or the visual selection, to the runner.
function M.send_selection()
  local mode = vim.fn.mode()
  local lines
  if mode == "v" or mode == "V" or mode == "\22" then
    lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode })
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
  else
    lines = { vim.api.nvim_get_current_line() }
  end
  M.send(table.concat(lines, "\n"))
end

---Load the runner's screen and scrollback into the quickfix list.
function M.quickfix()
  if not ensure_active() then
    return
  end
  if not runner_alive() then
    notify("No runner pane", vim.log.levels.WARN)
    return
  end
  local res = rex({ "capture", "-s", session, "-b", state.runner, "--trim", "--unwrap" })
  if res.code ~= 0 then
    notify("capture failed: " .. (res.stderr or ""), vim.log.levels.ERROR)
    return
  end
  vim.fn.setqflist({}, " ", { title = "rex output", lines = vim.split(res.stdout, "\n", { trimempty = true }) })
  vim.cmd("copen")
end

function M.focus_runner()
  if M.runner() then
    rex({ "focus", "-s", session, state.runner })
  end
end

function M.close_runner()
  if runner_alive() then
    rex({ "block", "close", "-s", session, state.runner })
  end
  state.runner = nil
end

---Open `file` (default: current file) in a new Rex pane with its own nvim.
---@param direction? "right"|"left"|"above"|"below"
---@param file? string
function M.split(direction, file)
  if not ensure_active() then
    return
  end
  file = file ~= nil and file ~= "" and file or vim.api.nvim_buf_get_name(0)
  local args = {
    "split", "-s", session, "-b", block,
    "--split=" .. (direction or "right"), "-c", vim.fn.getcwd(), "--",
    "nvim",
  }
  if file ~= "" then
    table.insert(args, file)
  end
  local res = rex(args)
  if res.code ~= 0 then
    notify("Failed to open pane: " .. (res.stderr or ""), vim.log.levels.ERROR)
  end
end

---Move to the neighbouring Neovim window, falling through to the Rex pane
---in that direction when already at the edge.
---@param key "h"|"j"|"k"|"l"
function M.navigate(key)
  local dirs = { h = "left", j = "down", k = "up", l = "right" }
  local win = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. key)
  if vim.api.nvim_get_current_win() == win and M.active() then
    vim.system({ "rex", "focus", "-s", session, dirs[key] })
  end
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  local cmd = vim.api.nvim_create_user_command
  cmd("RexRun", function(a) M.run(a.args ~= "" and a.args or state.last_cmd) end, { nargs = "*", complete = "shellcmd" })
  cmd("RexRerun", M.rerun, {})
  cmd("RexSend", function(a)
    if a.range > 0 then
      M.send(table.concat(vim.api.nvim_buf_get_lines(0, a.line1 - 1, a.line2, false), "\n"))
    else
      M.send(a.args)
    end
  end, { nargs = "*", range = true })
  cmd("RexQuickfix", M.quickfix, {})
  cmd("RexFocus", M.focus_runner, {})
  cmd("RexClose", M.close_runner, {})
  cmd("RexSplit", function(a) M.split(a.fargs[1], a.fargs[2]) end, {
    nargs = "*",
    complete = function() return { "right", "left", "above", "below" } end,
  })

  if not M.active() then
    return
  end

  local map = vim.keymap.set
  for _, key in ipairs({ "h", "j", "k", "l" }) do
    map({ "n", "t" }, "<C-" .. key .. ">", function() M.navigate(key) end, { desc = "Go to window / Rex pane (" .. key .. ")" })
  end

  map("n", "<leader>rr", M.prompt, { desc = "Rex: run command" })
  map("n", "<leader>rl", M.rerun, { desc = "Rex: rerun last command" })
  map("n", "<leader>rt", M.test, { desc = "Rex: run tests" })
  map({ "n", "v" }, "<leader>rs", M.send_selection, { desc = "Rex: send line/selection" })
  map("n", "<leader>rq", M.quickfix, { desc = "Rex: output to quickfix" })
  map("n", "<leader>rf", M.focus_runner, { desc = "Rex: focus runner pane" })
  map("n", "<leader>rk", M.close_runner, { desc = "Rex: close runner pane" })
  map("n", "<leader>rv", function() M.split("right") end, { desc = "Rex: file in pane (right)" })
  map("n", "<leader>rh", function() M.split("below") end, { desc = "Rex: file in pane (below)" })

  vim.opt.autoread = true
  vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
    group = vim.api.nvim_create_augroup("rex_autoread", { clear = true }),
    command = "silent! checktime",
  })
end

return M
