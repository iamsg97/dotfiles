;;; init.el --- simple Emacs for a Vim user who wants VS Code comforts  -*- lexical-binding: t; -*-
;;
;; Layout of this file:
;;   1. Packages        5. Completion (search / fuzzy finding / autocomplete)
;;   2. Look & feel     6. Code: tree-sitter, LSP, diagnostics
;;   3. Sane defaults   7. Git & file tree
;;   4. Vim (evil)      8. Keybindings (VS Code style + SPC leader)

;;; 1. Packages --------------------------------------------------------------
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(require 'use-package)
(setq use-package-always-ensure t)   ; auto-install anything missing

;; Keep M-x customize junk out of this file.
(setq custom-file (locate-user-emacs-file "custom.el"))
(load custom-file 'noerror 'nomessage)

;;; 2. Look & feel (Tsoding style) ------------------------------------------
(use-package gruber-darker-theme
  :config (load-theme 'gruber-darker t))

;; Only matters if you ever run the GUI (`emacs` without -nw).
(when (display-graphic-p)
  (set-face-attribute 'default nil :family "Iosevka" :height 180))

(setq display-line-numbers-type 'relative)   ; relative numbers, vim style
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(add-hook 'text-mode-hook #'display-line-numbers-mode)
(column-number-mode 1)
(show-paren-mode 1)
(global-hl-line-mode 1)
(setq-default truncate-lines t)

;;; 3. Sane defaults ---------------------------------------------------------
(setq ring-bell-function 'ignore
      use-short-answers t                       ; y/n instead of yes/no
      make-backup-files nil                     ; no file~ litter
      auto-save-file-name-transforms `((".*" ,(locate-user-emacs-file "auto-save/") t))
      create-lockfiles nil
      scroll-margin 8 scroll-conservatively 101 ; vim-like scrolloff
      require-final-newline t)
(make-directory (locate-user-emacs-file "auto-save/") t)
(setq-default indent-tabs-mode nil tab-width 4)

(global-auto-revert-mode 1)   ; reload files changed on disk
(electric-pair-mode 1)        ; auto-close brackets/quotes
(save-place-mode 1)           ; reopen files at last position
(recentf-mode 1)              ; remember recent files
(savehist-mode 1)             ; remember minibuffer history
(delete-selection-mode 1)

;; macOS's `ls' lacks GNU's --dired flag; tell dired not to use it.
(setq dired-use-ls-dired nil)

;; Terminal niceties: mouse support + system clipboard via pbcopy/pbpaste.
(unless (display-graphic-p)
  (xterm-mouse-mode 1)
  (global-set-key (kbd "<mouse-4>") #'scroll-down-line)
  (global-set-key (kbd "<mouse-5>") #'scroll-up-line)
  (when (eq system-type 'darwin)
    (setq interprogram-cut-function
          (lambda (text)
            (let ((process-connection-type nil))
              (let ((proc (start-process "pbcopy" nil "pbcopy")))
                (process-send-string proc text)
                (process-send-eof proc))))
          interprogram-paste-function
          (lambda () (shell-command-to-string "pbpaste")))))

;; Make Emacs see the same PATH as your shell (for gopls, node, etc.).
(use-package exec-path-from-shell
  :config
  (exec-path-from-shell-initialize)
  ;; Stable tool dirs: `go install`ed tools (gopls) and fnm's default Node
  ;; (fnm's normal PATH entry is a temp dir that disappears).
  (dolist (dir '("~/go/bin" "~/.local/share/fnm/aliases/default/bin"))
    (let ((dir (expand-file-name dir)))
      (when (file-directory-p dir)
        (add-to-list 'exec-path dir)
        (setenv "PATH" (concat dir ":" (getenv "PATH")))))))

;;; 4. Vim (evil) ------------------------------------------------------------
(use-package evil
  :init
  (setq evil-want-keybinding nil        ; evil-collection handles other modes
        evil-want-C-u-scroll t
        evil-want-Y-yank-to-eol t
        evil-undo-system 'undo-redo
        evil-split-window-below t
        evil-vsplit-window-right t)
  :config (evil-mode 1))

(use-package evil-collection            ; vim keys in dired, help, ...
  :after evil
  :config (evil-collection-init))

(use-package evil-commentary            ; gcc / gc{motion} like vim-commentary
  :after evil
  :config (evil-commentary-mode 1))

(use-package evil-surround              ; cs"' ds( ysiw] like vim-surround
  :after evil
  :config (global-evil-surround-mode 1))

(use-package evil-terminal-cursor-changer  ; block cursor in normal, bar in insert
  :unless (display-graphic-p)
  :after evil
  :config (evil-terminal-cursor-changer-activate))

;;; 5. Completion ------------------------------------------------------------
;; which-key: press SPC (or any prefix) and wait -> popup of what comes next.
(which-key-mode 1)
(setq which-key-idle-delay 0.3)

;; Vertical minibuffer list (like the VS Code quick-open box).
(use-package vertico
  :init (vertico-mode 1))

;; Fuzzy-ish matching: type words in any order, separated by spaces.
(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

;; Extra info next to candidates (docstrings, file sizes, ...).
(use-package marginalia
  :init (marginalia-mode 1))

;; Search commands: grep the project, jump to symbol, search lines, ...
(use-package consult
  :config
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref))

;; Autocomplete popup while typing (works in the terminal).
(use-package company
  :hook (after-init . global-company-mode)
  :custom
  (company-idle-delay 0.1)
  (company-minimum-prefix-length 1)
  (company-tooltip-align-annotations t)
  (company-selection-wrap-around t))

;;; 6. Code: tree-sitter, LSP, diagnostics -----------------------------------
;; Tree-sitter: better syntax highlighting. Grammars auto-install the first
;; time you open a file of that language (needs a C compiler; you have one).
(use-package treesit-auto
  :custom (treesit-auto-install t)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode 1))
(setq treesit-font-lock-level 4          ; maximum highlighting detail
      treesit-auto-install-grammar 'always) ; Emacs 31: don't ask, just install

;; Eglot: built-in LSP client. Starts automatically for these languages if
;; the language server is installed (see the README notes at the bottom).
(use-package eglot
  :ensure nil
  :hook ((go-ts-mode python-ts-mode js-ts-mode typescript-ts-mode tsx-ts-mode
          c-ts-mode c++-ts-mode rust-ts-mode) . eglot-ensure)
  :custom
  (eglot-autoshutdown t)              ; stop server when last buffer closes
  (eglot-events-buffer-config '(:size 0)))  ; faster: no event logging

;; Show errors inline at the end of the line, like VS Code's Error Lens.
(setq flymake-show-diagnostics-at-end-of-line 'short)

;; Modes for languages without built-in tree-sitter mode.
(use-package markdown-mode)
(use-package yaml-mode)

;;; 7. Git & file tree -------------------------------------------------------
;; Git change markers in the gutter (added/modified/deleted lines).
(use-package diff-hl
  :config
  (global-diff-hl-mode 1)
  (unless (display-graphic-p) (diff-hl-margin-mode 1)))

(defun my/refresh-after-git ()
  "Reload file buffers and gutter marks after git changed things outside Emacs."
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when (and buffer-file-name (not (buffer-modified-p)))
        (revert-buffer :ignore-auto :noconfirm :preserve-modes)
        (when (bound-and-true-p diff-hl-mode) (diff-hl-update))))))

(defun my/lazygit ()
  "Open lazygit for the current project.
Inside tmux it opens in a floating popup over Emacs; otherwise in a terminal buffer."
  (interactive)
  (let ((dir (expand-file-name
              (or (when-let* ((pr (project-current))) (project-root pr))
                  default-directory))))
    (if (getenv "TMUX")
        (progn
          ;; Blocks until you quit lazygit (q), then refreshes buffers.
          (call-process "tmux" nil nil nil "display-popup" "-E"
                        "-w" "90%" "-h" "90%" "-d" dir "lazygit")
          (redraw-display)
          (my/refresh-after-git))
      (let ((default-directory dir))
        (ansi-term "lazygit" "*lazygit*")))))

;; Sidebar file tree (Ctrl+b / SPC e).
(use-package neotree
  :custom
  (neo-theme 'arrow)
  (neo-smart-open t)
  (neo-window-width 30)
  (neo-show-hidden-files t))

(defun my/toggle-file-tree ()
  "Toggle the file tree, rooted at the current project."
  (interactive)
  (if (neo-global--window-exists-p)
      (neotree-hide)
    (let ((root (when-let* ((pr (project-current))) (project-root pr)))
          (file buffer-file-name))
      (neotree-dir (or root default-directory))
      (when file (neotree-find file)))))

;;; 8. Keybindings ----------------------------------------------------------
(defun my/comment-dwim ()
  "Comment/uncomment the selection, or the current line."
  (interactive)
  (if (use-region-p)
      (comment-or-uncomment-region (region-beginning) (region-end))
    (comment-line 1)))

;; --- VS Code style (work in every evil state) ---
;; Note: terminals can't send most Ctrl+Shift combos, so those live on SPC.
(evil-define-key '(normal insert visual motion) 'global
  (kbd "C-s")   #'save-buffer                    ; Ctrl+S  save
  (kbd "C-p")   #'project-find-file              ; Ctrl+P  quick open
  (kbd "C-b")   #'my/toggle-file-tree            ; Ctrl+B  sidebar
  (kbd "C-/")   #'my/comment-dwim                ; Ctrl+/  comment
  (kbd "C-_")   #'my/comment-dwim                ;  (what terminals send for C-/)
  (kbd "C-f")   #'consult-line                   ; Ctrl+F  search in file
  (kbd "C-.")   #'eglot-code-actions             ; Ctrl+.  quick fix
  (kbd "<f2>")  #'eglot-rename                   ; F2      rename symbol
  (kbd "<f5>")  #'compile                        ; F5      run/build command
  (kbd "<f8>")  #'flymake-goto-next-error        ; F8      next problem
  (kbd "<f12>") #'xref-find-definitions          ; F12     go to definition
  (kbd "S-<f12>") #'xref-find-references)        ; Shift+F12 references
(evil-define-key 'insert 'global
  (kbd "C-SPC") #'company-complete)              ; Ctrl+Space suggestions

;; --- Vim-native code navigation ---
;; gd = definition, gr = references, K = docs, C-o = jump back,
;; ]d / [d = next/prev diagnostic.
(evil-define-key 'normal 'global
  (kbd "gd") #'xref-find-definitions
  (kbd "gr") #'xref-find-references
  (kbd "K")  #'eldoc-doc-buffer
  (kbd "]d") #'flymake-goto-next-error
  (kbd "[d") #'flymake-goto-prev-error)

;; --- SPC leader (press SPC and wait for the which-key menu) ---
(evil-set-leader '(normal visual motion) (kbd "SPC"))
(evil-define-key '(normal visual motion) 'global
  (kbd "<leader>SPC") #'project-find-file        ; find file in project
  (kbd "<leader>/")   #'consult-ripgrep          ; search text in project (Ctrl+Shift+F)
  (kbd "<leader>:")   #'execute-extended-command ; command palette (Ctrl+Shift+P)
  (kbd "<leader>e")   #'my/toggle-file-tree
  ;; files
  (kbd "<leader>ff")  #'find-file
  (kbd "<leader>fr")  #'consult-recent-file
  (kbd "<leader>fs")  #'save-buffer
  ;; buffers
  (kbd "<leader>bb")  #'consult-buffer
  (kbd "<leader>bk")  #'kill-current-buffer
  ;; project
  (kbd "<leader>pp")  #'project-switch-project
  (kbd "<leader>pc")  #'project-compile
  ;; code (LSP)
  (kbd "<leader>ca")  #'eglot-code-actions
  (kbd "<leader>cr")  #'eglot-rename
  (kbd "<leader>cf")  #'eglot-format-buffer
  (kbd "<leader>cd")  #'flymake-show-buffer-diagnostics
  (kbd "<leader>cD")  #'flymake-show-project-diagnostics
  (kbd "<leader>cs")  #'consult-imenu            ; go to symbol in file (Ctrl+Shift+O)
  ;; git
  (kbd "<leader>gg")  #'my/lazygit
  (kbd "<leader>gb")  #'vc-annotate              ; blame (built-in)
  (kbd "<leader>gr")  #'diff-hl-revert-hunk      ; undo the change under cursor
  (kbd "]h")          #'diff-hl-next-hunk
  (kbd "[h")          #'diff-hl-previous-hunk
  ;; windows
  (kbd "<leader>wv")  #'evil-window-vsplit
  (kbd "<leader>ws")  #'evil-window-split
  (kbd "<leader>wd")  #'evil-window-delete
  (kbd "<leader>ww")  #'other-window
  ;; help
  (kbd "<leader>hk")  #'describe-key
  (kbd "<leader>hf")  #'describe-function
  (kbd "<leader>hv")  #'describe-variable)

;; Ctrl+h/j/k/l to move between splits (like many vim setups).
(evil-define-key 'normal 'global
  (kbd "C-h") #'evil-window-left
  (kbd "C-j") #'evil-window-down
  (kbd "C-k") #'evil-window-up
  (kbd "C-l") #'evil-window-right)

;; Escape quits minibuffer prompts too.
(global-set-key (kbd "<escape>") #'keyboard-escape-quit)

;;; Notes --------------------------------------------------------------------
;; Language servers eglot will use if they're on your PATH:
;;   Go:          go install golang.org/x/tools/gopls@latest
;;   TS/JS:       npm i -g typescript@5 typescript-language-server  (TS 7 has no tsserver)
;;   Python:      npm i -g pyright
;;   C/C++:       clangd (ships with Xcode command line tools)
;;   Rust:        rustup component add rust-analyzer
;; Other languages: M-x eglot in a file of that language.
