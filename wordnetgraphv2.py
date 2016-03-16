#simple node -> only name
#complex node -> name,definition
#simple edge -> edge to a simple node(contains name and that edge type)
#complex edge -> edge to a complex node(contains name,definition and that edge type)
	
#put all words in the seed set and run
#results obtained as form of dictionary
#each key in dictionary is a node and its values are that nodes edges.

#Different type of relations : synonym,hypernym,Hyponym,Part_meronym,Substance_meronym,member_meronym,part_holonym,substance_holonym,member_holonym

import nltk
from matplotlib import pyplot as plt
from nltk.corpus import wordnet as wn
import collections
import sys
import networkx as nx

#simpnode = collections.namedtuple('simp','name')
compnode = collections.namedtuple('comp','name definition')
#simpedge = collections.namedtuple('simpe','name relation')
compedge = collections.namedtuple('compe','name definition relation')
seed_set = ['farming']
dictionary = {}
G = nx.Graph()

def getsynhypoandparts(cur):
	#print cur
	#print cur.definition()
	#curnode = compnode(str(cur.name()),str(cur.definition()))
	syno = cur.lemmas()
	hypo = cur.hyponyms()
	memb = cur.member_meronyms()
	subs = cur.substance_meronyms()
	part = cur.part_meronyms()
	if len(syno)>0 : 
		for item2 in syno :
			temp = compnode(str(item2.name()),str(cur.definition()))
			#print("temp is ")
			#print(temp)
			# tempedge1 = simpedge(str(item2.name()),'Synonym')
			# tempedge2 = compedge(str(cur.name()),str(cur.definition()),'Synonym') 
			# if dictionary.has_key(curnode) :
			# 	if dictionary[curnode].count(tempedge1) == 0:
			# 		dictionary[curnode].append(tempedge1)
			# 		if dictionary.has_key(temp):
			# 			if dictionary[temp].count(tempedge2) == 0:
			# 				G.add_edge(curnode,temp,{'et':'Syn'})
			# 				dictionary[temp].append(tempedge2)
			# 		else:
			# 			G.add_node(temp,{'name':str(item2.name())})
			# 			G.add_edge(curnode,temp,{'et':'Syn'})
			# 			dictionary[temp] = []
			# 			dictionary[temp].append(tempedge2)
			# else:
			# 	G.add_node(curnode,{'name':str(cur.name())})
			# 	dictionary[curnode] = []
			# 	dictionary[curnode].append(tempedge1)
			# 	if dictionary.has_key(temp) :
			# 		G.add_edge(curnode,temp,{'et':'Syn'})
			# 		dictionary[temp].append(tempedge2)
			# 	else:
			# 		G.add_node(temp,{'name':str(item2.name())})
			# 		G.add_edge(curnode,temp,{'et':'Syn'})
			# 		dictionary[temp] = []
			# 		dictionary[temp].append(tempedge2)
			if len(hypo)>0 : 
				for item3 in hypo :
					index=1
					for item4 in item3.lemmas():
						temp1 = compnode(str(item4.name()),str(item3.definition()))
						tempedge1 = compedge(str(item4.name()),str(item3.definition()),'Hyponym')
						tempedge2 = compedge(str(item2.name()),str(cur.definition()),'Hypernym') 
						if dictionary.has_key(temp) :
							#print dictionary[curnode]
							#print dictionary[curnode].count(tempedge1)
							if dictionary[temp].count(tempedge1) == 0:
								dictionary[temp].append(tempedge1)
								if dictionary.has_key(temp1):
									if dictionary[temp1].count(tempedge2) == 0:
										G.add_edge(temp,temp1,{'et':'Hyp'})
										dictionary[temp1].append(tempedge2)
								else:
									G.add_node(temp1,{'name':str(item4.name())})
									G.add_edge(temp,temp1,{'et':'Hyp'})
									dictionary[temp1] = []
									dictionary[temp1].append(tempedge2)
									if(index==1):
										getsynhypoandparts(item3)
						else:
							G.add_node(temp,{'name':str(item2.name())})
							dictionary[temp] = []
							dictionary[temp].append(tempedge1)
							if dictionary.has_key(temp1) :
								G.add_edge(temp,temp1,{'et':'Hyp'})
								dictionary[temp1].append(tempedge2)
							else:
								G.add_node(temp1,{'name':str(item4.name())})
								G.add_edge(temp,temp1,{'et':'Hyp'})
								dictionary[temp1] = []
								dictionary[temp1].append(tempedge2)
								if(index==1):
									getsynhypoandparts(item3)
						index = index+1
					
			if len(part)>0 : 
				for item3 in part :
					index=1
					for item4 in item3.lemmas():
						temp1 = compnode(str(item4.name()),str(item3.definition()))
						tempedge1 = compedge(str(item4.name()),str(item3.definition()),'Part_Meronym')
						tempedge2 = compedge(str(item2.name()),str(cur.definition()),'Part_Holonym') 
						if dictionary.has_key(temp) :
							#print dictionary[curnode]
							#print dictionary[curnode].count(tempedge1)
							if dictionary[temp].count(tempedge1) == 0:
								dictionary[temp].append(tempedge1)
								if dictionary.has_key(temp1):
									if dictionary[temp1].count(tempedge2) == 0:
										G.add_edge(temp,temp1,{'et':'PM'})
										dictionary[temp1].append(tempedge2)
								else:
									G.add_node(temp1,{'name':str(item4.name())})
									G.add_edge(temp,temp1,{'et':'PM'})
									dictionary[temp1] = []
									dictionary[temp1].append(tempedge2)
									if(index==1):
										getsynhypoandparts(item3)
						else:
							G.add_node(temp,{'name':str(item2.name())})
							dictionary[temp] = []
							dictionary[temp].append(tempedge1)
							if dictionary.has_key(temp1) :
								G.add_edge(temp,temp1,{'et':'Hyp'})
								dictionary[temp1].append(tempedge2)
							else:
								G.add_node(temp1,{'name':str(item4.name())})
								G.add_edge(temp,temp1,{'et':'Hyp'})
								dictionary[temp1] = []
								dictionary[temp1].append(tempedge2)
								if(index==1):
									getsynhypoandparts(item3)
						index=index+1

			if len(subs)>0 : 
				for item3 in subs :
					index=1
					for item4 in item3.lemmas():
						temp1 = compnode(str(item4.name()),str(item3.definition()))
						tempedge1 = compedge(str(item4.name()),str(item3.definition()),'Substance_Meronym')
						tempedge2 = compedge(str(item2.name()),str(cur.definition()),'Substance_Holonym') 
						if dictionary.has_key(temp) :
							#print dictionary[curnode]
							#print dictionary[curnode].count(tempedge1)
							if dictionary[temp].count(tempedge1) == 0:
								dictionary[temp].append(tempedge1)
								if dictionary.has_key(temp1):
									if dictionary[temp1].count(tempedge2) == 0:
										G.add_edge(temp,temp1,{'et':'SM'})
										dictionary[temp1].append(tempedge2)
								else:
									G.add_node(temp1,{'name':str(item4.name())})
									G.add_edge(temp,temp1,{'et':'SM'})
									dictionary[temp1] = []
									dictionary[temp1].append(tempedge2)
									if(index==1):
										getsynhypoandparts(item3)
						else:
							G.add_node(temp,{'name':str(item2.name())})
							dictionary[temp] = []
							dictionary[temp].append(tempedge1)
							if dictionary.has_key(temp1) :
								G.add_edge(temp,temp1,{'et':'SM'})
								dictionary[temp1].append(tempedge2)
							else:
								G.add_node(temp1,{'name':str(item4.name())})
								G.add_edge(temp,temp1,{'et':'SM'})
								dictionary[temp1] = []
								dictionary[temp1].append(tempedge2)
								if(index==1):
									getsynhypoandparts(item3)
						index=index+1

			if len(memb)>0 : 
				for item3 in memb :
					index=1
					for item4 in item3.lemmas():
						temp1 = compnode(str(item4.name()),str(item3.definition()))
						tempedge1 = compedge(str(item4.name()),str(item3.definition()),'Member_Meronym')
						tempedge2 = compedge(str(item2.name()),str(cur.definition()),'Member_Holonym') 
						if dictionary.has_key(temp) :
							#print dictionary[curnode]
							#print dictionary[curnode].count(tempedge1)
							if dictionary[temp].count(tempedge1) == 0:
								dictionary[temp].append(tempedge1)
								if dictionary.has_key(temp1):
									if dictionary[temp1].count(tempedge2) == 0:
										G.add_edge(temp,temp1,{'et':'Hyp'})
										dictionary[temp1].append(tempedge2)
								else:
									G.add_node(temp1,{'name':str(item4.name())})
									G.add_edge(temp,temp1,{'et':'Hyp'})
									dictionary[temp1] = []
									dictionary[temp1].append(tempedge2)
									if(index==1):
										getsynhypoandparts(item3)
						else:
							G.add_node(temp,{'name':str(item2.name())})
							dictionary[temp] = []
							dictionary[temp].append(tempedge1)
							if dictionary.has_key(temp1) :
								G.add_edge(temp,temp1,{'et':'Hyp'})
								dictionary[temp1].append(tempedge2)
							else:
								G.add_node(temp1,{'name':str(item4.name())})
								G.add_edge(temp,temp1,{'et':'Hyp'})
								dictionary[temp1] = []
								dictionary[temp1].append(tempedge2)
								if(index==1):
									getsynhypoandparts(item3)
						index=index+1


		for index1 in range(len(syno)):
			item1 = syno[index1]
			temp=compnode(str(item1.name()),str(cur.definition()))
			for index2 in range(index1+1,len(syno)):
				item2 = syno[index2]
				temp1=compnode(str(item2.name()),str(cur.definition()))
				tempedge1 = compedge(str(item2.name()),str(cur.definition()),'Synonym')
				tempedge2 = compedge(str(item1.name()),str(cur.definition()),'Synonym')
				if dictionary.has_key(temp) :
					#print dictionary[curnode]
					#print dictionary[curnode].count(tempedge1)
					if dictionary[temp].count(tempedge1) == 0:
						dictionary[temp].append(tempedge1)
						if dictionary.has_key(temp1):
							if dictionary[temp1].count(tempedge2) == 0:
								G.add_edge(temp,temp1,{'et':'Syn'})
								dictionary[temp1].append(tempedge2)
						else:
							G.add_node(temp1,{'name':str(item2.name())})
							G.add_edge(temp,temp1,{'et':'Syn'})
							dictionary[temp1] = []
							dictionary[temp1].append(tempedge2)
				else:
					G.add_node(temp,{'name':str(item1.name())})
					dictionary[temp] = []
					dictionary[temp].append(tempedge1)
					if dictionary.has_key(temp1) :
						G.add_edge(temp,temp1,{'et':'Syn'})
						dictionary[temp1].append(tempedge2)
					else:
						G.add_node(temp1,{'name':str(item2.name())})
						G.add_edge(temp,temp1,{'et':'Syn'})
						dictionary[temp1] = []
						dictionary[temp1].append(tempedge2)			


				
			# if len(cur.part_meronyms())>0 : 
			# 	for item2 in cur.part_meronyms() :
			# 		temp = compnode(str(item2.name()),str(item2.definition()))
			# 		tempedge1 = compedge(str(item2.name()),str(item2.definition()),'Part_Meronym')
			# 		tempedge2 = compedge(str(cur.name()),str(cur.definition()),'Part_Holonym') 
			# 		if dictionary.has_key(curnode) :
			# 			if dictionary[curnode].count(tempedge1) == 0:
			# 				dictionary[curnode].append(tempedge1)
			# 				if dictionary.has_key(temp):
			# 					if dictionary[temp].count(tempedge2) == 0:
			# 						G.add_edge(curnode,temp,{'et':'PM'})
			# 						dictionary[temp].append(tempedge2)
			# 				else:
			# 					G.add_node(temp,{'name':str(item2.name())})
			# 					G.add_edge(curnode,temp,{'et':'PM'})
			# 					dictionary[temp] = []
			# 					dictionary[temp].append(tempedge2)
			# 					getsynhypoandparts(item2)
			# 		else:
			# 			G.add_node(curnode,{'name':str(cur.name())})
			# 			dictionary[curnode] = []
			# 			dictionary[curnode].append(tempedge1)
			# 			if dictionary.has_key(temp) :
			# 				G.add_edge(curnode,temp,{'et':'PM'})
			# 				dictionary[temp].append(tempedge2)
			# 			else:
			# 				G.add_node(temp,{'name':str(item2.name())})
			# 				G.add_edge(curnode,temp,{'et':'PM'})
			# 				dictionary[temp] = []
			# 				dictionary[temp].append(tempedge2)
			# 				getsynhypoandparts(item2)
					

			# if len(cur.substance_meronyms())>0 : 
			# 	for item2 in cur.substance_meronyms() :
			# 		temp = compnode(str(item2.name()),str(item2.definition()))
			# 		tempedge1 = compedge(str(item2.name()),str(item2.definition()),'Substance_Meronym')
			# 		tempedge2 = compedge(str(cur.name()),str(cur.definition()),'Substance_Holonym') 
			# 		if dictionary.has_key(curnode) :
			# 			if dictionary[curnode].count(tempedge1) == 0:
			# 				dictionary[curnode].append(tempedge1)
			# 				if dictionary.has_key(temp):
			# 					if dictionary[temp].count(tempedge2) == 0:
			# 						G.add_edge(curnode,temp,{'et':'SM'})
			# 						dictionary[temp].append(tempedge2)
			# 				else:
			# 					G.add_node(temp,{'name':str(item2.name())})
			# 					G.add_edge(curnode,temp,{'et':'SM'})
			# 					dictionary[temp] = []
			# 					dictionary[temp].append(tempedge2)
			# 					getsynhypoandparts(item2)
			# 		else:
			# 			G.add_node(curnode,{'name':str(cur.name())})
			# 			dictionary[curnode] = []
			# 			dictionary[curnode].append(tempedge1)
			# 			if dictionary.has_key(temp) :
			# 				G.add_edge(curnode,temp,{'et':'SM'})
			# 				dictionary[temp].append(tempedge2)
			# 			else:
			# 				G.add_node(temp,{'name':str(item2.name())})
			# 				G.add_edge(curnode,temp,{'et':'SM'})
			# 				dictionary[temp] = []
			# 				dictionary[temp].append(tempedge2)
			# 				getsynhypoandparts(item2)
					

			# if len(cur.member_meronyms())>0 : 
			# 	for item2 in cur.member_meronyms() :
			# 		temp = compnode(str(item2.name()),str(item2.definition()))
			# 		tempedge1 = compedge(str(item2.name()),str(item2.definition()),'Member_Meronym')
			# 		tempedge2 = compedge(str(cur.name()),str(cur.definition()),'Member_Holonym') 
			# 		if dictionary.has_key(curnode) :
			# 			if dictionary[curnode].count(tempedge1) == 0:
			# 				dictionary[curnode].append(tempedge1)
			# 				if dictionary.has_key(temp):
			# 					if dictionary[temp].count(tempedge2) == 0:
			# 						G.add_edge(curnode,temp,et='MM')
			# 						dictionary[temp].append(tempedge2)
			# 				else:
			# 					G.add_node(temp,{'name':str(item2.name())})
			# 					G.add_edge(curnode,temp,et='MM')
			# 					dictionary[temp] = []
			# 					dictionary[temp].append(tempedge2)
			# 					getsynhypoandparts(item2)
			# 		else:
			# 			G.add_node(curnode,{'name':str(cur.name())})
			# 			dictionary[curnode] = []
			# 			dictionary[curnode].append(tempedge1)
			# 			if dictionary.has_key(temp) :
			# 				G.add_edge(curnode,temp,et='MM')
			# 				dictionary[temp].append(tempedge2)
			# 			else:
			# 				G.add_node(temp,{'name':str(item2.name())})
			# 				G.add_edge(curnode,temp,et='MM')
			# 				dictionary[temp] = []
			# 				dictionary[temp].append(tempedge2)
			# 				getsynhypoandparts(item2)
			


for item in seed_set : 
	i=1
	for item1 in wn.synsets(item):
		print item
		print i
		print item1
		print item1.definition()
		print "\n"
		i=i+1
	if(len(wn.synsets(item)) > 0):
		index = raw_input("Enter number : ")
		cur = wn.synsets(item)[int(index) - 1]
		getsynhypoandparts(cur)

print dictionary
pos = nx.spring_layout(G)
nx.draw_networkx(G, pos,with_labels=False)
#shifted_pos = {k:[v[0],v[1]+.05] for k,v in pos.iteritems()}
node_labels = {i:G.node[i]['name'] for i in G.nodes()}
edge_labels = {i[0:2]:'{}'.format(i[2]['et']) for i in G.edges(data=True)}
#dge_labels = nx.get_edge_attributes(G,'et')
nx.draw_networkx_labels(G, pos=pos, labels=node_labels)
nx.draw_networkx_edge_labels(G, pos=pos, edge_labels=edge_labels)
plt.savefig('this.png')
plt.show()


