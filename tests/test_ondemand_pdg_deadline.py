# This file is used in the .sh script to test cooking with preflight.

import hou
node=hou.node('/obj/topnet1/ropfetch_remote_node_test')

if hou.isUIAvailable():
    from nodegraphtopui import cookNode
    cookNode(node)
else:
    node.executeGraph(block=True)