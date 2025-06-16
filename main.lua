local config = require("config")
local board = require("board")
local menu = require("menu")
local game_renderer = require("game_renderer")
local game_logic = require("game_logic")

local pieces = {}
local pieceImages = {}
local boardImage
local bgImage
local selectedPiece = nil
local currentPlayer = "white"
local gameState = "menu"
local gameStarted = false

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
end

function love.draw()
    if gameState == "menu" then
        menu.draw(bgImage, pieceImages, gameStarted)
    elseif gameState == "playing" then
        game_renderer.drawGame(boardImage, pieces, pieceImages, selectedPiece, currentPlayer)
    end
end

function love.mousepressed(x, y, button)
    if gameState == "menu" then
        local action = menu.handleClick(x, y, button)
        if action == "playing" then
            if not gameStarted or not next(pieces) then
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
        end
    elseif gameState == "playing" then
        selectedPiece, currentPlayer = game_logic.handleClick(x, y, button, pieces, selectedPiece, currentPlayer)
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
        end
    end
end