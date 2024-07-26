using PyCall
using ReadFiles


function tricontourf(node_set, field_name)
    plt = pyimport("matplotlib.pyplot")

    x = get_field_by_name(node_set, "x")
    y = get_field_by_name(node_set, "y")
    values = get_field_by_name(node_set, field_name)
    
    plt.tricontourf(x, y, values)
    plt.colorbar()
    ax = plt.gca()
    ax.set_aspect("equal")
    plt.show()
    return nothing
end



