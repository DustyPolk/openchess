local config = require("config")
local chess_rules = require("chess_rules")

local game_logic = {}


function game_logic.updateLastMove(moved_piece, from_row, from_col, is_two_square_adv)
    if moved_piece then
        _G.lastMove = {
            piece = moved_piece, -- Reference to the piece object
            fromRow = from_row,
            fromCol = from_col,
            toRow = moved_piece.row, -- Updated row
            toCol = moved_piece.col, -- Updated col
            isTwoSquarePawnAdvance = is_two_square_adv
        }
    else
        _G.lastMove = nil
    end
end

function game_logic.handleClick(x, y, button, pieces, selectedPiece, currentPlayer)
    if button == 1 then
        local col = math.floor((x - config.BOARD_OFFSET_X) / config.TILE_SIZE) + 1
        local row = math.floor((y - config.BOARD_OFFSET_Y) / config.TILE_SIZE) + 1
        
        if col >= 1 and col <= config.BOARD_SIZE and row >= 1 and row <= config.BOARD_SIZE then
            if selectedPiece then
                local validMoves = chess_rules.getValidMoves(pieces, selectedPiece)
                local chosen_move_details = nil
                for _, move in ipairs(validMoves) do
                    if move.row == row and move.col == col then
                        chosen_move_details = move
                        break
                    end
                end

                if chosen_move_details then
                    local fromRow, fromCol = selectedPiece.row, selectedPiece.col
                    local pieceTypeBeforeMove = selectedPiece.type

                    game_logic.movePiece(pieces, selectedPiece, row, col, chosen_move_details)

                    local isTwoSquareAdvance = (pieceTypeBeforeMove == "pawn" and math.abs(row - fromRow) == 2)
                    game_logic.updateLastMove(selectedPiece, fromRow, fromCol, isTwoSquareAdvance)

                    if selectedPiece.promotion_pending then
                        return nil, currentPlayer, selectedPiece
                    else
                        local nextPlayer = currentPlayer == "white" and "black" or "white"
                        return nil, nextPlayer, nil
                    end
                else
                    -- Clicked on a square that is not a valid move for the selected piece
                    -- Deselect if clicked on empty or opponent's piece, otherwise keep selection
                    if not pieces[row][col] or pieces[row][col].color ~= currentPlayer then
                        game_logic.updateLastMove(nil) -- Clear last move as no move was made
                        return nil, currentPlayer, nil
                    elseif pieces[row][col] and pieces[row][col].color == currentPlayer then
                         -- Clicked on another of own pieces, select that one instead
                        game_logic.updateLastMove(nil) -- Clear last move
                        return pieces[row][col], currentPlayer, nil
                    end
                    return selectedPiece, currentPlayer, nil -- Should not be reached often
                end
            else -- No piece was selected, try to select one
                local piece_at_click = pieces[row][col]
                if piece_at_click and piece_at_click.color == currentPlayer then
                    game_logic.updateLastMove(nil) -- Clear last move as no move was made yet
                    return piece_at_click, currentPlayer, nil
                end
            end
        else -- Clicked outside board
            game_logic.updateLastMove(nil) -- Clear last move
            return nil, currentPlayer, nil
        end
    end
    -- No action for other buttons or if conditions not met, maintain current selection
    -- and don't clear lastMove if it was from a previous successful turn.
    return selectedPiece, currentPlayer, nil
end

function game_logic.movePiece(pieces, piece, newRow, newCol, move_details)
    if not piece then return end
    
    local originalRow, originalCol = piece.row, piece.col -- Capture original position

    pieces[originalRow][originalCol] = nil
    pieces[newRow][newCol] = piece
    piece.row = newRow
    piece.col = newCol
    piece.has_moved = true -- Set has_moved flag for the piece that moved

    -- En Passant capture: Remove the captured pawn
    if move_details and move_details.en_passant_details then
        local ep_pos = move_details.en_passant_details.captured_pawn_pos
        if pieces[ep_pos.row] and pieces[ep_pos.row][ep_pos.col] then
            pieces[ep_pos.row][ep_pos.col] = nil
        end
    -- Castling: Move the rook
    elseif move_details and move_details.castling_details then
        local cd = move_details.castling_details
        local rook = pieces[newRow][cd.rook_original_col] -- King's row (newRow) is rook's row
        if rook then -- Rook should definitely exist here if validation passed
            pieces[newRow][cd.rook_original_col] = nil
            pieces[newRow][cd.rook_target_col] = rook
            rook.col = cd.rook_target_col
            rook.has_moved = true
        end
    end

    -- Pawn Promotion Logic
    piece.promotion_pending = false -- Default
    if piece.type == "pawn" then
        if (piece.color == "white" and newRow == 1) or
           (piece.color == "black" and newRow == config.BOARD_SIZE) then
            piece.promotion_pending = true
        end
    end
end

return game_logic