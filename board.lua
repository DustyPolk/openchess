local config = require("config")

local board = {}

function board.initialize()
    local layout = {
        {"rook", "knight", "bishop", "queen", "king", "bishop", "knight", "rook"},
        {"pawn", "pawn", "pawn", "pawn", "pawn", "pawn", "pawn", "pawn"},
        {nil, nil, nil, nil, nil, nil, nil, nil},
        {nil, nil, nil, nil, nil, nil, nil, nil},
        {nil, nil, nil, nil, nil, nil, nil, nil},
        {nil, nil, nil, nil, nil, nil, nil, nil},
        {"pawn", "pawn", "pawn", "pawn", "pawn", "pawn", "pawn", "pawn"},
        {"rook", "knight", "bishop", "queen", "king", "bishop", "knight", "rook"}
    }
    
    local pieces = {}
    for row = 1, config.BOARD_SIZE do
        pieces[row] = {}
        for col = 1, config.BOARD_SIZE do
            if layout[row][col] then
                local color = row <= 2 and "black" or "white"
                pieces[row][col] = {
                    type = layout[row][col],
                    color = color,
                    row = row,
                    col = col
                }
            end
        end
    end
    
    return pieces
end

return board