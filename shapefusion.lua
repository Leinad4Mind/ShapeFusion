-- By Youka
--

script_name = "Shape fusion"
script_description = "Combines lines with shapes."
script_author = "Youka"
script_version = "1.0"
script_modified = "3rd December 2010"

function prepare_lines(subs, sel)
	--Basic data
	local shape_lines = {}
	local pos_x, pos_y
	local off_i = 0
	--Get shape lines
	for ii, i in ipairs(sel) do
		local line = subs[i - off_i]
		--Get position
		local _, _, pos_xx, pos_yy = line.text:find("\\pos%((%s*%-?[%d%.]+%s*),(%s*%-?[%d%.]+%s*)%)")
		--Test valid lines
		pos_xx = tonumber(pos_xx, 10)
		pos_yy = tonumber(pos_yy, 10)
		if pos_xx and pos_yy and line.text:find("{(.-)}m %-?%d+ %-?%d+ ") then
			local shape_line = {}
			--First line (text without \p0 save, position save)
			if ii==1 then
				pos_x = pos_xx
				pos_y = pos_yy
				line.text = line.text:gsub("\\p0", "")
				shape_line.off_x = 0
				shape_line.off_y = 0
				shape_line.text = line.text
				table.insert(shape_lines, shape_line)
			--Lines to append (text without \p and \pos tag save, position offset save, delete old line)
			elseif pos_x and pos_y then
				subs.delete(i - off_i)
				off_i = off_i + 1
				line.text = line.text:gsub("\\p%d+", "")
				line.text = line.text:gsub("\\pos%((%s*%-?[%d%.]+%s*),(%s*%-?[%d%.]+%s*)%)", "")
				shape_line.off_x = pos_xx - pos_x
				shape_line.off_y = pos_yy - pos_y
				shape_line.text = line.text
				table.insert(shape_lines, shape_line)
			end
		end
	end
	--Get maximal height, single width and height of shapes
	local max_height = 0
	for shape_i, shape_line in ipairs(shape_lines) do
		local _, _, shape = shape_line.text:find("}([mlbsc%-%d%s]+)")
		local neg_width, pos_width = 0, 0
		local neg_height, pos_height = 0, 0
		local function x_y_get(x,y)
			pos_width = math.max(pos_width, x)
			neg_width = math.min(neg_width, x)
			pos_height = math.max(pos_height, y)
			neg_height = math.min(neg_height, y)
		end
		shape:gsub("(%-?%d+) (%-?%d+)", x_y_get)
		shape_line.width = -neg_width + pos_width
		shape_line.height = -neg_height + pos_height
		max_height = math.max(max_height, shape_line.height)
	end
	return shape_lines, max_height
end

--Process
function shape_combine(subs, sel)
	local shape_lines, max_height = prepare_lines(subs, sel)
	--Fix shape coordinates
	local cur_x = 0
	for shape_i, shape_line in ipairs(shape_lines) do
		local _, _, shape = shape_line.text:find("}([mlbsc%-%d%s]+)")
		local function x_y_fix(x,y)
			local x_fix = x - cur_x + shape_line.off_x
			local y_fix = y - (max_height - shape_line.height) + shape_line.off_y
			return x_fix.." "..y_fix
		end
		shape = shape:gsub("(%-?%d+) (%-?%d+)", x_y_fix)
		shape_line.text = shape_line.text:gsub("}([mlbsc%-%d%s]+)", "}"..shape)
		cur_x = cur_x + shape_line.width
	end
	--Append shapes to first shape line
	if #shape_lines < 2 then
		aegisub.debug.out(1, "Nothing done!")
	else
		local line = subs[sel[1]]
		line.text = ""
		for shape_i, shape_line in ipairs(shape_lines) do
			line.text = line.text .. shape_line.text
		end
		subs[sel[1]] = line
		aegisub.set_undo_point("\""..script_name.."\"")
	end
end

--Register macro in aegisub
aegisub.register_macro(script_name,script_description,shape_combine)
