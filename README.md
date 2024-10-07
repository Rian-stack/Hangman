# Hangman Assembly Program (V4.2)

## Authors
- Daniel Flores
- Rianne Papa
- Ethan Vine
- Cody Witty

## Class
CIS123 Assembly Language

## File Names
- Hangman_V4.2.asm
- File_AI.txt
- File_Companies.txt
- File_Food.txt

## Creation Date
October 29, 2022

## Program Description
The Hangman program is a text-based implementation of the classic word-guessing game. Players attempt to guess a hidden word by suggesting letters within a limited number of attempts. The game can be played in two modes: **Multiplayer** and **Random Word Guessing**. In the Multiplayer mode, two players take turns guessing letters, while in the Random Word Guessing mode, the program selects a word from a predefined set of categories, such as food, companies, or assembly language terms. The program provides feedback on correct and incorrect guesses, displays the current state of the word, and informs players when they win or lose.

### Expected Inputs
- User selects a game mode (1 for Multiplayer, 2 for Random Word Guessing, 3 to Quit).
- In Multiplayer mode, each player inputs a word for the other player to guess.
- Players enter letters to guess the hidden word.
- The program prompts for the number of rounds in Multiplayer mode.

### Output Results
- The program displays the current progress of the word being guessed, showing correctly guessed letters and placeholders for remaining letters.
- It indicates the number of incorrect attempts remaining.
- Upon completion of the game, the program announces whether the player has won or lost and displays the final results for both players in Multiplayer mode.

## Features
- Multiplayer and Random Word Guessing modes.
- Custom word entries for Multiplayer.
- Selection of random words from different categories.
- Visual representation of incorrect guesses with a stick figure drawing.
- Input validation to ensure correct game flow.

## Usage
1. Assemble and link the program using an assembly language compiler that supports the Irvine32 library.
2. Run the executable file and follow the on-screen prompts to start the game.
3. Enjoy guessing the hidden words while keeping track of your attempts!

## Dependencies
- Irvine32 Library

## Acknowledgments
Special thanks to the instructors and classmates in CIS123 for their support and collaboration on this project.
