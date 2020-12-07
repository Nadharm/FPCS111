# FPCS111
Final Project for CS111

The goal of this game is to navigate the mysterious mansion you find yourself in and figure out a way to escape it. To do this, you'll have move through the different rooms,
solve some puzzles, and fight some bad guys in order to unravel the secrets of the mansion and find a way out.

Here's how to play:

**(look)**: The most basic command is (look). This tells you the room you're currently in, along with the contents of the room.

**(go (the door))**: If you want to go to a different room, simply type (go (the door-name)) and you will move there. For example, if you wanted to go to the kitchen, you would type (go (the kitchen door)). Upon entering the room, you'll see which room you're now in and all of its contents.

The same concept applies to stairs. Type (go (the stairs)) to move through a certain room's stairs.

**(examine (the item))**: To interact with the items around you, you'll have to take a closer look at each of them. Type (examine (the item)) to learn more about the item you're interested in.

**(take (the item))**: If the item looks like something you could use later, make sure to pick it up! Type (take (the item)) to place it in your inventory so you can use it later. 

**(inventory)**: Type (inventory) to check all the items you're currently hoarding.

**(eat (the food))**: If you happened to pick up some food, simply type (eat (the food)). Each food item has it's own caloric count.

**(check-calories)**: Make sure to not eat too much!

**(equip (the weapon))**: In the starting room, you'll also see enemies. Oh no! You'll have to fight them to get out of the mansion safely. But first, you need to make sure you're armed. If you have any weapons in your inventory, type (equip (the weapon)) to get ready for combat. You need to pick up weapons before you can equip them!

**(stats (the weapon))**: You can also type (stats (the weapon)) to check how strong your weapon is (damage, speed, durability).

    SPEED MECHANIC: Attack sequences will recursively decrement a copied speed values from weapon and enemy until both have the same speed. During the decrement period, the one with the higher speed will be given free hits. Once equal, both will hit simultaneously until both values are 0.

**(check-health), (check-defense)**: While preparing for combat, you can also check your own stats by typing (check-health) and (check-defense) to see what your current health and defense is.

    DEFENSE MECHANIC: Damage Taken = (incoming damage) * (1 - defense-value)

**(check-equipped-weapon)**: Use this to see what your currently equipped weapon is.

**(attack (the enemy))**: Now it's time to fight! Type (attack (the enemy)) to attack a chosen enemy with your equipped weapon. Damage will be calculated automatically based on the stats of the weapon and the enemy, so you don't need to worry. Keep attacking till you've won! Any goodies enemy leaves behind after dying will automatically get added into yout inventory. Attacks will happen in sequences to allow you to re-evaluate the fight and decide if you want to proceed!

**(drink (the potion))**: You've successfully defeated your first enemy. But wait! You've lost some health! You need to find a potion. Once you've found one, type (drink (the potion)) to consume it and replenish some of your missing health. Remember, enemies will never engage with you unless you attack them, so feel free to stop attacking and go find some potions to refill your health before going back in. **Not all potions give health!** Some benefit other aspects of your character, so make sure to try every potion. It's probably safe...

**Locked doors**: As you continue traversing the mansion, you'll find some locked doors. You'll need the appropriate key to walk through those doors. Take as many keys as you can find.

**(activate (the puzzle))**: Eventually, you'll run into some strange mysterious items with "prompts". These are puzzles! Type (activate (the puzzle)) to turn on the puzzle and see what riddle it has in store for you.

**(solve (the puzzle) answer)**: After reading the prompt, you'll need to solve it. Type (solve (the puzzle) "answer") to solve it. Your answer must be in the form of a string, so don't forget those quotation marks. After solving it, you'll get a prize! Yayyyyy! Check your inventory by typing (inventory) to see what you got. **NOTE:** All solutions to puzzles will be in lower case. Some of the prompts can be pretty tricky!

**(douse (the fireplace))**: This is a one off function that will come in very useful!! You just need to make sure you have something to douse it with!

That's all the knowledge you need to fully navigate the mansion. Remember, your goal is to escape this place so make sure you find a way outside. 

**HERE IS A MAP TO HELP YOU**:
<img src="./manofinal-01.png">
