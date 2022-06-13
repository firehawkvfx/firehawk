# This file is used in the .sh script to test cooking with preflight.

import hou
# node=hou.node('/obj/topnet1/ropfetch_ondemand_ubl') # This tests engine with a UBL license
node=hou.node('/obj/topnet1/ropfetch_ondemand_byo_license')

if hou.isUIAvailable():
    from nodegraphtopui import cookNode
    cookNode(node)
else:
    node.executeGraph(block=True)