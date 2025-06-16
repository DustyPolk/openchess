local config = require("config")

local chess_rules = {}

function chess_rules.isPathClear(pieces, fromRow, fromCol, toRow, toCol)
    local rowStep = toRow > fromRow and 1 or (toRow < fromRow and -1 or 0)
    local colStep = toCol > fromCol and 1 or (toCol < fromCol and -1 or 0)
    
    local currentRow = fromRow + rowStep
    local currentCol = fromCol + colStep
    
    while currentRow ~= toRow or currentCol ~= toCol do
        if currentRow < 1 or currentRow > config.BOARD_SIZE or 
           currentCol < 1 or currentCol > config.BOARD_SIZE then
            return false
        end
        if pieces[currentRow][currentCol] then
            return false
        end
        currentRow = currentRow + rowStep
        currentCol = currentCol + colStep
    end
    
    return true
end

function chess_rules.isValidMove(pieces, piece, newRow, newCol)
    if newRow < 1 or newRow > config.BOARD_SIZE or newCol < 1 or newCol > config.BOARD_SIZE then
        return false
    end
    
    local targetPiece = pieces[newRow][newCol]
    if targetPiece and targetPiece.color == piece.color then
        return false
    end
    
    local rowDiff = newRow - piece.row
    local colDiff = newCol - piece.col
    
    if piece.type == "pawn" then
        local direction = piece.color == "white" and -1 or 1
        local startRow = piece.color == "white" and 7 or 2
        
        if colDiff == 0 and not targetPiece then
            if rowDiff == direction then
                return true
            elseif piece.row == startRow and rowDiff == 2 * direction then
                local checkRow = piece.row + direction
                if checkRow >= 1 and checkRow <= config.BOARD_SIZE and not pieces[checkRow][piece.col] then
                    return true
                end
            end
        elseif math.abs(colDiff) == 1 and rowDiff == direction then -- Diagonal move
            if targetPiece and targetPiece.color ~= piece.color then -- Normal capture
                return true
            elseif not targetPiece then -- Potential en passant
                if _G.lastMove and _G.lastMove.isTwoSquarePawnAdvance and
                   _G.lastMove.piece.type == "pawn" and _G.lastMove.piece.color ~= piece.color and
                   _G.lastMove.toRow == piece.row and _G.lastMove.toCol == newCol then
                    -- The opponent's pawn (_G.lastMove.piece) landed adjacent (piece.row, newCol)
                    -- And the current pawn is attacking the square it skipped over
                    if newRow == piece.row + direction then
                        return { en_passant = true, captured_pawn_pos = {row = _G.lastMove.toRow, col = _G.lastMove.toCol} }
                    end
                end
            end
        end
    elseif piece.type == "rook" then
        if rowDiff == 0 or colDiff == 0 then
            return chess_rules.isPathClear(pieces, piece.row, piece.col, newRow, newCol)
        end
    elseif piece.type == "knight" then
        return (math.abs(rowDiff) == 2 and math.abs(colDiff) == 1) or
               (math.abs(rowDiff) == 1 and math.abs(colDiff) == 2)
    elseif piece.type == "bishop" then
        if math.abs(rowDiff) == math.abs(colDiff) then
            return chess_rules.isPathClear(pieces, piece.row, piece.col, newRow, newCol)
        end
    elseif piece.type == "queen" then
        if rowDiff == 0 or colDiff == 0 or math.abs(rowDiff) == math.abs(colDiff) then
            return chess_rules.isPathClear(pieces, piece.row, piece.col, newRow, newCol)
        end
    elseif piece.type == "king" then
        -- Normal King Move
        if math.abs(rowDiff) <= 1 and math.abs(colDiff) <= 1 then
            return true
        end

        -- Castling Logic
        if rowDiff == 0 and math.abs(colDiff) == 2 and not piece.has_moved then
            if chess_rules.isKingInCheck(pieces, piece.color) then
                return false -- Cannot castle while in check
            end

            local kingside = colDiff > 0
            local rook_col = kingside and config.BOARD_SIZE or 1
            local rook = pieces[piece.row][rook_col]

            if not rook or rook.type ~= "rook" or rook.color ~= piece.color or rook.has_moved then
                return false -- Rook missing, wrong type, wrong color, or has moved
            end

            local opponent_color = piece.color == "white" and "black" or "white"

            -- Check path clear and squares not under attack
            if kingside then -- Kingside castling (O-O) King to G, Rook to F
                -- Path for king: E to G (F, G must be clear). Rook path: H to F (G, F must be clear)
                -- Squares king passes/lands on: F, G (cols piece.col+1, piece.col+2)
                if pieces[piece.row][piece.col + 1] or pieces[piece.row][piece.col + 2] then
                    return false -- Path not clear between king and king's destination
                end
                -- Check squares king passes through/lands on for attack
                if chess_rules.isSquareUnderAttack(pieces, piece.row, piece.col + 1, opponent_color) or
                   chess_rules.isSquareUnderAttack(pieces, piece.row, piece.col + 2, opponent_color) then
                    return false
                end
                -- Also ensure rook's path from its original position to its destination is clear
                -- (only piece.col+1 needs to be clear for the rook if king moves to piece.col+2)
                -- This is implicitly covered by pieces[piece.row][piece.col + 1] == nil for king's path.

                return { castling_details = {
                    kingside = true,
                    rook_original_col = rook_col,
                    rook_target_col = piece.col + 1 -- Rook moves to F (col 6 if king on E=5)
                }}
            else -- Queenside castling (O-O-O) King to C, Rook to D
                -- Path for king: E to C (D, C must be clear). Rook path: A to D (B, C, D must be clear)
                -- Squares king passes/lands on: D, C (cols piece.col-1, piece.col-2)
                if pieces[piece.row][piece.col - 1] or pieces[piece.row][piece.col - 2] or (config.BOARD_SIZE == 8 and pieces[piece.row][piece.col - 3]) then -- piece.col-3 is B file, only if rook needs to pass it
                    return false -- Path not clear
                end
                 -- Check squares king passes through/lands on for attack
                if chess_rules.isSquareUnderAttack(pieces, piece.row, piece.col - 1, opponent_color) or
                   chess_rules.isSquareUnderAttack(pieces, piece.row, piece.col - 2, opponent_color) then
                    return false
                end
                -- Rook path from A to D (cols 1 to 4 if king on E=5, king moves to C=3)
                -- Squares B, C, D (cols piece.col-3, piece.col-2, piece.col-1) must be clear for rook
                -- This check: pieces[piece.row][piece.col - 1], pieces[piece.row][piece.col - 2] already done.
                -- pieces[piece.row][piece.col - 3] (B file) also needs to be clear for rook to pass.
                -- The condition above (config.BOARD_SIZE == 8 and pieces[piece.row][piece.col - 3]) handles the B file check.
                -- If board size is not 8, this specific piece.col-3 might be out of bounds or not relevant.
                -- For a standard 8x8 board, queen-side castling has king on e1, rook on a1. King moves to c1, rook to d1.
                -- Path for king: d1, c1. Path for rook: b1, c1, d1.
                -- Squares to be empty: b1, c1, d1 (cols 2,3,4 if king at 5) or (king.col-3, king.col-2, king.col-1)
                -- The check `(config.BOARD_SIZE == 8 and pieces[piece.row][piece.col - 3])` is correct for the B file for queenside.

                return { castling_details = {
                    kingside = false,
                    rook_original_col = rook_col,
                    rook_target_col = piece.col - 1 -- Rook moves to D (col 4 if king on E=5)
                }}
            end
        end
    end
    
    return false
