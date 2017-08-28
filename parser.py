#!/usr/bin/env python2.7
import sys
import re
from collections import OrderedDict

num_nodes = 15
sink_id = 1
senders = range(2, num_nodes+1)


input_file = sys.argv[1]

record_format = "cooja_tab"

record_pattern = {
		"cooja":"(?P<time>\d+):(?P<self_id>\d+):%s", # Cooja
		"cooja_tab":"(?P<time>[\w:.]+)\s+ID:(?P<self_id>\d+)\s+%s", # Cooja with tabs
		}.get(record_format, None)

recv			= re.compile(record_pattern%"app:Recv from (?P<src>\d+) seqn (?P<seqn>\d+)")
unicast_send	= re.compile(record_pattern%"app:Send to sink seqn (?P<seqn>\d+)")

recv_seqn = {}
send_seqn = {}


testlog = open(input_file,'r')
sendlog = open("send.log",'w')
recvlog = open("recv.log",'w')

sendlog.write("time\tdst\tsrc\tseqn\n")
recvlog.write("time\tdst\tsrc\tseqn\n")

def parse_collect():
	global recv_seqn, send_seqn
	global testlog, recvlog, sendlog
	for l in testlog:
		m = recv.match(l)
		if m:
			g = m.groupdict()
			time = g["time"]
			src = int(g["src"])
			dst = int(g["self_id"])
			seqn = int(g["seqn"])
			
			if dst == sink_id:
				recv_seqn.setdefault(src, {})[seqn] = time
			
			recvlog.write("%s\t%d\t%d\t%d\n"%(time, dst, src, seqn))

		else:
			m = unicast_send.match(l)
			if m:
				g = m.groupdict()
				time = g["time"]
				src = int(g["self_id"])
				dst = 1
				seqn = int(g["seqn"])

				sendlog.write("%s\t%d\t%d\t%d\n"%(time, dst, src, seqn))
				if dst == sink_id:
					send_seqn.setdefault(src, {})[seqn] = time

parse_collect()

all_sent_seqns = set()
for node in send_seqn.values():
	all_sent_seqns.update(node.keys())

all_recv_seqns = set()
for node in recv_seqn.values():
	all_recv_seqns.update(node.keys())

missing_send_record = all_recv_seqns - all_sent_seqns
all_seqns = all_sent_seqns.union(all_recv_seqns)


PSNs = {i:len(send_seqn.get(i,())) for i in senders} 
PRNs = {i:len(set(recv_seqn.get(i,{}).keys())-missing_send_record) for i in senders}
PRNs_total = {i:len(recv_seqn.get(i,{})) for i in senders}

PDRs = {i:(float(PRNs[i])/PSNs[i]*100 if PSNs[i]!=0 else 0) for i in senders} 

not_sent = {i for i in senders if i not in send_seqn}
not_recvd = {i for i in senders if i not in recv_seqn}

print
print "-- Nodes stats ----------------"
print "# nodes in topology:", num_nodes
print "Not probed:", ", ".join(str(x) for x in sorted(not_sent)) 
print "Isolated:", ", ".join(str(x) for x in sorted(not_recvd-not_sent)) 
print
print "-- Seqnum stats ---------------"
print "Not sent but received:", sorted(missing_send_record)
print
print "-- Packets stats --------------"
print "# packets node:received/sent:"
print ", ".join("%d: %d/%d"%(i,PRNs_total[i],PSNs[i]) for i in senders)
print 
print "PDRs:" 
print ", ".join(["%d: %.1f"%(i,PDRs[i]) for i in senders])
print 

l = [PDRs[i] for i in senders]

min_pdr = min(l) if (len(l) != 0) else 0
print "min PDR (of those probed):", min_pdr 

n_sent = 0
for node,seqns in send_seqn.items():
	n_sent += len(seqns)

n_recv = 0
for node,seqns in recv_seqn.items():
	n_recv += len(seqns)

print "average network PDR:", float(n_recv)/n_sent 
print

# -*- vim: ts=4 sw=4 noexpandtab
