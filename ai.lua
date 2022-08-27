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

-- THIS IS UNIMPLEMENTED

function universeBoardToState(universe, timestep)
	local board = multiverse[universe][timestep]
	
	return deepCopy(board)
end

function insertIfValid(board, positions, piece, row, column)
	local r = board[row]
	if r == nil then return false end
	if r[column] == nil or r[column].color == piece.color then return false end
	
	table.insert(positions, {row=row, column=column})
	
	return true
end

function getNextMoves(board, piece)
	-- Returns the possible next moves for a piece on a 2D board
	-- Similar to projectPositions
	if piece == nil then return {} end
	
	local positions = {}
	if piece.type == kingPiece then
		for da=-1,1 do
			for db=-1,1 do
				if da ~= 0 or db ~= 0 then
					insertIfValid(board, positions, piece, piece.row + da, piece.column + db)
				end
			end
		end
	end
	
	if piece.type == rookPiece or piece.type == queenPiece then
		for offset in ipairs({{-1, 0}, {1, 0}, {0, 1}, {0, -1}}) do
			local a, b
			a = piece.row
			b = piece.column
			
			while insertIfValid(board, positions, piece, a, b) do
				a = a + offset[1]
				b = b + offset[2]
			end
		end
	end
	
	if piece.type == bishopPiece or piece.type == queenPiece then
		for offset in ipairs({{-1, -1}, {-1, 1}, {1, -1}, {1, 1}}) do
			local a, b
			a = piece.row
			b = piece.column
			
			while insertIfValid(board, positions, piece, a, b) do
				a = a + offset[1]
				b = b + offset[2]
			end
		end
	end
	
	if piece.type == knightPiece then
		
	end
	
	if piece.type == pawnPiece then
		
	end
	
	return positions
end

function isCheckmate(board)
	local kings = {}
	
	for i, row in ipairs(board) do
		for j, piece in ipairs(row) do
			if piece ~= nil then
				
			end
		end
	end
	
	
end

function boardHeuristic(board, color)
	
end



function getSuccessors(universe, timestep, successorFunction, color, maxDepth)
	local board = universeToBoardState(universe, timestep)
	
	maxDepth = maxDepth or 4
	
	local successors = {}
	
	for depth=1,maxDepth do
		local i, j
		i = 1
		
		while board[i] ~= nil then
			j = 1
			
			while board[i][j] ~= nil then
				if board[i][j].color == color then
					for position in ipairs(projectPositions(universe, timestep, i, j) do
						if position.universe == universe and position.timestep == timestep then
							
						end
					end
				end
				
				j = j + 1
			end
			
			i = i + 1
		end
	end
	
	return successors
end