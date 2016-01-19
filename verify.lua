require 'torch'
require 'nn'
require 'nngraph'
require 'optim'
require 'lfs'

require 'util.OneHot'
require 'util.misc'

require 'table_lib'


-- gated print: simple utility function wrapping a print
function gprint(str)
    if opt.verbose == 1 then print(str) end
end

function predicNext(model, primetext)

	checkpoint = torch.load(model)
	protos = checkpoint.protos
	protos.rnn:evaluate() -- put in eval mode so that dropout works properly

	-- initialize the vocabulary (and its inverted version)
	local vocab = checkpoint.vocab
	local ivocab = {}
	for c,i in pairs(vocab) do ivocab[i] = c end

	-- initialize the rnn state to all zeros
	local current_state
	current_state = {}
	for L = 1,checkpoint.opt.num_layers do
		-- c and h for all layers
		local h_init = torch.zeros(1, checkpoint.opt.rnn_size):double()
		table.insert(current_state, h_init:clone())
		if checkpoint.opt.model == 'lstm' then
			table.insert(current_state, h_init:clone())
		end
	end
	state_size = #current_state

	assert(string.len(primetext) > 0)
	for c in primetext:gmatch'.' do
		prev_char = torch.Tensor{vocab[c]}
		local lst = protos.rnn:forward{prev_char, unpack(current_state)}
		-- lst is a list of [state1,state2,..stateN,output]. We want everything but last piece
		current_state = {}
		for i=1,state_size do table.insert(current_state, lst[i]) end
		prediction = lst[#lst] -- last element holds the log probabilities
	end

	-- log probabilities from the previous timestep
	prediction:div(1) -- scale by temperature
	local probs = torch.exp(prediction):squeeze()
	probs:div(torch.sum(probs)) -- renormalize so probs sum to one
	prev_char = torch.multinomial(probs:float(), 1):resize(1):float()

	return probs:max(1)[1], ivocab[prev_char[1]]
end

function getSampleIdx()
	local idx = 0
	local flag = 0
	local idx_tmp 

	while(idx == 0) do
		idx_tmp = torch.random(1, #history - 50)
		for i = idx_tmp + 1, idx_tmp + opt.length do
			if history[idx_tmp][1] == 1 then
				flag = 1
				break
			end
		end
		if flag == 1 then
			idx = 0
			flag = 0
		else
			idx = idx_tmp
		end
	end
	
	return idx
end


function charToPrice(high, low, next_char)
	local t1, b1, t2, b2 
	t1 = high
	b1 = low

	if next_char == '1' then
		b2 =  0.1*(t1-b1) + t1
		t2 = t1 + 0.7 * (t1 - b1)
	elseif next_char == '2' then
		b2 = b1 + 0.7 * (t1 - b1)
		t2 = b2 + 0.7 * (t1 - b1)
	elseif next_char == '3' then
		b2 = b1 + 0.2 * (t1 - b1)
		t2 = b2 + 0.7 * (t1 - b1)
	elseif next_char == '4' then
		t2 = t1 - 0.2 * (t1 - b1)
		b2 = t2 - 0.7 * (t1 - b1)
	elseif next_char == '5' then
		t2 = t1 - 0.7 * (t1 - b1)
		b2 = t2 - 0.7 * (t1 - b1)
	elseif next_char == '6' then
		t2 = b1
		b2 = t2 - 0.7 * (t1 - b1)
	elseif next_char == '7' then
		t2 = t1
		b2 = b1
	elseif next_char == '8' then
		b2 = 0.1 * (t1 - b1) + t1
		high = t1 + 1.5 * (t1 - b1)
	elseif next_char == '9' then
		b2 = b1 + 0.8 * (t1 - b1)
		t2 = b2 + 1.5 * (t1 - b1)
	elseif next_char == '0' then
		b2 = b1 + 0.3 * (t1 - b1)
		t2 = b2 + 1.5 * (t1 - b1)
	elseif next_char == 'a' then
		t2 = t1 - 0.2 * (t1 - b1)
		b2 = t2 - 1.5 * (t1 - b1)
	elseif next_char == 'b' then
		t2 = t1 - 0.7 * (t1 - b1)
		b2 = t2 - 1.5 * (t1 - b1)
	elseif next_char == 'c' then
		t2 = b1
		b2 = t2 - 1.5 * (t1 - b1)
	elseif next_char == 'd' then
		t2 = t1 + 0.2 * (t1 - b1)
		b2 = b1 - 0.2 * (t1 - b1)
	elseif next_char == 'e' then
		b2 = 0.1 * (t1 - b1) + t1
		t2 = t1 + 2.5 * (t1 - b1)
	elseif next_char == 'f' then
		b2 = b1 + 0.9 * (t1 - b1)
		t2 = b2 + 2.5 * (t1 - b1)
	elseif next_char == 'g' then
		b2 = b1 + 0.3 * (t1 - b1)
		t2 = b2 + 2.5 * (t1 - b1)
	elseif next_char == 'h' then
		t2 = t1 - 0.3 * (t1 - b1)
		b2 = t2 - 2.5 * (t1 - b1)
	elseif next_char == 'i' then
		t2 = t1 - 0.8 * (t1 - b1)
		b2 = t2 - 2.5 * (t1 - b1)
	elseif next_char == 'j' then
		t2 = b1
		b2 = t2 - 2.5 * (t1 - b1)
	elseif next_char == 'k' then
		t2 = t1 + (t1 - b1)
		b2 = b1 - (t1 - b1)
	else 
		print('unknown char type',next_char)
	end
	
	print(t2,b2)
	return t2, b2
end


cmd = torch.CmdLine()
cmd:text()
cmd:text('test the model')
cmd:text()
cmd:text('Options')
cmd:argument('-model','model checkpoint')
cmd:option('-length',10,'primetext length')
cmd:option('-batches',100,'test batches')
cmd:option('-maxprob',0.3,'max probility to invest')
cmd:option('-stop_earn',0.2,'percentage to stop earning')
cmd:option('-stop_loss',-0.1,'percentage to stop lossing')
cmd:option('-verbose',1,'verbose print mode')
cmd:text()

opt = cmd:parse(arg)
torch.manualSeed(1)

local yields = 0
local i
local cur_idx

history = torch.load('data/stock/history.t7')
assert(history)

for i=1, opt.batches do
	cur_idx = getSampleIdx()
	assert(cur_idx > 0)

	str = ''
	for j = 0, opt.length - 1 do
		str = str..history[cur_idx+j][7]
	end
	max_prob, next_char = predicNext(opt.model, str)
	print(cur_idx,str,max_prob,next_char)

	if max_prob > opt.maxprob then
		local predict_high, predict_low = charToPrice(history[cur_idx+opt.length-1][4], history[cur_idx+opt.length-1][5], next_char)
		invest_percent = (1 + yields) * (max_prob*opt.stop_earn-(1-max_prob)*opt.stop_loss)/(opt.stop_earn/opt.stop_loss)

		if history[cur_idx+opt.length][4] >= predict_high then
			if history[cur_idx+opt.length][5] <= predict_low then
				yields = yields + invest_percent * ((predict_high - predict_low) / (predict_high * 0.08)) * 0.95
			else
				if (predict_high - history[cur_idx+opt.length][4])/(predict_high * 0.08) * 1.05 < opt.stop_loss then
					yields = yields + invest_percent * opt.stop_loss 
				else
					if (predict_high - history[cur_idx+opt.length][6]) > 0 then
						yields = yields + invest_percent * (predict_high - history[cur_idx+opt.length][6])/(predict_high * 0.08) * 0.95
					else
						yields = yields + invest_percent * (predict_high - history[cur_idx+opt.length][6])/(predict_high * 0.08) * 1.05
					end
				end
			end
		end

		if history[cur_idx+opt.length][5] <= predict_low then
			if history[cur_idx+opt.length][4] >= predict_high then
				yields = yields + invest_percent * ((predict_high - predict_low) / (predict_low * 0.08)) * 0.95
			else
				if (history[cur_idx+opt.length][5] - predict_low)/(predict_low * 0.08) * 1.05 < opt.stop_loss then
					yields = yields + invest_percent * opt.stop_loss 
				else
					if (history[cur_idx+opt.length][6] - predict_low) > 0 then
						yields = yields + invest_percent * (history[cur_idx+opt.length][6] - predict_low)/(predict_low * 0.08) * 0.95
					else
						yields = yields + invest_percent * (history[cur_idx+opt.length][6] - predict_low)/(predict_low * 0.08) * 1.05
					end
				end
			end
		end
	end
end

print(yields)
