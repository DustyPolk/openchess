local config = require("config")
local chess_rules = require("chess_rules")

local game_logic = {}

function game_logic.handleClick(x, y, button, pieces, selectedPiece, currentPlayer)
    if button == 1 then
        local col = math.floor((x - config.BOARD_OFFSET_X) / config.TILE_SIZE) + 1
        local row = math.floor((y - config.BOARD_OFFSET_Y) / config.TILE_SIZE) + 1
        
        if col >= 1 and col <= config.BOARD_SIZE and row >= 1 and row <= config.BOARD_SIZE then
            if selectedPiece then
                if chess_rules.isValidMove(pieces, selectedPiece, row, col) and 
                   not chess_rules.wouldMoveLeaveKingInCheck(pieces, selectedPiece, row, col) then
                    game_logic.movePiece(pieces, selectedPiece, row, col)
                    currentPlayer = currentPlayer == "white" and "black" or "white"
                end
                selectedPiece = nil
            else
                local piece = pieces[row][col]
                if piece and piece.color == currentPlayer then
                    selectedPiece = piece
                end
            end
        end
    end
    
    return selectedPiece, currentPlayer
end

function game_logic.movePiece(pieces, piece, newRow, newCol)
    pieces[piece.row][piece.col] = nil
    pieces[newRow][newCol] = piece
    piece.row = newRow
    piece.col = newCol
end

return game_logic