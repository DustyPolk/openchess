local config = require("config")
local chess_rules = require("chess_rules")

local game_renderer = {}

function game_renderer.drawBoard(boardImage)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(boardImage, config.BOARD_OFFSET_X, config.BOARD_OFFSET_Y, 0, config.BOARD_SCALE, config.BOARD_SCALE)
end

function game_renderer.drawPieces(pieces, pieceImages)
    for row = 1, config.BOARD_SIZE do
        for col = 1, config.BOARD_SIZE do
            local piece = pieces[row][col]
            if piece then
                local x = config.BOARD_OFFSET_X + (col - 1) * config.TILE_SIZE
                local y = config.BOARD_OFFSET_Y + (row - 1) * config.TILE_SIZE
                local pieceWidth = config.pieceSizes[piece.color][piece.type][1]
                local pieceHeight = config.pieceSizes[piece.color][piece.type][2]
                local pieceOffsetX = (config.TILE_SIZE - pieceWidth * config.BOARD_SCALE) / 2
                local pieceOffsetY = (config.TILE_SIZE - pieceHeight * config.BOARD_SCALE) / 2
                love.graphics.draw(pieceImages[piece.color][piece.type], x + pieceOffsetX, y + pieceOffsetY, 0, config.BOARD_SCALE, config.BOARD_SCALE)
            end
        end
    end
end

function game_renderer.drawSelectedPiece(selectedPiece, pieces)
    if selectedPiece and selectedPiece.row and selectedPiece.col then
        love.graphics.setColor(0, 1, 0, 0.5)
        local x = config.BOARD_OFFSET_X + (selectedPiece.col - 1) * config.TILE_SIZE
        local y = config.BOARD_OFFSET_Y + (selectedPiece.row - 1) * config.TILE_SIZE
        love.graphics.rectangle("fill", x, y, config.TILE_SIZE, config.TILE_SIZE)
        
        local validMoves = chess_rules.getValidMoves(pieces, selectedPiece)
        for _, move in ipairs(validMoves) do
            local moveX = config.BOARD_OFFSET_X + (move.col - 1) * config.TILE_SIZE + config.TILE_SIZE / 2
            local moveY = config.BOARD_OFFSET_Y + (move.row - 1) * config.TILE_SIZE + config.TILE_SIZE / 2
            
            if move.capture then
                love.graphics.setColor(1, 0, 0, 0.7)
            else
                love.graphics.setColor(0, 1, 0, 0.7)
            end
            
            love.graphics.circle("fill", moveX, moveY, config.TILE_SIZE / 4)
        end
    end
end

function game_renderer.drawGameStatus(currentPlayer, pieces)
    if chess_rules.isKingInCheck(pieces, currentPlayer) then
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("Current player: " .. currentPlayer .. " (CHECK!)", 10, 10)
    else
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Current player: " .. currentPlayer, 10, 10)
    end
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Press ESC for menu", 10, 30)
end

function game_renderer.drawGame(boardImage, pieces, pieceImages, selectedPiece, currentPlayer)
    game_renderer.drawBoard(boardImage)
    game_renderer.drawPieces(pieces, pieceImages)
    game_renderer.drawSelectedPiece(selectedPiece, pieces)
    game_renderer.drawGameStatus(currentPlayer, pieces)
end

return game_renderer