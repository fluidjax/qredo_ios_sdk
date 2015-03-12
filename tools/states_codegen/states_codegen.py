import os
import sys
import pydot
import re
from pprint import pprint
from sets import Set

dot_file = sys.argv[1]
print "Reading from ", dot_file
f = file( dot_file, 'rt' )
graph_data = f.read()
f.close()

g = pydot.graph_from_dot_data(graph_data)

nodes = g.obj_dict['nodes']
edges = g.obj_dict['edges']

graph_name = g.obj_dict['name']

objc_protocol_prefix = "Qredo" + graph_name
objc_protocol_name = objc_protocol_prefix + "Protocol"

objc_protocol_property = graph_name[0].lower() + graph_name[1:] + "Protocol"


all_nodes = set(nodes.keys())

for edge_nodes in edges:
	(node1, node2) = edge_nodes
	all_nodes.add(node1)
	all_nodes.add(node2)

def objc_stateName(node):
	return objc_protocol_prefix + "State_" + node[0].upper() + node[1:]

def stmtForSwitchState(node):
	return "[self.conversationProtocol switchToState:self." + objc_protocol_property + "." + node + "State];"

def handleEvent(label, node2):
	handled = False

	if label.startswith("onMessage"):
		messageType = re.search("com.qredo.[\w.]+", label)
		if messageType and ('==' in label):
			messageTypes[messageType.group()] = node2
			handled = True

	if label.startswith("onCancel"):
		handled = True

		print "- (void)cancel"
		print "{"
		print "\t" + stmtForSwitchState(node2)
		print "}"

	if label.startswith("onTimeout"):
		handled = True
		print "- (void)didTimeout"
		print "{"
		print "\t" + stmtForSwitchState(node2)
		print "}"

	return handled

state_interfaces = ""

for node in all_nodes:
	class_name = objc_stateName(node)
	messageTypes = {}

	notHandledEvents = []

	node_params = nodes[node]

	node_label = ""
	if node_params:
		node_params = node_params[0]
		node_attrs = node_params.get('attributes')
		if node_attrs:
			node_label = node_attrs.get('label')
			if not node_label:
				node_label = ""


	node_label = node_label.strip("\"'")
	label_lines = node_label.split('\\n')
	state_interfaces += "\n".join(map(lambda x: "// " + x, label_lines)) + "\n"
	state_interfaces += "@interface " + class_name + " : " + objc_protocol_prefix + "State\n"
	state_interfaces += "@end\n"

	print "@implementation " + class_name



	enter_line = filter(lambda x: x.strip().startswith("Enter:"), label_lines)

	if enter_line:
		print "- (void)didEnter"
		print "{"
		print "\t// TODO: " + enter_line[0]
		print "}"

	for edge_nodes, edge_params in edges.iteritems():
		(node1, node2) = edge_nodes
		edge_params = edge_params[0]

		if node1 != node:
			continue

		attributes = edge_params.get('attributes')

		if not attributes:
			continue

		label = attributes.get('label')

		if not label:
			continue

		label = label.strip('"\'')
		if label.startswith('"') and label.endswith('"'):
			label = label[1:len(label)-1]

		events = label.split('||')
		for event in events:
			event = event.strip()
			handled = handleEvent(event, node2)

			if not handled:
				notHandledEvents.append(event + " ---> " + stmtForSwitchState(node2))

	if len(messageTypes):
		print "- (void)didReceivedMessage:(QredoConversationMessage *)message"
		print "{"

		def printMessageType(messageType):
			print "\tif ([message.dataType isEqualToString: @\"" + messageType + "\"]) {"
			print "\t\t" + stmtForSwitchState(node2)
			print "\t} else"
		map(printMessageType, messageTypes)
		print "\t{"
		print "\t\t// TODO: error: unknown message"
		print "\t}"
		print "}"


	def printNotHandledEvents(event):
		print "// TODO: " + event
	map(printNotHandledEvents, notHandledEvents)

	print "@end"

print ""

print "\n////////// " + objc_protocol_name + ".h\n"
print "@class " + objc_protocol_name + ";"
print "@protocol " + objc_protocol_name + "Delegate"
print "// TODO: delegate methods"
print "@end\n"

print "@interface " + objc_protocol_prefix + "State : QredoConversationProtocolCancelableState"
print "// Events"
print "@end\n"

print "@interface " + objc_protocol_name + " : QredoConversationProtocol"
print "@property id<" + objc_protocol_name + "Delegate> delegate;"
print "@end\n"

print "\n////////// " + objc_protocol_name + ".m\n"

print state_interfaces

print "@interface " + objc_protocol_name + " ()"
print "\n".join(map(lambda x: "@property (nonatomic) " + objc_stateName(x) + " *" + x + "State;", all_nodes))

print "@end\n"

print "@interface " + objc_protocol_prefix + "State ()"
print "@property (nonatomic, readonly) " + objc_protocol_name + " *" + objc_protocol_property + ";"
print "@end\n"

print "@implementation " + objc_protocol_prefix + "State"
print "- (" + objc_protocol_name + " *)" + objc_protocol_property
print "{"
print "\treturn (" + objc_protocol_name + " *)self.conversationProtocol;"
print "}"
print "@end\n"


print "@implementation " + objc_protocol_name
print "@end"
