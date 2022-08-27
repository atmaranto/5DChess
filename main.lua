--[[

MIT License

Copyright (c) 2022 Anthony Maranto

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

--]]

-- ai = require("ai")

function loadfont(size)
	if fontcache == nil then
		fontcache = {}
	end
	
	if fontcache[size] == nil then
		fontcache[size] = love.graphics.newFont("comic.ttf", size)
	end
	love.graphics.setFont(fontcache[size])
	fontsize = size
	
	return fontcache[size]
end

function getFilePathFor(color, piece)
	return "Pieces/" .. color:sub(1, 1):upper() .. color:sub(2) .. "/" .. piece:sub(1, 1):upper() .. piece:sub(2) .. ".png"
end

factory_metatable = {}
factory_metatable.__index = function(tbl, key)
	if key == "_tbl" then return rawget(tbl, "_tbl") end
	
	local item = rawget(tbl, "_tbl")[key]
	
	if type(item) == "function" then
		return item()
	end
	
	return item
end
factory_metatable.__newindex = function(tbl, key, value)
	if tbl._tbl == nil then
		rawset(tbl, "_tbl", {})
	end
	
	tbl._tbl[key] = value
end

blackColor = "black"
whiteColor = "white"

kingPiece = "king"
queenPiece = "queen"
bishopPiece = "bishop"
knightPiece = "knight"
rookPiece = "rook"
pawnPiece = "pawn"

pieces = {}

for _, color in ipairs({blackColor, whiteColor}) do
	pieces[color] = {}
	setmetatable(pieces[color], factory_metatable)
	
	for _, piece in ipairs({kingPiece, queenPiece, bishopPiece, knightPiece, rookPiece, pawnPiece}) do
		local p = function()
			return {color=color, type=piece, _history={}, moved=false}
		end
		
		table.insert(pieces, p())
		pieces[color][piece] = p
	end
end

blackExpands = -1 --Black expands the MV upwards
whiteExpands = 1  --White expands the MV downwards

multiversalExpansionByColor = {black=blackExpands, white=whiteExpands}

function printTable(item, recursive, tabs)
	if tabs == nil then
		tabs = 0
	end
	
	if type(item) ~= "table" or (not recursive and tabs > 0) then
		print(item)
	else
		print(item)
		for k,v in pairs(item) do
			for i=1,tabs do
				io.write("\t")
			end
			
			io.write(tostring(k) .. "\t" .. "=" .. "\t")
			printTable(v, recursive, tabs + 1)
			io.write("\n")
			io.write("\n")
		end
	end
end

positionEmpty = "empty"

function getPositionSafe(universe, timestep, row, column)
	universe = multiverse[universe]
	
	if universe == nil then return nil end
	
	timestep = universe[timestep]
	
	if timestep == nil then return nil end
	
	if row > timestep.rows or row < 1 or column > timestep.columns or column < 1 then return nil end
	
	local piece = timestep[row][column]
	
	if piece == nil then return positionEmpty end
	
	return piece
end

function checkAndAdd(positions, piece, universe, timestep, row, column, failOnEnemy)
	local other = getPositionSafe(universe, timestep, row, column)
	
	if other ~= nil then
		if other == positionEmpty or (other.color ~= piece.color and failOnEnemy ~= true) then
			table.insert(positions, {universe=universe,timestep=timestep,row=row,column=column})
			if other == positionEmpty then return true end
		end
	end
	
	return false
end

function projectDirections(positions, directions, piece, universe, timestep, row, column)
	for _, direction in ipairs(directions) do
		local u, t, r, c = universe, timestep, row, column
		
		repeat
			u, t, r, c = u + direction[1], t + direction[2], r + direction[3], c + direction[4]
		until not checkAndAdd(positions, piece, u, t, r, c)
	end
end

rookDirections = {{-1, 0, 0, 0}, {1, 0, 0, 0}, {0, -1, 0, 0}, {0, 1, 0, 0}, {0, 0, -1, 0}, {0, 0, 1, 0}, {0, 0, 0, -1}, {0, 0, 0, 1}}
function projectRookPositions(positions, piece, universe, timestep, row, column)
	projectDirections(positions, rookDirections, piece, universe, timestep, row, column)
