# FPCS111
Final Project for CS111

The goal of this game is to navigate the mysterious mansion you find yourself in and figure out a way to escape it. To do this, you'll have move through the different rooms,
solve some puzzles, and fight some bad guys in order to unravel the secrets of the mansion and find a way out.

Here's how to play:

The most basic command is (look). This tells you the room you're currently in, along with the contents of the room.

If you want to go to a different room, simply type (go (the room)) and you will move there. For example, if you wanted to go to the kitchen, you would type (go (the kitchen)).
Upon entering the room, you'll see which room you're now in and all of its contents.

The same concept applies to stairs. Type (go (the stairs)) to move through a certain room's stairs.

To interact with the items around you, you'll have to take a closer look at each of them. Type (examine (the item)) to learn more about the item you're interested in.

If the item looks like something you could use later, make sure to pick it up! Type (take (the item)) to place it in your inventory so you can use it later. Type (inventory) to
check all the items you're currently hoarding.

If you happened to pick up some food, simply type (eat (the food)). Each food item has it's own caloric count, and you can check how many calories you've consumed by typing 
(check-calories). Make sure to not eat too much!

In the starting room, you'll also see enemies. Oh no! You'll have to fight them to get out of the mansion safely. But first, you need to make sure you're armed. If you have any
weapons in your inventory, type (equip (the weapon)) to get ready for combat. You can also type (stats (the weapon)) to check how strong your weapon is.

While preparing for combat, you can also check your own stats by typing (check-health) and (check-defense) to see what your current health and defense is.

Now it's time to fight! Type (attack (the enemy)) to attack a chosen enemy with yout equipped weapon. Damage will be calculated automatically based on the stats of the weapon
and the enemy, so you don't need to worry. Keep attacking till you've won! Any goodies enemy leaves behind after dying will automatically get added into yout inventory.

You've successfully defeated your first enemy. But wait! You've lost some health! You need to find a potion. Once you've found one, type (drink (the potion)) to consume it and
replenish some of your missing health. Remember, enemies will never engage with you unless you attack them, so feel free to stop attacking and go find some potions to refill 
your health before going back in.

Not all potions give health! Some benefit other aspects of your character, so make sure to try every potion. It's probably safe...

As you continue traversing the mansion, you'll find some locked doors. You'll need the appropriate key to walk through those doors. Take as many keys as you can find.

Eventually, you'll run into some strange mysterious items with "prompts". These are puzzles! Type (activate (the puzzle)) to turn on the puzzle and see what riddle it has in
store for you.

After reading the prompt, you'll need to solve it. Type (solve (the puzzle) "answer") to solve it. Your answer must be in the form of a string, so don't forget those quotation
marks. After solving it, you'll get a prize! Yayyyyy! Check your inventory by typing (inventory) to see what you got.

That's all the knowledge you need to fully navigate the mansion. Remember, your goal is to escape this place so make sure you find a way outside. And most importantly, make sure
to avoid the cellar...
