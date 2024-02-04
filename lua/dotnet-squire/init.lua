-- [nfnl] Compiled from fnl/dotnet-squire/init.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("dotnet-squire.nfnl.module")
local autoload = _local_1_["autoload"]
local core = autoload("dotnet-squire.nfnl.core")
local notify = autoload("dotnet-squire.nfnl.notify")
local fs = autoload("dotnet-squire.nfnl.fs")
local m = {}
local secrets_base_path
do
  local os = string.lower(jit.os)
  if (("linux" == os) or ("osx" == os) or ("bsd" == os)) then
    secrets_base_path = "~/.microsoft/usersecrets"
  else
    secrets_base_path = "%APPDATA%\\Microsoft\\UserSecrets"
  end
end
local function get_user_secrets_path(secret_id)
  return vim.fn.expand(fs["join-path"]({secrets_base_path, secret_id, "secrets.json"}))
end
local function iterator_to_table(iterator)
  local out = {}
  for k, _ in iterator do
    table.insert(out, k)
  end
  return out
end
local function notify_newline()
  return notify.info(" ")
end
local function read_user_secrets_id(proj_path)
  local secrets_id = iterator_to_table(string.gmatch(core.slurp(proj_path), "<UserSecretsId>([%w-]+)</UserSecretsId>"))
  local _3_ = secrets_id
  if ((_G.type(_3_) == "table") and (nil ~= (_3_)[1])) then
    local secret_id = (_3_)[1]
    return secret_id
  elseif true then
    local _ = _3_
    return nil
  else
    return nil
  end
end
local function create_user_secrets(proj_path)
  local init_cmd_txt = ("dotnet user-secrets init --project " .. vim.fn.expand(proj_path))
  local create_output = vim.fn.system(init_cmd_txt)
  local exit_code_ok_3f = (0 == vim.v.shell_error)
  return exit_code_ok_3f, create_output, init_cmd_txt
end
local function handle_create_user_secret_id(selected_yes_3f, proj_path)
  notify_newline()
  if not selected_yes_3f then
    return notify.info(("Not creating user secrets for project: " .. proj_path))
  else
    local exit_code_ok_3f, msg, init_cmd_txt = create_user_secrets(proj_path)
    if not exit_code_ok_3f then
      return notify.info(("Could not create user secrets for project: " .. proj_path .. ", command was:\n" .. init_cmd_txt .. "\n" .. "error output was:\n" .. msg))
    else
      return m["handle-user-secret-id"](read_user_secrets_id(proj_path), proj_path)
    end
  end
end
local function prompt_for_create_user_secrets(proj_path, handler)
  local function _7_(_241)
    return handler(("Yes" == _241))
  end
  return vim.ui.select({"Yes", "No"}, {prompt = ("Do you want to initialize user secrets for project: " .. proj_path)}, _7_)
end
local function open_secrets_in_buffer(secret_id)
  local path = get_user_secrets_path(secret_id)
  fs.mkdirp(fs.basename(path))
  if core["empty?"](vim.fn.findfile(path)) then
    vim.fn.system(("echo {} > " .. path))
  else
  end
  notify.info(("\nOpening secrets for identifier: " .. secret_id))
  return vim.api.nvim_cmd({cmd = "edit", args = {path}}, {})
end
m["handle-user-secret-id"] = function(secret_id, proj_path)
  local _9_ = secret_id
  if (_9_ == nil) then
    notify.info(("\nNo user secrets found for project: " .. proj_path))
    local function _10_(_241)
      return handle_create_user_secret_id(_241, proj_path)
    end
    return prompt_for_create_user_secrets(proj_path, _10_)
  elseif (nil ~= _9_) then
    local id = _9_
    return open_secrets_in_buffer(id)
  else
    return nil
  end
end
local function open_project_secrets(proj_path)
  if not core["empty?"](proj_path) then
    return m["handle-user-secret-id"](read_user_secrets_id(proj_path), proj_path)
  else
    return nil
  end
end
local function select_proj(projs, handle_choice)
  return vim.ui.select(projs, {prompt = "Select project"}, handle_choice)
end
local function find_proj_files(dir)
  return core.concat(fs.absglob(dir, "*.csproj"), fs.absglob(dir, "*.fsproj"))
end
local function secrets()
  local proj_files = find_proj_files(vim.fn.getcwd())
  local _13_ = proj_files
  local function _14_()
    return (1 < #proj_files)
  end
  if ((_G.type(_13_) == "table") and _14_()) then
    return select_proj(proj_files, open_project_secrets)
  elseif ((_G.type(_13_) == "table") and (nil ~= (_13_)[1])) then
    local proj_file = (_13_)[1]
    return open_project_secrets(proj_file)
  elseif true then
    local _ = _13_
    return notify.info("No dotnet project files found, are you sure you are in the correct directory?")
  else
    return nil
  end
end
local function setup()
  return vim.api.nvim_create_user_command("Secrets", secrets, {})
end
return {setup = setup, secrets = secrets}