end

bishopDirections = {}
for i=-1,1,2 do
	for j=-1,1,2 do
		table.insert(bishopDirections, {i, j, 0, 0})
		table.insert(bishopDirections, {i, 0, j, 0})
		table.insert(bishopDirections, {i, 0, 0, j})
		table.insert(bishopDirections, {0, i, j, 0})
		table.insert(bishopDirections, {0, i, 0, j})
		table.insert(bishopDirections, {0, 0, i, j})
	end
end

function projectBishopPositions(positions, piece, universe, timestep, row, column)
	projectDirections(positions, bishopDirections, piece, universe, timestep, row, column)
end

knightPositions = {}

for a=1,-1,2 do
	for b=-2,2,4 do
		for _,pair in ipairs({{a, b}, {b, a}}) do
			local i, j = pair[1], pair[2]
			
			table.insert(bishopDirections, {i, j, 0, 0})
			table.insert(bishopDirections, {i, 0, j, 0})
			table.insert(bishopDirections, {i, 0, 0, j})
			table.insert(bishopDirections, {0, i, j, 0})
			table.insert(bishopDirections, {0, i, 0, j})
			table.insert(bishopDirections, {0, 0, i, j})
		end
	end
end

function projectKnightPositions(positions, piece, universe, timestep, row, column)
	for _, position in ipairs(knightPositions) do
		checkAndAdd(positions, piece, universe + position[1], timestep + position[2], row + position[3], column + position[4])
	end
end

function projectPositions(universe, timestep, row, column)
	local positions = {}
	
	local piece = multiverse[universe][timestep][row][column]
	
	if piece == nil then return positions end
	
	if piece.type == "king" then
		for a=-1,1 do
			for b = -1,1 do
				for c=-1,1 do
					for d = -1,1 do
						checkAndAdd(positions, piece, universe + a, timestep + b, row + c, column + d)
					end
				end
			end
		end
	elseif piece.type == "queen" then
		for a=-1,1 do
			for b = -1,1 do
				for c=-1,1 do
					for d = -1,1 do
						if a ~= 0 or b ~= 0 or c ~= 0 or d ~= 0 then
							local u, t, r, c2 = universe, timestep, row, column
							
							repeat
								u, t, r, c2 = u + a, t + b, r + c, c2 + d
							until not checkAndAdd(positions, piece, u, t, r, c2)
						end
					end
				end
			end
		end
	elseif piece.type == "bishop" then
		projectBishopPositions(positions, piece, universe, timestep, row, column)
	elseif piece.type == "knight" then
		projectKnightPositions(positions, piece, universe, timestep, row, column)
	elseif piece.type == "rook" then
		projectRookPositions(positions, piece, universe, timestep, row, column)
	elseif piece.type == "pawn" then
		if checkAndAdd(positions, piece, universe, timestep, row + -multiversalExpansionByColor[piece.color], column, true) and not piece.moved then
			checkAndAdd(positions, piece, universe, timestep, row + -multiversalExpansionByColor[piece.color] * 2, column, true)
		end
		
		if checkAndAdd(positions, piece, universe + -multiversalExpansionByColor[piece.color], timestep, row, column, true) and not piece.moved then
			checkAndAdd(positions, piece, universe + -multiversalExpansionByColor[piece.color] * 2, timestep, row, column, true)
		end
		
		local check
		
		for c=-1,1,2 do
			check = getPositionSafe(universe, timestep, row + -multiversalExpansionByColor[piece.color], column + c)
			
			if check ~= nil and check ~= positionEmpty then
				checkAndAdd(positions, piece, universe, timestep, row + -multiversalExpansionByColor[piece.color], column + c)
			end
		end
		
		for t=-1,1,2 do
			check = getPositionSafe(universe + -multiversalExpansionByColor[piece.color], timestep + t, row, column)
			
			if check ~= nil and check ~= positionEmpty then
				checkAndAdd(positions, piece, universe + -multiversalExpansionByColor[piece.color], timestep + t, row, column)
			end
		end
	end
	
	return positions
