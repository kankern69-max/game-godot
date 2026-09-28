# game-godot

A small Godot game project about designing and arranging electronic components on a PCB-like board.

This repository contains a playful prototype called `pcd desinger v1` (a PCB designer / circuit builder) built in Godot 4 using GDScript.

## About the project

The game presents a green board area with a grid, where you can place and manage electronic parts such as resistors, capacitors, diodes, transistors, LEDs, switches, and power components. It has a UI layer for selecting components and interacting with the board, and it includes a full Godot project under the `pcd-desinger-v-1/` folder.

The project is intentionally lightweight and experimental: more of a silly little game prototype than a production-ready design tool.

## Features

- PCB-style board with a visible grid and component placement area
- Component library for common electronics items
- Circuit-like gameplay focused on arranging functional pieces
- Godot-powered UI and scene-based architecture
- Fullscreen toggle with `F11`
- Included exported HTML build in `pcd-desinger-v-1/html game/`

## Repository structure

```text
.
├── README.md
├── pcd-desinger-v-1/
│   ├── project.godot
│   ├── game.tscn
│   ├── mainSystems/
│   ├── components/
│   ├── ui/
│   ├── addons/
│   ├── html game/
│   └── LICENSE
└── ...
```

## How to run

1. Install Godot 4.6 or newer.
2. Clone this repository:
   ```bash
   git clone https://github.com/kankern69-max/game-godot.git
   ```
3. Open the project folder:
   ```text
   pcd-desinger-v-1/
   ```
4. Load `project.godot` in Godot.
5. Press Play in the editor to run the game.

## Controls

- Use the in-game UI to choose tools and place components.
- Use the board to arrange items on the PCB grid.
- Press `F11` to toggle fullscreen.

## Notes

This project appears to be a creative prototype and is still evolving. The codebase contains a lot of scene data, component resources, and helper scripts, so it is best explored directly in the Godot editor.

## License

The Godot project includes a `LICENSE` file in `pcd-desinger-v-1/`. Please refer to that file for the exact terms.

## Credits

- Built with Godot Engine
- GDScript-based gameplay and UI logic
- Includes the `godot_super-wakatime` addon for development tracking
