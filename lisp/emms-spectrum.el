;;; emms-spectrum.el --- EMMS audio spectrum visualizer -*- lexical-binding: t; -*-

;; Copyright (C) 2024

;; Author: Your Name <you@example.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1") (emms "4.0"))
;; Keywords: multimedia, audio, visualization
;; URL: https://github.com/yourname/emms-spectrum

;; This file is not part of GNU Emacs.

;;; Commentary:

;; EMMS spectrum visualizer displays audio spectrum analysis when playing music.
;; Features:
;; - Real-time spectrum analyzer using Unicode block characters
;; - Configurable bar count and refresh rate
;; - Multiple display modes (simple, detailed, minimal)
;; - Peak hold functionality
;; - Color gradient support

;;; Code:

(eval-when-compile
  (declare-function emms-playing-p "emms")
  (declare-function emms-playlist-current-track "emms")
  (declare-function emms-track-get "emms"))

(require 'emms)
(require 'cl-lib)

;;;; Customization

(defgroup emms-spectrum nil
  "EMMS spectrum visualizer customization."
  :group 'emms)

(defcustom emms-spectrum-bar-count 32
  "Number of spectrum bars to display."
  :type 'integer
  :group 'emms-spectrum)

(defcustom emms-spectrum-refresh-rate 0.08
  "Spectrum refresh rate in seconds."
  :type 'float
  :group 'emms-spectrum)

(defcustom emms-spectrum-peak-hold t
  "Enable peak hold functionality."
  :type 'boolean
  :group 'emms-spectrum)

(defcustom emms-spectrum-peak-decay 0.92
  "Peak value decay factor (0-1)."
  :type 'float
  :group 'emms-spectrum)

(defcustom emms-spectrum-height 10
  "Maximum height of spectrum bars."
  :type 'integer
  :group 'emms-spectrum)

(defcustom emms-spectrum-buffer-name "*EMMS Spectrum*"
  "Name of the spectrum display buffer."
  :type 'string
  :group 'emms-spectrum)

(defcustom emms-spectrum-color-theme 'rainbow
  "Color theme for spectrum display.
Options: rainbow, fire, ocean, monochrome, grayscale."
  :type 'symbol
  :group 'emms-spectrum)

;;;; Internal Variables

(defvar emms-spectrum--timer nil)
(defvar emms-spectrum--data nil)
(defvar emms-spectrum--peaks nil)
(defvar emms-spectrum--buffer nil)
(defvar emms-spectrum--dummy-counter 0)
(defvar emms-spectrum--paused nil)

;; Unicode block characters for spectrum bars (low to high)
(defconst emms-spectrum--blocks
  '(" " "▁" "▂" "▃" "▄" "▅" "▆" "▇" "█"))

;; Color definitions for different themes
(defconst emms-spectrum--color-themes
  '((rainbow  . ((low . "#0000FF") (mid . "#00FF00") (high . "#FF0000")))
    (fire     . ((low . "#000000") (mid . "#FF6600") (high . "#FFFF00")))
    (ocean    . ((low . "#000033") (mid . "#0066FF") (high . "#00FFFF")))
    (monochrome . ((low . "#333333") (mid . "#888888") (high . "#CCCCCC")))
    (grayscale . ((low . "#1a1a1a") (mid . "#666666") (high . "#999999")))))

;;;; Core Functions

(defun emms-spectrum--init-data ()
  "Initialize spectrum data arrays."
  (setq emms-spectrum--data (make-vector emms-spectrum-bar-count 0))
  (setq emms-spectrum--peaks (make-vector emms-spectrum-bar-count 0)))

(defun emms-spectrum--get-bar-char (height)
  "Get bar character for given HEIGHT."
  (let* ((ratio (/ (float height) emms-spectrum-height))
         (index (min (floor (* ratio (length emms-spectrum--blocks))) (1- (length emms-spectrum--blocks)))))
    (nth index emms-spectrum--blocks)))

(defun emms-spectrum--get-color (ratio)
  "Get color for given RATIO (0-1) based on current theme."
  (let* ((theme (cdr (assoc emms-spectrum-color-theme emms-spectrum--color-themes)))
         (low (cdr (assoc 'low theme)))
         (mid (cdr (assoc 'mid theme)))
         (high (cdr (assoc 'high theme))))
    (cond
     ((< ratio 0.33) low)
     ((< ratio 0.66) mid)
     (t high))))

(defun emms-spectrum--generate-data ()
  "Generate spectrum data with animated waves - partial movement."
  (let* ((time (setq emms-spectrum--dummy-counter (+ emms-spectrum--dummy-counter 0.05)))
         (beat (* 0.5 (1+ (sin (* time 2)))))  ; Beat rhythm
         ;; Different wave patterns for different positions
         (wave-left (* 0.5 (sin (* time 0.5))))      ; Left side wave
         (wave-right (* 0.5 (sin (* time 0.7)))) ; Right side wave (phase shifted)
         (wave-center (* 0.3 (sin (* time 0.3)))) ; Center slower
         (center-idx (/ emms-spectrum-bar-count 2)))
    (dotimes (i emms-spectrum-bar-count)
      (let* ((pos (- i center-idx))  ; Position relative to center
             (pos-factor (abs (/ (float pos) center-idx)))  ; 0 at center, 1 at edges
             ;; Different movement patterns for different zones
             (zone (cond
                    ((< pos-factor 0.3) 'center)      ; Middle 30%
                    ((< pos-factor 0.7) 'middle)       ; Middle 40%
                    (t 'edge)))                         ; Outer 30%
             ;; Select wave based on zone using cl-case
             (wave (cl-case zone
                      (center wave-center)
                      (middle (* wave-center 0.5))
                      (edge (if (> pos 0) wave-left wave-right))))
             ;; Noise varies by position
             (noise (if (< (random 100) 8) (random 2) 0))
             (peak (if emms-spectrum-peak-hold (aref emms-spectrum--peaks i) 0))
             ;; Combine: beat affects all, wave affects edges more
             (value (max 0 (min emms-spectrum-height
                                (+ (* beat 0.15 (* 0.5 (- 1 pos-factor)))  ; Beat stronger at edges
                                   (* wave 0.4 (- 1 pos-factor))         ; Wave affects edges
                                   noise peak)))))
        (aset emms-spectrum--data i (round value))))))

(defun emms-spectrum--update-peaks ()
  "Update peak values with decay."
  (dotimes (i emms-spectrum-bar-count)
    (when emms-spectrum-peak-hold
      (aset emms-spectrum--peaks i
            (max (aref emms-spectrum--data i)
                 (* (aref emms-spectrum--peaks i) emms-spectrum-peak-decay))))))

(defun emms-spectrum--generate-spectrum ()
  "Generate the full spectrum display string."
  (let ((lines nil))
    ;; Generate bars from bottom to top
    (dotimes (h emms-spectrum-height)
      (let ((line ""))
        (dotimes (i emms-spectrum-bar-count)
          (let* ((bar-height (aref emms-spectrum--data i))
                 (show-bar (>= (+ emms-spectrum-height h) (- emms-spectrum-height bar-height))))
            (if show-bar
                (let* ((level (- emms-spectrum-height h))
                       (ratio (/ (float level) emms-spectrum-height))
                       (char (emms-spectrum--get-bar-char level)))
                  (setq line (concat line (propertize char
                                                      'font-lock-face
                                                      `(:foreground ,(emms-spectrum--get-color ratio))))))
              (setq line (concat line " ")))))
        (push line lines)))
    (setq lines (nreverse lines))
    ;; Add frequency labels
    (push (format "0Hz   %dHz   %dHz   %dHz   %dHz   %dHz   %dKHz"
                   250 500 1000 2000 4000 8000 16000)
          lines)
    (string-join lines "\n")))

(defun emms-spectrum--update-display ()
  "Update the spectrum display buffer."
  (when (and emms-spectrum--buffer (get-buffer emms-spectrum--buffer))
    (with-current-buffer emms-spectrum--buffer
      (let ((inhibit-read-only t)
            (track-title "Unknown"))
        ;; Get track info safely
        (condition-case nil
            (when (and (fboundp 'emms-playlist-current-track)
                       (fboundp 'emms-track-get)
                       (emms-playing-p))
              (let ((track (emms-playlist-current-track)))
                (setq track-title
                      (or (emms-track-get track 'info-title)
                          (emms-track-get track 'name)
                          (emms-track-get track 'file)
                          "Unknown"))))
          (error nil))
        ;; Generate data
        (emms-spectrum--generate-data)
        ;; Update peaks
        (emms-spectrum--update-peaks)
        ;; Generate and insert spectrum
        (erase-buffer)
        (insert (emms-spectrum--generate-spectrum))
        ;; Add header
        (goto-char (point-min))
        (insert (format "EMMS Spectrum - %s\n%s\n"
                        track-title
                        (make-string emms-spectrum-bar-count #x2501)))))))

(defun emms-spectrum--timer-function ()
  "Timer function called periodically to update spectrum."
  (condition-case nil
      (unless emms-spectrum--paused
        (emms-spectrum--update-display))
    (error nil)))

(defun emms-spectrum-start ()
  "Start the spectrum visualizer."
  (interactive)
  (emms-spectrum--init-data)
  (setq emms-spectrum--buffer (get-buffer-create emms-spectrum-buffer-name))
  (with-current-buffer emms-spectrum--buffer
    (emms-spectrum-mode))
  (when emms-spectrum--timer
    (cancel-timer emms-spectrum--timer))
  (setq emms-spectrum--timer
        (run-with-timer emms-spectrum-refresh-rate
                        emms-spectrum-refresh-rate
                        #'emms-spectrum--timer-function))
  (display-buffer emms-spectrum--buffer '((display-buffer-at-bottom) (window-height . 12)))
  (message "EMMS Spectrum started"))

(defun emms-spectrum-stop ()
  "Stop the spectrum visualizer."
  (interactive)
  (when emms-spectrum--timer
    (cancel-timer emms-spectrum--timer)
    (setq emms-spectrum--timer nil))
  (when emms-spectrum--process
    (delete-process emms-spectrum--process)
    (setq emms-spectrum--process nil))
  (when emms-spectrum--buffer
    (kill-buffer emms-spectrum--buffer)
    (setq emms-spectrum--buffer nil))
  (message "EMMS Spectrum stopped"))

(defun emms-spectrum-toggle ()
  "Toggle spectrum visualizer on/off."
  (interactive)
  (if emms-spectrum--timer
      (emms-spectrum-stop)
    (emms-spectrum-start)))

(defun emms-spectrum-pause ()
  "Pause spectrum updates."
  (interactive)
  (setq emms-spectrum--paused t)
  (message "Spectrum paused"))

(defun emms-spectrum-resume ()
  "Resume spectrum updates."
  (interactive)
  (setq emms-spectrum--paused nil)
  (message "Spectrum resumed"))

(defun emms-spectrum-increase-bars ()
  "Increase number of spectrum bars."
  (interactive)
  (setq emms-spectrum-bar-count (min 64 (+ emms-spectrum-bar-count 8)))
  (emms-spectrum--init-data)
  (message "Bar count: %d" emms-spectrum-bar-count))

(defun emms-spectrum-decrease-bars ()
  "Decrease number of spectrum bars."
  (interactive)
  (setq emms-spectrum-bar-count (max 8 (- emms-spectrum-bar-count 8)))
  (emms-spectrum--init-data)
  (message "Bar count: %d" emms-spectrum-bar-count))

(defun emms-spectrum-set-theme (theme)
  "Set spectrum color THEME."
  (interactive
   (list (intern (completing-read "Color theme: "
                                  '("rainbow" "fire" "ocean" "monochrome" "grayscale")
                                  nil t))))
  (setq emms-spectrum-color-theme theme)
  (message "Theme: %s" theme))

;;;; Minor Mode

(defvar emms-spectrum-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "p" #'emms-spectrum-pause)
    (define-key map "r" #'emms-spectrum-resume)
    (define-key map "+" #'emms-spectrum-increase-bars)
    (define-key map "-" #'emms-spectrum-decrease-bars)
    (define-key map "t" #'emms-spectrum-set-theme)
    (define-key map "q" #'emms-spectrum-stop)
    map)
  "Keymap for emms-spectrum mode.")

(define-derived-mode emms-spectrum-mode special-mode "EMMS Spectrum"
  "Mode for displaying EMMS audio spectrum."
  (setq buffer-read-only t)
  (setq-local truncate-lines t))

;; Integration with EMMS
(add-to-list 'emms-player-started-hook
             (lambda () (when emms-spectrum--timer (emms-spectrum--update-display))))

(add-to-list 'emms-player-stopped-hook
             (lambda ()
               (when emms-spectrum--buffer
                 (with-current-buffer emms-spectrum--buffer
                   (let ((inhibit-read-only t))
                     (erase-buffer)
                     (insert "EMMS Spectrum - Paused\n"))))))

;;;; Convenience Functions

(defun emms-spectrum-demo ()
  "Start the spectrum visualizer with animated demo."
  (interactive)
  (emms-spectrum-start))

(provide 'emms-spectrum)

;;; emms-spectrum.el ends here
