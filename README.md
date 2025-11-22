# Security Office Keypad Enabler

A UE4SS mod for Abiotic Factor that enables the security office keypad in the Office Sector to function as a door/shutter toggle after being hacked.

## Description

In Abiotic Factor, the security office in the Office Sector requires hacking a keypad to gain access. Once hacked, the keypad becomes permanently disabled, and the only way to open or close the door is via a button on the inside.

This mod re-enables the keypad after hacking, allowing you to toggle the security office door from the outside. This is particularly useful when leaving your base and wanting to close the door behind you to keep intruders out.

## Requirements

- **Abiotic Factor**
- **UE4SS from https://github.com/UE4SS-RE/RE-UE4SS or https://www.nexusmods.com/abioticfactor/mods/35** installed

## Installation

1. Install UE4SS if you haven't already
2. Download this mod
3. Extract the `SecurityOfficeKeypadEnabler` folder into your Abiotic Factor install folder:
```
   [...]\AbioticFactor\AbioticFactor\Binaries\Win64\ue4ss\Mods\
```
4. Your final path should look something like:
```
   [...]\AbioticFactor\AbioticFactor\Binaries\Win64\ue4ss\Mods\SecurityOfficeKeypadEnabler\Scripts\main.lua
```
5. Launch the game

## Usage

1. Hack the security office keypad (if you haven't already)
2. Once hacked, the keypad will remain interactable
3. Use the keypad from outside to toggle the door open/closed
4. The keypad only works after it has been hacked - it won't bypass the initial hack requirement

## Multiplayer

This mod works in multiplayer and needs to be installed by the **host** and anyone else who wants to be able to open/close the shutters via keypad. If only the host as it installed and no one else, only the host will be able to open and close the shutters.