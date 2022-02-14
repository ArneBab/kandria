;; -*- mode: poly-dialog; -*-
(in-package #:org.shirakumo.fraf.kandria)

(define-sequence-quest (kandria demo-semis)
  :author "Tim White"
  :title "Find the Semi Sisters"
  :description "I need to find the tech-witch Semi Sisters, so they can restore the water supply for my friends on the surface."
  (:go-to (innis)
   :title "Find the Semi Sisters")
  (:interact (innis :now T)
    "
~ innis
| (:angry)<-STOP-> WHERE YOU ARE!!
| Did you think ya could just waltz right through here?
| (:sly)We've been watching you, android.
~ player
- Who are you?
  ~ innis
  | Alas, no' too smart...
- What do you want?
  ~ innis
  | (:sly)I'll ask the questions, if ya dinnae mind.
- Are you the Semi Sisters?
  ~ innis
  | (:sly)I'll ask the questions, if ya dinnae mind.
| (:normal)What //should// we do with you? I bet your \"Genera\"(red) core could run our entire operation.
| What do you think, Islay?
! eval (setf (nametag (unit 'islay)) (@ islay-nametag))
~ islay
| (:unhappy)I think you should leave her alone.
~ innis
| (:angry)...
| (:normal)Come now, sister - the pinnacle of human engineering is standing before you, and that's all you can say?
| (:sly)That wasn't a compliment by the way, android. (:normal)But let's no' get off on the wrong foot now.
~ player
- (Keep quiet)
  ~ innis
  | (:sly)Why are you are here? I ken lots about you, but I wanna ken more.
- My name's Stranger.
  ~ innis
  | This I ken, android. (:sly)Tell me, why are you here?
~ player
- If you're the Semi Sisters I need your help.
  ~ innis
  | (:pleased)You see, sister, the direct approach once again yields results - and confirms my info.
  | (:normal)Well you'll be pleased to ken that we can turn the water back on for you.
- My business is my business.
  ~ innis
  | If that's your prerogative.
  | But you'll be pleased to ken that we can turn the water back on for you.
- Screw you!
  ~ islay
  | (:happy)...
  ~ innis
  | (:angry)...
  | I remember your kind! You think you're clever just 'cause you can mimic us.
  | You're a machine, and if I wanted I could have you pulled apart and scattered to the four corners of this valley.
  | (:normal)Now, let's try again.
  | You'll be pleased to ken that we can turn the water back on for you.
~ innis
| (:sly)Once you've done something for us.
| (:angry)Did your \"friends\" honestly think they could siphon it off forever?
| That's no' how the world works.
| (:normal)And I don't know why you bother - you don't need to drink. I'd sack them off if I was you.
| Anyway, my \"sister\"(orange) knows what we need. \"Talk to her.\"(orange)
  ")
  (:eval
   :on-complete (demo-cctv-intro)))
   
#|
dinnae = don't (Scottish)
ken = know (Scottish)
|#