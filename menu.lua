local menu = {}

local menuButtons = {}
local hoveredButton = nil

function menu.updateButtons(gameStarted)
    menuButtons = {}
    
    local startY = 280
    
    if gameStarted then
        table.insert(menuButtons, {
            text = "CONTINUE",
            x = 345,
            y = startY,
            width = 200,
            height = 60,
            action = function()
                return "playing"
            end
        })
        startY = startY + 80
    end
    
    table.insert(menuButtons, {
        text = "NEW GAME",
        x = 345,
        y = startY,
        width = 200,
        height = 60,
        action = function()
            if gameStarted then
                if love.window.showMessageBox("New Game", "Start a new game? Current progress will be lost.", {"Yes", "No"}) == 1 then
                    return "new_game"
                end
            else
                return "new_game"
            end
            return nil
        end
    })
    
    table.insert(menuButtons, {
        text = "QUIT",
        x = 345,
        y = startY + 80,
        width = 200,
        height = 60,
        action = function()
            love.event.quit()
        end
    })
    
    for _, button in ipairs(menuButtons) do
        button.x = button.x - button.width / 2
    end
end

function menu.draw(bgImage, pieceImages, gameStarted)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(bgImage, 0, 0, 0, 4.3125, 4.3125)
    
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, 690, 690)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(60))
    love.graphics.print("CHESS", 345 - love.graphics.getFont():getWidth("CHESS") / 2, 100)
    
    love.graphics.setFont(love.graphics.newFont(20))
    
    local decorY = 180
    love.graphics.draw(pieceImages.white.king, 200, decorY, 0, 3, 3)
    love.graphics.draw(pieceImages.white.queen, 250, decorY, 0, 3, 3)
    love.graphics.draw(pieceImages.black.queen, 410, decorY, 0, 3, 3)
    love.graphics.draw(pieceImages.black.king, 460, decorY, 0, 3, 3)
    
    if gameStarted then
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.print("Game in progress", 345 - love.graphics.getFont():getWidth("Game in progress") / 2, 240)
        love.graphics.setFont(love.graphics.newFont(20))
    end
    
    for _, button in ipairs(menuButtons) do
        if button == hoveredButton then
            love.graphics.setColor(0.3, 0.7, 0.3)
        else
            love.graphics.setColor(0.2, 0.5, 0.2)
        end
        love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)
        
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", button.x, button.y, button.width, button.height)
        
        love.graphics.setColor(1, 1, 1)
        local textWidth = love.graphics.getFont():getWidth(button.text)
        local textHeight = love.graphics.getFont():getHeight()
        love.graphics.print(button.text, button.x + button.width / 2 - textWidth / 2, button.y + button.height / 2 - textHeight / 2)
    end
end

function menu.handleClick(x, y, button)
    if button == 1 then
        for _, btn in ipairs(menuButtons) do
            if x >= btn.x and x <= btn.x + btn.width and y >= btn.y and y <= btn.y + btn.height then
                return btn.action()
            end
        end
    end
    return nil
end

function menu.updateHover(x, y)
    hoveredButton = nil
    for _, button in ipairs(menuButtons) do
        if x >= button.x and x <= button.x + button.width and y >= button.y and y <= button.y + button.height then
            hoveredButton = button
        end
    end
end

return menu