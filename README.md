# Chess Game

A pixel art chess game built with Lua and the LÖVE framework.

## Features

- Complete chess rules implementation
- Pixel art graphics with crisp rendering
- Visual move indicators showing all valid moves
- Check detection and prevention of illegal moves
- Turn-based gameplay
- Clean menu system with game state preservation
- Hover effects and intuitive controls

## Requirements

- LÖVE 11.0 or higher
- Lua 5.1+

## How to Run

```bash
love .
```

Or drag the project folder onto the LÖVE executable.

## Controls

- **Mouse**: Click to select and move pieces
- **ESC**: Return to menu (game state is preserved)

## Gameplay

1. Click on a piece to select it
2. Valid moves are shown as colored dots:
   - Green dots: Empty squares you can move to
   - Red dots: Enemy pieces you can capture
3. Click on a valid square to move
4. The game alternates between white and black players
5. When in check, the status is displayed in red

## Project Structure

```
chess_green/
├── main.lua          # Main entry point and game loop
├── config.lua        # Game configuration and constants
├── board.lua         # Board initialization
├── chess_rules.lua   # Chess rules and move validation
├── menu.lua          # Menu system and UI
├── game_renderer.lua # Game rendering functions
├── game_logic.lua    # Game state management
├── assets/           # Game assets
│   ├── board.png     # Chess board (180x180)
│   ├── bg.png        # Background image
│   └── [color]_[piece].png  # Chess pieces (13-20px sprites)
├── README.md         # This file
└── CLAUDE.md         # AI assistant documentation
```

## Chess Rules Implemented

- All standard piece movements (pawn, rook, knight, bishop, queen, king)
- Pawn double-move from starting position
- Piece capture mechanics
- Check detection
- Prevention of moves that leave king in check
- Path validation for sliding pieces

## Known Limitations

- No castling
- No en passant
- No pawn promotion
- No checkmate detection (game continues after king capture prevention)
- No stalemate detection
- No move history or undo
- No AI opponent

## Assets

The game uses pixel art assets for:
- Chess pieces in black and white variants
- Chess board with alternating squares
- Background texture
- All graphics use nearest-neighbor filtering for crisp pixel art