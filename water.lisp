(in-package #:org.shirakumo.fraf.kandria)

(define-shader-entity water (lit-entity vertex-entity sized-entity listener resizable ephemeral medium collider)
  ((vertex-buffer :accessor vertex-buffer)
   (prev :accessor prev))
  (:inhibit-shaders (vertex-entity :vertex-shader)))

(defun make-water-vertex-data (bsize)
  (let ((array (make-array (* 2 2 (1+ (floor (vx bsize) 2))) :element-type 'single-float))
        (h (vy bsize))
        (i 0))
    (loop for x from (- (vx bsize)) to (+ (vx bsize)) by 4
          do (setf (aref array (+ i 0)) x)
             (setf (aref array (+ i 1)) (- h))
             (setf (aref array (+ i 2)) x)
             (setf (aref array (+ i 3)) (+ h))
             (incf i 4))
    (setf (aref array (- i 2)) (vx bsize))
    (setf (aref array (- i 4)) (vx bsize))
    array))

(defmethod submerged ((entity entity) (water water)))

(defmethod layer-index ((water water)) +base-layer+)

(defmethod gravity ((water water))
  (vec 0 -5))

(defmethod drag ((water water))
  0.95)

(defmethod initialize-instance :after ((water water) &key)
  (setf (vertex-buffer water) (make-instance 'vertex-buffer :buffer-data (make-water-vertex-data (bsize water))
                                                            :data-usage :stream-draw))
  (setf (vertex-array water) (make-instance 'vertex-array :bindings `((,(vertex-buffer water) :size 2 :stride 8))
                                                          :size (/ (length (buffer-data (vertex-buffer water))) 2)
                                                          :vertex-form :triangle-strip))
  (setf (prev water) (copy-seq (buffer-data (vertex-buffer water)))))

(defmethod resize :after ((water water) width height)
  (setf (buffer-data (vertex-buffer water)) (make-water-vertex-data (bsize water)))
  (setf (prev water) (copy-seq (buffer-data (vertex-buffer water))))
  (setf (size (vertex-array water)) (/ (length (buffer-data (vertex-buffer water))) 2))
  (resize-buffer (vertex-buffer water) T))

(defmethod nudge ((water water) pos strength)
  (let ((i (+ (* (floor (- (vx pos) (- (vx (location water)) (vx (bsize water)))) 4) 4) 3))
        (data (buffer-data (vertex-buffer water))))
    (when (<= 4 i (- (length data) 4))
      (incf (aref data (- i 4)) strength)
      (incf (aref data i) strength)
      (incf (aref data (+ i 4)) strength))))

(defmethod enter ((entity game-entity) (water water))
  (when (< (+ (vy (bsize water)) (vy (location water)))
           (vy (location entity)))
    (nudge water (location entity)
           (clamp 0.5 (* 2 (abs (vy (velocity entity)))) 10.0))))

(defmethod leave ((entity game-entity) (water water))
  (when (< (+ (vy (bsize water)) (vy (location water)))
           (vy (location entity)))
    (nudge water (location entity)
           (clamp 0.5 (* 2 (abs (vy (velocity entity)))) 10.0))))

(defmethod propagation-speed ((water water))
  4000.0)

(defmethod dampening-factor ((water water))
  0.97)

(defmethod handle ((ev tick) (water water))
  (declare (optimize speed))
  (let* ((data (buffer-data (vertex-buffer water)))
         (prev (prev water))
         (h (vy (bsize water)))
         (dt (dt ev))
         (c (float (* dt dt (the single-float (propagation-speed water))) 0f0))
         (damp (the single-float (dampening-factor water))))
    (declare (type (simple-array single-float (*)) data prev))
    (declare (type single-float dt))
    ;; Discretized wave equation. We only care about i*4+3 indexes, as
    ;; those are the top edges. We then store our result for the next iteration
    ;; in the bottom edges. Once we're through we rotate and restore the bottom
    ;; edges to their constant y again.
    (loop for i from (+ 3 4) below (- (length data) 4) by 4
          for u = (- (aref data i) h)
          for p = (- (aref prev i) h)
          do (setf (aref prev i) (+ u h))
             (setf (aref data (- i 2))
                   (+ (* damp
                         (+ (- p)
                            (* 2 u)
                            (* c (+ (- (aref data (- i 4)) h)
                                    (* -2 u)
                                    (- (aref data (+ i 4)) h)))))
                      h)))
    (setf (aref data 3) h)
    (setf (aref data (- (length data) 1)) h)
    (loop for i from (+ 3 4) below (- (length data) 4) by 4
          do (shiftf (aref data i) (aref data (- i 2)) (- h)))
    (update-buffer-data (vertex-buffer water) T)))

(define-class-shader (water :vertex-shader)
  "layout (location = 0) in vec2 position;
out float height;
out vec2 world_pos;

uniform mat4 model_matrix;
uniform mat4 view_matrix;
uniform mat4 projection_matrix;

void main(){
  vec4 _position = model_matrix * vec4(position, 0.0f, 1.0f);
  world_pos = _position.xy;
  gl_Position = projection_matrix * view_matrix * _position;
  height = ((sign(position.y)+1)/2);
}")

(define-class-shader (water :fragment-shader)
  "in float height;
out vec4 color;
in vec2 world_pos;

void main(){
  color = apply_lighting_flat(vec4(0.53, 0.76, 0.99, 0.8), vec2(0), 1-(height*height*height*height), world_pos);
}")

(define-shader-entity sludge (water)
  ()
  (:inhibit-shaders (water :fragment-shader)))

(defmethod drag ((sludge sludge))
  0.8)

(define-class-shader (sludge :fragment-shader)
  "in float height;
out vec4 color;
in vec2 world_pos;

void main(){
  color = apply_lighting_flat(vec4(0.08, 0.05, 0.03, 1.0), vec2(0), 1-(height*height*height*height), world_pos);
}")

(defmethod nudge ((sludge sludge) pos strength)
  (call-next-method sludge pos (* 0.1 strength)))

(defmethod propagation-speed ((sludge sludge))
  50.0)

(defmethod dampening-factor ((sludge sludge))
  0.98)

(defmethod (setf medium) :around ((slude sludge) (player player))
  (setf (air-time player) 0.0)
  (call-next-method))

(define-shader-entity magma (water)
  ((emitter :accessor emitter)
   (nudge-time :initform 0.0 :accessor nudge-time))
  (:inhibit-shaders (water :fragment-shader)))

(defmethod initialize-instance :after ((magma magma) &key)
  (setf (emitter magma) (make-instance 'bubbler :tiles (make-tile-uvs 8 8 128 128 32) :parent magma)))

(defmethod stage :after ((magma magma) (area staging-area))
  (stage (emitter magma) area))

(defmethod enter* :after ((magma magma) container)
  (enter* (emitter magma) container))

(defmethod leave* :after ((magma magma) container)
  (leave* (emitter magma) container))

(defmethod drag ((magma magma))
  0.8)

(define-class-shader (magma :fragment-shader)
  "in float height;
out vec4 color;
in vec2 world_pos;

void main(){
  color = apply_lighting_flat(vec4(1.5, 0.5, 0.0, 1.0), vec2(0), 1-(height*height*height*height), world_pos);
}")

(defmethod nudge ((magma magma) pos strength)
  (call-next-method magma pos (* 0.3 strength)))

(defmethod propagation-speed ((magma magma))
  100.0)

(defmethod dampening-factor ((magma magma))
  0.99)

(defmethod handle :after ((ev tick) (magma magma))
  (when (<= (decf (nudge-time magma) (dt ev)) 0.0)
    (setf (nudge-time magma) (random* 1.0 1.0))
    (nudge magma (vec (random* (vx (location magma)) (* 2 (vx (bsize magma))))
                      (+ (vy (location magma)) (vy (bsize magma))))
           1.0)))

(define-shader-entity bubbler (light-emitter)
  ((parent :initarg :parent :accessor parent)
   (multiplier :initform 2.0)
   (amount :initform 32)))

(defmethod handle ((ev tick) (emitter bubbler))
  (let* ((vio (vio emitter))
         (live (update-particle-data (buffer-data vio) (* 2 (dt ev)) (gravity emitter))))
    (when (< live 2)
      (make-particle-data (make-tile-uvs 8 1 128 128 64)
                          :count 1
                          :scale 2.0 :scale-var 0.0
                          :dir-var 0
                          :speed 50 :speed-var 20
                          :origin (vec (vx (location (parent emitter)))
                                       (+ (vy (location (parent emitter)))
                                          (vy (bsize (parent emitter)))))
                          :spread (vec (* 2 (vx (bsize (parent emitter))))
                                       0)
                          :life 1.2 :life-var 0.3
                          :elt (buffer-data vio)
                          :start live))
    (update-buffer-data vio T)))
