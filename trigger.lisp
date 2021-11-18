(in-package #:org.shirakumo.fraf.kandria)

(defclass trigger (sized-entity resizable ephemeral collider)
  ((active-p :initarg :active-p :initform T :accessor active-p :accessor quest:active-p :type boolean)))

(defmethod initargs append ((trigger trigger)) '(:active-p))

(defmethod interact :around ((trigger trigger) source)
  (when (active-p trigger)
    (call-next-method)))

(defmethod quest:activate ((trigger trigger))
  (setf (active-p trigger) T))

(defmethod quest:deactivate ((trigger trigger))
  (setf (active-p trigger) NIL))

(defclass one-time-trigger (trigger)
  ())

(defmethod interact :after ((trigger one-time-trigger) source)
  (setf (active-p trigger) NIL))

(defclass checkpoint (trigger creatable)
  ())

(defmethod interact ((trigger checkpoint) entity)
  (setf (spawn-location entity)
        (vec (vx (location trigger))
             (+ (- (vy (location trigger))
                   (vy (bsize trigger)))
                (vy (bsize entity))))))

(defclass story-trigger (one-time-trigger creatable)
  ((story-item :initarg :story-item :initform NIL :accessor story-item :type symbol)
   (target-status :initarg :target-status :initform :active :accessor target-status :type symbol)))

(defmethod initargs append ((trigger story-trigger)) '(:story-item :target-status))

(defmethod interact ((trigger story-trigger) entity)
  (let ((name (story-item trigger)))
    (flet ((finish (thing)
             (ecase (target-status trigger)
               (:active (quest:activate thing))
               (:inactive (quest:deactivate thing))
               (:complete (quest:complete thing)))
             (return-from interact)))
      (loop for quest being the hash-values of (quest:quests (storyline +world+))
            do (loop for task being the hash-values of (quest:tasks quest)
                     do (loop for trigger being the hash-values of (quest:triggers task)
                              do (when (eql name (quest:name trigger))
                                   (finish trigger)))
                        (when (eql name (quest:name task))
                          (finish task)))
               (when (eql name (quest:name quest))
                 (finish quest)))
      (v:warn :kandria.quest "Could not find story-item named ~s when firing trigger ~s"
              name (name trigger)))))

(defclass interaction-trigger (one-time-trigger creatable)
  ((interaction :initarg :interaction :initform NIL :accessor interaction :type symbol)))

(defmethod initargs append ((trigger interaction-trigger)) '(:interaction))

(defmethod interact ((trigger interaction-trigger) entity)
  (when (typep entity 'player)
    (show (make-instance 'dialog :interactions (list (quest:find-trigger (interaction trigger) +world+))))))

(defclass walkntalk-trigger (one-time-trigger creatable)
  ((interaction :initarg :interaction :initform NIL :accessor interaction :type symbol)
   (target :initarg :target :initform T :accessor target :type symbol)))

(defmethod initargs append ((trigger walkntalk-trigger)) '(:interaction :target))

(defmethod interact ((trigger walkntalk-trigger) entity)
  (when (typep (name entity) (target trigger))
    (walk-n-talk (quest:find-trigger (interaction trigger) +world+))))

(defclass tween-trigger (trigger)
  ((left :initarg :left :accessor left :initform 0.0 :type single-float)
   (right :initarg :right :accessor right :initform 1.0 :type single-float)
   (horizontal :initarg :horizontal :accessor horizontal :initform T :type boolean)
   (ease-fun :initarg :easing :accessor ease-fun :initform 'linear :type symbol)))

(defmethod initargs append ((trigger tween-trigger)) '(:left :right :horizontal :ease-fun))

(defmethod interact ((trigger tween-trigger) (entity located-entity))
  (let* ((x (if (horizontal trigger)
                (+ (/ (- (vx (location entity)) (vx (location trigger)))
                      (* 2.0 (vx (bsize trigger))))
                   0.5)
                (+ (/ (- (vy (location entity)) (vy (location trigger)))
                      (* 2.0 (vy (bsize trigger))))
                   0.5)))
         (v (ease (clamp 0 x 1) (ease-fun trigger) (left trigger) (right trigger))))
    (setf (value trigger) v)))

(defclass sandstorm-trigger (tween-trigger creatable)
  ())

(defmethod stage :after ((trigger sandstorm-trigger) (area staging-area))
  (stage (// 'sound 'sandstorm) area))

(defmethod (setf value) (value (trigger sandstorm-trigger))
  (let ((value (max 0.0 (- value 0.01))))
    (cond ((< 0 value)
           (harmony:play (// 'sound 'sandstorm))
           (setf (mixed:volume (// 'sound 'sandstorm)) (/ value 4)))
          (T
           (harmony:stop (// 'sound 'sandstorm))))
    (setf (strength (unit 'sandstorm T)) value)))

(defclass zoom-trigger (tween-trigger creatable)
  ((easing :initform 'quint-in)))

(defmethod (setf value) (value (trigger zoom-trigger))
  (setf (intended-zoom (unit :camera T)) value))

(defclass pan-trigger (tween-trigger creatable)
  ())

(defmethod (setf value) (value (trigger pan-trigger))
  (duck-camera (vx value) (vy value)))

(defclass teleport-trigger (trigger creatable)
  ((target :initform NIL :initarg :target :accessor target)
   (primary :initform T :initarg :primary :accessor primary)))

(defmethod initargs append ((trigger teleport-trigger)) '(:target))

(defmethod default-tool ((trigger teleport-trigger)) (find-class 'freeform))

(defmethod enter :after ((trigger teleport-trigger) (region region))
  (when (primary trigger)
    (destructuring-bind (&optional (location (vec (+ (vx (location trigger)) (* 2 (vx (bsize trigger))))
                                                  (vy (location trigger))))
                                   (bsize (vcopy (bsize trigger)))) (target trigger)
      (let* ((other (clone trigger :location location :bsize bsize :target trigger :active-p NIL :primary NIL)))
        (setf (target trigger) other)
        (enter other region)))))

(defmethod interact ((trigger teleport-trigger) (entity located-entity))
  (setf (location entity) (target trigger))
  (vsetf (velocity entity) 0 0))

(defclass earthquake-trigger (trigger creatable)
  ((duration :initform 60.0 :initarg :duration :accessor duration)
   (clock :initform 0.0 :accessor clock)))

(defmethod stage :after ((trigger earthquake-trigger) (area staging-area))
  (stage (// 'sound 'ambience-earthquake) area))

(defmethod closest-acceptable-location ((trigger earthquake-trigger) location)
  location)

(defmethod interact ((trigger earthquake-trigger) (player player))
  (decf (clock trigger) 0.01)
  (let* ((max 7.0)
         (hmax (/ max 2.0)))
    (cond ((eql :fishing (state (unit 'player +world+))))
          ((<= (clock trigger) (- max))
           (shake-camera :duration 0.0 :intensity 0)
           (setf (clock trigger) (+ (duration trigger) (random 10.0))))
          ((<= (clock trigger) -0.1)
           (let ((intensity (* 10 (- 1 (/ (expt 3 (abs (+ hmax (clock trigger))))
                                          (expt 3 hmax))))))
             (shake-camera :duration 7.0 :intensity intensity :rumble-intensity 0.1)))
          ((<= (clock trigger) 0.0)
           (harmony:play (// 'sound 'ambience-earthquake))))))
;; TODO: make dust fall down over screen.

(defclass action-prompt (trigger listener creatable)
  ((action :initarg :action :initform NIL :accessor action
           :type alloy::any)
   (interrupt :initarg :interrupt :initform NIL :accessor interrupt
              :type boolean)
   (prompt :initform (make-instance 'prompt) :reader prompt)
   (triggered :initform NIL :accessor triggered)))

(defmethod initargs append ((prompt action-prompt)) '(:action :interrupt))

(defmethod interactable-p ((prompt action-prompt))
  (active-p prompt))

(defmethod handle ((ev tick) (prompt action-prompt))
  (unless (triggered prompt)
    (when (slot-boundp (prompt prompt) 'alloy:layout-parent)
      (hide (prompt prompt))))
  (setf (triggered prompt) NIL))

(defmethod interact ((prompt action-prompt) (player player))
  (when (eql :normal (state player))
    (when (interrupt prompt)
      ;; KLUDGE: clear dash to ensure player can always recover.
      (when (eql (action prompt) 'dash)
        (setf (dash-time player) 0.0))
      (if (<= 0.01 (time-scale +world+))
          (setf (time-scale +world+) (* (time-scale +world+) 0.95))
          (setf (time-scale +world+) 0.0)))
    (let ((loc (vec (vx (location prompt))
                    (+ (vy (location player)) (vy (bsize player))))))
      (show (prompt prompt) :button (action prompt)
                            :description (language-string (unlist (action prompt)) NIL)
                            :location loc)
      (setf (triggered prompt) T))))

(defmethod handle ((ev trial:action) (prompt action-prompt))
  (when (and (interrupt prompt)
             (typep ev (action prompt))
             (active-p prompt)
             (contained-p prompt (unit 'player +world+)))
    (setf (time-scale +world+) 1.0)
    (setf (active-p prompt) NIL)))

(defmethod leave* :before ((prompt action-prompt) from)
  (hide (prompt prompt)))

(define-shader-entity wind (textured-entity lit-entity trigger listener creatable)
  ((vertex-array :initform NIL :accessor vertex-array)
   (vertex-buffer :initform NIL :accessor vertex-buffer)
   (texture :initform (// 'kandria 'wind))
   (clock :initform 0.0 :accessor clock)
   (strength :initarg :strength :initform (vec 0 0) :accessor strength :type vec2)
   (kind :initarg :kind :initform :constant :accessor kind :type symbol)
   (active-time :initform 0.0 :accessor active-time)))

(defmethod initialize-instance :after ((wind wind) &key)
  ;; FIXME: cache between all
  (let* ((arr (make-array (+ (* 4 4) (* 4 16)) :element-type 'single-float))
         (vbo (make-instance 'vertex-buffer :data-usage :stream-draw :buffer-data arr))
         (vao (make-instance 'vertex-array :bindings `((,vbo :size 2 :offset 0 :stride 16)
                                                       (,vbo :size 2 :offset 8 :stride 16)
                                                       (,vbo :size 2 :offset 64 :stride 16 :instancing 1)
                                                       (,vbo :size 2 :offset 72 :stride 16 :instancing 1)))))
    (setf (vertex-array wind) vao)
    (setf (vertex-buffer wind) vbo)
    (macrolet ((seta (&rest els)
                 `(progn ,@(loop for i from 0 for el in els
                                 collect `(setf (aref arr ,i) ,(float el))))))
      (seta  -4 -4  0  0
             +4 -4  1  0
             +4 +4  1  1
             -4 +4  0  1))
    (loop for i from (* 4 4) below (length arr) by 4
          do (setf (aref arr (+ i 0)) most-negative-single-float)
             (setf (aref arr (+ i 1)) most-positive-single-float)
             (setf (aref arr (+ i 2)) 1.0)
             (setf (aref arr (+ i 3)) 1.0))))

(defmethod interact ((wind wind) (player player))
  ;; FIXME: how do we get the actual dt here?
  (unless (eq :dashing (state player))
    (nv+ (velocity player) (v* (strength wind) 0.01))
    (when (svref (collisions player) 2)
      (incf (vx (frame-velocity player)) (* (vx (strength wind)) 0.01))))
  (incf (active-time wind) 0.02))

(defmethod stage :after ((wind wind) (area staging-area))
  (stage (vertex-array wind) area))

(defmethod handle ((ev tick) (wind wind))
  (incf (clock wind) (dt ev))
  (setf (active-time wind) (clamp 0.0 (- (active-time wind) (dt ev)) 1.0))
  (ecase (kind wind)
    (:constant
     (setf (vx (strength wind)) (* 5 (+ (cos (tt ev)) (cos (* (tt ev) 1.5427)))))
     (setf (vy (strength wind)) (* 5 (sin (* (tt ev) 0.542))))))
  (let* ((vbo (vertex-buffer wind))
         (arr (buffer-data vbo))
         (camera (unit :camera +world+))
         (view (bsize camera))
         (spd (strength wind))
         (dir (vunit spd))
         (r (sqrt (+ (expt (vx view) 2) (expt (vy view) 2))))
         (off (v* dir r))
         (d (* r 1.75)))
    (flet ((respawn (ai)
             (let ((off (nv- (nv* (vec (- (vy dir)) (vx dir)) (- (random d) (* 0.5 d))) off)))
               (setf (aref arr (+ ai 0)) (+ (vx off) (vx (location camera)) (random* 0 128)))
               (setf (aref arr (+ ai 1)) (+ (vy off) (vy (location camera)) (random* 0 128)))))
           (contained-p (x y)
             (and (< (* (vx view) -2.5) (- x (vx (location camera))) (* (vx view) 2.5))
                  (< (* (vy view) -2.5) (- y (vy (location camera))) (* (vy view) 2.5)))))
      (dotimes (i 16)
        (let ((ai (+ (* i 4) 16)))
          (unless (contained-p (aref arr (+ ai 0)) (aref arr (+ ai 1)))
            (respawn ai))
          (incf (aref arr (+ ai 0)) (* (vx spd) 200 (dt ev)))
          (incf (aref arr (+ ai 1)) (* (vy spd) 200 (dt ev)))
          (setf (aref arr (+ ai 2)) (max 1.0 (vlength spd)))
          (setf (aref arr (+ ai 3)) (atan (vy dir) (vx dir))))))
    (update-buffer-data vbo arr)))

(defmethod render ((wind wind) (program shader-program))
  (when (< 0.0 (active-time wind))
    (setf (uniform program "view_matrix") *view-matrix*)
    (setf (uniform program "projection_matrix") *projection-matrix*)
    (setf (uniform program "visibility") (clamp 0.0 (active-time wind) 1.0))
    (let* ((vao (vertex-array wind)))
      (gl:bind-vertex-array (gl-name vao))
      (gl:draw-arrays-instanced :triangle-fan 0 4 16))))

(define-class-shader (wind :vertex-shader)
  "layout (location = 0) in vec2 position;
layout (location = 2) in vec2 offset;
layout (location = 3) in vec2 stretch;

uniform mat4 view_matrix;
uniform mat4 projection_matrix;
out vec2 world_pos;

void main(){
  float phi = stretch.y;
  mat2 rot = mat2(cos(phi), sin(phi), -sin(phi), cos(phi));
  world_pos = offset + rot*(position*vec2(stretch.x, 1));
  gl_Position = projection_matrix * view_matrix * vec4(world_pos, 0, 1.0f);
}")

(define-class-shader (wind :fragment-shader)
  "uniform float visibility;
out vec4 color;
in vec2 world_pos;

void main(){
  color = apply_lighting_flat(color, vec2(0), 0, world_pos) * visibility;
}")
