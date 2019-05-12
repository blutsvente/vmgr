;put a new button into the menu bar
(add-menu-item nil "Revert" 'revert-buffer t)

(defun prepend-path ( my-path )
  (setq load-path (cons (expand-file-name my-path) load-path)))

(defun append-path ( my-path )
  (setq load-path (append load-path (list (expand-file-name my-path)))))

;; workaround for un-debugged problem
;;(setq allow-remote-paths 1)

;;
;; all search pathes; the order is significant
;;
;;(append-path "/home/thorsten/data/xemacs/lisp")
;; (append-path "/tools/gnu/lib/xemacs/xemacs-packages/lisp/xemacs-base")
;; locally installed
(prepend-path "/home/dworzakx/data/lisp")
;;(append-path "/home/thorsten/data/lisp/xemacs-base")
;;(append-path "/home/thorsten/data/lisp/prog-modes")
;;(append-path "/home/thorsten/data/lisp/cc-mode")
;;(append-path "/home/thorsten/data/lisp/perl-modes")
;;(append-path "/home/thorsten/data/lisp/muse")
;;
;;(append-path "/tools/gnu/lib/xemacs/xemacs-packages/lisp")
;;(append-path "/tools/gnu/lib/xemacs/xemacs-packages/lisp/edit-utils")
;;(append-path "/tools/gnu/lib/xemacs/xemacs-packages/lisp/mail-lib")
;;(append-path "/home/thorsten/data/lisp/mmm-mode")
;;(append-path "/home/thorsten/data/lisp/psgml")
;;(append-path "/tools/gnu/lib/xemacs/xemacs-packages/lisp/text-modes")
;;(append-path "/tools/gnu/lib/xemacs/xemacs-packages/lisp/net-utils")

(defalias 'perl-mode 'cperl-mode)
(autoload 'cperl-mode "cperl-mode" "CPerl mode" t)
(setq auto-mode-alist (cons  '("\\.pl\\'" . cperl-mode) auto-mode-alist))
(setq auto-mode-alist (cons  '("\\.pm\\'" . cperl-mode) auto-mode-alist))

;; load c-mode
(autoload 'c-mode "cc-mode" "C mode" t)
(setq auto-mode-alist (cons  '("\\.c\\'" . c-mode) auto-mode-alist))
(setq auto-mode-alist (cons  '("\\.cpp\\'" . c-mode) auto-mode-alist))
(setq auto-mode-alist (cons  '("\\.h\\'" . c-mode) auto-mode-alist))

;; load vhdl-mode
(autoload 'vhdl-mode "vhdl-mode" "VHDL mode" t)
(setq auto-mode-alist (cons  '("\\.vhd\\'" . vhdl-mode) auto-mode-alist))
(setq auto-mode-alist (cons  '("\\.vhdl\\'" . vhdl-mode) auto-mode-alist))

;; Load verilog mode only when needed
(autoload 'verilog-mode "verilog-mode" "Verilog mode" t )
(setq auto-mode-alist (cons  '("\\.v\\'" . verilog-mode) auto-mode-alist))
(setq auto-mode-alist (cons  '("\\.vh\\'" . verilog-mode) auto-mode-alist))
(setq auto-mode-alist (cons  '("\\.sv\\'" . verilog-mode) auto-mode-alist))
(setq auto-mode-alist (cons  '("\\.svh\\'" . verilog-mode) auto-mode-alist))

;; Load tcl mode
(autoload 'tcl-mode "tcl-mode" "Tcl mode" t )
(setq auto-mode-alist (cons  '("\\.tcl\\'" . tcl-mode) auto-mode-alist))
(setq auto-mode-alist (cons  '("\\.custom\\'" . tcl-mode) auto-mode-alist))

;; Any files that end in .v should be in verilog mode
(setq auto-mode-alist (cons  '("\\.v\\'" . verilog-mode) auto-mode-alist))
;; Any files in verilog mode should have their keywords colorized
(add-hook 'verilog-mode-hook '(lambda () (font-lock-mode 1)))

;; M4-mode
(autoload 'm4-mode "m4-mode" nil t)

(setq auto-mode-alist
       (cons '(".*\\.m4$" . m4-mode)
             auto-mode-alist))

;; Make-mode
(autoload 'makefile-mode "make-mode" nil t)
(setq auto-mode-alist (cons '("\\Makefile.*\\'" . makefile-mode) auto-mode-alist))

(require 'compile)		; make sure 'compile.el' is initialized

;;; ffap - find file at point (Note: does not seem to work in XEmacs)
(require 'ffap)
;; rebind C-x C-f and others to the ffap bindings (see variable ffap-bindings)
(ffap-bindings)
;; C-u C-x C-f finds the file at point
(setq ffap-require-prefix t)
;; browse urls at point via w3m
(setq ffap-url-fetcher 'w3m-browse-url)

;; -----------------------------------------------------------------------------
;; muse-mode
;;
;; -----------------------------------------------------------------------------
(require 'easy-mmode)
;;(require 'code-cmds) 
;;(require 'files)
;;(require 'code-files) 
;;(require 'code-process) 
;;(require 'muse-mode)
;;(require 'muse-publish)
;;(require 'muse-html)  ;; and so on

;; load PSGML mode
(autoload 'sgml-mode "psgml" "Major mode to edit SGML files." t)
(autoload 'xml-mode "psgml" "Major mode to edit XML files." t)
(autoload 'html-mode "psgml" "Major mode to edit XML files." t)
(setq auto-mode-alist (cons  '("\\.xml\\'" . xml-mode) auto-mode-alist))
(setq auto-mode-alist (cons  '("\\.xsd\\'" . xml-mode) auto-mode-alist))

;; required by file selector box
(require 'annotations)

;; automatically start gnuserv
(gnuserv-start)

;; My menu item to insert Verilog body
(defvar vlog-project (or (getenv "PROJECT") "mic32"))

(defun verilog-insert-file-body()
  (interactive)
  (let ((start (point)))
  (insert-file "~/data/verilog_body.tmpl")
    (goto-char start)
    (search-forward "<author>") (replace-match "" t t)
    (insert (user-full-name))
	(search-forward "<copydate>") (replace-match "" t t)
    (specman-insert-year)
    (goto-char start)
    (let (string)
      (setq string (read-string "project: " vlog-project))
      (make-variable-buffer-local 'vlog-project)
      (setq vlog-project string)
      (search-forward "<project>")
      (replace-match string t t))
    (let (string)
      (setq string (read-string "module-name: " string))
      (make-variable-buffer-local 'string)
      (search-forward "<name>")
      (replace-match string t t)
      (search-backward "<description>")
      (replace-match "" t t)))
)
(defun verilog-insert-file-body2()
  (interactive)
  (let ((start (point)))
  (insert-file "~/data/system_verilog_body.tmpl")
    (goto-char start)
    (search-forward "<author>") (replace-match "" t t)
    (insert (user-full-name))
	(search-forward "<copydate>") (replace-match "" t t)
    (specman-insert-year)
    (goto-char start)
    (let (string)
      (setq string (read-string "project: " vlog-project))
      (make-variable-buffer-local 'vlog-project)
      (setq vlog-project string)
      (search-forward "<project>")
      (replace-match string t t))
    (let (string)
      (setq string (read-string "module-name: " string))
      (make-variable-buffer-local 'string)
      (search-forward "<name>")
      (replace-match string t t)
      (search-backward "<description>")
      (replace-match "" t t)))
)
(defun verilog-insert-file-body3()
  (interactive)
  (let ((start (point)))
  (insert-file "~/data/system_verilog_pkg.tmpl")
    (goto-char start)
    (search-forward "<author>") (replace-match "" t t)
    (insert (user-full-name))
	(search-forward "<copydate>") (replace-match "" t t)
    (specman-insert-year)
    (goto-char start)
    (let (string)
      (setq string (read-string "project: " vlog-project))
      (make-variable-buffer-local 'vlog-project)
      (setq vlog-project string)
      (search-forward "<project>")
      (replace-match string t t))
    (let (string)
      (setq string (read-string "pkg-name: " string))
      (make-variable-buffer-local 'string)
      (search-forward "<name>")
      (replace-match (upcase string) t t)
      (search-forward "<name>")
      (replace-match (upcase string) t t)
      (search-forward "<name>")
      (replace-match string t t)
      (search-backward "<description>")
      (replace-match "" t t))
))
(defun verilog-insert-file-body4()
  (interactive)
  (let ((start (point)))
  (insert-file "~/data/system_verilog_class.tmpl")
    (goto-char start)
    (search-forward "<author>") (replace-match "" t t)
    (insert (user-full-name))
	(search-forward "<copydate>") (replace-match "" t t)
    (specman-insert-year)
    (goto-char start)
    (let (string)
      (setq string (read-string "project: " vlog-project))
      (make-variable-buffer-local 'vlog-project)
      (setq vlog-project string)
      (search-forward "<project>")
      (replace-match string t t))
    (let (string)
      (setq string (read-string "class-name: " string))
      (make-variable-buffer-local 'string)
      (search-forward "<name>")
      (replace-match (upcase string) t t)
      (search-forward "<name>")
      (replace-match (upcase string) t t)
      (search-forward "<name>")
      (replace-match string t t)
    (let (string)
      (setq string (read-string "base-class: " string))
      (make-variable-buffer-local 'string)
      (search-forward "<base-class>")
      (replace-match string t t))
      (search-backward "<description>")
      (replace-match "" t t)
)))

(defun verilog_mode_add_insert_body()
  (interactive)
  (add-menu-item '("Verilog" "Insert") "Verilog-1995 Template" 'verilog-insert-file-body t "Line up declarations around point")
  (add-menu-item '("Verilog" "Insert") "SystemVerilog Module Template" 'verilog-insert-file-body2 t "Line up declarations around point")
  (add-menu-item '("Verilog" "Insert") "SystemVerilog Package Template" 'verilog-insert-file-body3 t "Line up declarations around point")
  (add-menu-item '("Verilog" "Insert") "SystemVerilog OVM Class Template" 'verilog-insert-file-body4 t "Line up declarations around point")
)
(add-hook 'verilog-mode-hook 'verilog_mode_add_insert_body)

;; end "My menu..."
;;	local setup's
;;
(global-set-key "\C-x\C-c" nil)
;; occur
(global-set-key (kbd "C-c o") 'occur)
;; grep recursive
(global-set-key (kbd "C-c g") 'grep-all-files-in-current-directory-and-below)
;; Make F1 revert-buffer w/o asking
(global-set-key [f1] '(lambda () (interactive) (revert-buffer nil t)))
;; Make f4/8/12 copy/past/cut
(global-set-key [f4] 'x-copy-primary-selection)
(global-set-key [f8] 'x-yank-clipboard-selection)
(global-set-key [f5] 'x-kill-primary-selection)
(global-set-key [f9] 'shell-command-on-file)
;; mouse scroll button
(global-set-key [button4] '(lambda () (interactive) (scroll-down 4)))
(global-set-key [button5] '(lambda () (interactive) (scroll-up 4)))

;;(global-set-key [(alt ?x)] 'execute-extended-command)
;;(global-set-key [(alt ?g)] 'goto-line)
(setq-default tab-width 3)
;;(setq vc-checkin-switches '("-u"))
;;(setq vc-checkout-switches '("-l"))

;; auto-delete selected region
(pending-delete-mode 1)

