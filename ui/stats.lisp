(in-package #:org.shirakumo.fraf.kandria)

(defclass stats-screen (pausing-panel menuing-panel)
  ())

(defmethod initialize-instance :after ((prompt stats-screen) &key (player (unit 'player T)) next)
  (let* ((stats (stats player))
         (layout (make-instance 'big-prompt-layout))
         (focus (make-instance 'alloy:focus-list))
         (title (make-instance 'header :level 0 :value #@stats-screen-title))
         (grid (make-instance 'alloy:grid-layout :col-sizes '(T 250) :row-sizes '(30) :cell-margins (alloy:margins 10 -5))))
    (alloy:enter (make-instance 'alloy:component :data NIL :shapes (list (make-basic-background))) layout
                 :constraints `((:fill :h) (:center :w) (:width 680)))
    (alloy:enter title layout :constraints `((:fill :w) (:top 50) (:height 50)))
    (alloy:enter grid layout :constraints `((:center :w) (:below ,title 20) (:size 600 300)))
    (loop for (value label format) in `((,(stats-distance stats) distance-travelled :metres)
                                        (,(stats-play-time stats) full-play-time :clock)
                                        (,(level player) player-level-count)
                                        (,(stats-kills stats) number-of-kills)
                                        (,(stats-deaths stats) number-of-deaths)
                                        (,(stats-secrets-found stats) number-of-secrets-found)
                                        (,(price player) money-accrued)
                                        (,(completion player) completion-rate :percentage)
                                        (,(score player) total-score))
          do (let ((value (case format
                            (:percentage (format NIL "~d%" (round (* 100 value))))
                            (:clock (format-relative-time value))
                            (:metres (format NIL "~,2fm" (/ value 16.0)))
                            (T (princ-to-string value)))))
               (make-instance 'label :value (language-string label) :layout-parent grid)
               (make-instance 'label :value value :layout-parent grid :style `((:label :halign :right)))))
    (let ((return (make-instance 'button :focus-parent focus :value #@continue-to-next :on-activate (lambda ()
                                                                                                      (hide prompt)
                                                                                                      (when next (funcall next))))))
      (alloy:enter return layout :constraints `((:bottom 40) (:size 300 40) (:center :w)))
      (let ((rank (make-instance 'label :value (language-string (compute-rank player)) :style `((:label :size ,(alloy:un 50) :halign :middle)))))
        (alloy:enter rank layout :constraints `((:below ,grid 5) (:above ,return 5) (:fill :w))))
      (alloy:on alloy:exit (focus)
        (setf (alloy:focus focus) :strong)
        (setf (alloy:focus return) :weak)))
    (alloy:finish-structure prompt layout focus)))

