local config = require("config")
local board = require("board")
local menu = require("menu")
local game_renderer = require("game_renderer")
local game_logic = require("game_logic")
local chess_rules = require("chess_rules") -- Added for isCheckmate

local pieces = {}
local pieceImages = {}
local boardImage
local bgImage
local selectedPiece = nil
local currentPlayer = "white"
local gameState = "menu"
local gameStarted = false
local gameOverMessage = "" -- Added for checkmate message
local promotionPiece = nil -- Piece pending promotion
local promotionUI = { -- UI elements for pawn promotion
    show = false,
    options = {"queen", "rook", "bishop", "knight"},
    selectedOption = nil, -- Currently hovered or selected
    optionRects = {} -- To store clickable areas for UI options
}

function love.load()
    love.window.setTitle("Chess Game")
    love.window.setMode(690, 690)
    
    love.graphics.setDefaultFilter("nearest", "nearest")
    
    boardImage = love.graphics.newImage("assets/board.png")
    bgImage = love.graphics.newImage("assets/bg.png")
    
    for _, color in ipairs(config.colors) do
        pieceImages[color] = {}
        for _, pieceType in ipairs(config.pieceTypes) do
            pieceImages[color][pieceType] = love.graphics.newImage("assets/" .. color .. "_" .. pieceType .. ".png")
        end
    end
    
    menu.updateButtons(gameStarted)
    _G.lastMove = nil -- Initialize lastMove information
end