end

function chess_rules.findKing(pieces, color)
    for row = 1, config.BOARD_SIZE do
        for col = 1, config.BOARD_SIZE do
            local piece = pieces[row][col]
            if piece and piece.type == "king" and piece.color == color then
                return piece
            end
        end
    end
    return nil
end

function chess_rules.isSquareUnderAttack(pieces, targetRow, targetCol, byColor)
    for row = 1, config.BOARD_SIZE do
        for col = 1, config.BOARD_SIZE do
            local piece = pieces[row][col]
            if piece and piece.color == byColor then
                if piece.type == "pawn" then
                    local direction = piece.color == "white" and -1 or 1
                    -- Check left diagonal attack
                    if targetRow == piece.row + direction and targetCol == piece.col - 1 then
                        return true -- Square is attacked by this pawn
                    end
                    -- Check right diagonal attack
                    if targetRow == piece.row + direction and targetCol == piece.col + 1 then
                        return true -- Square is attacked by this pawn
                    end
                else -- For other pieces, use the existing isValidMove logic
                    local tempPiece = {
                        type = piece.type,
                        color = piece.color,
                        row = row,
                        col = col
                    }
                    if chess_rules.isValidMove(pieces, tempPiece, targetRow, targetCol) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function chess_rules.isKingInCheck(pieces, color)
    local king = chess_rules.findKing(pieces, color)
    if not king then return false end
    
    local enemyColor = color == "white" and "black" or "white"
    return chess_rules.isSquareUnderAttack(pieces, king.row, king.col, enemyColor)
end

