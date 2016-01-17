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
	torch.manualSeed(123)

	checkpoint = torch.load(model)
	protos = checkpoint.protos
	protos.rnn:evaluate() -- put in eval mode so that dropout works properly

	-- initialize the vocabulary (and its inverted version)
	local vocab = checkpoint.vocab
	local ivocab = {}
	for c,i in pairs(vocab) do ivocab[i] = c end

	-- initialize the rnn state to all zeros
	gprint('creating an ' .. checkpoint.opt.model .. '...')
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
	gprint('seeding with ' .. primetext)
	gprint('--------------------------')
	for c in primetext:gmatch'.' do
		prev_char = torch.Tensor{vocab[c]}
		io.write(ivocab[prev_char[1]])
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

	io.write(ivocab[prev_char[1]])
	return max_prob,prev_char
end


cmd = torch.CmdLine()
cmd:text()
cmd:text('test the model')
cmd:text()
cmd:text('Options')
cmd:argument('-model','model checkpoint')
cmd:option('-length',10,'primetext length')
cmd:option('-batches',100,'test batches')
cmd:option('-verbose',1,'verbose print mode')
cmd:text()

opt = cmd:parse(arg)

predicNext(opt.model, '99543aad21')
