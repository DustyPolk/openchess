local config = {}

config.BOARD_SIZE = 8
config.BOARD_SCALE = 3
config.TILE_SIZE = 22.5 * config.BOARD_SCALE
config.BOARD_OFFSET_X = 75
config.BOARD_OFFSET_Y = 75
config.PIECE_SCALE = 1.2 * config.BOARD_SCALE

config.pieceTypes = {"pawn", "rook", "knight", "bishop", "queen", "king"}
config.colors = {"white", "black"}

config.pieceSizes = {
    white = {
        pawn = {13, 16},
        rook = {14, 18},
        knight = {16, 18},
        bishop = {18, 19},
        queen = {18, 18},
        king = {20, 20}
    },
    black = {
        pawn = {13, 16},
        rook = {14, 18},
        knight = {16, 18},
        bishop = {18, 19},
        queen = {16, 18},
        king = {20, 20}
    }
}

return config