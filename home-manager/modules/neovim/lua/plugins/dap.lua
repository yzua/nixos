-- nvim-dap: Debug Adapter Protocol integration.

local dap = require("dap")
local dapui = require("dapui")

dapui.setup()
require("nvim-dap-virtual-text").setup()

-- Auto open/close DAP UI on debug sessions
dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
end

-- Go (delve)
dap.adapters.delve = {
  type = "server",
  port = "${port}",
  executable = {
    command = "dlv",
    args = { "dap", "-l", "127.0.0.1:${port}" },
  },
}
dap.configurations.go = {
  {
    type = "delve",
    name = "Debug",
    request = "launch",
    program = "${file}",
  },
  {
    type = "delve",
    name = "Debug (test)",
    request = "launch",
    mode = "test",
    program = "${file}",
  },
  {
    type = "delve",
    name = "Debug (test function)",
    request = "launch",
    mode = "test",
    program = "${file}",
    args = function()
      local name = vim.fn.input("Test name: ")
      return { "-test.run", name }
    end,
  },
}

-- C/C++/Rust (GDB)
dap.adapters.gdb = {
  type = "executable",
  command = "gdb",
  args = { "--interpreter=dap", "--eval-command", "set print pretty on" },
}
dap.configurations.c = {
  {
    name = "Launch",
    type = "gdb",
    request = "launch",
    program = function()
      return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
    end,
    cwd = "${workspaceFolder}",
  },
}
dap.configurations.cpp = dap.configurations.c
dap.configurations.rust = dap.configurations.c

-- Python (debugpy)
dap.adapters.python = {
  type = "executable",
  command = "python3",
  args = { "-m", "debugpy.adapter" },
}
dap.configurations.python = {
  {
    type = "python",
    request = "launch",
    name = "Launch file",
    program = "${file}",
    pythonPath = function()
      local venv = os.getenv("VIRTUAL_ENV")
      if venv then
        return venv .. "/bin/python"
      end
      return "python3"
    end,
  },
}

-- Keybindings
local map = vim.keymap.set
map("n", "<F5>", dap.continue, { desc = "Debug: Continue" })
map("n", "<F10>", dap.step_over, { desc = "Debug: Step Over" })
map("n", "<F11>", dap.step_into, { desc = "Debug: Step Into" })
map("n", "<F12>", dap.step_out, { desc = "Debug: Step Out" })
map("n", "<leader>db", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
map("n", "<leader>dB", function()
  dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "Debug: Conditional Breakpoint" })
map("n", "<leader>dr", dap.repl.open, { desc = "Debug: Open REPL" })
map("n", "<leader>du", dapui.toggle, { desc = "Debug: Toggle UI" })
