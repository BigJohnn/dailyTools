#!/usr/bin/env python
# encoding: utf-8

# -------------------------------------------------------
# version: v0.1                                         
# author: hph
# license: Apache Licence
# function: 
# file: converter.py
# time: 16-11-8 下午5:10
#---------------------------------------------------------
import os
import xml.dom.minidom as dm

prefix = 'cut9_'
logos_dir = '/home/hph/logos'

class frame():
    def __init__(self):
        self.objects = []
        self.framenum=''

class object():
    def __init__(self):
        self.class_name = ''
        self.rect = ''

frames=[]
# nodeSize
def process(logo_root):
    for i in os.listdir(logo_root):
        flag=0
        current = os.path.join(logo_root, i)

        if os.path.isdir(current):
            # print i
            process(current)

        if os.path.isfile(current):
            result = current.split('/')[-3:]
            ffront = result[2].split('.')[0]
            ffsplit = ffront.split('_')[-5:]

            print ffsplit
            o = object()
            o.class_name = result[1]+'_'+result[0]
            o.rect = ffsplit[-4:]
            f = frame()
            f.framenum = ffsplit[0]
            f.objects.append(o)

            if frames is []:
                frames.append(f)
            else:
                exist = False
                for item in frames:
                    if item.framenum != f.framenum:
                        continue
                    else:
                        exist = True
                        item.objects.append(o)
                if not exist:
                    frames.append(f)

def save():
    for f in frames:
        doc = dm.Document()
        root = doc.createElement('annotation')
        doc.appendChild(root)

        nodeFolder = doc.createElement('folder')
        nodeFolder.appendChild(doc.createTextNode('XinYinSport'))
        root.appendChild(nodeFolder)

        nodeSize = doc.createElement('size')
        nodeWidth = doc.createElement('width')
        nodeWidth.appendChild(doc.createTextNode('1920'))
        nodeHeight = doc.createElement('height')
        nodeHeight.appendChild(doc.createTextNode('1080'))
        nodeChannel = doc.createElement('depth')
        nodeChannel.appendChild(doc.createTextNode('3'))
        nodeSize.appendChild(nodeHeight)
        nodeSize.appendChild(nodeWidth)
        nodeSize.appendChild(nodeChannel)
        root.appendChild(nodeSize)

        nodeFilename = doc.createElement('filename')
        nodePath = doc.createElement('path')
        img_dir = prefix + f.framenum + '.jpg'
        nodeFilename.appendChild(doc.createTextNode(img_dir))
        nodePath.appendChild(doc.createTextNode('imgs/' + img_dir))
        root.appendChild(nodeFilename)
        root.appendChild(nodePath)

        for o in f.objects:
            nodeObjects = doc.createElement('objects')
            nodeName = doc.createElement('name')
            nodeBoundingbox = doc.createElement('bndbox')
            nodeXmin = doc.createElement('xmin')
            nodeXmax = doc.createElement('xmax')
            nodeYmin = doc.createElement('ymin')
            nodeYmax = doc.createElement('ymax')

            nodeObjects.appendChild(nodeName)
            nodeObjects.appendChild(nodeBoundingbox)
            nodeBoundingbox.appendChild(nodeXmax)
            nodeBoundingbox.appendChild(nodeXmin)
            nodeBoundingbox.appendChild(nodeYmax)
            nodeBoundingbox.appendChild(nodeYmin)


            root.appendChild(nodeObjects)
            nodeName.appendChild(doc.createTextNode(o.class_name))
            nodeXmin.appendChild(doc.createTextNode(o.rect[0]))
            nodeYmin.appendChild(doc.createTextNode(o.rect[1]))
            nodeXmax.appendChild(doc.createTextNode(o.rect[2]))
            nodeYmax.appendChild(doc.createTextNode(o.rect[3]))

        xml_dir = prefix+f.framenum + '.xml'
        if not os.path.exists("xmls"):
            os.mkdir("xmls")

        fp = open('xmls/' + xml_dir, 'w')
        doc.writexml(fp, indent='\t', addindent='\t', newl='\n', encoding='utf-8')

def compare(dir0,dir1):
    list0 = os.listdir(dir0)
    list1 = os.listdir(dir1)
    imgs=[]
    xmls =[]
    for item in list0:
        imgs.append(item.split('.')[0])
    for item in list1:
        xmls.append(item.split('.')[0])
    # print imgs,xmls

    imgs2del = list(set(imgs).difference(set(xmls)))
    print 'imgs to delete: ' ,imgs2del
    xmls2del = list(set(xmls).difference(set(imgs)))
    print 'xmls to delete: ', xmls2del

    for item in imgs2del:
        if os.path.exists('imgs/'+item+'.jpg'):
            os.remove('imgs/'+item+'.jpg')

    for item in xmls2del:
        if os.path.exists('xmls/'+item+'.xml'):
            os.remove('xmls/'+item+'.xml')


if __name__ == '__main__':
    # process(logos_dir)
    # save()
    compare('imgs','xmls')
    pass
