;;; Commentary:

;; グロバールキーバンディング定義

;;; Code:
(require 'my-lisp-utils)

(message "init_keybinding ...")

;;
;; prefixキーマップの定義
;;______________________________________________________________________
(define-key global-map (kbd "C-z") (make-sparse-keymap))

;;
;; keymap 優先順位の制御
;;______________________________________________________________________
;; マイナモードのキーマップ衝突問題を対応するために、マイナモード優先順位を制御する
;; (install-elisp-from-emacswiki "minor-mode-hack.el")
(require 'minor-mode-hack)
;; (lower-minor-mode-map-alist 'java-mode)
;; (raise-minor-mode-map-alist 'auto-complete-mode)

;;
;; caps sticky --> just like capslock
;;______________________________________________________________________
;; 「；」を押しことで単語の先頭文字を大文字にする
;; (install-elisp-from-emacswiki "sticky.el")
;; (require 'sticky)
;; (use-sticky-key ";" sticky-alist:ja)

;;
;; 連続操作smartrep.el
;; 導入：
;;	git clone https://github.com/myuhe/smartrep.el.git
;; ソース：
;; 	https://github.com/myuhe/smartrep.el
;; 記事：
;; 	http://sheephead.homelinux.org/2011/12/19/6930/
;; 	http://sheephead.homelinux.org/2012/01/30/6934/
;;______________________________________________________________________
(require 'smartrep)
;; プレフィックスキーの設定
(defvar ctl-t-map (make-keymap))
(define-key global-map "\C-t" ctl-t-map)
;; TODO
;; 元々 C-tに割り当てた[transpose-chars]コマンドを別のキーに割り当てする

;; smartrepモードが有効になった時のカスタマイズ
;; モードラインに表示される文字列
(setq smartrep-mode-line-string-activated
      (propertize
       "========== SMARTREP =========="
       'face
       'mode-line-buffer-id
       ;; '(face (:foreground "green"))
       ))

;; モードラインの背景色
(setq smartrep-mode-line-active-bg (face-background 'modeline))

;;; resetup mode line format smartrep
(setq mode-line-format (delete 'smartrep-mode-line-string mode-line-format))
(let ((cell (or (memq 'mode-line-position mode-line-format)
                (memq 'mode-line-buffer-identification mode-line-format)))
      (newcdr '(:eval smartrep-mode-line-string)))
  (unless (member newcdr mode-line-format)
    (setcdr cell (cons newcdr (cdr cell)))))

;; キーバインドの設定
(smartrep-define-key
    global-map "C-t" '(
                    ;; ページャモード
                    ("l"      . 'forward-char)
                    ("h"      . 'backward-char)
                    ("j"      . (scroll-up 1))
                    ("k"      . (scroll-up -1))
                    ;; FIX問題：smartrepモードになれず
                    ("<down>" . 'scroll-down)
                    ("<up>"   . 'scroll-up)
                    ("SPC"    . 'scroll-up)
                    ("b"      . 'scroll-down)
                    ;; 二画面分割時の画面移動
                    ("a"      . (beginning-of-buffer-other-window 0))
                    ("e"      . (end-of-buffer-other-window 0))
                    ("n"      . (scroll-other-window 1))
                    ("p"      . (scroll-other-window -1))
                    ("N"      . 'scroll-other-window)
                    ("P"      . (scroll-other-window '-))
                    ("i"      . 'keyboard-quit)
                    ))

;;
;; sequential typing (時間かかるため延時ロード)
;;______________________________________________________________________
;; 同じコマンドを連続実行したときの振舞いを変更する
;; (auto-install-batch "sequential-command")
;; 例：C-a C-a、一回目は行の先頭へ飛び、二回目はバッファーの先頭へ飛び
;;    M-u M-l M-cの挙動を使いやすくにする
(require 'sequential-command-config)
(sequential-command-setup-keys)

;; 強制的次のコマンドへシフトする
(defun my-seq-next ()
  (if (not (eq last-command this-command))
      (setq last-command this-command))
  (call-interactively this-command))

;;; カーソルスマート移動できるマクロの定義
(defmacro my-seq-define-cursor-command (source-command &optional comp-form)
  (declare (indent 1))
  (setq comp-form (or comp-form
                      '(= seq-old-point seq-new-point)))
  `(defun ,(intern (concat "seq-" (symbol-name source-command))) ()
     (interactive)
     (let ((seq-old-point (point)))
       (call-interactively ',source-command)
       (let ((seq-new-point (point)))
         (when ,comp-form
           (my-seq-next))))))

;;; 前へ移動系コマンドの定義
(my-seq-define-cursor-command back-to-indentation-or-beginning)
(my-seq-define-cursor-command beginning-of-line)
(my-seq-define-cursor-command beginning-of-defun)
(my-seq-define-cursor-command beginning-of-buffer)

;; C-a キーバンディング再定義
(define-sequential-command
  seq-home                ;コマンドID
  seq-back-to-indentation-or-beginning
                          ;;back-to-indentation-or-beginning          ;行頭空白でないところ
  seq-beginning-of-line   ;行頭
  seq-beginning-of-defun  ;関数先頭へ
  seq-beginning-of-buffer ;バッファー先頭
  seq-return)             ;現在の位置に戻る

;; C-e キーバンディング再定義
(define-sequential-command
  seq-end                               ;コマンドID
  end-of-line                           ;行末へ
  end-of-defun                          ;関数終了ポイント
  end-of-buffer                         ;バッファーの後尾
  seq-return)                           ;元に戻る

;; ---- 定義済みコマンド
;; (global-set-key "\C-a" 'seq-home)
;; (global-set-key "\C-e" 'seq-end)
;; (global-set-key "\M-u" 'seq-upcase-backward-word)
;; (global-set-key "\M-c" 'seq-capitalize-backward-word)
;; (global-set-key "\M-l" 'seq-downcase-backward-word)

;;
;; chord key binding
;;______________________________________________________________________
;; キーボード同時押しでコマンドを実行する
;; (install-elisp "http://www.emacswiki.org/emacs/download/key-chord.el")
(require 'key-chord)
(setq key-chord-two-keys-delay 0.05)
(key-chord-mode 1)

;; emacs-lisp-mode メジャーモードで df で describe-functionを実行する
(key-chord-define emacs-lisp-mode-map "df" 'describe-function)

;;
;; ミニバッファのカスタマイズキーバンド
;;______________________________________________________________________
;;; ミニバッファに現在ポイントの文字列を挿入する
(define-key minibuffer-local-map (kbd "C-,")  'my-minibuffer-insert-thing-at-point)

(defun my-minibuffer-insert-thing-at-point ()
  (interactive)
  (let (current-thing)
    (save-excursion
        ;; バッファーを一時的に切り替える
        (with-current-buffer (window-buffer (minibuffer-selected-window))
          (setq current-thing (my-thing-at-point)))
        (if current-thing
            (insert-string current-thing)))))

;; パスを1階層ずつ削除
(defun my-minibuffer-delete-parent-directory (donot-expand-home)
  "Delete one level of file path."
  (interactive "P")
  (let ((current-pt (point))
        (home-path-idx (if donot-expand-home nil
                         (string-match ": ~[/]?$" (buffer-substring-no-properties (point-min) (point))))))
    ;; ~ の展開
    (if home-path-idx
        (progn
          (goto-char (+ 3 home-path-idx))
          (delete-forward-char 2)
          (insert (expand-file-name "~/")))
      ;; パス階層削除
      (when (re-search-backward "/[^/]+/?" nil t)
        (forward-char 1)
        (delete-region (point) current-pt)))))
(define-key minibuffer-local-map (kbd "M-^") 'my-minibuffer-delete-parent-directory)

;;
;; 鬼軍曹.el
;;______________________________________________________________________
;; blog   ->  http://blog.livedoor.jp/k1LoW/archives/65055608.html
;; github ->  https://github.com/k1LoW/emacs-drill-instructor
;; (install-elisp "https://raw.github.com/k1LoW/emacs-drill-instructor/master/drill-instructor.el")
;; (require 'drill-instructor)
;; (setq drill-instructor-global t)

;; ;; ↓ここから追加
;; (mapc (lambda (name)
;;         (fset name 'kill-emacs))
;;       '(drill-instructor-alert-up
;;         drill-instructor-alert-down
;;         drill-instructor-alert-right
;;         drill-instructor-alert-left
;;         drill-instructor-alert-del
;;         drill-instructor-alert-return
;;         drill-instructor-alert-tab))

;;
;; one-key キー入力支援
;;______________________________________________________________________
;;; wiki http://www.emacswiki.org/emacs/OneKey
;;; install
;; (install-elisp "http://www.emacswiki.org/emacs/download/hexrgb.el")
;; (install-elisp "http://www.emacswiki.org/cgi-bin/wiki/download/one-key.el")
;; (install-elisp "http://www.emacswiki.org/cgi-bin/wiki/download/one-key-config.el")
;; (install-elisp "http://www.emacswiki.org/cgi-bin/wiki/download/one-key-default.el")
;; (require 'one-key-default) ; one-key.el も一緒に読み込んでくれる
;; (require 'one-key-config) ; one-key.el をより便利にする
;; (one-key-default-setup-keys) ; one-key- で始まるメニュー使える様になる
;; ;; (define-key global-map "\C-x" 'one-key-menu-C-x) ;; C-x にコマンドを定義
;; (require 'one-key)

;;
;; OneTwoThreeMenu キー入力支援
;;______________________________________________________________________
;; (install-elisp "http://www.emacswiki.org/emacs/download/123-menu.el")
(require '123-menu)
(require 'my-123-menu)

;;
;; general key bind
;;______________________________________________________________________
;; "M-Tab" を "C-z Tab" にリングする
(add-hook 'after-init-hook (lambda()
                             (setf (global-key-binding (kbd "C-z <tab>")) (kbd "M-<tab>"))
                             (setf (global-key-binding (kbd "C-z TAB")) (kbd "M-<tab>"))))

;; help key変更
(global-set-key "\M-?" 'help-for-help)

;; (global-set-key "f1" 'help-command)
;; (define-key global-map (kbd "C-h") 'delete-char)

;; home, end キー再バンディングする
(if (fboundp 'back-to-indentation-or-beginning)
    (global-set-key [home] 'back-to-indentation-or-beginning)
    (global-set-key [home] 'move-beginning-of-line)
  )

(global-set-key [end] 'move-end-of-line)

;; M-u に単語をupcase/downcase/capitalizeに動的にする
(global-set-key "\M-u" 'toggle-letter-case)

;; 折り返し制御
(global-set-key [f12] 'toggle-truncate-lines)

;; 状態を脱出する
(global-set-key (kbd "C-M-g") 'keyboard-escape-quit)

;; ファイル検索
(global-set-key (kbd "<C-f3>") 'find-name-dired)

(provide 'init_keybinding)
;;; init_keybinding.el ends here