function love.draw()
    if gameState == "menu" then
        menu.draw(bgImage, pieceImages, gameStarted)
    elseif gameState == "playing" then
        game_renderer.drawGame(boardImage, pieces, pieceImages, selectedPiece, currentPlayer)
    elseif gameState == "pawn_promotion" then
        game_renderer.drawGame(boardImage, pieces, pieceImages, nil, currentPlayer) -- Draw board, no selected piece highlighted
        -- Draw promotion UI
        local uiX = config.BOARD_WIDTH / 2 - 100
        local uiY = config.BOARD_HEIGHT / 2 - 80
        local optionHeight = 40
        local padding = 5
        love.graphics.setColor(0.2, 0.2, 0.2, 0.9) -- Dark semi-transparent background for UI
        love.graphics.rectangle("fill", uiX, uiY, 200, #promotionUI.options * (optionHeight + padding) + padding)

        promotionUI.optionRects = {} -- Clear previous rects
        for i, optionType in ipairs(promotionUI.options) do
            local rectY = uiY + (i-1) * (optionHeight + padding) + padding
            local rect = {x = uiX + padding, y = rectY, width = 200 - 2 * padding, height = optionHeight}
            table.insert(promotionUI.optionRects, rect)

            love.graphics.setColor(0.4, 0.4, 0.4)
            if promotionUI.selectedOption == optionType then -- Basic hover/selection indication
                love.graphics.setColor(0.6, 0.6, 0.6)
            end
            love.graphics.rectangle("fill", rect.x, rect.y, rect.width, rect.height)

            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(optionType, rect.x, rect.y + optionHeight / 2 - 7, rect.width, "center")
        end
    elseif gameState == "game_over" then -- Handles checkmate and stalemate
        game_renderer.drawGame(boardImage, pieces, pieceImages, selectedPiece, currentPlayer) -- Draw board
        love.graphics.setColor(0, 0, 0, 0.7) -- Semi-transparent black background for text
        love.graphics.rectangle("fill", 0, config.BOARD_HEIGHT / 2 - 30, config.BOARD_WIDTH, 60)
        love.graphics.setColor(1, 1, 1) -- White text
        love.graphics.printf(gameOverMessage, 0, config.BOARD_HEIGHT / 2 - 10, config.BOARD_WIDTH, "center")
    end
end

function love.mousepressed(x, y, button)
    if gameState == "menu" then
        local action = menu.handleClick(x, y, button)
        if action == "playing" then
            if not gameStarted or not next(pieces) then -- Resume game
                pieces = board.initialize()
                currentPlayer = "white"
                selectedPiece = nil
                gameStarted = true
            end
            gameState = "playing"
        elseif action == "new_game" then
            gameState = "playing"
            pieces = board.initialize()
            currentPlayer = "white"
            selectedPiece = nil
            gameStarted = true
            gameOverMessage = "" -- Reset game over message
        end
    elseif gameState == "playing" then
        local newSelectedPiece, newCurrentPlayer, pendingPromotionPiece = game_logic.handleClick(x, y, button, pieces, selectedPiece, currentPlayer)
        selectedPiece = newSelectedPiece

        if pendingPromotionPiece then
            gameState = "pawn_promotion"
            promotionPiece = pendingPromotionPiece
            promotionUI.show = true
            selectedPiece = nil -- Clear selection during promotion
            -- currentPlayer is NOT switched yet
        else
            -- Only switch player and check for game end if a move actually happened (selectedPiece is nil)
            -- and it's not just a re-selection or invalid click.
            -- newCurrentPlayer would be different from currentPlayer if a move was made and player switched.
            if currentPlayer ~= newCurrentPlayer or (selectedPiece == nil and newCurrentPlayer == currentPlayer) then
                 -- (selectedPiece == nil and newCurrentPlayer == currentPlayer) covers cases where a piece was deselected by clicking elsewhere
                 -- if a move was made, selectedPiece would be nil and newCurrentPlayer would be the next player.
                local moveMade = currentPlayer ~= newCurrentPlayer
                currentPlayer = newCurrentPlayer

                if moveMade then -- Only check for checkmate/stalemate if a move was actually made
                    if chess_rules.isCheckmate(pieces, currentPlayer) then
                        gameState = "game_over"
                        local winner = currentPlayer == "white" and "Black" or "White"
                        gameOverMessage = "Checkmate! " .. winner .. " wins!"
                    elseif chess_rules.isStalemate(pieces, currentPlayer) then
                        gameState = "game_over"
                        gameOverMessage = "Stalemate! The game is a draw."
                    end
                end
            end
        end
    elseif gameState == "pawn_promotion" then
        for i, rect in ipairs(promotionUI.optionRects) do
            if x >= rect.x and x <= rect.x + rect.width and y >= rect.y and y <= rect.y + rect.height then
                local chosenType = promotionUI.options[i]
                promotionPiece.type = chosenType
                if promotionPiece.promotion_pending then promotionPiece.promotion_pending = false end

                promotionUI.show = false
                gameState = "playing"

                -- NOW switch player
                currentPlayer = currentPlayer == "white" and "black" or "white"

                -- And NOW check for checkmate/stalemate for the new current player
                if chess_rules.isCheckmate(pieces, currentPlayer) then
                    gameState = "game_over"
                    local winner = currentPlayer == "white" and "Black" or "White"
                    gameOverMessage = "Checkmate! " .. winner .. " wins!"
                elseif chess_rules.isStalemate(pieces, currentPlayer) then
                    gameState = "game_over"
                    gameOverMessage = "Stalemate! The game is a draw."
                end

                promotionPiece = nil
                break
            end
        end
    elseif gameState == "game_over" then -- Handles both checkmate and stalemate
        gameState = "menu"
        gameStarted = false -- Allow starting a new game
        menu.updateButtons(gameStarted)
    end
end

function love.mousemoved(x, y)
    if gameState == "menu" then
        menu.updateHover(x, y)
    end
end

function love.keypressed(key)
    if key == "escape" then
        if gameState == "playing" then
            gameState = "menu"
            menu.updateButtons(gameStarted)
        elseif gameState == "game_over" then -- Handles checkmate and stalemate
            gameState = "menu"
            gameStarted = false -- Allow starting a new game
            menu.updateButtons(gameStarted)
        -- No specific key handling for pawn_promotion, escape will not exit it.
        -- User must choose a piece or click escape to go to menu (if that's added for playing state)
        end
    end
end