end

function isCheckMate(universe)
	
end

function createNewUniverse()
	local universe = {}
	local timeStep = {
		{pieces.black.rook, pieces.black.knight, pieces.black.bishop, pieces.black.queen, pieces.black.king, pieces.black.bishop, pieces.black.knight, pieces.black.rook},
		{pieces.black.pawn, pieces.black.pawn,   pieces.black.pawn,   pieces.black.pawn,  pieces.black.pawn, pieces.black.pawn,   pieces.black.pawn,   pieces.black.pawn},
		{nil, nil, nil, nil, nil, nil, nil, nil},
		{nil, nil, nil, nil, nil, nil, nil, nil},
		{nil, nil, nil, nil, nil, nil, nil, nil},
		{nil, nil, nil, nil, nil, nil, nil, nil},
		{pieces.white.pawn, pieces.white.pawn,   pieces.white.pawn,   pieces.white.pawn,  pieces.white.pawn, pieces.white.pawn,   pieces.white.pawn,   pieces.white.pawn},
		{pieces.white.rook, pieces.white.knight, pieces.white.bishop, pieces.white.queen, pieces.white.king, pieces.white.bishop, pieces.white.knight, pieces.white.rook},
		rows=8, columns=8, universe=1, timestep=1,
		_highlight={}
	}
	
	table.insert(universe, timeStep)
	
	return universe
end

function createNewMultiverse()
	-- Axes: [Multiverse][Timestep][x][y]
	-- Note: The "fifth" of the five dimensions is the user's timescale
	local multiverse = {}
	
	multiverse[1] = createNewUniverse()
	
	-- Used to define the start and end of the multiverse, with verse=1 being the original timeline. Black expands the multiverse upwards and white expands it downwards.
	multiverse.first = 1
	multiverse.last = 1
	
	multiverse._view = {x=1, y=1, zoom=1}
	
	return multiverse
end


function love.load()
	math.randomseed(os.time())
	
	loadfont(30)
	
	if math.tointeger == nil then
		function math.tointeger(n)
			if n < 0 then return math.ceil(n) end
			return math.floor(n)
		end
	end
	
	love.window.width, love.window.height = love.graphics.getDimensions()
	
	multiverse = createNewMultiverse()
	
	love.keyboard.setKeyRepeat(true)
	
	step = 400
	
	boardWidth = 200
	boardHeight = 200
	
	boardPaddingX = 20
	boardPaddingY = 20
	
	spaceX = math.tointeger(boardWidth / 8)
	spaceY = math.tointeger(boardHeight / 8)
	
	pieceImages = {}
	
	for _,color in ipairs({blackColor, whiteColor}) do
		pieceImages[color] = {}
		
		for _,piece in ipairs({kingPiece, queenPiece, bishopPiece, knightPiece, rookPiece, pawnPiece}) do
			pieceImages[color][piece] = love.graphics.newImage(getFilePathFor(color, piece))
		end
	end
	
	basePieceX, basePieceY = pieceImages[blackColor][kingPiece]:getDimensions()
	pieceScaleX = spaceX / basePieceX
	pieceScaleY = spaceY / basePieceY
	
	keysPressed = {}
	
	-- Contains turn information
	local turn = {color="black", thePresent=1}
	
	uiState = {hoveringOver=nil,selected=nil,drag=nil,turn=turn}
	settings = {jumpToNewBoard=true}
	
	historyArrows = {}
	
	needsUpdate = true
	
	jumpToBoard(1, 1)
end

function love.update(dt)
	if keysPressed.space then
		
	end
	if keysPressed.w then
		multiverse._view.y = multiverse._view.y + step * dt
	end
	if keysPressed.s then
		multiverse._view.y = multiverse._view.y - step * dt
	end
	if keysPressed.a then
		multiverse._view.x = multiverse._view.x + step * dt
	end
	if keysPressed.d then
		multiverse._view.x = multiverse._view.x - step * dt
	end
end

function love.resize(w, h)
	love.window.width = w
	love.window.height = h
end

