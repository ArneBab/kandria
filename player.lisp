(in-package #:org.shirakumo.fraf.kandria)

(define-global +player-movement-data+
    (macrolet ((mktab* (&rest entries)
                 `(mktab ,@(loop for (k v) in entries
                                 collect `(list ',k ,v)))))
      (mktab* (coyote-time     0.08)
              (velocity-limit  (vec 10 20))
              (walk-acc        0.1)
              (walk-limit      1.9)
              (run-acc         0.0125)
              (run-time        3.0)
              (run-limit       4.0)
              (air-acc         0.08)
              (air-dcc         0.97)
              (climb-up        0.8)
              (climb-down      1.5)
              (climb-strength  7.0)
              (climb-jump-cost 1.5)
              (slide-limit    -1.2)
              (crawl           0.5)
              (jump-acc        2.5)
              (jump-mult       1.1)
              (walljump-acc    (vec 2.75 2.5))
              (dash-acc        1.2)
              (dash-dcc        0.875)
              (dash-air-dcc    0.98)
              (dash-acc-start  0.05)
              (dash-dcc-start  0.2)
              (dash-dcc-end    0.3)
              (dash-min-time   0.25)
              (dash-max-time   0.675))))

(defmacro p! (name)
  `(gethash ',name +player-movement-data+))

(define-shader-entity player (animatable profile ephemeral)
  ((name :initform 'player)
   (bsize :initform (vec 7.0 15.0))
   (spawn-location :initform (vec2 0 0) :accessor spawn-location)
   (interactable :initform NIL :accessor interactable)
   (jump-time :initform 1.0 :accessor jump-time)
   (dash-time :initform 1.0 :accessor dash-time)
   (run-time :initform 1.0 :accessor run-time)
   (air-time :initform 1.0 :accessor air-time)
   (climb-strength :initform 1.0 :accessor climb-strength)
   (buffer :initform NIL :accessor buffer)
   (chunk :initform NIL :accessor chunk)
   (inventory :initform NIL :accessor inventory)
   (prompt :initform (make-instance 'prompt) :reader prompt)
   (profile-sprite-data :initform (asset 'kandria 'player-profile))
   (nametag :initform "The Stranger"))
  (:default-initargs
   :sprite-data (asset 'kandria 'player)))

(defmethod initialize-instance :after ((player player) &key)
  (setf (spawn-location player) (vcopy (location player))))

(defmethod minimum-idle-time ((player player)) 30)

(defmethod resize ((player player) w h))

(defmethod have (thing (player player))
  (have thing (inventory player)))

(defmethod capable-p ((player player) (edge jump-edge)) T)
(defmethod capable-p ((player player) (edge crawl-edge)) T)
(defmethod capable-p ((player player) (edge climb-edge)) T)

(defmethod movement-speed ((player player))
  (case (state player)
    (:crawling 1.0)
    (T 1.9)))

(defmethod stage :after ((player player) (area staging-area))
  (dolist (sound '(dash jump land slide step death slash rope splash ground-hit))
    (stage (// 'kandria sound) area))
  (stage (prompt player) area))

(defmethod enter :after ((player player) (medium medium))
  (harmony:play (// 'kandria 'splash)))

(defmethod handle ((ev interact) (player player))
  (let ((interactable (interactable player)))
    (when interactable
      (discard-events +world+)
      (setf (buffer player) NIL)
      (interact interactable player))))

(defmethod interact :before ((thing dialog-entity) (player player))
  (setf (state player) :normal)
  (hide (prompt player)))

(defmethod interact ((door door) (player player))
  (setf (animation door) 'open)
  (let ((location (location (target door))))
    (start-animation 'enter player)
    (transition
      (start-animation 'exit player)
      (setf (animation (target door)) 'open)
      (setf (air-time player) 0.0)
      (setf (buffer player) NIL)
      (vsetf (location player) (vx location) (- (vy location) 5))
      (issue +world+ 'switch-chunk :chunk (find-containing player (region +world+)))
      (issue +world+ 'force-lighting)
      (snap-to-target (unit :camera T) player))))

(defmethod handle ((ev dash) (player player))
  (case (state player)
    (:normal
     (let ((vel (velocity player))
           (endangering (in-danger-p player)))
       (cond (endangering
              ;; FIXME: If we are holding the opposite of what
              ;;        we are facing, we should evade left.
              ;;        to do this, need to buffer for a while.
              (if (= (direction player)
                     (signum (- (vx (location endangering)) (vx (location player)))))
                  (start-animation 'evade-left player)
                  (start-animation 'evade-right player)))
             ((and (eq :normal (state player))
                   (<= (dash-time player) 0))
              (if (typep (trial::source-event ev) 'gamepad-event)
                  (let ((dev (device (trial::source-event ev))))
                    (vsetf vel
                           (absinvclamp 0.3 (gamepad:axis :l-h dev) 0.5)
                           (absinvclamp 0.3 (gamepad:axis :l-v dev) 0.5)))
                  (vsetf vel
                         (cond ((retained 'left)  -0.5)
                               ((retained 'right) +0.5)
                               (T                            0))
                         (cond ((retained 'up)    +0.5)
                               ((retained 'down)  -0.5)
                               (T                            0))))
              (setf (state player) :dashing)
              (if (svref (collisions player) 2)
                  (trigger 'dash player)
                  (trigger 'air-dash player))
              (setf (animation player) 'dash)
              (when (v= 0 vel) (setf (vx vel) (direction player)))
              (nvunit vel)))))
    (:animated
     ;; Queue dash //except// for when we're being hit, as it's
     ;; unlikely the player will want to dish right after getting
     ;; hit.
     (let ((name (name (animation player))))
       (unless (or (eq name 'light-hit)
                   (eq name 'hard-hit))
         (setf (buffer player) 'dash))))))

(defmethod handle ((ev jump) (player player))
  (cond ((eql :animated (state player))
         (setf (buffer player) 'jump))
        ((not (eql :crawling (state player)))
         (setf (jump-time player) (- (p! coyote-time))))))

(defmethod handle ((ev crawl) (player player))
  (unless (svref (collisions player) 0)
    (case (state player)
      (:normal (setf (state player) :crawling))
      (:crawling (setf (state player) :normal)))))

(defmethod handle ((ev light-attack) (player player))
  (cond ((eql :animated (state player))
         (setf (buffer player) 'light-attack))
        ((not (eql :crawling (state player)))
         (setf (buffer player) 'light-attack)
         (setf (state player) :animated))))

(defmethod handle ((ev heavy-attack) (player player))
  (cond ((eql :animated (state player))
         (setf (buffer player) 'heavy-attack))
        ((not (eql :crawling (state player)))
         (setf (buffer player) 'heavy-attack)
         (setf (state player) :animated))))

#-kandria-release
(let ((type (copy-seq '(box zombie ball))))
  (defmethod handle ((ev mouse-scroll) (player player))
    (setf type (cycle-list type))
    (status :note "Switched to spawning ~a" (first type)))
  
  (defmethod handle ((ev mouse-release) (player player))
    (when (eql :middle (button ev))
      (let ((enemy (make-instance (first type) :location (mouse-world-pos (pos ev)))))
        (trial:commit enemy (loader (handler *context*)) :unload NIL)
        (enter enemy (region +world+))
        (compile-into-pass enemy (region +world+) +world+)))))

(flet ((handle-solid (player hit)
         (when (< 0 (vy (hit-normal hit)))
           (cond ((and (< (vy (velocity player)) -3)
                       (< 1.0 (air-time player)))
                  (trigger 'land player :location (nv+ (v* (velocity player) (hit-time hit))
                                                       (location player)))
                  (start-animation 'land player)
                  (duck-camera :offset (velocity player))
                  (shake-camera :intensity (* 3 (/ (abs (vy (velocity player))) (vy (p! velocity-limit))))))
                 ((and (< (vy (velocity player)) -0.5)
                       (< 0.2 (air-time player)))
                  (harmony:play (// 'kandria 'land)))))
         (when (<= 0 (vy (hit-normal hit)))
           (setf (air-time player) 0.0))
         (when (and (< 0 (vy (hit-normal hit)))
                    (not (eql :dashing (state player))))
           (setf (dash-time player) 0.0))))
  (defmethod collide :before ((player player) (block block) hit)
    (unless (typep block 'spike)
      (handle-solid player hit)))

  (defmethod collide :before ((player player) (solid solid) hit)
    (handle-solid player hit)))

(defmethod collide ((player player) (trigger trigger) hit)
  (when (active-p trigger)
    (fire trigger)))

(defmethod (setf state) :before (state (player player))
  (unless (eq state (state player))
    (case state
      (:crawling
       (setf (vy (bsize player)) 7)
       (decf (vy (location player)) 8)))
    (case (state player)
      (:crawling
       (incf (vy (location player)) 8)
       (setf (vy (bsize player)) 15)))))

(defmethod handle :before ((ev tick) (player player))
  (when (path player)
    (return-from handle))
  (let* ((collisions (collisions player))
         (dt (* 100 (dt ev)))
         (loc (location player))
         (vel (velocity player))
         (size (bsize player))
         (ground (svref collisions 2))
         (ground-limit (if (< (p! run-time) (run-time player))
                           (p! run-limit)
                           (p! walk-limit)))
         (ground-acc (if (< (p! run-time) (run-time player))
                         (p! run-acc)
                         (p! walk-acc))))
    (when (< (abs (vx vel)) (/ (p! walk-limit) 2))
      (setf (run-time player) 0.0))
    (incf (run-time player) (dt ev))
    (setf (interactable player) NIL)
    (for:for ((entity over (region +world+)))
      (when (and (typep entity 'interactable)
                 (contained-p (vec (vx loc) (vy loc) 16 8) entity))
        (setf (interactable player) entity)))
    (if (and (interactable player)
             (interactable-p (interactable player)))
        (let ((loc (vec (vx (location (interactable player)))
                        (+ (vy loc) (vy (bsize player))))))
          (show (prompt player) :button 'interact :location loc))
        (hide (prompt player)))
    (ecase (state player)
      ((:dying :animated :stunned)
       (when (and ground (eql 'heavy-aerial-3 (name (animation player))))
         (start-animation 'heavy-aerial-3-release player))
       (let ((buffer (buffer player)))
         (when (and buffer (cancelable-p (frame player)))
           (setf (buffer player) NIL)
           (cond ((retained 'left) (setf (direction player) -1))
                 ((retained 'right) (setf (direction player) +1)))
           (case buffer
             (light-attack
              (case (name (animation player))
                (light-ground-1 (start-animation 'light-ground-2 player))
                (light-ground-2 (start-animation 'light-ground-3 player))
                (light-ground-3 (setf (frame player) (loop-to (animation player))))
                (light-aerial-1 (start-animation 'light-aerial-2 player))
                (light-aerial-2 (start-animation 'light-aerial-3 player))
                (T
                 (cond ((not (svref (collisions player) 2))
                        (if (retained 'down)
                            (start-animation 'light-aerial-down player)
                            (start-animation 'light-aerial-1 player)))
                       ((retained 'up)
                        (start-animation 'light-up player))
                       (T
                        (start-animation 'light-ground-1 player))))))
             (heavy-attack
              (case (name (animation player))
                (heavy-ground-1 (start-animation 'heavy-ground-2 player))
                (heavy-ground-2 (start-animation 'heavy-ground-3 player))
                (heavy-aerial-1 (start-animation 'heavy-aerial-2 player))
                (heavy-aerial-2 (start-animation 'heavy-aerial-3 player))
                (T
                 (cond ((not (svref (collisions player) 2))
                        (if (retained 'down)
                            (start-animation 'heavy-aerial-down player)
                            (start-animation 'heavy-aerial-1 player)))
                       ((retained 'up)
                        (start-animation 'heavy-up player))
                       (T
                        (start-animation 'heavy-ground-1 player))))))
             (dash
              (setf (state player) :normal)
              (handle (make-instance 'dash) player))
             (jump
              (setf (state player) :normal)
              (handle (make-instance 'jump) player)))))
       (nv+ vel (v* (gravity (medium player)) dt))
       (handle-animation-states player ev)
       (when (and (cancelable-p (frame player))
                  (or (retained 'left)
                      (retained 'right)))
         (setf (state player) :normal))
       (when ground
         (setf (vy vel) (max (vy vel) 0))))
      (:dashing
       (incf (dash-time player) (dt ev))
       (setf (jump-time player) 100.0)
       (setf (run-time player) 0.0)
       (cond ((or (< (p! dash-max-time) (dash-time player))
                  (and (< (p! dash-min-time) (dash-time player))
                       (not (retained 'dash))))
              (setf (state player) :normal))
             ((< (p! dash-dcc-end) (dash-time player)))
             ((< (p! dash-dcc-start) (dash-time player))
              (nv* vel (damp* (p! dash-dcc) dt)))
             ((< (p! dash-acc-start) (dash-time player))
              (nv* vel (p! dash-acc))))
       (when (typep (interactable player) 'rope)
         (nudge (interactable player) loc (* (direction player) 20)))
       ;; Adapt velocity if we are on sloped terrain
       ;; I'm not sure why this is necessary, but it is.
       (typecase ground
         (slope
          (when (v/= 0 vel)
            (let* ((normal (nvunit (vec2 (- (vy2 (slope-l ground)) (vy2 (slope-r ground)))
                                         (- (vx2 (slope-r ground)) (vx2 (slope-l ground))))))
                   (slope (vec (- (vy normal)) (vx normal)))
                   (proj (v* slope (v. slope vel)))
                   (angle (vangle slope (vunit vel))))
              (when (or (< angle (* PI 1/4)) (< (* PI 3/4) angle))
                (vsetf vel (vx proj) (vy proj))))))
         (null
          (nv* vel (damp* (p! dash-air-dcc) dt)))))
      (:climbing
       ;; Movement
       (let* ((top (if (= -1 (direction player))
                       (scan-collision +world+ (vec (- (vx loc) (vx size) 10) (- (vy loc) (vy size) 2)))
                       (scan-collision +world+ (vec (+ (vx loc) (vx size) 10) (- (vy loc) (vy size) 2)))))
              (attached (or (svref collisions (if (< 0 (direction player)) 1 3))
                            (interactable player)
                            top)))
         (setf (vx vel) 0f0)
         (when (or (not (retained 'climb))
                   (not attached)
                   (<= (climb-strength player) 0))
           (setf (state player) :normal))
         (when (typep attached 'rope)
           (nudge attached loc (* (direction player) -8))
           (cond ((retained 'left)
                  (let ((target-x (- (vx (location (interactable player))) (vx (bsize player)))))
                    (unless (scan-collision +world+ (vec target-x (vy loc) (vx size) (vy size)))
                      (setf (direction player) +1)
                      (setf (vx loc) target-x))))
                 ((retained 'right)
                  (let ((target-x (+ (vx (location (interactable player))) (vx (bsize player)))))
                    (unless (scan-collision +world+ (vec target-x (vy loc) (vx size) (vy size)))
                      (setf (direction player) -1)
                      (setf (vx loc) target-x))))))
         (cond ((retained 'jump)
                (when (typep attached 'rope)
                  (nudge attached (location player) (* (direction player) 16)))
                (setf (state player) :normal))
               ((and top (eq attached top))
                (setf (vy vel) (p! climb-up))
                (setf (vx vel) (* (direction player) (p! climb-up))))
               ((retained 'up)
                (unless (typep attached 'rope)
                  (decf (climb-strength player) (dt ev)))
                (if (< (vy vel) (p! climb-up))
                    (setf (vy vel) (p! climb-up))
                    (decf (vy vel) 0.1)))
               ((retained 'down)
                (setf (vy vel) (* (p! climb-down) -1)))
               (T
                (setf (vy vel) 0)))))
      (:crawling
       ;; Uncrawl on ground loss
       (when (and (not ground)
                  (< 0.1 (air-time player)))
         (when (scan-collision +world+ (vec (vx loc) (vy loc) 16 32))
           (decf (vy loc) 16))
         (setf (state player) :normal))
       
       (cond ((retained 'left)
              (setf (vx vel) (- (p! crawl))))
             ((retained 'right)
              (setf (vx vel) (+ (p! crawl))))
             (T
              (setf (vx vel) 0)))
       ;; Slope sticky
       (when (and (<= (vy vel) 0) (typep ground 'slope))
         (if (= (signum (vx vel))
                (signum (- (vy (slope-l ground)) (vy (slope-r ground)))))
             (decf (vy vel) 1)))
       (nv+ vel (v* (gravity (medium player)) dt)))
      (:normal
       ;; Handle jumps
       (when (< (jump-time player) 0.0)
         (cond ((or (svref collisions 1)
                    (svref collisions 3)
                    (and (typep (interactable player) 'rope)
                         (extended (interactable player))))
                ;; Wall jump
                (let ((dir (if (svref collisions 1) -1.0 1.0))
                      (mov-dir (cond ((retained 'left) -1)
                                     ((retained 'right) +1)
                                     (T 0))))
                  (setf (jump-time player) 0.0)
                  (harmony:play (// 'kandria 'jump))
                  (cond ((or (= dir mov-dir)
                             (not (retained 'climb)))
                         (setf (direction player) dir)
                         (setf (vy vel) (vy (p! walljump-acc)))
                         (setf (vx vel) (* dir (vx (p! walljump-acc)))))
                        ((<= -0.1 (climb-strength player))
                         (unless (typep (interactable player) 'rope)
                           (decf (climb-strength player) (p! climb-jump-cost)))
                         (setf (vy vel) (+ 0.3 (vy (p! walljump-acc))))))))
               ((< (air-time player) (p! coyote-time))
                ;; Ground jump
                (trigger 'jump player)
                (setf (vy vel) (+ (p! jump-acc)
                                  (if ground
                                      (* 0.25 (max 0 (vy (velocity ground))))
                                      0)))
                (setf (jump-time player) 0.0))))
       
       ;; Test for climbing
       (when (and (retained 'climb)
                  (not (retained 'jump))
                  (or (typep (svref collisions 1) '(or ground solid))
                      (typep (svref collisions 3) '(or ground solid))
                      (and (typep (interactable player) 'rope)
                           (extended (interactable player))))
                  (< 0 (climb-strength player)))
         (cond ((typep (interactable player) 'rope)
                (let* ((direction (signum (- (vx (location (interactable player))) (vx loc))))
                       (target-x (+ (vx (location (interactable player))) (* direction -8))))
                  (unless (scan-collision +world+ (vec target-x (vy loc) (vx size) (vy size)))
                    (setf (direction player) direction)
                    (setf (vx loc) target-x)
                    (setf (state player) :climbing)
                    (return-from handle))))
               (T
                (setf (direction player) (if (svref (collisions player) 1) +1 -1))
                (setf (state player) :climbing)
                (return-from handle))))

       ;; Movement
       (cond (ground
              (setf (climb-strength player) (p! climb-strength))
              (incf (vy vel) (min 0 (vy (velocity ground))))
              (cond ((retained 'left)
                     (setf (direction player) -1)
                     ;; Quick turns on the ground.
                     (when (< 0 (vx vel))
                       (setf (vx vel) 0))
                     (if (< (- ground-limit) (vx vel))
                         (decf (vx vel) ground-acc)
                         (setf (vx vel) (- ground-limit))))
                    ((retained 'right)
                     (setf (direction player) +1)
                     ;; Quick turns on the ground.
                     (when (< (vx vel) 0)
                       (setf (vx vel) 0))
                     (if (< (vx vel) ground-limit)
                         (incf (vx vel) ground-acc)
                         (setf (vx vel) ground-limit)))
                    (T
                     (setf (vx vel) 0))))
             ((retained 'left)
              (setf (direction player) -1)
              (when (< (- ground-limit) (vx vel))
                (decf (vx vel) (p! air-acc))))
             ((retained 'right)
              (setf (direction player) +1)
              (when (< (vx vel) ground-limit)
                (incf (vx vel) (p! air-acc)))))
       ;; Slope sticky
       (when (and (<= (vy vel) 0) (typep ground 'slope))
         (if (= (signum (vx vel))
                (signum (- (vy (slope-l ground)) (vy (slope-r ground)))))
             (decf (vy vel) 1)))
       ;; Air friction
       (unless ground
         (setf (vx vel) (* (vx vel) (damp* (p! air-dcc) dt))))
       ;; Jump progress
       (when (and (retained 'jump)
                  (<= 0.05 (jump-time player) 0.15))
         (setf (vy vel) (* (vy vel) (damp* (p! jump-mult) dt))))
       (nv+ vel (v* (gravity (medium player)) dt))
       ;; Limit when sliding down wall
       (when (and (or (typep (svref collisions 1) 'ground)
                      (typep (svref collisions 3) 'ground))
                  (< (vy vel) (p! slide-limit)))
         (setf (vy vel) (p! slide-limit)))))
    (nvclamp (v- (p! velocity-limit)) vel (p! velocity-limit))
    (nv+ (frame-velocity player) vel)))

(defmethod handle :after ((ev tick) (player player))
  (incf (jump-time player) (dt ev))
  (incf (air-time player) (dt ev))
  ;; OOB
  (when (not (contained-p (location player) (chunk player)))
    (if (eql :dying (state player))
        (vsetf (velocity player) 0 0)
        (let ((other (find-containing player (region +world+))))
          (cond (other
                 (issue +world+ 'switch-chunk :chunk other))
                ((< (vy (location player))
                    (- (vy (location (chunk player)))
                       (vy (bsize (chunk player)))))
                 (kill player))
                (T
                 (setf (vx (location player)) (clamp (- (vx (location (chunk player)))
                                                        (vx (bsize (chunk player))))
                                                     (vx (location player))
                                                     (+ (vx (location (chunk player)))
                                                        (vx (bsize (chunk player)))))))))))
  ;; Animations
  (let ((vel (velocity player))
        (collisions (collisions player)))
    (setf (playback-direction player) +1)
    (setf (playback-speed player) 1.0)
    (case (state player)
      (:climbing
       (setf (animation player) 'climb)
       (cond
         ((< (vy vel) 0)
          (setf (playback-direction player) -1)
          (setf (playback-speed player) 1.5))
         ((= 0 (vy vel))
          (setf (clock player) 0.0))))
      (:crawling
       (cond ((< 0 (vx vel))
              (setf (direction player) +1))
             ((< (vx vel) 0)
              (setf (direction player) -1)))
       (setf (animation player) 'crawl)
       (when (= 0 (vx vel))
         (setf (clock player) 0.0)))
      (:normal
       (cond ((< 0 (vx vel))
              (setf (direction player) +1))
             ((< (vx vel) 0)
              (setf (direction player) -1)))
       (cond ((< 0 (vy vel))
              (setf (animation player) 'jump))
             ((null (svref collisions 2))
              (cond ((typep (svref collisions 1) 'ground)
                     (setf (animation player) 'slide)
                     (setf (direction player) +1)
                     (when (< (clock player) 0.01)
                       (trigger 'slide player :direction -1)))
                    ((typep (svref collisions 3) 'ground)
                     (setf (animation player) 'slide)
                     (setf (direction player) -1)
                     (when (< (clock player) 0.01)
                       (trigger 'slide player :direction +1)))
                    ((< 0.1 (air-time player))
                     (setf (animation player) 'fall))))
             ((< 0 (abs (vx vel)))
              (setf (playback-speed player) (/ (abs (vx vel)) (p! walk-limit)))
              (setf (animation player) 'run))
             (T
              (setf (animation player) 'stand)))))
    (cond ((eql (name (animation player)) 'slide)
           (harmony:play (// 'kandria 'slide)))
          (T
           (harmony:stop (// 'kandria 'slide))))))

(defmethod handle ((ev switch-region) (player player))
  (let* ((region (slot-value ev 'region))
         (other (find-containing player (region +world+))))
    (unless other
      (warn "Player is somehow outside all chunks, picking first chunk we can get.")
      (setf other (for:for ((entity over region))
                    (when (typep entity 'chunk) (return entity))))
      (unless other
        (error "What the fuck? Could not find any chunks.")))
    (snap-to-target (unit :camera T) player)
    (issue +world+ 'switch-chunk :chunk other)))

(defmethod handle ((ev switch-chunk) (player player))
  (let ((loc (vcopy (location player))))
    (when (v/= 0 (velocity player))
      (nv+ loc (v* (vunit (velocity player)) +tile-size+)))
    (setf (chunk player) (chunk ev))
    (setf (spawn-location player) loc)))

(defmethod respawn ((player player))
  (vsetf (velocity player) 0 0)
  (vsetf (location player)
         (vx (spawn-location player))
         (vy (spawn-location player)))
  (setf (state player) :normal)
  (snap-to-target (unit :camera T) player))

(defmethod hurt :after ((player player) damage)
  (setf (clock (progression 'hurt +world+)) 0)
  (start (progression 'hurt +world+))
  (shake-camera :intensity 5))

(defmethod kill :after ((player player))
  (harmony:play (// 'kandria 'death))
  (setf (clock (progression 'death +world+)) 0f0)
  (start (progression 'death +world+)))

(defmethod die ((player player))
  (kill player))

(defun player-screen-y ()
  (* (- (vy (location (unit 'player T))) (vy (location (unit :camera T))))
     (view-scale (unit :camera T))))

(defmethod render :before ((player player) (program shader-program))
  (setf (uniform program "flash")
        (cond ((<= (climb-strength player) 0)
               (if (<= (mod (clock (scene (handler *context*))) 0.5) 0.2) 0.8 0.0))
              ((<= (climb-strength player) 1)
               (if (<= (mod (clock (scene (handler *context*))) 0.15) 0.08) 1.0 0.0))
              ((<= (climb-strength player) 2)
               (if (<= (mod (clock (scene (handler *context*))) 0.3) 0.12) 0.8 0.0))
              ((<= (climb-strength player) 3)
               (if (<= (mod (clock (scene (handler *context*))) 0.4) 0.15) 0.5 0.0))
              (T
               0.0))))

(define-class-shader (player :fragment-shader)
  "uniform float flash = 0;
out vec4 color;

void main(){
  color = mix(color, vec4(10, 0, 0, color.a), flash);
}")
