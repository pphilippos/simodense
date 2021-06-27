#!/bin/env python
import os
import commands

s=[]
for i in range(3000):
	c=commands.getoutput("devmem %s "%(hex(int("0x47000000",16)+i*4),))	
	
	try:
		s+=[chr(int(c,16))]
	except:
		s+=""

print "".join(s)