function love.keypressed(key, sc, isrepeat)
	needsUpdate = true
	
	keysPressed[key] = true
end

function love.keyreleased(key, sc, isrepeat)
	needsUpdate = true
	
	keysPressed[key] = false
end

function jumpToBoard(universe, timestep)
	multiverse._view.x = (-(boardWidth + boardPaddingX) * (timestep - 0.5))  + math.floor(love.window.width / 2) / multiverse._view.zoom
	multiverse._view.y = (-(boardHeight + boardPaddingY) * (universe - 0.5)) + math.floor(love.window.height / 2) / multiverse._view.zoom
end

function getScaledPosition(x, y)
	return (x / multiverse._view.zoom - multiverse._view.x), (y / multiverse._view.zoom - multiverse._view.y) 
end

function getRegularPosition(x, y)
	return (x + multiverse._view.x) * multiverse._view.zoom, (y + multiverse._view.y) * multiverse._view.zoom
end

function getContainingBoard(x, y)
	-- A utility function that gets the board that contains the pixel coordinates (x, y). Returns nil if there is none.
	
	local scaledX, scaledY = getScaledPosition(x, y)
	
	local boardX = math.floor(scaledX / (boardWidth + boardPaddingX)) + 1
	local boardY = math.floor(scaledY / (boardHeight + boardPaddingY)) + 1
	
	if boardY < multiverse.first or boardY > multiverse.last then
		return nil
	end
	
	local offsetY = scaledY - (boardHeight + boardPaddingY) * (boardY - 1)
	local offsetX = scaledX - (boardWidth + boardPaddingX)  * (boardX - 1)
	
	if offsetY >= boardHeight or offsetX >= boardWidth then
		return nil
	end
	
	local timeline = multiverse[boardY]
	
	if boardX < 1 or boardX > table.maxn(timeline) then
		return nil
	end
	
	local board = timeline[boardX]
	
	local cellX = math.floor((offsetX / boardWidth) * board.columns) + 1
	local cellY = math.floor((offsetY / boardHeight) * board.rows)   + 1
	
	return {timeline=timeline, board=board, universe=boardY, timestep=boardX, column=cellX, row=cellY}
end

function love.mousepressed(x, y, button, istouch, presses)
	uiState.drag = {startx=x, starty=y, x=x, y=y, moved=false}
end

function deepCopy(value)
	if type(value) == "table" then
		local copy = {}
		
		for key, value in pairs(value) do
			if type(key) == "string" and key:sub(1, 1) == "_" and type(value) == "table" then
				copy[key] = {}
			else
				copy[key] = deepCopy(value)
			end
		end
		
		return copy
	end
	
	return value
end

function copyBoard(board)
	local newBoard = {}
	
	for key, value in pairs(board) do
		if type(key) == "string" and key:sub(1, 1) == "_" and type(value) == "table" then
			-- Initialize to blank
			newBoard[key] = {}
		elseif type(key) ~= "number" then
			newBoard[key] = value
		else
			newBoard[key] = deepCopy(value)
		end
	end
	
	return newBoard
end

function insertUniverse(causedByColor, timeline, board, newBoard)
	local i = 1
	local newUniverse = {}
	
	while i <= table.maxn(timeline) do
		table.insert(newUniverse, copyBoard(timeline[i]))
		if timeline[i] == board then
			break
		end
		
		i = i + 1
	end
	
	table.insert(newUniverse, newBoard)
	
	local freeIndex = 1
	while multiverse[freeIndex] do
		freeIndex = freeIndex + multiversalExpansionByColor[causedByColor]
	end
	
	multiverse[freeIndex] = newUniverse
	
	for i, b in ipairs(newUniverse) do
		b.universe = freeIndex
		b.timestep = i
	end
	
	if freeIndex < 1 then
		multiverse.first = freeIndex
	else
		multiverse.last = freeIndex
	end
	
	return newUniverse
end

function addArrow(historyItem)
	if historyItem.from.universe ~= historyItem.finalTo.universe or historyItem.from.timestep ~= historyItem.finalTo.timestep - 1 then
		table.insert(historyArrows, historyItem)
	end
end

