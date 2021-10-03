(in-package #:org.shirakumo.fraf.kandria)

(defun should-show-pause-screen (main)
  (and (not (find-panel 'load-panel))
       (not (find-panel 'main-menu))
       (unit 'environment (scene main))))

(defmethod handle ((ev lose-focus) (main main))
  (when (and (setting :gameplay :pause-on-focus-loss)
             (should-show-pause-screen main))
    (show-panel 'pause-screen)))

(defmethod handle ((ev gain-focus) (main main))
  (hide-panel 'pause-screen))

(steam:define-callback steam*::game-overlay-activated (result active)
  (when (should-show-pause-screen +main+)
    (if (= 1 active)
        (show-panel 'pause-screen)
        (hide-panel 'pause-screen))))

(defclass pause-screen (pausing-panel)
  ())

(defmethod initialize-instance :after ((panel pause-screen) &key)
  (let* ((layout (make-instance 'load-screen-layout :style `((:bg :pattern ,(colored:color 0 0 0 0.5)))))
         (header (make-instance 'header :level 0 :value #@game-paused-title)))
    (alloy:enter header layout :constraints `(:center (:size 1000 1000)))
    (alloy:finish-structure panel layout NIL)))
