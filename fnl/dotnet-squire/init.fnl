(local {: autoload} (require :dotnet-squire.nfnl.module))
(local core (autoload :dotnet-squire.nfnl.core))
(local notify (autoload :dotnet-squire.nfnl.notify))
(local fs (autoload :dotnet-squire.nfnl.fs))


(local m {})


(local secrets-base-path
  (let [os (string.lower jit.os)]
    (if (or (= :linux os)
            (= :osx os)
            (= :bsd os))
      "~/.microsoft/usersecrets"
      "%APPDATA%\\Microsoft\\UserSecrets")))


(fn get-user-secrets-path [secret-id]
  (-> [secrets-base-path secret-id "secrets.json"]
    fs.join-path
    vim.fn.expand))


(fn iterator-to-table [iterator]
  (let [out []]
    (each [k _ iterator]
      (table.insert out k))
    out))


(fn notify-newline []
  ; Needed to print a newline for the next notify messages
  (notify.info " "))


(fn read-user-secrets-id [proj-path]
  (let [secrets-id 
         (-> proj-path
           core.slurp
           (string.gmatch "<UserSecretsId>([%w-]+)</UserSecretsId>")
           iterator-to-table)]
    (case secrets-id
      [secret-id] secret-id
      _ nil)))


(fn create-user-secrets [proj-path]
  (let [init-cmd-txt
         (->> proj-path
           vim.fn.expand
           (.. "dotnet user-secrets init --project "))
        create-output (vim.fn.system init-cmd-txt)
        exit-code-ok? (= 0 (. vim.v "shell_error"))]
    (values exit-code-ok? create-output init-cmd-txt)))


(fn handle-create-user-secret-id [selected-yes? proj-path]
  (notify-newline)
  (if (not selected-yes?)
    (notify.info (.. "Not creating user secrets for project: " proj-path))
    (let [(exit-code-ok? msg init-cmd-txt) (create-user-secrets proj-path)]
      (if (not exit-code-ok?)
        (notify.info 
          (.. 
            "Could not create user secrets for project: "
            proj-path
            ", command was:\n"
            init-cmd-txt
            "\n"
            "error output was:\n"
            msg))
        (-> (read-user-secrets-id proj-path)
            (m.handle-user-secret-id proj-path))))))


(fn prompt-for-create-user-secrets [proj-path handler]
  (vim.ui.select
    [:Yes :No]
    {:prompt (.. "Do you want to initialize user secrets for project: " proj-path)}
    #(handler (= :Yes $1))))


(fn open-secrets-in-buffer [secret-id]
  (let [path (get-user-secrets-path secret-id)]
    (fs.mkdirp (fs.basename path))
    (when (core.empty? (vim.fn.findfile path)) (vim.fn.system (.. "echo {} > " path)))
    (notify.info (.. "\nOpening secrets for identifier: " secret-id))
    (vim.api.nvim_cmd {:cmd :edit :args [path]} {})))


; This needs to be a module fn because it will be called from a function it
; calles itself. Having mutual recursive fns like that by default doesn't work
(fn m.handle-user-secret-id [secret-id proj-path]
  (case secret-id
        nil 
        (do 
          (notify.info (.. "\nNo user secrets found for project: " proj-path))
          (prompt-for-create-user-secrets proj-path #(handle-create-user-secret-id $1 proj-path)))
        id (open-secrets-in-buffer id)))


(fn open-project-secrets [proj-path]
  (when (not (core.empty? proj-path))
      (-> proj-path
          read-user-secrets-id
          (m.handle-user-secret-id proj-path))))


(fn select-proj [projs handle-choice]
  (vim.ui.select
    projs
    {:prompt "Select project"}
    handle-choice))


(fn find-proj-files [dir]
  (core.concat (fs.absglob dir "*.csproj") (fs.absglob dir "*.fsproj")))


(fn secrets []
  (let [proj-files (find-proj-files (vim.fn.getcwd))]
    (case proj-files
          (where [] (< 1 (length proj-files))) (select-proj proj-files open-project-secrets)
          [proj-file] (open-project-secrets proj-file)
          _ (notify.info "No dotnet project files found, are you sure you are in the correct directory?"))))


(fn setup []
  (vim.api.nvim_create_user_command "Secrets" secrets {}))


{: setup : secrets }

