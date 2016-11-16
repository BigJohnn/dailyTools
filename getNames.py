import os
import random
names = os.listdir('/home/hhhj/lirui/py-faster-rcnn/data/VOCdevkit2007/VOC2007/JPEGImages')
result = []
f = open('trainval.txt','w')
fv = open('validate.txt','w')
ft = open('train.txt','w')

for name in names:
    str = name.split('.')[0]
    result.append(str)
    f.write(str+'\n')

validata = random.sample(result,200)
traindata = list(set(validata)^set(result))

for item in validata:
    fv.write(item+'\n')
for item in traindata:
    ft.write(item+'\n')
print result