function chess_rules.wouldMoveLeaveKingInCheck(pieces, piece, newRow, newCol, move_details)
    if not piece then return true end
    
    local originalRow = piece.row
    local originalCol = piece.col
    local originalKingHasMoved = piece.has_moved -- Save king's has_moved state
    local capturedPiece = pieces[newRow][newCol]
    
    local temp_en_passant_captured_pawn = nil
    local en_passant_capture_pos = nil
    local temp_castling_rook = nil
    local originalRookPos = nil
    local originalRookHasMoved = nil
    local castling_rook_new_col = nil

    -- Simulate move
    pieces[originalRow][originalCol] = nil
    pieces[newRow][newCol] = piece
    piece.row = newRow
    piece.col = newCol
    piece.has_moved = true -- Simulate king has moved

    if move_details then
        if move_details.en_passant_details then
            en_passant_capture_pos = move_details.en_passant_details.captured_pawn_pos
            if pieces[en_passant_capture_pos.row] then
                 temp_en_passant_captured_pawn = pieces[en_passant_capture_pos.row][en_passant_capture_pos.col]
                 pieces[en_passant_capture_pos.row][en_passant_capture_pos.col] = nil
            end
        elseif move_details.castling_details then
            local cd = move_details.castling_details
            originalRookPos = {row = originalRow, col = cd.rook_original_col}
            temp_castling_rook = pieces[originalRookPos.row][originalRookPos.col]
            if temp_castling_rook then -- Rook should exist
                originalRookHasMoved = temp_castling_rook.has_moved
                castling_rook_new_col = cd.rook_target_col

                pieces[originalRookPos.row][originalRookPos.col] = nil
                pieces[originalRookPos.row][castling_rook_new_col] = temp_castling_rook
                temp_castling_rook.col = castling_rook_new_col
                temp_castling_rook.has_moved = true
            end
        end
    end
    
    local inCheck = chess_rules.isKingInCheck(pieces, piece.color)
    
    -- Undo the move
    pieces[originalRow][originalCol] = piece
    pieces[newRow][newCol] = capturedPiece
    piece.row = originalRow
    piece.col = originalCol
    piece.has_moved = originalKingHasMoved -- Restore king's has_moved state

    if en_passant_capture_pos and pieces[en_passant_capture_pos.row] then
        pieces[en_passant_capture_pos.row][en_passant_capture_pos.col] = temp_en_passant_captured_pawn
    end
    if temp_castling_rook and originalRookPos then -- Undo castling rook move
        pieces[originalRookPos.row][originalRookPos.col] = temp_castling_rook
        if pieces[originalRookPos.row][castling_rook_new_col] == temp_castling_rook then -- if rook is still there
             pieces[originalRookPos.row][castling_rook_new_col] = nil
        end
        temp_castling_rook.col = originalRookPos.col
        temp_castling_rook.has_moved = originalRookHasMoved
    end
    
    return inCheck
end

function chess_rules.getValidMoves(pieces, piece)
    local validMoves = {}
    if not piece then return validMoves end

    for r = 1, config.BOARD_SIZE do
        for c = 1, config.BOARD_SIZE do
            local move_validation_result = chess_rules.isValidMove(pieces, piece, r, c)
            local current_move_details = {}

            if type(move_validation_result) == "table" then
                if move_validation_result.en_passant then
                    current_move_details.en_passant_details = move_validation_result
                elseif move_validation_result.castling_details then
                    current_move_details.castling_details = move_validation_result
                else
                    -- Should not happen if table is only for special moves
                    goto next_iteration
                end
            elseif move_validation_result ~= true then
                -- isValidMove returned false
                goto next_iteration
            end
            -- At this point, move_validation_result was true or a table with details

            if not chess_rules.wouldMoveLeaveKingInCheck(pieces, piece, r, c, current_move_details) then
                local move_entry = { row = r, col = c }
                if current_move_details.en_passant_details then
                    move_entry.en_passant_details = current_move_details.en_passant_details
                    move_entry.capture = true
                elseif current_move_details.castling_details then
                    move_entry.castling_details = current_move_details.castling_details
                    move_entry.capture = false -- Castling is not a capture
                else
                    -- Normal move
                    move_entry.capture = (pieces[r][c] ~= nil and pieces[r][c].color ~= piece.color)
                end
                table.insert(validMoves, move_entry)
            end
            ::next_iteration::
        end
    end
    return validMoves
end

function chess_rules.isCheckmate(pieces, color)
    if not chess_rules.isKingInCheck(pieces, color) then
        return false -- Not in check, so not checkmate
    end

    -- Iterate through all pieces of the given color
    for row_iter = 1, config.BOARD_SIZE do
        for col_iter = 1, config.BOARD_SIZE do
            local current_piece = pieces[row_iter][col_iter]
            if current_piece and current_piece.color == color then
                -- Get all valid moves for this piece
                local validMoves = chess_rules.getValidMoves(pieces, current_piece)
                if #validMoves > 0 then
                    -- Found a piece that can make a legal move
                    return false -- Not checkmate
                end
            end
        end
    end

    -- No piece can make a legal move to get out of check
    return true -- Checkmate
end

function chess_rules.isStalemate(pieces, color)
    if chess_rules.isKingInCheck(pieces, color) then
        return false -- King is in check, so it's either checkmate or game continues
    end

    -- Iterate through all pieces of the given color
    for row_iter = 1, config.BOARD_SIZE do
        for col_iter = 1, config.BOARD_SIZE do
            local current_piece = pieces[row_iter][col_iter]
            if current_piece and current_piece.color == color then
                -- Get all valid moves for this piece
                local validMoves = chess_rules.getValidMoves(pieces, current_piece)
                if #validMoves > 0 then
                    -- Found a piece that can make a legal move
                    return false -- Not stalemate
                end
            end
        end
    end

    -- No piece can make a legal move, and king is not in check
    return true -- Stalemate
end

return chess_rules