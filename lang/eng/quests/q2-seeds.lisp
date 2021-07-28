;; -*- mode: poly-dialog; -*-
(in-package #:org.shirakumo.fraf.kandria)

(quest:define-quest (kandria q2-seeds)
  :author "Tim White"
  :title "Retrieve the Seeds"
  :description "The settlement are low on food, and need me to retrieve the last of the seeds from the cache they discovered."
  :on-activate (find-seeds)

  (find-seeds
   :title "Find the seed cache across the surface and beneath the Ruins to the east"
   :description NIL
   :invariant T
   :condition (have 'item:seeds 20)
   :on-activate (q2-reminder seeds-arrive)
   :on-complete (return-seeds)

   (:interaction q2-reminder
    :interactable fi
    :repeatable T
    :dialogue "
~ fi
| Travel across the surface and beneath the Ruins to the \"east - retrieve whatever seeds remain\"(orange) in the cache.
| Good luck, Stranger.
")

   ;; enemies on this quest will be world NPCs, not spawned for the quest
   ;; REMARK: Should have a lead-in to explain stuff lying around already:
   ;;         "Containers and sacks of seeds are strewn about. Someone's been through here before."
   ;;         "Most of the stuff lying around seems spoiled, but some of the closed containers should still have usable seeds."
   ;; TIM REPLY: Added this. I left it out, as I thought this ransacking would be clear from the visuals, and didn't want to repeat the obvious. Though I haven't seen the visuals yet. Doesn't hurt I guess for some extra emphasis here.
   ;; REMARK: The last option seems strange to me. Do we have consistent options throughout to be adversarial?
   ;;         Does that properly reflect in how the story develops? Does the stranger have a reason to be adversarial?
   ;;         Rephrasing it as something like "Somehow it doesn't feel right to take this stuff." seems a bit better at least.
   ;; TIM REPLY: I added the "somehow", as this help regardless. There are occasional adversarial options, usually just for flavour. Here my plan is that Alex could learn of this if you took the bad choice, and try and use it to frame you later. Right now it's just a hook, and it could be taken out later if it ends up leading to nothing.
   ;; TIM REPLY 2: From discussion with testers too, removed the adversarial options for now
   ;; TODO encode these retrieval quantities as global vars at the quest level, for use when returning the quest too
   (:interaction seeds-arrive
    :interactable cache
    :dialogue "
~ player
| \"//It's an old-world bunker. This must be the storage cache.//\"(light-gray)
| \"//It smells as old as it looks. Containers and sacks of seeds are strewn about. Someone's been through here before.//\"(light-gray)
| \"//Most of this is spoiled, but some of the drawers may still house usable seeds. Let's see...//\"(light-gray)
| \"//This is all that's left:\"(light-gray) \"24 sachets\"(orange)\". Inside each one the seeds are tiny and hard like grit.//\"(light-gray)
| (:skeptical)\"//Will they still grow?//\"(light-gray)
| (:normal)\"//I take them regardless and stow them in my compartment.//\"(light-gray)
| \"//I should return to Fi.//\"(light-gray)
! eval (store 'item:seeds 24)
! eval (deactivate 'q2-reminder)
"))
  ;; TODO: use a variable to track if you took none / destroyed, which could come back and bite you in the ass later (Alex finds out, and tries to frame you to cover his own tracks? - ties into the plot outline) - log as a var on the storyline
  ;; TODO: use an exact technical unit/amount of pressure e.g. X pounds per inch (research)

  #| TODO removed option to destroy the seeds, logged here in case needed in the future beyond act 1, where a choice like this might be more suitable (e.g. doing a task for another faction, playing them off against one another, etc.)
  - (Take all the sachets)
  | //I stow 54 sachets in my compartment.//
  ! eval (store 'seeds 54)
  - (Take some of the sachets)
  | //I stow 17 sachets in my compartment.//
  ! eval (store 'seeds 17)
  - (Destroy the seeds)
  | //Somehow it doesn't feel right to take them.//
  | //I hold the sachets in my hands, several at a time, and exert pressure sufficient to crush them into particulates.//
  | //My hands feel warm with the pressure and friction.//
  |#

  (return-seeds
   :title "Return to Fi on the Farm"
   :condition all-complete
   :on-activate T

   ;; enemies on this quest will be world NPCs, not spawned for the quest
   ;; REMARK: It feels a bit too soon for Fi to fully trust the stranger already.
   ;;         I think it would be better if she remarked positively about it and hinted at
   ;;         welcoming her into the group, but only making her an actual member in Act 2.
   ;;         Also gives the player something to look forward to and we can build it up
   ;;         to be a more impactful and rewarding moment.
   ;; TIM REPLY & TODO: Good point. Will leave this comment here as a reminder
   ;; REMARK: Also as you already mentioned in the other part, would be best if the lie
   ;;         options were gated behind a variable that is set in the other task if you
   ;;         don't take anything.
   ;; TIM REPLY: I thought it could be cool if you can take the seeds from the cache AND lie about it, so keep them for yourself. Perhaps if you later trade them in with Sahil, word gets back to Fi - could be a nice consequence
   (:interaction seeds-return-fi
    :interactable fi
    :dialogue "
~ fi
| You're back - did you find the seeds?
~ player
| I've got the last of them right here.
~ fi
! eval (retrieve 'item:seeds T)
| Oh my. There must be... twenty sachets here. All fully stocked.
| You've done well. Very well. I'll see these are sown right away.
| This buys us hope I never thought we'd have.
| Know that you are earning my trust, Stranger. Perhaps you will become a part of the \"Noka\"(red) yourself.
| But for now, please accept this reward as a token of my appreciation.
! eval (retrieve 'item:semi-factory-key 1)
! eval (store 'item:parts 20)
~ fi
? (complete-p 'q3-new-home)
| | You should \"check in with Catherine\"(orange) - I'm sure she'd like to see you again.
| ! eval (activate 'sq-act1-intro)
|?
| ? (not (active-p 'q3-new-home))
| | | Oh, I've also \"given Jack a special assignment\"(orange) - something I think you'll be well-suited to help with.
| | | He'll be in Engineering.
|   
| | I also heard \"Sahil is here - our trader friend\"(orange). His caravan is down in the Midwest Market, beneath the \"Zenith Hub\"(red).
| | You would be wise to equip well for your work.
| ! eval (activate 'trader-arrive)
")))

;; kuso = shit (Japanese)
;; TODO: act 2 prelude too
;; player learns "Noka" for the first time
;; TODO fi happy - | Oh my. There must be... fifty sachets here. All fully stocked.

;; Removing key unspoken, as it can't sound anything but negative at a positive time, if Fi takes it back. Also, there's nothing left of value in the cache now, so it can remain open, and undiscussed here (implied, save words)

#| ARCHIVED VERSION before lie options removed - for reference. May be useable in a future act.

(quest:interaction :name seeds-return-fi :interactable fi :dialogue "
~ fi
| You're back - did you find the seeds?
~ player
- [(have 'item:seeds) I've got them right here.]
~ fi
? (= 54 (item-count 'seeds))
| ! eval (retrieve 'seeds 54)
| | Oh my... there must be... fifty sachets here. All fully stocked.
| | You've done well. Very well. I'll see these are sown right away.
| | This buys us hope I never thought we'd have.
| | Know that you are earning my trust, Stranger. Perhaps in time you will become a part of the Noka yourself.
| | God knows we could use another hunter.
| | But for now, please accept this reward as a token of my appreciation.
| ! eval (store 'parts 20)
| < end
|? (= 17 (item-count 'seeds))
| ! eval (retrieve 'seeds 17)
| | Oh, is that all that was left?
| ~ player
| - I'm afraid so.
|   ~ fi
|   | That's... disappointing. But I guess it was a long shot.
|   | I knew we should have taken them all when we had the chance.
|   | I suppose I was worried they'd be destroyed, if we came under attack.
| - Someone must have taken them.
|   ~ fi
|   | Perhaps... Though what use they'd be to anyone else, I do not know.
|   | We're the only ones crazy enough to live on the surface.
| - The bunker was old and ransacked.
|   ~ fi
|   | Yes... Alex had previously reported it as such.
| ~ fi
| | Oh well, I suppose this is better than nothing. I just hope it will be enough.
| | Thank you for you efforts. I'll see these are sown right away.
| | But this has earned some trust - perhaps in time you will become a part of the Noka yourself.
| | God knows we could use another hunter. But for now, please accept this reward as a token of my appreciation.
| ! eval (store 'parts 20)
| < end
- (Lie) I'm afraid there weren't any left.
~ fi
| ...
| None left... Alex told me there were at least fifty sachets remaining.
| I knew we should have taken them all when we had the chance.
| I suppose I was worried they'd be destroyed, if we came under attack.
< bad-end
- (Lie) There were rogue robots. I think they took them.
~ fi
| Rogues... in the cache?...
| We've never seen them there before - which means the Wraw must have discovered that as well.
| Kuso... It seems they have us at a serious disadvantage.
< bad-end
# bad-end
| Well, thank you for making the journey. This has earned some trust.
| Perhaps in time you will become a part of the Noka yourself. God knows we could use another hunter.
| But for now, please accept this reward as a token of my appreciation.
! eval (store 'parts 20)
| Now I must think about our next move. Whatever it is, I fear it won't be straightforward.
< end
# end
~ fi
? (complete-p 'q3-new-home)
| | You should check in with Catherine too - I'm sure she'd like to see you again.
| ! eval (activate 'sq-act1-intro)
|?
| ? (not (active-p 'q3-new-home))
| | | Oh, I've also given Jack a special assignment - something I think you'll be well-suited to help with.
| | | He'll be in Engineering.
|   
| | I also heard Sahil is here - our trader friend. His caravan is down in the Midwest Market, beneath the Zenith Hub.
| | It would be wise to be well-equipped for your work.
| ! eval (setf (location 'trader) 'loc-trader)
| ! eval (activate 'trader-arrive)
")

|#