function movePiece(a, b)
	local newBoard = copyBoard(a.board)
	local piece = newBoard[a.row][a.column]
	
	local historyItem = {what=piece, from=a, to=b, finalTo=newBoard}
	
	table.insert(piece._history, historyItem)
	
	piece.moved = true
	
	newBoard[a.row][a.column] = nil
	
	local timeline = multiverse[a.universe]
	
	if a.board ~= b.board then
		-- Multiversal move
		table.insert(timeline, newBoard)
		newBoard.timestep = table.maxn(timeline)
		
		newBoard = copyBoard(b.board)
		
		timeline = multiverse[b.universe]
		
		historyItem.finalTo = newBoard
	else
		table.insert(newBoard._highlight, {row=a.row, column=a.column, color={0.9, 0.3, 0.2}})
		table.insert(newBoard._highlight, {row=b.row, column=b.column, color={0.9, 0.9, 0.2}})
	end
	
	newBoard[b.row][b.column] = piece
	
	if timeline[table.maxn(timeline)] ~= b.board then
		-- We have to create a new universe
		insertUniverse(piece.color, timeline, b.board, newBoard)
	else
		table.insert(timeline, newBoard)
		newBoard.timestep = table.maxn(timeline)
	end
	
	if settings.jumpToNewBoard then
		jumpToBoard(newBoard.universe, newBoard.timestep)
	end
	
	addArrow(historyItem)
	
	return newBoard
	
	--[[if a.board == b.board then
		--Classical move
		
		
	else
		--Multiversal move
		
		
	end]]--
end

function canMovePiece(info)
	-- Checks if a piece can be moved in the current turn
	local piece = info.board[info.row][info.column]
	if piece == nil then return false end
	
	return (info.timestep >= uiState.turn.thePresent and info.timestep == table.maxn(multiverse[info.universe])) and piece.color == uiState.turn.color
	--For now, I'm going to flat prevent moving into the past from a future not in thePresent
	--return (info.timestep >= uiState.turn.thePresent and info.timestep == table.maxn(multiverse[info.universe])) and piece.color == uiState.turn.color
end

function getValidMoves()
	-- Excludes moves in the future, since those are optional
	local validMoves = {}
	
	for universe=multiverse.first,multiverse.last do
		if table.maxn(multiverse[universe]) == uiState.turn.thePresent then
			table.insert(validMoves, multiverse[universe][uiState.turn.thePresent])
		end
	end
	
	return validMoves
end

otherColor = {black="white",white="black"}

function love.mousereleased(x, y, button, istouch, presses)
	if button == 2 and (uiState.drag == nil or not uiState.drag.moved) then
		uiState.selected = nil
	else
		if not uiState.drag.moved then
			local info = getContainingBoard(x, y)
			
			if info ~= nil then
				local nilOrDoesntContain = true
				
				if uiState.selected ~= nil and uiState.selected.canMovePiece then
					for _, position in ipairs(uiState.selected.positions) do
						if position.universe == info.universe and position.timestep == info.timestep and position.column == info.column and position.row == info.row then
							nilOrDoesntContain = false
						end
					end
				end
				
				if nilOrDoesntContain then
					uiState.selected = info
					uiState.selected.positions = projectPositions(info.universe, info.timestep, info.row, info.column)
					
					uiState.selected.canMovePiece = canMovePiece(info)
				elseif uiState.selected.canMovePiece then
					local nValidMoves = table.maxn(getValidMoves()) --Track the number of valid moves *beforehand*
					local targetBoard = movePiece(uiState.selected, info)
					
					if nValidMoves - 1 <= 0 or targetBoard.timestep ~= uiState.turn.thePresent then
						uiState.turn.thePresent = targetBoard.timestep
						uiState.turn.color = otherColor[uiState.turn.color]
					end
					
					uiState.selected = nil
				end
			end
		end
	end
	
	uiState.drag = nil
end

