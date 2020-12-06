;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-advanced-reader.ss" "lang")((modname adventure) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #t #t none #f () #f)))
(require "adventure-define-struct.rkt")
(require "macros.rkt")
(require "utilities.rkt")

;;;
;;; OBJECT
;;; Base type for all in-game objects
;;;

(define-struct object
  ;; adjectives: (listof string)
  ;; List of adjectives to be printed in the description of this object
  (adjectives)
  
  #:methods
  ;; noun: object -> string
  ;; Returns the noun to use to describe this object.
  (define (noun o)
    (type-name-string o))

  ;; description-word-list: object -> (listof string)
  ;; The description of the object as a list of individual
  ;; words, e.g. '("a" "red" "door").
  (define (description-word-list o)
    (cons "the" (append (object-adjectives o)
                        (remove "room" (list (noun o))))))
  ;; description: object -> string
  ;; Generates a description of the object as a noun phrase, e.g. "a red door".
  (define (description o)
    (words->string (description-word-list o)))
  
  ;; print-description: object -> void
  ;; EFFECT: Prints the description of the object.
  (define (print-description o)
    (begin (printf (description o))
           (newline)
           (void))))

;;;
;;; CONTAINER
;;; Base type for all game objects that can hold things
;;;

(define-struct (container object)
  ;; contents: (listof thing)
  ;; List of things presently in this container
  (contents)
  
  #:methods
  ;; container-accessible-contents: container -> (listof thing)
  ;; Returns the objects from the container that would be accessible to the player.
  ;; By default, this is all the objects.  But if you want to implement locked boxes,
  ;; rooms without light, etc., you can redefine this to withhold the contents under
  ;; whatever conditions you like.
  (define (container-accessible-contents c)
    (container-contents c))
  
  ;; prepare-to-remove!: container thing -> void
  ;; Called by move when preparing to move thing out of
  ;; this container.  Normally, this does nothing, but
  ;; if you want to prevent the object from being moved,
  ;; you can throw an exception here.
  (define (prepare-to-remove! container thing)
    (void))
  
  ;; prepare-to-add!: container thing -> void
  ;; Called by move when preparing to move thing into
  ;; this container.  Normally, this does nothing, but
  ;; if you want to prevent the object from being moved,
  ;; you can throw an exception here.
  (define (prepare-to-add! container thing)
    (void))
  
  ;; remove!: container thing -> void
  ;; EFFECT: removes the thing from the container
  (define (remove! container thing)
    (set-container-contents! container
                             (remove thing
                                     (container-contents container))))
  
  ;; add!: container thing -> void
  ;; EFFECT: adds the thing to the container.  Does not update the thing's location.
  (define (add! container thing)
    (set-container-contents! container
                             (cons thing
                                   (container-contents container))))

  ;; describe-contents: container -> void
  ;; EFFECT: prints the contents of the container
  (define (describe-contents container)
    (begin (local [(define other-stuff (remove me (container-accessible-contents container)))]
             (if (empty? other-stuff)
                 (printf "There's nothing here.~%")
                 (begin (printf "You see:~%")
                        (for-each print-description other-stuff))))
           (void))))

;; move!: thing container -> void
;; Moves thing from its previous location to container.
;; EFFECT: updates location field of thing and contents
;; fields of both the new and old containers.
(define (move! thing new-container)
  (begin
    (prepare-to-remove! (thing-location thing)
                        thing)
    (prepare-to-add! new-container thing)
    (prepare-to-move! thing new-container)
    (remove! (thing-location thing)
             thing)
    (add! new-container thing)
    (set-thing-location! thing new-container)))

;; destroy!: thing -> void
;; EFFECT: removes thing from the game completely.
(define (destroy! thing)
  ; We just remove it from its current location
  ; without adding it anyplace else.
  (remove! (thing-location thing)
           thing))


;;;
;;; ROOM
;;; Base type for rooms and outdoor areas
;;;

(define-struct (room container)
  ())

