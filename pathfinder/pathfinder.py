import pydot, Tkinter as tk
import sys, uni, time, pydot

# suppose this came out of the xml parser
nodes = ["a", "b", "c", "d", "e", "f", "g" ]
edges = {
    "a" : ["c"],
    "b" : ["e"],
    "c" : ["b", "d", "f"],
    "d" : ["e"],
    "e" : ["g"],
    "f" : ["g"],
    "g" : ["b"]
}

def edges_to_tuples(edges):
    return [ (x,  y)  for x in edges.keys() for y in edges[x] ]

# [a, b, c] -> [(a, b), (b, c)]
def edge_tuples_from_nodes_list(nodes):
    edge_tuples = []
    for i in range(len(nodes) - 1):
        edge_tuples.append((nodes[i], nodes[i+1]))
    return edge_tuples

def gen_graph(edges, nodes, active_nodes=[]):
    tuples = edges_to_tuples(edges)
    graph = pydot.Dot(graph_type='digraph')
    active_edges = edge_tuples_from_nodes_list(active_nodes)

    for n in nodes:
        if  n in active_nodes:
            fontcolour="red"
            fillcolour="#cccccc"
        else:
            fontcolour="black"
            fillcolour="white"

        graph.add_node(pydot.Node(n,
            style="filled",
            fillcolor=fillcolour,
            fontcolor=fontcolour)
            )

    for (src, dest) in tuples:
        edge_colour = "red" if (src, dest) in active_edges else "black"
        e = pydot.Edge(src, dest, color=edge_colour)
        graph.add_edge(e)

    graph.set_rankdir("LR")
    graph.write("mygraph.gif", format="gif")

# Instantiate Prolog
e = uni.Engine("""
    path(From, To, MaxLen, Nodes) :-
        path(From, To, MaxLen, Nodes, 1).

    path(Node, Node, _, [Node], _).
    path(From, To, MaxLen, [From | Ahead ], Len) :-
        Len < MaxLen, edge(From, Next),
        Len1 is Len + 1,
        path(Next, To, MaxLen, Ahead, Len1).

    edge(From, To) :- python:get_edges(From, To).
""")

# Generate initial graph
graph = gen_graph(edges, nodes)

# Set up GUI
top = tk.Tk()
top.title("Unipycation: PathFinder")

# entry boxes
col = 1; row = 1
entry_frame = tk.Frame(top)
entry_frame.grid(row=row, column=1)

from_lbl = tk.Label(entry_frame, text="From:")
from_lbl.grid(column=col, row=row)
from_entry = tk.Entry(entry_frame)
from_entry.grid(row=row, column=col+1)
from_entry.insert(0, "d")
col += 2

max_lbl = tk.Label(entry_frame, text="Max nodes:")
max_lbl.grid(column=col, row=row)
max_spin = tk.Spinbox(entry_frame, from_=0, to=9)
max_spin.grid(row=row, column=col+1)
for i in range(4): max_spin.invoke("buttonup")
col += 2

find_paths_closure = lambda : find_paths(top, e, nodes, edges, from_entry, max_spin)

go_button = tk.Button(entry_frame, text="Find Paths",
    command=find_paths_closure)
go_button.grid(row=row, column=col)
col += 2

# initial graph display
def show_graph():
    col = 1; row = 2
    graph_img = tk.PhotoImage(file="mygraph.gif")
    graph_lbl = tk.Label(image=graph_img)
    graph_lbl.grid(column=1, row=row)
show_graph()

# Prolog helper
def get_edges(src_node):
   return iter(edges[src_node])

def find_paths(top, engine, nodes, edges, from_entry, max_spin):
    paths = e.db.path.iter

    # fetch parameters from gui and query
    found_paths = [ (to, path) for (to, path) in
        paths(from_entry.get(), None, int(max_spin.get()), None) ]

    for (to, path) in found_paths:
        gen_graph(edges, nodes, path)
        show_graph()
        top.update_idletasks()
        time.sleep(1)

    # reset
    gen_graph(edges, nodes)
    show_graph()

# go
top.mainloop()
