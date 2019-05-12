(custom-set-variables
 '(cperl-indent-level 4)
 '(cperl-invalid-face (quote default))
 '(ecb-layout-name "left-thorsten")
 '(ecb-options-version "2.31")
 '(ecb-source-path (quote (("/var/vob/com_vip/COMeVC/vob/units/soc_evc" "SOC_EVC") "/var/vob/com_vip/COMeVC/vob" "/vobs/ipr_ia-subsys_xg642-vob/units/subsys_sofia" "/vobs/ipr_ia-subsys_bhn_lte-vob/units/subsys_sofia" "/vobs/iprnoc-csf_rtl-vob/units/mnoc_router" "/vobs/ipr_ia-subsys_xg746-vob" ("/home/dworzakx" "HOME"))))
 '(fill-column 200)
 '(font-lock-auto-fontify t)
 '(font-lock-mode t nil (font-lock))
 '(frame-background-mode (quote light))
 '(get-frame-for-buffer-default-instance-limit nil)
 '(gnuserv-frame (quote gnuserv-visible-frame-function))
 '(gnuserv-kill-quietly t)
 '(gutter-buffers-tab-visible-p nil)
 '(htmlize-html-major-mode (quote html-mode))
 '(kill-whole-line t)
 '(lazy-shot-mode t nil (lazy-shot))
 '(line-number-mode t)
 '(package-get-install-to-user-init-directory t)
 '(paren-max-blinks 40)
 '(paren-mode (quote sexp) nil (paren))
 '(query-user-mail-address nil)
 '(ruby-indent-level 3)
 '(specman-auto-endcomments-for-major-scopes-only t)
 '(specman-auto-endcomments-kill-existing-comment nil)
 '(specman-auto-newline nil)
 '(specman-basic-offset 3)
 '(specman-company "IMC")
 '(specman-highlight-beyond-max-line-length nil)
 '(specman-max-line-length 200)
 '(specman-package "ifx_soc")
 '(specman-project "soc_evc")
 '(specman-tab-width 3 t)
 '(user-mail-address "thorsten.dworzak@verilab.com")
 '(verilog-auto-endcomments nil)
 '(verilog-auto-newline nil)
 '(verilog-linter "")
 '(vhdl-basic-offset 3)
 '(vhdl-entity-file-name (quote (".*" . "\\&-e")))
 '(vhdl-standard (quote (93 nil)))
 '(vhdl-underscore-is-part-of-word t)
 '(vhdl-upper-case-keywords t)
 '(zmacs-regions t))

(set-variable' fill-column 200)

(add-hook 'after-save-hook 'unix-sync)

(custom-set-faces
 '(default ((t (:size "12pt" :family "Lucidatypewriter"))) t)
 '(bold ((t (:size "10" :bold t))) t)
 '(bold-italic ((t (:size "10" :bold t))) t)
 '(cperl-array-face ((((class color) (background light)) (:foreground "Blue"))))
 '(cperl-hash-face ((((class color) (background light)) (:foreground "Red"))))
 '(highlight ((t (:bold nil))) t)
 '(specman-highlight-beyond-max-line-length-face ((t nil))))

;; MUSE stuff
;;(setq muse-project-alist
;;      '(("notes" ("~/text" :default "index")
;;         (:base "html" :path "~/text")
;;         (:base "pdf" :path "~/text"))))

;; customize Verilog mode
(setq-default indent-tabs-mode nil)

;; Use bash, not tcsh
(setq shell-command-switch "-ic")
(setq shell-file-name "/bin/bash")

;; daniel's function
(defun shell-command-on-file ()
  "Execute 'shell-command' on current open file and display the output in the minibuffer. If prefix argument insert command output at current point."
  (interactive)
  (shell-command
   (concat
    (read-string "shell-command-on-file: ") ; command
    " "                             ; space
    (buffer-file-name)              ; filename
    )
   current-prefix-arg)
  (revert-buffer t nil t)
  )

;;(require 'i-switch)
;;(require 'speedbar)

;; --------------------------
;; TCL mode
;; --------------------------
(autoload 'tcl-mode "tcl" "Tcl mode." t)
(autoload 'inferior-tcl "tcl" "Run inferior Tcl process." t)
(setq auto-mode-alist (append (list
                               (cons "\\.tcl'" 'tcl-mode)
                               (cons "\\.do'" 'tcl-mode)
                               ) auto-mode-alist))

;; --------------------------
;; Specman mode
;; --------------------------
(require 'specman-mode) 
;;(autoload 'specman-mode "specman-mode" "Specman code editing mode" t) 

(setq auto-mode-alist 
  (append (list 
	   (cons "\\.e\\'" 'specman-mode)
	   (cons "\\.e3\\'" 'specman-mode)
	   (cons "\\.load\\'" 'specman-mode)
	   (cons "\\.ecom\\'" 'specman-mode)
	   (cons "\\.etst\\'" 'specman-mode))
	  auto-mode-alist)) 
	                      
;; Any files in specman mode should have their keywords colorized 
(add-hook 'specman-mode-hook '(lambda () (font-lock-mode 1)))

;; Add another variable for the specman header
(defcustom specman-package "ifx_soc"
  "*Default name of Package for specman header. If set will become buffer local."
  :group 'specman-mode
  :type 'string  
  )

;; define a new specman header for us
(defun specman-header ()
  "Insert the company standard Specman file header."
  (interactive)
  (let ((start (point)))
  (insert "\
======================================================================
All rights reserved.
Copyright(c) <copydate> Intel Mobile Communications GmbH
======================================================================
Original Author   : Thorsten Dworzak <thorsten.dworzak@verilab.com>
Technical Contact : thorstenx.dworzak@intel.com, iNet 8-534 1027
IMC Contact       : bernhard.klein@intel.com, iNet 8-532 3614
Project           : <project>
======================================================================
<description>

======================================================================

<'
package <package>;

-- sit straight !

'>
")
    (goto-char start)
	(search-forward "<copydate>") (replace-match "" t t)
    (specman-insert-year)
    ;;(search-forward "<filename>")
    ;;(replace-match (buffer-name) t t)
    ;;(search-forward "<author>") (replace-match "" t t)
    ;;(insert (user-full-name))
    ;;(insert " <" (user-login-name) ">")
    ;;(search-forward "<email>") (replace-match "" t t)
    ;;(insert (user-mail-address))
    ;;(search-forward "<credate>") (replace-match "" t t)
    ;;(specman-insert-date)
    ;;(insert " : created")
    (goto-char start)
    (let (string)
      (setq string (read-string "project: " specman-project))
      (make-variable-buffer-local 'specman-project)
      (setq specman-project string)
      (search-forward "<project>")
      (replace-match string t t))
    (let (string1)
      (setq string1 (read-string "package: " specman-package))
      (make-variable-buffer-local 'specman-package)
      (setq specman-package string1)      
      (search-forward "<package>")
      (replace-match string1 t t)
      (search-backward "<description>")
      (replace-match "" t t)
  )))


(setq minibuffer-max-depth nil)
