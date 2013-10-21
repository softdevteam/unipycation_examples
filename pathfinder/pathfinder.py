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
entry_frame = tk.Frame(top)
entry_frame.grid(row=1, column=1)

from_lbl = tk.Label(entry_frame, text="From:")
from_lbl.grid(column=1, row=1)
from_entry = tk.Entry(entry_frame)
from_entry.grid(row=1, column=2)
from_entry.insert(0, "d")

max_lbl = tk.Label(entry_frame, text="Max nodes:")
max_lbl.grid(column=3, row=1)
max_spin = tk.Spinbox(entry_frame, from_=1, to=9)
max_spin.grid(row=1, column=4)
for i in range(4): max_spin.invoke("buttonup")

# status bar
INITIAL_STATUS_TEXT="Awaiting path specification"
status_lbl = tk.Label(top, text=INITIAL_STATUS_TEXT)
status_lbl.grid(column=1, row=3)

# Button
find_paths_closure = lambda : find_paths(top, e, nodes, edges, from_entry, max_spin, go_button, status_lbl)

INITIAL_BUTTON_TEXT = "Find Paths"
NEXT_BUTTON_TEXT = "Next Path"
go_button = tk.Button(entry_frame,
    text=INITIAL_BUTTON_TEXT,
    command=find_paths_closure)
go_button.grid(row=1, column=5)

# initial graph display
def show_graph():
    graph_img = tk.PhotoImage(file="mygraph.gif")
    graph_lbl = tk.Label(image=graph_img)
    graph_lbl.grid(column=1, row=2)
show_graph()

# Prolog helper
def get_edges(src_node):
   return iter(edges[src_node])

# Called when the "find paths" button is clicked for the first time
def find_paths(top, engine, nodes, edges, from_entry,
        max_spin, go_button, status_lbl):
    paths = e.db.path.iter
    sol_iter = paths(from_entry.get(), None, int(max_spin.get()), None)
    generator = cycle_results(top, sol_iter, nodes, edges, status_lbl)

    # Now we have result iterator, we change the function of the button.
    # Each press will find another path until no more.
    def new_button_command(generator, from_entry, max_spin, button):
        try:
            generator.next()
        except StopIteration:
            # Once exhausted, revert button to initaial function
            go_button["command"] = find_paths_closure
            go_button["text"] = INITIAL_BUTTON_TEXT
            # re-enable the user input widgets
            from_entry["state"] = tk.NORMAL
            max_spin["state"] = tk.NORMAL
            status_lbl["text"] = INITIAL_STATUS_TEXT

    go_button["command"] = lambda : new_button_command(
        generator, from_entry, max_spin, go_button)
    go_button["text"] = NEXT_BUTTON_TEXT

    # Dim out entries
    from_entry["state"] = tk.DISABLED
    max_spin["state"] = tk.DISABLED

    # show first path
    new_button_command(generator, from_entry, max_spin, go_button)

# Generator pumped lazily to get next path.
# Called when "next path" clicked
def cycle_results(top, sol_iter, nodes, edges, status_lbl):
    for (to, path) in sol_iter:
        gen_graph(edges, nodes, path)
        show_graph()
        status_lbl["text"] = str(path)
        yield
    # reset
    gen_graph(edges, nodes)
    show_graph()

# go
top.mainloop()