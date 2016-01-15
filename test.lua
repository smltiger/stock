require 'torch'
require 'nn'
require 'nngraph'
inputs = {}
table.insert(inputs, nn.Identity()())
table.insert(inputs, nn.Identity()())

t1 = nn.Linear(5,3)(inputs[1])
t2 = nn.Linear(4,3)(inputs[2])
add = nn.CAddTable()({t1,t2})
outputs = {}
table.insert(outputs,add)

model = nn.gModule(inputs, outputs)
param = model:getParameters()
param:fill(1)
print(param)

i1 = torch.Tensor(5):fill(1)
i2 = torch.Tensor(4):fill(1)

result = model:forward({i1,i2})
print(result)