function love.mousemoved(x, y, dx, dy, istouch)
	if uiState.drag ~= nil then
		uiState.drag.x = x
		uiState.drag.y = y
		uiState.drag.moved = true
		
		multiverse._view.x = multiverse._view.x + dx / multiverse._view.zoom * 0.8
		multiverse._view.y = multiverse._view.y + dy / multiverse._view.zoom * 0.8
	end
	
	local info = getContainingBoard(x, y)
	
	uiState.hoveringOver = info
end

function love.wheelmoved(x, y)
	if y ~= 0 then
		needsUpdate = true
	end
	
	if y > 0 then
		multiverse._view.zoom = multiverse._view.zoom / 0.95
	elseif y < 0 then
		multiverse._view.zoom = multiverse._view.zoom * 0.95
	end
end

function clear()
	love.graphics.clear(1.0, 1.0, 1.0)
end

function HSV(h, s, v)
	-- Taken from https://love2d.org/wiki/HSV_color
	
	if s <= 0 then return v, v, v end
	
	h = h * 6
	
	local c = v * s
	local x = (1 - math.abs((h % 2) - 1)) * c
	local m, r, g, b = (v - c), 0, 0, 0
	
	if h < 1 then
		r, g, b = c, x, 0
	elseif h < 2 then
		r, g, b = x, c, 0
	elseif h < 3 then
		r, g, b = 0, c, x
	elseif h < 4 then
		r, g, b = 0, x, c
	elseif h < 5 then
		r, g, b = x, 0, c
	else
		r, g, b = c, 0, x
	end
	
	return (r + m), (g + m), (b + m)
end

rainbowDuration = 7

function rainbow(t)
	return HSV((t - math.floor(t / rainbowDuration) * rainbowDuration) / rainbowDuration, 1.0, 1.0)
end

function rainbowNow()
	return rainbow(love.timer.getTime())
end

function drawBoard(board)
	love.graphics.setLineWidth(2)
	
	love.graphics.setColor(0, 0, 0)
	love.graphics.rectangle("line", -1, -1, boardWidth+1, boardHeight+1)
	
	love.graphics.setColor(0.8, 0.8, 0.8)
	love.graphics.rectangle("fill", 0, 0, boardWidth, boardHeight)
	
	love.graphics.setLineWidth(1)
	love.graphics.setColor(0, 0, 0)
	
	for i=2,8 do
		love.graphics.line((i - 1) * spaceX, 0, (i - 1) * spaceX, boardHeight)
		love.graphics.line(0, (i - 1) * spaceY, boardWidth, (i - 1) * spaceY)
	end
	
	love.graphics.setColor(1, 1, 1)
	
	for i=1,board.columns do		
		for j=1,board.rows do
			local piece = board[i][j]
			
			if piece ~= nil then
				love.graphics.draw(pieceImages[piece.color][piece.type], (j - 1) * spaceX, (i - 1) * spaceY, 0, pieceScaleX, pieceScaleY)
			end
		end
	end
	
	for _, highlight in ipairs(board._highlight) do
		love.graphics.setColor(highlight.color[1], highlight.color[2], highlight.color[3])
		love.graphics.rectangle("line", (highlight.column - 1) * spaceX, (highlight.row - 1) * spaceY, spaceX, spaceY)
	end
end

function drawUI()
	local primaryColor, secondaryColor
	if uiState.turn.color == "black" then
		primaryColor = {0.1, 0.1, 0.1}
		secondaryColor = {0.9, 0.9, 0.9}
	else
		primaryColor = {0.9, 0.9, 0.9}
		secondaryColor = {0.1, 0.1, 0.1}
	end
	
	local _, yStart = getScaledPosition(0, 0)
	local _, yEnd   = getScaledPosition(0, love.window.height)
	
	local xPos = (boardWidth + boardPaddingX) * (uiState.turn.thePresent - 1) - boardPaddingX + 5
	
	local bannerWidth = boardWidth + boardPaddingX * 2 - 10
	
	love.graphics.setColor(primaryColor)
	love.graphics.rectangle("fill", xPos, yStart, bannerWidth, yEnd - yStart)
	
	love.graphics.setColor(secondaryColor)
	love.graphics.rectangle("line", xPos, yStart, bannerWidth, yEnd - yStart)
	
	-- TODO: Put text on it
	
	local font = loadfont(30)
	local text = uiState.turn.color:sub(1, 1):upper() .. uiState.turn.color:sub(2) .. "'s turn"
	
	local textX  = xPos + math.tointeger((bannerWidth - font:getWidth(text)) / 2)
	local textY1 = (boardHeight + boardPaddingY) * (multiverse.first - 1) - boardPaddingY - font:getAscent()
	local textY2 = (boardHeight + boardPaddingY) * multiverse.last
	
	loadfont(30)
	love.graphics.print(text, textX, textY1)
	love.graphics.print(text, textX, textY2)
