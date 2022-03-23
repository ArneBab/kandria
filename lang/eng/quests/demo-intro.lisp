;; -*- mode: poly-dialog; -*-
(in-package #:org.shirakumo.fraf.kandria)

(define-sequence-quest (kandria demo-intro)
  :author "Tim White"
  :title "Talk to Islay"
  :description "The Semi in charge (I didn't catch her name) said I should talk to her sister, Islay, about what I can do for them, in exchange for turning the water back on."
  (:interact (islay)
   :title "Talk to Islay in the Semi Sisters base"
  "
~ islay
| Hello, Stranger. (:happy)It's an honour to meet you in person.
| (:unhappy)I'm sorry about my sister.
~ player
- What do I need to do?
  ~ islay
  | (:expectant)Right, yes. The sooner we get started, the sooner \"Innis\"(yellow) will turn your water back on.
- What's her problem?
  ~ islay
  | (:happy)How long have you got? Let's just say diplomacy isn't one of \"Innis'\"(yellow) strengths.
  ! eval (setf (nametag (unit 'innis)) (@ innis-nametag))
  | (:expectant)Anyway, about the job. The sooner we get started, the sooner we can turn your water back on.
- Can't you just turn the water back on?
  ~ islay
  | (:nervous)I'm afraid not. Much as I sympathise with your predicament.
  | (:normal)\"Innis\"(yellow) is at least right about that - we need that water too.
  ! eval (setf (nametag (unit 'innis)) (@ innis-nametag))
  | (:expectant)But a trade is acceptable. And the sooner we get started, the sooner we can turn it back on for you.
~ islay
| Basically we've got \"rail engineers stuck\"(orange) after a tunnel collapse in the \"high west\"(orange).
| And \"4 of our CCTV cameras on the low eastern\"(orange) \"Cerebat\"(red) border have gone down.
? (not (active-p (unit 'blocker-engineers)))
| ~ islay
| | Actually, no: don't worry about the engineers.
| | The last report shows they've been freed - by whom I'm not sure.
| ~ player
| - It was me.
|   < thank-you
| - Your guardian angel.
|   ~ islay
|   | (:expectant)Wait - are you saying...?
|   ~ player
|   - Yes.
|     < thank-you
|   - No.
|     ~ islay
|     | (:unhappy)Oh, okay then. Anyway...
|     < metro
|   - I'm not saying anything.
|     ~ islay
|     | (:unhappy)Oh, okay. Anyway...
|     < metro
| - Who do you think?
|   < thank-you
! label questions
~ player
- [(active-p (unit 'blocker-engineers)) Tell me about the trapped engineers.|]
  ~ islay
  | (:nervous)There were ten of them, working in the \"high west of our territory\"(orange).
  | We're slowly digging out the old maglev metro system. (:happy)We've got a basic electrified railway going.
  | (:unhappy)But it's dangerous work. They didn't report in, and our hunters found the tunnel collapsed.
  < questions
- [(not (active-p (unit 'blocker-engineers))) So the engineers were working on the metro?|]
  ~ islay
  | Correct. We're slowly digging out the old maglev system. (:happy)We've got a basic electrified railway going.
  | (:nervous)But it's dangerous work.
  < questions
- Tell me about the down CCTV cameras.
  ~ islay
  | We monitor the surrounding areas, immediately above and below.
  | (:nervous)But \"4 of our cameras\"(orange) on the Cerebat border have gone down, in the \"low eastern region\"(orange).
  | (:normal)It's probably just an electrical fault. Unfortunately the way we daisy-chain them together, when one goes they all go.
  | I'd like you to check them out.
  < questions
- Understood.
~ islay
| (:expectant)We've seen what you can do - you're better suited to this than our hunters.
| (:nervous)Just don't tell Innis I said that. She'll think I've gone soft for androids.
! eval (setf (nametag (unit 'innis)) (@ innis-nametag))
| I can also \"trade any items you find for scrap parts, the currency we use around here\"(orange). Then you can \"buy supplies\"(orange) to help you in the field.
| \"Let me know if you want to trade.\"(orange)
| \"Report back to Innis\"(orange) when you have news - by then we \"might be up in the control room\"(orange).
| Good luck.
! eval (activate (unit 'cctv-4-trigger))
! eval (activate 'trader-shop-semi)
? (active-p (unit 'blocker-engineers))
| ! eval (activate 'demo-engineers)

# thank-you
~ islay
| Really? You did that for us?
~ player
- Sure.
- That's what I do.
- I was exploring, so figured why not.
~ islay
| (:happy)Well in that case, thank you. We owe you.
| But there's more to do.
< metro

# metro
~ islay
| This does mean our engineering works are back on schedule though.
| With that in mind, I think we could grant you \"access to the metro\"(orange). It will certainly \"speed up your errands\"(orange).
? (or (unlocked-p (unit 'station-surface)) (unlocked-p (unit 'station-semi-sisters)))
| | We know you've seen the metro already, and that's alright. But now it's official.
| | I'll send out word, so Innis won't have you... (:happy)apprehended.
| ! eval (setf (nametag (unit 'innis)) (@ innis-nametag))
| | (:normal)\"The stations run throughout our territory and beyond\"(orange). Though \"not all are operational\"(orange) while we expand the network.
|?
| | (:normal)You'll find \"the stations run throughout our territory and beyond\"(orange). Though \"not all are operational\"(orange) while we expand the network.
| | Just \"choose your destination from the route map\"(orange) and board the train.
? (not (unlocked-p (unit 'station-semi-sisters)))
| | \"Our station is beneath this central block.\"(orange)
< questions
")
  (:eval
   :on-complete (demo-cctv)))
