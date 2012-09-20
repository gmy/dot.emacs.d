;;; mew-dispicon.el --- Drag & drop $B$7$?$j!"(BIcon $BI=<($7$?$j(B
;;
;; Author: Hideyuki SHIRAI <shirai@mew.org>
;; Keywords: Windows, Icon, Mew
;;

;; Copyright (C) 2005 Hideyuki SHIRAI <shirai@meadowy.org>

;; $B;H$$J}(B
;; 1. http://wiki.gohome.org/teranisi/?EmacsOnWindows $B$+$i(B dropfile
;;    $B$H(B dispicon $B$rF~<j$7$F$/$@$5$$!#(B
;;
;; 2. ~/.mew $B$G(B (require 'mew-dispicon)
;;
;; 3. summary $B$H$+(B message buffer $B$N$=$l$i$7$-$H$3$m$r(B mouse-1 $B$r2!$9$H(B
;;    Windows application $B$K(B drag & drop $B$G$-$^$9!#(B
;;

(eval-when-compile
  (require 'mew)
  (require 'dropfile)
  (require 'dispicon))

(defvar mew-mw32-dropfile-use-icon t
  "*Icon $BI=<($NF0:n@_Dj!#(Bicon $B$,$J$/$F$b(B dropfile $B$O$G$-$k!#(B
t $B$G(B summary $B$b(B message $B$b(B icon $BI=<(!#(B
nil $B$G(B icon $B$rI=<($7$J$$!#(B
'summary-only $B$G(B summary $B$N$_(B icon $BI=<(!#(B")

(defvar mew-mw32-dropfile-dummies
  `(("image/jpeg" . "drop.jpg")
    ("image/png" .  "drop.png")
    ("image/gif" .  "drop.gif")
    ("image/tiff" . "drop.tif")
    ("text/html"  . "drop.htm")
    ("text/plain" . "drop.txt"))
  "*Dropfile $B$r;H$&$H$-$K%U%!%$%kL>$,L5$$$H$-$N%F%s%]%i%j%U%!%$%kL>!#(B
HTML $BCf$N(B CID $B2hA|I=<($J$I$KJXMx$N$h$&$J5$$,$9$k!#(B")

(defvar mew-mw32-dropfile-force-denotation t
  "*$B%U%!%$%kL>$,$J$/$F$b$`$j$d$jI=<($9$k!#(B
Decode policy $B$,(B STRICT $B$J$I$N$H$-$KNI$$$+$b!#(B")

(add-hook 'mew-syntax-format-hook 'mew-summary-mw32-dropfile 'append)
(add-hook 'mew-message-hook 'mew-message-mw32-dropfile 'apend)

(defun mew-mw32-dropfile (file buf beg end &optional cs)
  (with-temp-buffer
    (mew-frwlet
     mew-cs-dummy (or cs mew-cs-binary)
     (insert-buffer-substring-no-properties buf beg end)
     (write-region (point-min) (point-max) file nil 'nomsg)))
  (dropfile file))

(eval-when-compile
  (defvar ct)
  (defvar syntax)
  (defvar filename))

(defun mew-summary-mw32-dropfile ()
  "summary $B$N(B syntax $BI=<($G(B icon & dropfile."
    ;; ct, syntax, filename $B$O(B hook $BFb$G(B bind $B$5$l$F$$$k!#(B
  (when (and (string-match mew-buffer-cache-prefix (buffer-name))
	     (not (string= "Message/Rfc822" ct))
	     (not (mew-case-equal ct mew-ct-msg))
	     (or (not mew-mw32-dropfile-use-icon)
		 (fboundp 'dispicon))
	     (fboundp 'dropfile)
	     window-system
	     (not (string= ct "RFC822")))	;; $BGr0f@lMQ(B
    (condition-case nil
	(let* ((ctl (mew-syntax-get-ct syntax))
	       (params (mew-syntax-get-params ctl))
	       (ct (downcase (if (stringp ctl) ctl (car ctl))))
	       (buf (current-buffer))
	       (beg (mew-syntax-get-begin syntax))
	       (end (mew-syntax-get-end syntax))
	       (cs (mew-charset-to-cs (mew-syntax-get-param params "charset")))
	       (map (make-sparse-keymap))
	       fullname orgfile bmpfile)
	  (unless filename
	    (setq filename (or (cdr (assoc ct mew-mw32-dropfile-dummies))
			       (and mew-mw32-dropfile-force-denotation "drop.dmy"))))
	  (setq orgfile filename)
	  (when (and (not cs) (string-match "^text" ct))
	    (setq cs 'shift_jis-dos))
	  (when filename
	    (setq fullname (expand-file-name filename mew-temp-dir))
	    ;; $BK\Ev$O(B overlay $B$K$7$?$$$,L5M}!#(B
	    (when mew-mw32-dropfile-use-icon
	      (if (or (string-match "\\.bmp$" (downcase filename))
		      (string-match "\\.ico$" (downcase filename))
		      (string-match "\\.exe$" (downcase filename)))
		  ;; BMP/ICO/EXE $B$OL5M}LpM}(B ICON $B$KCf?H$rI=<($7$F$_$k(B
		  (with-temp-buffer
		    (mew-flet
		     (insert-buffer-substring-no-properties buf beg end)
		     (write-region (point-min) (point-max) fullname nil 'nomsg))
		    (setq bmpfile fullname)
		    (setq filename
			  (concat
			   (dispicon bmpfile 'small
				     (aref (font-info (face-font 'default (selected-frame))) 3))
			   " " filename)))
		(setq filename
		      (concat
		       (dispicon filename 'small
				 (aref (font-info (face-font 'default (selected-frame))) 3))
		       " " filename))))
	    (define-key map [down-mouse-1] `(lambda ()
					      (interactive)
					      (mew-mw32-dropfile ,fullname ,buf ,beg ,end
								 (quote ,cs))))
	    (add-text-properties 0 (length filename)
				 `(keymap ,map mouse-face highlight
					  dropfile ,orgfile
					  bmpfile ,bmpfile
					  help-echo "mouse-1: Drop to the other application")
				 filename)))
	(error nil))))

(defadvice mew-summary-execute-external (after mw32-dropfile activate)
  "Advice for dropfile."
  (let ((win (selected-window))
	(mbuf (mew-buffer-message)))
    (if (get-buffer-window mbuf)
	(set-buffer mbuf)
      (mew-window-configure 'message))
    (mew-message-mw32-dropfile)
    (select-window win)))

(defun mew-message-mw32-dropfile ()
  "messge buffer $B$N@hF,$G(B icon & dropfile."
  (when (and (or (not mew-mw32-dropfile-use-icon)
		 (fboundp 'dispicon))
	     (fboundp 'dropfile)
	     window-system)
    (let ((vfld (mew-minfo-get-summary))
	  (w3mprop (get-text-property (point-min) 'w3m))
	  filename orgfile map dropfile pos beg)
      (unless (get-text-property (point-min) 'dropfile)
	(when (get-buffer vfld)
	  (save-excursion
	    (set-buffer vfld)
	    (setq pos (point))
	    (end-of-line)
	    (skip-chars-backward " \r.")
	    (backward-char 1)
	    (setq filename (get-text-property (point) 'dropfile))
	    (setq dropfile (or (get-text-property (point) 'bmpfile) filename))
	    (setq map (get-text-property (point) 'keymap))
	    (goto-char pos))
	  (when (and filename map)
	    (setq orgfile filename)
	    (goto-char (point-min))
	    (mew-elet
	     (insert ";; ")
	     (add-text-properties (point-min) (1- (point))
				  `(invisible t dropfile ,orgfile))

	     (setq beg (point))
	     (when (and mew-mw32-dropfile-use-icon
			(not (eq mew-mw32-dropfile-use-icon 'summary-only)))
	       (insert (dispicon dropfile 'large))
	       (insert " "))
	     (insert filename)
	     (add-text-properties beg (point)
				  `(keymap ,map mouse-face highlight
					   face mew-face-header-from
					   dropfile ,orgfile
					   help-echo "mouse-1: Drop to the other application"))
	     (insert "\n\n")
	     (when w3mprop
	       (put-text-property (point-min) (point) 'w3m t)))))))))

(provide 'mew-dispicon)

;;drop.htm

