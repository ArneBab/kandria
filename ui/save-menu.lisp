(in-package #:org.shirakumo.fraf.kandria)

(defclass save-button (alloy:direct-value-component)
  ((intent :initarg :intent :initform :new :accessor intent)
   (texture :initform NIL :accessor texture)
   (alloy:ideal-bounds :initform (alloy:extent 0 0 500 108))))

(defmethod initialize-instance :after ((button save-button) &key)
  (setf (texture button)
        (let ((image (image (alloy:value button))))
          (etypecase image
            (pathname (generate-resources 'image-loader image :min-filter :linear :mag-filter :linear))
            (vector (error "TODO"))
            (null (// 'kandria 'empty-save)))))
  (trial:commit (texture button) (loader +main+) :unload NIL))

(defmethod alloy:activate ((button save-button))
  (ecase (intent button)
    (:new
     (setf (state +main+) (alloy:value button))
     (load-game NIL +main+))
    (:load
     (load-game (alloy:value button) +main+))))

(presentations:define-realization (ui save-button)
  ((:background simple:rectangle)
   (alloy:margins)
   :pattern (if alloy:focus
                (colored:color 0.15 0.15 0.15 1)
                (colored:color 0.15 0.15 0.15 0.5)))
  ((:icon simple:icon)
   (alloy:extent 0 0 192 (alloy:ph 1))
   (texture alloy:renderable)
   :sizing :contain)
  ((:author simple:text)
   (alloy:margins 210 10 10 10)
   (author alloy:value)
   :size (alloy:un 30)
   :pattern colors:white
   :font (setting :display :font)
   :valign :top :halign :left)
  ((:save-time simple:text)
   (alloy:margins 210 10 10 10)
   (if (exists-p alloy:value)
       (format-absolute-time (save-time alloy:value))
       "")
   :size (alloy:un 20)
   :pattern colors:white
   :font (setting :display :font)
   :valign :bottom :halign :left))

(presentations:define-update (ui save-button)
  (:background
   :pattern (if alloy:focus
                (colored:color 0.15 0.15 0.15 1)
                (colored:color 0.15 0.15 0.15 0.5)))
  (:icon)
  (:author
   :pattern (if alloy:focus colors:white colors:gray))
  (:save-time
   :pattern (if alloy:focus colors:white colors:gray)))

(presentations:define-animated-shapes save-button
  (:background (simple:pattern :duration 0.2))
  (:author (simple:pattern :duration 0.2))
  (:save-time (simple:pattern :duration 0.2)))

(defclass save-menu (menuing-panel)
  ())

(defmethod initialize-instance :after ((panel save-menu) &key intent)
  (let ((layout (make-instance 'org.shirakumo.alloy.layouts.constraint:layout
                               :shapes (list (simple:rectangle (unit 'ui-pass T) (alloy:margins)
                                                               :pattern colors:black :name :bg))))
        (list (make-instance 'alloy:vertical-linear-layout))
        (focus (make-instance 'alloy:focus-list))
        (saves (list-saves)))
    (alloy:enter list layout :constraints `((:left 50) (:right 50) (:bottom 100) (:top 100)))
    (dolist (name '("1" "2" "3" "4"))
      (let ((save (or (find name saves :key (lambda (s) (pathname-name (file s))) :test #'string=)
                      (make-instance 'save-state :author (@ empty-save-file) :file name))))
        (make-instance 'save-button :value save :layout-parent list :focus-parent focus :intent intent)))
    (alloy:enter (make-instance 'label :value (ecase intent
                                                (:new (@ new-game))
                                                (:load (@ load-game)))
                                       :style `((:label :size ,(alloy:un 40))))
                 layout :constraints `((:top 20) (:left 50) (:right 10) (:above ,list 10)))
    (let ((back (make-instance 'button :value (@ go-backwards-in-ui) :on-activate (lambda () (hide panel)))))
      (alloy:enter back layout :constraints `((:left 50) (:below ,list 10) (:size 200 50)))
      (alloy:enter back focus)
      (alloy:on alloy:exit (focus)
        (setf (alloy:focus back) :strong)))
    (alloy:finish-structure panel layout focus)))