end

function drawMultiverse()
	love.graphics.push()
		love.graphics.scale(multiverse._view.zoom, multiverse._view.zoom)
		love.graphics.translate(multiverse._view.x, multiverse._view.y)
		
		drawUI()
		
		for universeY=multiverse.first,multiverse.last do
			local universe = multiverse[universeY]
			
			for timestepX,timestep in ipairs(universe) do
				love.graphics.push()
					love.graphics.translate((boardWidth + boardPaddingX) * (timestepX - 1), (boardHeight + boardPaddingY) * (universeY - 1))
					drawBoard(timestep)
				love.graphics.pop()
			end
		end
		
		love.graphics.setLineWidth(2)
		if uiState.selected ~= nil then
			if uiState.selected.canMovePiece then
				love.graphics.setColor(0.2, 1.0, 0.2)
			else
				love.graphics.setColor(0.95, 0.65, 0.25)
			end
			
			for _,position in ipairs(uiState.selected.positions) do
				love.graphics.push()
					love.graphics.translate((boardWidth + boardPaddingX) * (position.timestep - 1), (boardHeight + boardPaddingY) * (position.universe - 1))
					love.graphics.rectangle("line", (position.column - 1) * spaceX, (position.row - 1) * spaceY, spaceX, spaceY)
				love.graphics.pop()
			end
		end
		
		if uiState.hoveringOver ~= nil then
			love.graphics.push()
				love.graphics.translate((boardWidth + boardPaddingX) * (uiState.hoveringOver.timestep - 1), (boardHeight + boardPaddingY) * (uiState.hoveringOver.universe - 1))
				
				love.graphics.setColor(0.2, 0.2, 1.0)
				love.graphics.rectangle("line", (uiState.hoveringOver.column - 1) * spaceX, (uiState.hoveringOver.row - 1) * spaceY, spaceX, spaceY)
			love.graphics.pop()
		end
		
		if uiState.selected ~= nil then
			love.graphics.push()
				love.graphics.translate((boardWidth + boardPaddingX) * (uiState.selected.timestep - 1), (boardHeight + boardPaddingY) * (uiState.selected.universe - 1))
				
				--love.graphics.setColor(rainbowNow())
				--love.graphics.rectangle("line", (uiState.selected.column - 1) * spaceX, (uiState.selected.row - 1) * spaceY, spaceX, spaceY)
				
				if uiState.selected.canMovePiece then
					local t = love.timer.getTime()
					
					love.graphics.setColor(rainbow(t))
					love.graphics.line((uiState.selected.column - 1) * spaceX, (uiState.selected.row - 1) * spaceY, (uiState.selected.column - 1 + 1) * spaceX, (uiState.selected.row - 1) * spaceY)
					
					love.graphics.setColor(rainbow(t + 1.25))
					love.graphics.line((uiState.selected.column - 1 + 1) * spaceX, (uiState.selected.row - 1) * spaceY, (uiState.selected.column - 1 + 1) * spaceX, (uiState.selected.row - 1 + 1) * spaceY)
					
					love.graphics.setColor(rainbow(t + 2.5))
					love.graphics.line((uiState.selected.column - 1 + 1) * spaceX, (uiState.selected.row - 1 + 1) * spaceY, (uiState.selected.column - 1) * spaceX, (uiState.selected.row - 1 + 1) * spaceY)
					
					love.graphics.setColor(rainbow(t + 3.75))
					love.graphics.line((uiState.selected.column - 1) * spaceX, (uiState.selected.row - 1 + 1) * spaceY, (uiState.selected.column - 1) * spaceX, (uiState.selected.row - 1) * spaceY)
				else
					love.graphics.setColor(0.9, 0.4, 0.2)
					love.graphics.rectangle("line", (uiState.selected.column - 1) * spaceX, (uiState.selected.row - 1) * spaceY, spaceX, spaceY)
				end
			love.graphics.pop()
		end
		
		for _, historyItem in ipairs(historyArrows) do
			local board1X, board1Y = (boardWidth + boardPaddingX) * (historyItem.from.timestep - 1) + (historyItem.from.column - 0.5) * spaceX, (boardHeight + boardPaddingY) * (historyItem.from.universe - 1) + (historyItem.from.row - 0.5) * spaceY
			local board2X, board2Y = (boardWidth + boardPaddingX) * (historyItem.finalTo.timestep - 1) + (historyItem.to.column - 0.5) * spaceX, (boardHeight + boardPaddingY) * (historyItem.finalTo.universe - 1) + (historyItem.to.row - 0.5) * spaceX
			
			love.graphics.setColor(0, 0, 0)
			love.graphics.line(board1X, board1Y, board2X, board2Y)
		end
	love.graphics.pop()