;; new-room: string -> room
;; Makes a new room with the specified adjectives
(define (new-room adjectives)
  (make-room (string->words adjectives)
             '()))

;;;
;;; THING
;;; Base type for all physical objects that can be inside other objects such as rooms
;;;

(define-struct (thing container)
  ;; location: container
  ;; What room or other container this thing is presently located in.
  (location)
  
  #:methods
  (define (examine thing)
    (print-description thing))

  ;;eat -> lets you know that you can't eat a thing unless it's a food
  (define (eat thing)
    (display-line "You can't eat this. It is inedible."))

  ;; prepare-to-move!: thing container -> void
  ;; Called by move when preparing to move thing into
  ;; container.  Normally, this does nothing, but
  ;; if you want to prevent the object from being moved,
  ;; you can throw an exception here.
  (define (prepare-to-move! container thing)
    (void)))

;; initialize-thing!: thing -> void
;; EFFECT: adds thing to its initial location
(define (initialize-thing! thing)
  (add! (thing-location thing)
        thing))

;; new-thing: string container -> thing
;; Makes a new thing with the specified adjectives, in the specified location,
;; and initializes it.
(define (new-thing adjectives location)
  (local [(define thing (make-thing (string->words adjectives)
                                    '() location))]
    (begin (initialize-thing! thing)
           thing)))


;;;
;;; DOOR
;;; A portal from one room to another
;;; To join two rooms, you need two door objects, one in each room
;;;

(define-struct (door thing)
  ;; destination: container
  ;; The place this door leads to
  (destination)
  
  #:methods
  ;; go: door -> void
  ;; EFFECT: Moves the player to the door's location and (look)s around.
  (define (go door)
    (begin (move! me (door-destination door))
           (look)))

  (define (take door)
    (print "You can't take that!")))

;; join: room string room string
;; EFFECT: makes a pair of doors with the specified adjectives
;; connecting the specified rooms.
(define (join! room1 adjectives1 room2 adjectives2)
  (local [(define r1->r2 (make-door (string->words adjectives1)
                                    '() room1 room2))
          (define r2->r1 (make-door (string->words adjectives2)
                                    '() room2 room1))]
    (begin (initialize-thing! r1->r2)
           (initialize-thing! r2->r1)
           (void))))

;;;
;;; PERSON
;;; A character in the game.  The player character is a person.
;;;

(define-struct (person thing)
  (calorie-count)

  #:methods

  (define (take person)
    (print "You can't take that!"))

  (define (check-calories person)
    (if (> (person-calorie-count person) 60)
        (display-line "You are full!")
        (display-line (+ (person-calorie-count person) 0)))
    )
  )



;; initialize-person: person -> void
;; EFFECT: do whatever initializations are necessary for persons.
(define (initialize-person! p)
  (initialize-thing! p))

;; new-person: string container -> person
;; Makes a new person object and initializes it.
(define (new-person adjectives location calorie-total)
  (local [(define person
            (make-person (string->words adjectives)
                         '()
                         location
                         0))]
    (begin (initialize-person! person)
           person)))

;; This is the global variable that holds the person object representing
;; the player.  This gets reset by (start-game)
(define me empty)

;;;
;;; PROP
;;; A thing in the game that can be held by the person.
;;;

(define-struct (prop thing)
  (;; noun-to-print: string
   ;; The user can set the noun to print in the description so it doesn't just say "prop"
   noun-to-print
   ;; examine-text: string
   ;; Text to print if the player examines this object
   examine-text
   )
  
  #:methods
  (define (noun prop)
    (prop-noun-to-print prop))

  (define (examine prop)
    (display-line (prop-examine-text prop)))

  (define (take prop)
    (move! prop me))

  (define (drop prop)
    (move! prop (here)))

  (define (put prop container)
    (move! prop container)))

;; new-prop: string container -> prop
;; Makes a new prop with the specified description.
(define (new-prop description examine-text location)
  (local [(define words (string->words description))
          (define noun (last words))
          (define adjectives (drop-right words 1))
          (define prop (make-prop adjectives '() location noun examine-text))]
    (begin (initialize-thing! prop)
           prop)))

;;;
;;; ADD YOUR TYPES HERE!
;;;

;;;
;;; STAIRS
;;; Like doors, but go between floors
;;;

(define-struct (stairs door)
  ()

  #:methods
  (define (take stairs)
    (print "You can't take that!")))

;; join-floors: room string room string
;; EFFECT: makes a flight of stairs with the specified adjectives
;; connecting the specified rooms.

(define (join-floors! room1 adjectives1 room2 adjectives2)
  (local [(define r1->r2 (make-stairs (string->words adjectives1)
                                      '() room1 room2))
          (define r2->r1 (make-stairs (string->words adjectives2)
                                      '() room2 room1))]
    (begin (initialize-thing! r1->r2)
           (initialize-thing! r2->r1)
           (void))))

;;;
;;; FURNITURE
;;; A thing that exists as decoration or to be sat on. I'm almost jealous.
;;;

(define-struct (furniture thing)
  (;; noun-to-print: string
   ;; The user can set the noun to print in the description so it doesn't just say "prop"
   noun-to-print
   ;; examine-text: string
   ;; Text to print if the player examines this object
   examine-text
   )
  
  #:methods
  (define (noun furniture)
    (furniture-noun-to-print furniture))

  (define (examine furniture)
    (display-line (furniture-examine-text furniture)))

  (define (take furniture)
    (print "You can't take that!")))

;; new-furniture: string container -> furniture
;; Makes a new piece of furniture with the specified description.
(define (new-furniture description examine-text location)
  (local [(define words (string->words description))
          (define noun (last words))
          (define adjectives (drop-right words 1))
          (define furniture (make-furniture adjectives '() location noun examine-text))]
    (begin (initialize-thing! furniture)
           furniture)))

;;;
;;; FOOD
;;; A thing that a person can eat!
;;;

(define-struct (food prop)
  (calories)
  
  #:methods
  (define (eat food)
    (calorie-accumulator food me))

  (define (calorie-accumulator food person)
    (if (> (person-calorie-count person) 2500)
        (display-line "You can't eat anymore. You are full!")
        (begin (destroy! food)
               (set-person-calorie-count! person (+ (person-calorie-count person) (food-calories food)))
               (display-line "Yum!")))))

;; new-food: string container -> food
;; Makes a new piece of food with the specified description.
(define (new-food description examine-text location calorie)
  (local [(define words (string->words description))
          (define noun (last words))
          (define adjectives (drop-right words 1))
          (define food (make-food adjectives '() location noun examine-text calorie))]
    (begin (initialize-thing! food)
           food)))

;;;
;;; WEAPON
;;; A thing that is used to attack enemies.
;;;

(define-struct (weapon container)
  (damage speed durability ammunition)

  #:methods
  (define (attack enemy)
    ("Insert here"))

  (define (defend enemy)
    ("insert here")))

;;; new-weapon: string container -> weapon
;;; Creates a new weapon with the specified description

(define (new-weapon description examine-text location)
  (local [(define words (string->words description))
          (define noun (last words))
          (define adjectives (drop-right words 1))
          (define weapon (make-weapon adjectives '() location noun examine-text))]
    (begin (initialize-thing! weapon)
           weapon)))

;;;
;;; ARMOR
;;; A container that takes damage for the player without losing health
;;;

(define-struct (armor container)
  (armor-value))

;;;
;;; new-armor: string container -> weapon
;;; Creates a new armor with the specified description

(define (new-armor description examine-text location)
  (local [(define words (string->words description))
          (define noun (last words))
          (define adjectives (drop-right words 1))
          (define armor (make-armor adjectives '() location noun examine-text))]
    (begin (initialize-thing! armor)
           armor)))


;;;
;;; PUZZLE
;;; A puzzle that the player will solve to advance in the game
;;;

(define-struct (puzzle prop)
  (;; question-text: string
   ;; This is the question that the player must answer
   question-text
   ;; solution-text: string
   ;; This is the solution to the puzzle/question
   solution-text
   ;; prize: unknown
   prize
   )
  #:methods
  ;; question: get the question-text
  (define (question puzzle)
    (puzzle-question-text puzzle))
  ;; solution: get the solution-text
  (define (solution puzzle)
    (puzzle-solution-text puzzle))
  ;; activate!: activate the puzzle
  (define (activate! puzzle)
    (begin (display-line "use the solve! function to input answer")
           (display-line (question puzzle))
           (void)))
  ;; solve!: solve the puzzle
  (define (solve! puzzle answer)
    (if (string? answer)
        (if (string=? answer
                      (solution puzzle))
            (begin (display-line "Wow! Well done!")
                   (move! (puzzle-prize puzzle) me)
                   (display-line "Your prize has been added to your inventory!")
                   )
            (display-line "Sorry! That was incorrect. Maybe try inputting the correct answer?")
            )
        (display-line "Sorry, you'll need to enter an answer in the form of a string")
        )
    ))

;; new-puzzle: creates new puzzles
(define (new-puzzle description examine-text location question solution prize)
  (local [(define words (string->words description))
          (define noun (last words))
          (define adjectives (drop-right words 1))
          (define puzzle (make-puzzle adjectives '() location noun examine-text question solution prize))]
    (begin (initialize-thing! puzzle)
           puzzle)))




;;;
;;; LOCKED DOOR
;;; A door that joins together two rooms, but its initial state is locked.
;;;

(define-struct (locked-door door)
  (key)

  #:methods
  (define (go door)
    (if (have? (locked-door-key door))
        (begin (move! me (door-destination door))
               (look))
        (print "You need the key to unlock this door!"))))

(define (join-locked-door! room1 adjectives1 room2 adjectives2 key)
  (local [(define r1->r2 (make-locked-door (string->words adjectives1)
                                           '() room1 room2 key))
          (define r2->r1 (make-locked-door (string->words adjectives2)
                                           '() room2 room1 key))]
    (begin (initialize-thing! r1->r2)
           (initialize-thing! r2->r1)
           (void))))

;;;
;;; USER COMMANDS
;;;

(define (look)
  (begin (printf "You are in ~A.~%"
                 (description (here)))
         (describe-contents (here))
         (void)))

(define-user-command (look) "Prints what you can see in the room")

(define (inventory)
  (if (empty? (my-inventory))
      (printf "You don't have anything.~%")
      (begin (printf "You have:~%")
             (for-each print-description (my-inventory)))))

(define-user-command (inventory)
  "Prints the things you are carrying with you.")

(define-user-command (examine thing)
  "Takes a closer look at the thing")

(define-user-command (take prop)
  "Moves prop to your inventory")

(define-user-command (drop prop)
  "Removes prop from your inventory and places it in the room")


(define-user-command (put prop container)
  "Moves the prop from its current location and puts it in the container.")

(define (help)
  (for-each (λ (command-info)
              (begin (display (first command-info))
                     (newline)
                     (display (second command-info))
                     (newline)
                     (newline)))
            (all-user-commands)))

(define-user-command (help)
  "Displays this help information")

(define-user-command (go door)
  "Go through the door to its destination")

(define (check condition)
  (if condition
      (display-line "Check succeeded")
      (error "Check failed!!!")))

(define-user-command (check condition)
  "Throws an exception if condition is false.")

;;food
(define-user-command (eat food person)
  "Satiates the person.")

;;checking-calories
(define-user-command (check-calories person)
  "Checks how many calories that person has. Max of 60.")




;;;
;;; ADD YOUR COMMANDS HERE!
;;;

;;;
;;; ENDGAME CHECKS
;;; Checks at the end of the day how prepared the player is
;;;

(define (weapons-person?)
  "fill me in")

(define (armour-person?)
  "fill me in")

(define (location-person?)
  "fill me in")

(define (enemies-house?)
  "fill me in")

(define (calories-person?)
  "fill me in")

(define (potions-person?)
  "fill me in")

(define (locked-house?)
  "fill me in")

(define (secured-house?)
  "fill me in")

(define (ammo-person?)
  "fill me in")

(define (success-person?)
  "fill me in")

;;;
;;; THE GAME WORLD - FILL ME IN
;;;

;; start-game: -> void
;; Recreate the player object and all the rooms and things.
(define (start-game)
  ;; Fill this in with the rooms you want
  (local [(define room-0 (new-room "front yard"))
          (define room-1 (new-room "lobby"))
          (define room-2 (new-room "living-room"))
          (define room-3 (new-room "kitchen"))
          (define room-4 (new-room "dining-room"))
          (define room-5 (new-room "piano-room"))
          (define room-6 (new-room "bathroom"))
          (define room-7 (new-room "hallway"))
          (define room-8 (new-room "master-bedroom"))
          (define room-9 (new-room "guest-room"))
          (define room-10 (new-room "storage"))
          (define room-11 (new-room "study"))
          (define room-12 (new-room "balcony"))
          (define room-13 (new-room "basement"))
          (define room-14 (new-room "chamber"))
          (define room-15 (new-room "cellar"))
          (define room-16 (new-room "backyard"))
          (define room-17 (new-room "shed"))

          ;;This will be room for prize items
          (define room-100 (new-room "limbo"))
    
          ;; Setting up keys
          (define master-bedroom-key (new-prop "master-bedroom-key"
                                               "A key to the master bedroom on the second floor."
                                               room-5))
          (define study-key (new-prop "study-key"
                                      "A key to the study on the second floor."
                                      room-13))
          (define cellar-key (new-prop "cellar-key"
                                       "A mysterious, rusty key. It looks like it hasn't been used in a while."
                                       room-17))
          (define shed-key (new-prop "shed-key"
                                     "A key to the shed outside."
                                     room-3))
          (define house-key (new-prop "house key"
                                      "A key into the lobby"
                                      room-1))]
    
    ;; Add join commands to connect your rooms with doors
    (begin (set! me (new-person "" room-1 0))
           (join-locked-door! room-0 "lobby"
                              room-1 "front yard"
                              house-key)
           (join! room-1 "living-room"
                  room-2 "lobby")
           (join! room-1 "piano-room"
                  room-5 "lobby")
           (join! room-2 "kitchen"
                  room-3 "living-room")
           (join! room-3 "dining-room"
                  room-4 "kitchen")
           (join! room-4 "piano-room"
                  room-5 "dining-room")
           (join! room-5 "bathroom"
                  room-6 "dining-room")
           (join-floors! room-1 "lobby"
                         room-7 "hallway")
           (join-locked-door! room-7 "master-bedroom"
                              room-8 "hallway"
                              master-bedroom-key)
           (join! room-7 "guest-room"
                  room-9 "hallway")
           (join! room-7 "storage"
                  room-10 "hallway")
           (join-locked-door! room-7 "study"
                              room-11 "hallway"
                              study-key)
           (join! room-7 "balcony"
                  room-12 "hallway")
           (join-floors! room-5 "piano-room"
                         room-13 "basement")
           (join! room-13 "chamber"
                  room-14 "basement")
           (join-locked-door! room-14 "cellar"
                              room-15 "chamber"
                              cellar-key)
           (join! room-3 "backyard"
                  room-16 "kitchen")
           (join-locked-door! room-16 "shed"
                              room-17 "backyard"
                              shed-key)

           ;; Add code here to add things to your rooms
           (new-furniture "statue"
                          "It's just standing there. Menancingly..."
                          room-1)
           (new-furniture "piano"
                          "A rustic, old grand piano. Wonder if it still works."
                          room-5)
           (new-furniture "window"
                          "A beautiful day outside, besides the heavy downpour and wind."
                          room-5)
           (new-prop "cup"
                     "A cup. I can't think of anything more to say about it."
                     room-4)
           
           (new-furniture "toilet"
                          "A device for transporting waste to a secret, underground facility."
                          room-6)
           (new-food "apple"
                     "A crunchy, red fruit. Healthy!"
                     room-3
                     100)
           (new-food "banana"
                     "A yellow, bedtime snack. Also healthy!"
                     room-8
                     125)
           (new-food "can of corn"
                     "Contains lots of fiber. Tons of healthy!"
                     room-4
                     250)
           (new-food "granola bar"
                     "Man's best snack. That's an objective fact."
                     room-10
                     200)
           (new-food "chocolate cake"
                     "A half-eaten cake, topped with glorious amounts of chocolate. Unhealthy, but filling!"
                     room-11
                     2000)
           

           ;;Puzzles
           (new-puzzle "red puzzle box"
                       "It looks red and confusing."
                       room-1
                       "What color is the sky?"
                       "blue"
                       (new-food "Skittles"
                                 "Taste the rainbow!"
                                 room-100
                                 100))
           
                     
           
           (check-containers!)
           (void))))

;;; end-game -> void
;;; Runs the ending sequence to check if the player will survive the night.
(define (end-game)
  (begin (display-line "Your time has run out.")
         (display-line "Now it's time to see how you have done.")
         (display-line (string-append "Did you have weapons? " (weapons-person?)))
         (display-line (string-append "Did you have armour? " (armour-person?)))
         (display-line (string-append "Where did you spend the night? " (location-person?)))
         (display-line (string-append "Were there enemies in the house? " (enemies-house?)))
         (display-line (string-append "How many calories did you have? " (calories-person?)))
         (display-line (string-append "Did you take any potions? " (potions-person?)))
         (display-line (string-append "Did you lock all the doors? " (locked-house?)))
         (display-line (string-append "Did you secure the windows and doors? " (secured-house?)))
         (display-line (string-append "How much ammunition did you have? " (ammo-person?)))
         (display-line (string-append "Did you survive the night? " (success-person?)))))


;;;
;;; PUT YOUR WALKTHROUGHS HERE
;;;

;;;
;;; UTILITIES
;;;

;; here: -> container
;; The current room the player is in
(define (here)
  (thing-location me))

;; stuff-here: -> (listof thing)
;; All the stuff in the room the player is in
(define (stuff-here)
  (container-accessible-contents (here)))

;; stuff-here-except-me: -> (listof thing)
;; All the stuff in the room the player is in except the player.
(define (stuff-here-except-me)
  (remove me (stuff-here)))

;; my-inventory: -> (listof thing)
;; List of things in the player's pockets.
(define (my-inventory)
  (container-accessible-contents me))

;; accessible-objects -> (listof thing)
;; All the objects that should be searched by find and the.
(define (accessible-objects)
  (append (stuff-here-except-me)
          (my-inventory)))

;; have?: thing -> boolean
;; True if the thing is in the player's pocket.
(define (have? thing)
  (eq? (thing-location thing)
       me))

;; have-a?: predicate -> boolean
;; True if the player has something satisfying predicate in their pocket.
(define (have-a? predicate)
  (ormap predicate
         (container-accessible-contents me)))

;; find-the: (listof string) -> object
;; Returns the object from (accessible-objects)
;; whose name contains the specified words.
(define (find-the words)
  (find (λ (o)
          (andmap (λ (name) (is-a? o name))
                  words))
        (accessible-objects)))

;; find-within: container (listof string) -> object
;; Like find-the, but searches the contents of the container
;; whose name contains the specified words.
(define (find-within container words)
  (find (λ (o)
          (andmap (λ (name) (is-a? o name))
                  words))
        (container-accessible-contents container)))

;; find: (object->boolean) (listof thing) -> object
;; Search list for an object matching predicate.
(define (find predicate? list)
  (local [(define matches
            (filter predicate? list))]
    (case (length matches)
      [(0) (error "There's nothing like that here!")]
      [(1) (first matches)]
      [else (error "Which one?")])))

;; everything: -> (listof container)
;; Returns all the objects reachable from the player in the game
;; world.  So if you create an object that's in a room the player
;; has no door to, it won't appear in this list.
(define (everything)
  (local [(define all-containers '())
          ; Add container, and then recursively add its contents
          ; and location and/or destination, as appropriate.
          (define (walk container)
            ; Ignore the container if its already in our list
            (unless (member container all-containers)
              (begin (set! all-containers
                           (cons container all-containers))
                     ; Add its contents
                     (for-each walk (container-contents container))
                     ; If it's a door, include its destination
                     (when (door? container)
                       (walk (door-destination container)))
                     ; If  it's a thing, include its location.
                     (when (thing? container)
                       (walk (thing-location container))))))]
    ; Start the recursion with the player
    (begin (walk me)
           all-containers)))

;; print-everything: -> void
;; Prints all the objects in the game.
(define (print-everything)
  (begin (display-line "All objects in the game:")
         (for-each print-description (everything))))

;; every: (container -> boolean) -> (listof container)
;; A list of all the objects from (everything) that satisfy
;; the predicate.
(define (every predicate?)
  (filter predicate? (everything)))

;; print-every: (container -> boolean) -> void
;; Prints all the objects satisfying predicate.
(define (print-every predicate?)
  (for-each print-description (every predicate?)))

;; check-containers: -> void
;; Throw an exception if there is an thing whose location and
;; container disagree with one another.
(define (check-containers!)
  (for-each (λ (container)
              (for-each (λ (thing)
                          (unless (eq? (thing-location thing)
                                       container)
                            (error (description container)
                                   " has "
                                   (description thing)
                                   " in its contents list but "
                                   (description thing)
                                   " has a different location.")))
                        (container-contents container)))
            (everything)))

;; is-a?: object word -> boolean
;; True if word appears in the description of the object
;; or is the name of one of its types
(define (is-a? obj word)
  (let* ((str (if (symbol? word)
                  (symbol->string word)
                  word))
         (probe (name->type-predicate str)))
    (if (eq? probe #f)
        (member str (description-word-list obj))
        (probe obj))))

;; display-line: object -> void
;; EFFECT: prints object using display, and then starts a new line.
(define (display-line what)
  (begin (display what)
         (newline)
         (void)))

;; words->string: (listof string) -> string
;; Converts a list of one-word strings into a single string,
;; e.g. '("a" "red" "door") -> "a red door"
(define (words->string word-list)
  (string-append (first word-list)
                 (apply string-append
                        (map (λ (word)
                               (string-append " " word))
                             (rest word-list)))))

;; string->words: string -> (listof string)
;; Converts a string containing words to a list of the individual
;; words.  Inverse of words->string.
(define (string->words string)
  (string-split string))

;; add-a-or-an: (listof string) -> (listof string)
;; Prefixes a list of words with "a" or "an", depending
;; on whether the first word in the list begins with a
;; vowel.
(define (add-a-or-an word-list)
  (local [(define first-word (first word-list))
          (define first-char (substring first-word 0 1))
          (define starts-with-vowel? (string-contains? first-char "aeiou"))]
    (cons (if starts-with-vowel?
              "an"
              "a")
          word-list)))

;;
;; The following calls are filling in blanks in the other files.
;; This is needed because this file is in a different langauge than
;; the others.
;;
(set-find-the! find-the)
(set-find-within! find-within)
(set-restart-game! (λ () (start-game)))
(define (game-print object)
  (cond [(void? object)
         (void)]
        [(object? object)
         (print-description object)]
        [else (write object)]))

(current-print game-print)
   
;;;
;;; Start it up
;;;

(start-game)
(begin (display-line "You have arrived at a house, and you have one objective: Survive.")
       (display-line "The zombie apocalypse plunged the world into darkness for a long time now,")
       (display-line "But you had no idea because you bunkered in your house since the virus in 2020.")
       (display-line "All you know is that a wave of zombies is coming by this house in 24 hours,")
       (display-line "And during that time, you'll have to do everything you can to protect yourself.")
       (display-line "You open the door, and enter..."))
(look)


