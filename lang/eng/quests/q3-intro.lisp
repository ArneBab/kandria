;; -*- mode: poly-dialog; -*-
(in-package #:org.shirakumo.fraf.kandria)

(quest:define-quest (kandria q3-intro)
  :author "Tim White"
  :title "Query Jack"
  :description "It's been intimated that I could help Jack with something."
  :on-activate T
  
  (talk-to-jack
   :title "Talk to Jack in Engineering"
   :condition all-complete
   :on-activate T
   :on-complete (q3-new-home)

   ;; could have been sent here by Fi or Catherine
   (:interaction talk-jack
    :interactable jack
    :dialogue "
~ jack
| (:annoyed)Oh, it's you. Come to kill me?
~ player
- What?
  ~ jack
  | (:annoyed)No sense of humour. Figures.
- What do you think?
  ~ jack
  | (:annoyed)No. Not while you've got Fi and Cathy wrapped around your fake little finger.
- I wish.
  ~ jack
  | (:shocked)O oh, you keep talking like that and Fi will dismantle you. Wouldn't want that, would ya?
~ jack
| Anyway, you can do something for me.
| Fi wants to \"scout for a new home\"(orange) - I guess she's worried sick now the Wraw are breathing down our necks.
| Well as you can see, I'm no scout. I guess I just don't have the physique for it.
| \"Alex\"(yellow) is our hunter, but God knows where they are. So it's up to you... (:annoyed)Stranger.
~ player
- Lucky me.
  ~ jack
  | I hope so.
- What's the plan?
- You got it boss.
  ~ jack
  | (:annoyed)Don't you try and sweet-talk me, darlin'. Look...
~ jack
| I think the \"Ruins to the east\" are your best shot. It keeps us close to the Farm, and still gives us shelter.
| So \"cross the surface\"(orange), scout around, climb, dig - do whatever an android does.
| Just remember while you ninja around that we mere mortals gotta follow your path.
| Your android brain might think the top of a skyscraper is the safest place there is.
| But people can't climb up there, let alone live up there. You get me?
~ player
- Got it.
- Not really.
  ~ jack
  | (:annoyed)Tough titty - I ain't repeating myself.
- Do you think I'm stupid?
  ~ jack
  | (:annoyed)I'm yet to see evidence to the contrary. Just do the job, okay?
~ jack
| Well, I guess I should say good luck.
| Don't bother to check in with your FFS or whatever the fuck it's called - I'm busy.
~ player
| //Speaking of my FFCS: it indicates \"four candidate locations\". That should help narrow things down.//
")))