end

function drawOverlay()
	loadfont(30)
	
	love.graphics.setColor(0.4, 0.4, 0.4)
	love.graphics.rectangle("fill", 50, 50, love.window.width - 100, 100)
	
	love.graphics.setLineWidth(3)
	love.graphics.setColor(0.2, 0.2, 0.2)
	love.graphics.rectangle("line", 50, 50, love.window.width - 100, 100)
	
	love.graphics.setLineWidth(2)
	love.graphics.setColor(hoveringOver.color[1], hoveringOver.color[2], hoveringOver.color[3])
	
	local text = ""
	
	for i, command in ipairs(hoveringOver.program) do
		text = text .. command .. " "
	end
	
	love.graphics.printf(text, 53, 53, love.window.width - 106, "center")
	
	loadfont(15)
	
	local textTable
	
	if hoveringOver.alive then
		textTable = {{0, 0, 0}, "Age "..tostring(hoveringOver.age)..", ", {0.9, 0.1, 0.1}, tostring(hoveringOver.health), {0, 0, 0}, " / ", {0.1, 0.9, 0.4}, tostring(hoveringOver.energy)}
	else
		textTable = {{0, 0, 0}, "Age "..tostring(hoveringOver.age)..", ", {0.9, 0.1, 0.1}, tostring(hoveringOver.health), {0, 0, 0}, " / ", {0.1, 0.9, 0.4}, tostring(hoveringOver.energy), {0, 0, 0}, " (DEAD)"}
	end
	
	love.graphics.printf(textTable, love.window.width - 178, 100, 175, "left")
end

function love.draw()
	love.graphics.clear(1, 1, 1)
	love.graphics.setColor(0, 0, 0)
	
	drawMultiverse()
	
	--[[
	
	drawUniverse()
	
	if hoveringOver ~= nil then
		drawOverlay()
	end
	
	loadfont(30)
	
	if paused then
		love.graphics.setColor(0.9, 0.87, 0.2)
		love.graphics.print("Paused", 0, 0)
	else
		love.graphics.setColor(0.21, 0.9, 0.3)
		love.graphics.print("Running", 0, 0)
	end
	
	local tableText
	
	if oldestCell == nil then
		tableText = {{0, 0, 0}, "Oldest cell: nil"}
	else
		tableText = {{0, 0, 0}, "Oldest cell: ", {oldestCell[3].color[1], oldestCell[3].color[2], oldestCell[3].color[3]}, tostring(oldestCell[3].age)}
		
		love.graphics.setColor(0.658, 0.651, 0.196)
		love.graphics.rectangle("line", oldestCell[1] * cellWidth - 3, oldestCell[2] * cellHeight - 3, cellWidth + 6, cellHeight + 6)
	end
	
	love.graphics.printf(tableText, 10, love.window.height - 75, love.window.width - 20, "left")
	
	--love.button.draw()
	]]
end