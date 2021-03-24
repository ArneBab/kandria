(in-package #:org.shirakumo.fraf.kandria)

(define-shader-entity fade (transformed listener vertex-entity)
  ((name :initform 'fade)
   (vertex-array :initform (// 'trial 'fullscreen-square))
   (on-complete :initform NIL :accessor on-complete)
   (strength :initform 0.0 :accessor strength)
   (color :initform (vec 0 0 0) :accessor color)))

(defmethod handle ((ev transition-event) (fade fade))
  (unless (flare:running (progression 'transition +world+))
    (setf (on-complete fade) (on-complete ev))
    (setf (clock (progression 'transition +world+)) 0f0)
    (start (progression 'transition +world+))))

(defmethod apply-transforms progn ((fade fade))
  (setf *projection-matrix*
        (setf *view-matrix*
              (setf *model-matrix* (meye 4)))))

(defmethod render :before ((fade fade) (program shader-program))
  (setf (uniform program "screen_color") (color fade))
  (setf (uniform program "strength") (strength fade)))

(define-class-shader (fade :fragment-shader)
  "uniform float strength = 0.0;
uniform vec3 screen_color = vec3(0,0,0);
out vec4 color;
void main(){ color = vec4(screen_color,strength); }")

(define-progression death
  0 1.0 (distortion (set strength :from 0.0 :to 1.0))
  1.0 1.0 (player (call (lambda (player clock step) (respawn player))))  
  1.5 2.5 (distortion (set strength :from 1.0 :to 0.0 :ease circ-in)))

(define-progression hurt
  0.0 0.2 (distortion (set strength :from 0.0 :to 0.7 :ease expo-out))
  0.2 0.3 (distortion (set strength :from 0.7 :to 0.0 :ease expo-out)))

(define-progression transition
  0.0 0.0 (fade (set color :to (vec 0 0 0)))
  0.0 0.5 (fade (set strength :from 0.0 :to 1.0 :ease quint-in))
  0.5 0.5 (fade (call (lambda (fade clock step) (funcall (on-complete fade)))))
  0.5 1.0 (fade (set strength :from 1.0 :to 0.0 :ease quint-out)))

(define-progression flash
  0.0 0.0 (fade (set color :to (vec 5 5 5)))
  0.0 0.05 (fade (set strength :from 0.0 :to 0.8))
  0.05 0.2 (fade (set strength :from 0.8 :to 0.0 :ease expo-out)))

(define-progression stun
  0.0 0.1 (T (set time-scale :from 1.0 :to 0.5 :ease quint-in))
  0.2 0.3 (T (set time-scale :from 0.5 :to 1.0 :ease quint-out)))

(define-shader-pass distortion-pass (simple-post-effect-pass)
  ((name :initform 'distortion)
   (active-p :initform NIL)
   (texture :initform (// 'kandria 'pixelfont) :accessor texture)
   (strength :initform 0f0 :accessor strength)))

(defmethod (setf strength) :after (strength (pass distortion-pass))
  (unless (eq (active-p pass) (< 0 strength))
    (setf (active-p pass) (< 0 strength))))

(defmethod stage :after ((pass distortion-pass) (area staging-area))
  (stage (texture pass) area))

(defmethod prepare-pass-program :after ((pass distortion-pass) (program shader-program))
  (gl:active-texture :texture0)
  (gl:bind-texture :texture-2d (gl-name (texture pass)))
  (setf (uniform program "pixelfont") 0)
  (setf (uniform program "seed") (logand #xFFFF (sxhash (floor (* 10 (clock +world+))))))
  (setf (uniform program "strength") (strength pass)))

(defmethod handle ((event event) (pass distortion-pass)))

(define-class-shader (distortion-pass :fragment-shader)
  "uniform sampler2D pixelfont;
uniform sampler2D previous_pass;
uniform int seed = 0;
uniform float strength = 0.0;
in vec2 tex_coord;
out vec4 color;

const vec2 num = vec2(40, 26)*2;
const ivec2 glyphs = ivec2(10, 13);
const int glyph_count = 10*13;

float rand(vec2 co){
    float a = 12.9898;
    float b = 78.233;
    float c = 43758.5453;
    float dt= dot(co.xy ,vec2(a,b));
    float sn= mod(dt,3.14);
    return fract(sin(sn) * c);
}

void main(){
  float scalar = 1-clamp(strength,0,1);
  vec2 pos = floor(tex_coord*num);
  int r = int(rand(pos+seed)*glyph_count);
  float val = 1;
  if(scalar*glyph_count < r){
    vec2 idx = vec2(r%glyphs.x, r/glyphs.x);
    vec2 sub = mod(tex_coord*num, 1);
    val = texelFetch(pixelfont, ivec2((sub+idx)*7), 0).r;
  }
  float scale = clamp(r,scalar*30,glyph_count)*scalar*scalar;
  pos = floor(tex_coord*num*scale)/scale;
  if(val == 1){
    color = texture(previous_pass, pos/num);
    color = mix(color, vec4(0.2,0.3,0.7,1), clamp(strength*4-3,0,1));
  }else{
    color = texture(previous_pass, (pos+1)/num);
    color = mix(color, vec4(1), clamp(strength*4-3,0,1));
  }
}")

(define-shader-pass sandstorm-pass (simple-post-effect-pass)
  ((name :initform 'sandstorm)
   (active-p :initform NIL)
   (noise :port-type fixed-input :texture (// 'kandria 'noise))
   (noise-cloud :port-type fixed-input :texture (// 'kandria 'noise-cloud))
   (strength :initform 0f0 :accessor strength)))

(defmethod (setf strength) :after (strength (pass sandstorm-pass))
  (unless (eq (active-p pass) (< 0 strength))
    (setf (active-p pass) (< 0 strength))))

(defmethod stage :after ((pass sandstorm-pass) (area staging-area))
  (stage (texture (port pass 'noise)) area)
  (stage (texture (port pass 'noise-cloud)) area))

(defmethod render :before ((pass sandstorm-pass) (program shader-program))
  (setf (uniform program "strength") (strength pass))
  (setf (uniform program "time") (clock +world+)))

(define-class-shader (sandstorm-pass :fragment-shader)
  "
uniform float time;
uniform sampler2D previous_pass;
uniform sampler2D noise;
uniform sampler2D noise_cloud;
uniform float strength = 1.0;
in vec2 tex_coord;
out vec4 color;

void main(){
  vec3 previous = texture(previous_pass, tex_coord).rgb;
  float t = time*3;
  float r = (sin(t)+sin(t*0.3)+sin(t*0.1))*0.1;
  vec3  n = texture(noise,       (tex_coord+r*vec2(1, 0.20)+vec2(0, 0.0)+t*vec2(0.4, 0.1))*1.5).rgb;
  float a = texture(noise_cloud, (tex_coord+r*vec2(1, 0.21)+vec2(0, 0.0)+t*vec2(0.5, 0.05))*0.3).r;
  float b = texture(noise_cloud, (tex_coord+r*vec2(1, 0.22)+vec2(0, 0.5)+t*vec2(0.6, 0.1))*0.2).r;
  float c = texture(noise_cloud, (tex_coord+r*vec2(1, 0.23)+vec2(0, 0.3)+t*vec2(0.65,0.1))*0.1).r;
  float s = a*b*c*(length(n)*0.1+0.95)*strength;
  vec3 sand = vec3(0.9, 0.8, 0.7)*(s+0.5)+n/20;
  color = vec4(mix(sand, previous, clamp(1.3-s*5+strength, 0, 1)), 1);
}")
