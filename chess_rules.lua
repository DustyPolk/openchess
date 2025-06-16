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
        elseif math.abs(colDiff) == 1 and rowDiff == direction and targetPiece then
            return true
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
        return math.abs(rowDiff) <= 1 and math.abs(colDiff) <= 1
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
    return false
end

function chess_rules.isKingInCheck(pieces, color)
    local king = chess_rules.findKing(pieces, color)
    if not king then return false end
    
    local enemyColor = color == "white" and "black" or "white"
    return chess_rules.isSquareUnderAttack(pieces, king.row, king.col, enemyColor)
end

function chess_rules.wouldMoveLeaveKingInCheck(pieces, piece, newRow, newCol)
    if not piece then return true end
    
    local originalRow = piece.row
    local originalCol = piece.col
    local capturedPiece = pieces[newRow][newCol]
    
    pieces[originalRow][originalCol] = nil
    pieces[newRow][newCol] = piece
    piece.row = newRow
    piece.col = newCol
    
    local inCheck = chess_rules.isKingInCheck(pieces, piece.color)
    
    pieces[originalRow][originalCol] = piece
    pieces[newRow][newCol] = capturedPiece
    piece.row = originalRow
    piece.col = originalCol
    
    return inCheck
end

function chess_rules.getValidMoves(pieces, piece)
    local validMoves = {}
    
    if not piece then return validMoves end
    
    for row = 1, config.BOARD_SIZE do
        for col = 1, config.BOARD_SIZE do
            if chess_rules.isValidMove(pieces, piece, row, col) and 
               not chess_rules.wouldMoveLeaveKingInCheck(pieces, piece, row, col) then
                table.insert(validMoves, {row = row, col = col, capture = pieces[row][col] ~= nil})
            end
        end
    end
    
    return validMoves
end

return chess_rules