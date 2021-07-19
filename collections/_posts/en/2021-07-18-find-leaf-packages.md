---
title: "Finding Leaf Packages Faster: Optimization for In-degree Computation in
  Dependency Graph"
lang: en
tags:
  - Gentoo
  - Computer Science
  - Python
categories:
  - Blog
  - GSoC 2021
  - Tricks
toc: true
asciinema-player: true
---
{% include img-path.liquid %}
Dependency is a concept that appears often in software engineering.  In the
[previous article][gentoo-build-kt-src] for my GSoC project, I discussed build
systems and package managers, both of which apply the concept of dependencies.
A build system usually allows programmers to define different *tasks* in
building a project and let each of them depend on other tasks, hence dependency
relationships are established.  A package manager supports declaration of
package dependency relationships, or else it is not a good package manager.
This article focuses on the latter, which is dependency relationships among
packages.

When the packages in a package repository increase in quantity, a complicated
web is formed by the packages and the dependency relationships among them.  In
mathematics, the web is called a [*graph*][wikipedia-graph].  A graph is
composed of vertices, each of which represents an entity/object, and edges,
each of which connects a vertex to a vertex, usually to define a relationship
between the connected vertices.  More specifically, the web is a [*directed*
graph][wikipedia-directed-graph], meaning that each edge in the graph has a
direction (and thus is usually drawn as an arrow).  The direction is defined to
signify that a dependency relationship is normally *asymmetric*: if we say
"package *A* depends on package *B*", then the statement "package *B* depends
on package *A*" is generally false.  Thus, an arrow starting from the vertex
for package *A* and pointing to the vertex for package *B* is drawn on the
graph to show this relationship.

{% capture fig_path %}{{ img_path }}/dep-graph-example.svg{% endcapture %}
{: style="width: 75%; margin: auto"}
{% include figure image_path=fig_path alt="An example of a dependency graph"
    caption="An example of a dependency graph showing how some of the Kotlin
    packages I have created depend on other packages and dependencies of
    `dev-java/openjdk-bin:8`.  This graph is only intended for demonstrating
    how a dependency graph is visualized; it is not a precise representation of
    the actual dependency relationships of the packages included in this
    diagram and thus should not be used for informational purposes." %}

A lot of valuable information can be extracted from a dependency graph.  For
example, one can compute from a dependency graph a list of **leaf packages** in
a package repository.  A leaf package is defined to be a package without any
*reverse dependencies* -- that is, a package which is not a dependency of any
other package.  Such a list of leaf packages can have many applications in a
package maintainer's workflow.  As per the [instructions in Gentoo Developer
Guide][gentoo-dev-guide-remove-pkg], before a package is removed from the
Gentoo repository, it is necessary to ensure that the removal would not break
any dependencies.  If the package being removed is in the list of leaf
packages, then this requirement would be directly satisfied.  Furthermore, the
list of leaf packages is essentially a minimum collection of packages whose
installation would cause every package in the package repository to be
installed.  Should the repository's maintainers want to run an installation
test covering all packages in it, they only need to include the leaf packages
in the arguments to the package manager instead of enumerate potentially
hundreds of packages.  For example, if someone would like to test installation
of every package shown in the graph above, they only need to explicitly specify
`dev-java/kotlin-stdlib-jdk8`, which will cause the package manager to
automatically pull in all packages in the graph as dependencies.

So, how can the list of leaf packages be computed from a dependency graph?  In
this article, I will introduce some general graph algorithms that can be used
for this specialized task, evaluate their performance, and point out how they
can be optimized for this specific problem to run faster.

[gentoo-build-kt-src]: /2021/07/05/gentoo-build-kt-src.html
[wikipedia-graph]: https://en.wikipedia.org/wiki/Graph_(discrete_mathematics)
[wikipedia-directed-graph]: https://en.wikipedia.org/wiki/Directed_graph
[gentoo-dev-guide-remove-pkg]: https://devmanual.gentoo.org/ebuild-maintenance/removal/index.html#removing-a-package

## The Essence of Leaf Package Search

To find out an algorithm that solves a problem, we usually need to first figure
out any **data structures** *S* that are useful for representing all pieces of
information required to solve it and the **properties** *P* of elements in the
problem's solution set.  Then, the problem can be reduced to "find an algorithm
that returns all elements with property *P* in *S*".  For the leaf package
finding problem, the data structure encoding information required to solve it
is obviously the dependency graph, and the property of elements in the solution
set is that the number of packages that depend on it equals zero.

But some details are yet to be fleshed out.  A directed graph is only an
[*abstract data type*][wikipedia-adt] (ADT), which defines the data structure
only at a high and abstract level.  It does not necessarily specify how a
concrete implementation of the data type's should look like.  For instance, a
*list* is an abstract data type, and resizable array and linked list are both
concrete implementations of it.  (In Java, these correspond to the `List`
interface, the `ArrayList` class and the `LinkedList` class.)  The property of
packages being enumerated is also merely a high-level and abstract description:
it indicates nothing pertaining to how the number of packages depending on a
package should be determined.

For the implementation of directed graph, we would use [*adjacency
list*][wikipedia-adj-list] for a dependency graph because it perfectly depicts
how dependencies of packages are declared.  An adjacency list can be
implemented with an associative array (a.k.a. a dictionary or a map) that maps
each vertex to the list of edges going out from it.  In an ebuild (and
similarly, an RPM SPEC, a PKGBUILD, or a package definition file for most other
package managers), the package's *dependency specifications* are listed in its
`*DEPEND` variables.  If we view an ebuild as a vertex and a dependency
specification as one of its *outgoing edges*, then a whole ebuild repository
can be viewed as an adjacency list.

```bash
# A snippet of openjdk-bin-8.292_p10.ebuild
RDEPEND="
	>=sys-apps/baselayout-java-0.1.0-r1
	kernel_linux? (
		media-libs/fontconfig:1.0
		media-libs/freetype:2
		...
		sys-libs/zlib
		...
	)
"
```

```bash
# A snippet of freetype-2.10.4.ebuild
BDEPEND="
	virtual/pkgconfig
"
```

```python
# A possible internal representation of an adjacency list in Python syntax
dep_graph = {
    "dev-java/openjdk-bin:8": [
        "sys-apps/baselayout-java",
        "media-libs/fontconfig:1.0",
        "media-libs/freetype:2",
        "sys-libs/zlib"
    ],
    "media-libs/freetype:2": [
        "virtual/pkgconfig"
    ]
}
```

For the property of solution set's members, we can use the *in-degree* of a
vertex in a directed graph as the number of packages depending on the package
represented by the vertex.  The in-degree of a vertex is defined as the number
of the vertex's *incoming edges*, i.e. the number of edges pointing to the
vertex.  Because edges in a dependency graph are drawn in the direction from
the consumer to the dependency provider, having an incoming edge means having a
reverse dependency.  Whether a vertex's in-degree is equal to zero is
equivalent to whether the package represented by the vertex has no reverse
dependencies.

So, the concrete implementation of the dependency graph data structure has been
chosen to be an adjacency list based on an associative array, and the property
of every element in the solution set of the leaf package search problem is that
the element vertex's in-degree is zero.  We have successfully reduced this
problem to another problem, which is to find out all vertices with zero
in-degree in an adjacency list.  Does this sound like a problem that can
already be solved by an existing algorithm?

[wikipedia-adt]: https://en.wikipedia.org/wiki/Abstract_data_type
[wikipedia-adj-list]: https://en.wikipedia.org/wiki/Adjacency_list

## In-degree Calculation Algorithms for an Adjacency List

Indeed, we have algorithms for computing the in-degree of each vertex in an
adjacency list at our disposal.  We can use such an algorithm to get each
vertex's in-degree, and if the in-degree is zero, then the vertex will be added
to the solution set.  The pseudocode for this procedure is:

```python
def solve():
    result = []
    for vertex in dep_graph:
        if in_degree_of(vertex) == 0:
            result.append(vertex)
    return result
```

A vertex's in-degree can be trivially found by counting the number of edges
pointing to it.  This results in an algorithm like the following:

```python
def solve():
    result = []
    for vertex in dep_graph:
        in_degree = 0
        for edge in dep_graph:
            if edge.end == vertex:
                in_degree += 1
        if in_degree == 0:
            result.append(vertex)
    return result
```

This algorithm's time complexity is [*O*][wikipedia-big-o](\|*V*\|\|*E*\|),
where \|*V*\| represents the number of vertices, and \|*E*\| represents the
number of edges.  This means that the algorithm's runtime is approximately a
function of the number of vertices times the number of edges.

There exists a more scalable algorithm whose time complexity is just
*O*(\|*V*\| + \|*E*\|).  Instead of first iterate over all vertices, this
algorithm will just go through all edges and bookkeep the number of times each
vertex is pointed by an edge.  At the end of this process, an associative array
containing every vertex and its in-degree will be created, and the set of
vertices whose in-degree is zero can be obtained simply by filtering elements
in the associative array.

```python
def solve():
    # Initialize the associative array for vertices' in-degrees
    in_degrees = {}
    for vertex in dep_graph:
        in_degrees[vertex] = 0

    for edge in dep_graph:
        in_degrees[edge.end] += 1

    result = []
    for vertex in dep_graph:
        if in_degrees[vertex] == 0:
            result.append(vertex)
    return result
```

There is not any nested `for` loop in this algorithm's code; the three `for`
loops' running time are *O*(\|*V*\|), *O*(\|*E*\|) and *O*(\|*V*\|) are
respectively, so the overall running time of the algorithm is a function of the
number of vertices plus the number of edges, hence *O*(\|*V*\| + \|*E*\|).  In
practice, while the size of the graph goes up as the vertices and edges
increase in quantity, \|*V*\| + \|*E*\| always grows slower than
\|*V*\|\|*E*\|, so this second algorithm is more scalable than the first one.

[wikipedia-big-o]: https://en.wikipedia.org/wiki/Big_O_notation

## Optimization Specifically for Leaf Package Search

In the problem of searching for leaf packages in a package repository, we only
care about whether a package has no reverse dependencies or not.  In other
words, for any algorithms we would use to solve this problem, we are only
interested in whether a vertex's in-degree is zero.  In case it is not zero, we
would not care about the specific value of the in-degree at all.  This means,
as long as we can prove that a vertex's in-degree is non-zero any time when the
algorithm is being run, we can stop processing that vertex to save time.

This makes it possible to perform an optimization on the first algorithm
introduced in the previous section.  The first algorithm has an outer `for`
loop that iterates over every vertex and an inner loop which goes through every
edge.  In the inner loop, it tests if the edge points to the vertex, and if the
test result is positive, then we can conclude that the vertex's in-degree
cannot be positive since there exists an edge that points to it.  Thus, the
algorithm can break the inner loop immediately to move on to the next vertex
earlier.

```python
def solve():
    result = []
    for vertex in dep_graph:
        zero_in_degree = True
        for edge in dep_graph:
            if edge.end == vertex:
                zero_in_degree = False
                break
        if zero_in_degree:
            result.append(vertex)
    return result
```

Under the worst-case scenario for this algorithm, where the entire set of edges
have to be traversed before an edge pointing to a vertex can be found, the time
complexity of this optimized version of the algorithm is still
*O*(\|*V*\|\|*E*\|).  However, if for every vertex, the first edge processed by
the inner `for` loop points to it, then the inner loop always breaks after only
one iteration, resulting in the best-case scenario for this algorithm, where
the time complexity is *O*(\|*V*\|) instead, even better than *O*(\|*V*\| +
\|*E*\|) in terms of scalability.  To summarize, this optimized version of the
first algorithm will never perform worse than the unoptimized version, and it
might even outperform the second algorithm, which the unoptimized version would
fail to do, when the size of the graph being processed grows.

On the other hand, the second algorithm cannot be optimized in a similar way.
In the second algorithm, we cannot prove that the in-degree is zero for any
vertex until we have finished processing all edges in the dependency graph.
Even if the algorithm has discovered some vertices whose in-degree is non-zero,
it would be impractical to skip processing any more edges pointing to those
vertices.  Edges in an adjacency list are indexed based on their starting
vertex, so to iterate over all edges in the graph, we would actually need to
loop through every vertex and then go through the edges starting from it.  The
vertices traversed by the outer loop are the starting vertices of the edges in
the inner loop rather than the ending vertices of them, so there is no loop to
break early in the second algorithm.

```python
# The actual procedure for looping through every edge in an adjacency list
for vertex in dep_graph:
    for edge in dep_graph[vertex]:
        in_degrees[edge.end] += 1
```

But still, we can retrofit the second algorithm's pseudocode so it uses
booleans to indicate whether or not a vertex's in-degree is zero to make it
look similar to the code for the optimized version of the first algorithm.  The
`for edge in dep_graph` loop is replaced by the nested loops over all vertices
and their outgoing edges, but they are effectively equivalent.

```python
def solve():
    # Initialize the associative array that stores
    # whether each vertex's in-degree is zero
    zero_in_degree = {}
    for vertex in dep_graph:
        zero_in_degree[vertex] = True

    for vertex in dep_graph:
        for edge in dep_graph[vertex]:
            zero_in_degree[edge.end] = False

    result = []
    for vertex in dep_graph:
        if zero_in_degree[vertex]:
            result.append(vertex)
    return result
```

## Translation from Pseudocode to Executable Program

Having pseudocode that describes how the algorithms should be programmed is
great, but after all, pseudocode is not runnable program code, so the actual
code for the algorithms still needs to be written.  In particular, many
operations whose details were abstracted away in the pseudocode need to be
implemented.  In the pseudocode snippets above, some questions about the
implementation details are unanswered.  How should we get the vertices and
edges in the dependency graph?  How can we tell if an edge in the dependency
graph points to a vertex?

Because in the problem of searching for leaf packages, the vertices are the
packages and the edges are the dependency relationships, we can translate these
questions into problems for our specific context.  Getting the vertices and
edges in the dependency graph is equivalent to obtaining a list of all packages
and all dependency relationships within a repository; testing whether an edge
points to a vertex is essentially querying if a package meets a dependency
specification defined by another package.  Now, we just need to find out the
tools for doing these tasks.

In Portage, there exists utilities like `portageq` that can print all ebuilds
in a repository, and `equery` which can show all dependencies of an ebuild and
list all ebuilds that match an atom.  We can first use `portageq --no-filters
--repo <repo>` to get all vertices, then for each vertex,
`equery depgraph -MUl <atom>` can be used to get a list of its outgoing edges.
Iterating over all outgoing edges of every vertex is effectively iterating over
all edges in the dependency graph.  `equery depgraph` gives the raw dependency
specification atom for each dependency (e.g. `>=dev-java/java-config-2.2.0-r3`)
in its output, and whether an ebuild meets a dependency specification can be
tested by looking for its occurrences in the output of command
`equery list -op <atom>`.  This can be used to find if an edge points to a
vertex.

{% include asciinema-player.html name="list-ebuilds.cast" poster="npt:5.2" %}

{% include asciinema-player.html name="get-deps.cast" poster="npt:7.7" %}

{% include asciinema-player.html name="match-atom.cast" poster="npt:7.4" %}

Because both calling external programs and more sophisticated data structures
such as associative arrays are required to implement the algorithms, I chose
Python, a programming language I know that can be used to complete both tasks
easily, to write the program.  The following code implements the second leaf
package search algorithm.  There are a few things to note here:

1. The dependency graph is never created or re-created in this Python program.
   As mentioned above, `portageq` and `equery` already provide functionalities
   required for getting the vertices and edges, so the program use the
   information provided by those utilities as a logical dependency graph.

2. Parallelism is used for the iteration done by the second `for` loop in the
   pseudocode for the second algorithm.  The only data structure that might be
   concurrently written to is the `zero_in_degree` dictionary, and the `dict`
   data type [is thread safe][python-dict-thread-safety], at least when the
   CPython interpreter is used, so the iteration can be safely parallelized.

```python
import concurrent.futures
import os
import re
import subprocess
import sys


def main() -> None:
    if len(sys.argv) > 1:
        repo = sys.argv[1]
    else:
        repo = 'gentoo'
    zero_in_degree = create_ebuild_dict(repo)
    with concurrent.futures.ThreadPoolExecutor(max_workers=os.cpu_count()) \
            as executor:
        for ebuild in zero_in_degree:
            # Let the executor run function call
            # update_for_deps_of(ebuild, zero_in_degree)
            executor.submit(update_for_deps_of, ebuild, zero_in_degree)
    # Print leaf ebuilds to standard output
    for ebuild in zero_in_degree:
        if zero_in_degree[ebuild]:
            print(ebuild)


def create_ebuild_dict(repo: str) -> dict:
    """
    Create a dictionary with all ebuilds in the specified repository as keys
    that maps each key to a boolean value indicating whether it is a leaf
    ebuild with zero in-degree.
    """
    zero_in_degree = {}
    proc = subprocess.run(f'portageq --no-filters --repo {repo}',
                          capture_output=True, text=True,
                          shell=True, check=True)
    ebuilds = proc.stdout.splitlines()
    for ebuild in ebuilds:
        zero_in_degree[ebuild] = True
    return zero_in_degree


def update_for_deps_of(ebuild: str, zero_in_degree: dict) -> None:
    """
    For ebuilds that can be pulled as the specified ebuild's dependencies,
    update the boolean value for them in the given dictionary accordingly.
    """

    def get_dep_atoms() -> list:
        """
        Return a list of all dependency specification atoms.
        """
        dep_atoms = []
        equery_dep_atom_pattern = re.compile(r'\(.+/.+\)')
        proc = subprocess.run(f'equery -CN depgraph -MUl {ebuild}',
                              capture_output=True, text=True, shell=True)
        out_lines = proc.stdout.splitlines()
        for line in out_lines:
            dep_atom_match = equery_dep_atom_pattern.findall(line)
            dep_atom = [dep.strip('()') for dep in dep_atom_match]
            dep_atoms.extend(dep_atom)
        return dep_atoms

    def find_matching_ebuilds(atom: str) -> list:
        """
        Return a list of ebuilds that satisfy an atom.
        """
        proc = subprocess.run(f"equery list -op -F '$cpv' '{atom}'",
                              capture_output=True, text=True, shell=True)
        return proc.stdout.splitlines()

    print(f"Processing {ebuild} ...", file=sys.stderr)

    # Get dependency specifications in the ebuild;
    # equivalent to dep_graph[ebuild] in the examples above
    dep_atoms = get_dep_atoms()

    # Convert list of atoms to list of ebuilds that satisfy them
    dep_ebuilds = []
    for dep_atom in dep_atoms:
        dep_ebuilds.extend(find_matching_ebuilds(dep_atom))

    # Register dependency ebuilds as non-leaves
    for dep_ebuild in dep_ebuilds:
        # An ebuild in an overlay might depend on ebuilds from ::gentoo and/or
        # other repositories, but we only care about ebuilds in the dictionary
        # passed to this function
        if dep_ebuild in zero_in_degree:
            zero_in_degree[dep_ebuild] = False


if __name__ == '__main__':
    main()
```

Whereas for the first algorithm, it would be even easier to implement with the
help of the [`pquery`][pkgcore-pquery] program from
[pkgcore][gentoo-wiki-pkgcore], an alternative package manager for Gentoo.
`pquery` has a `--restrict-revdep` option that can be used for getting an
ebuild's reverse dependencies directly, so we would no longer need to write our
own algorithm for finding any incoming edges of a vertex.  It also has
`--first` option that will make the `pquery` process exit immediately when a
reverse dependency is found, just like what the optimized version of the first
algorithm would do.

```python
# In the main function, the call to executor.submit should be changed to
#   executor.submit(update_for, ebuild, zero_in_degree, repo)

# The rest is the same as the previous code snippet


def update_for(ebuild: str, zero_in_degree: dict, repo: str) -> None:
    """
    Update the boolean value for the specified ebuild in the given dictionary.
    Reverse dependencies of the ebuild will be searched in the specified
    repository only.
    """
    print(f"Processing {ebuild} ...", file=sys.stderr)
    proc = subprocess.run(f'pquery --first --restrict-revdep ={ebuild} '
                          f'--repo {repo} --raw --unfiltered',
                          capture_output=True, text=True, shell=True)
    zero_in_degree[ebuild] = len(proc.stdout) == 0
```

[python-dict-thread-safety]: https://docs.python.org/3/glossary.html#term-global-interpreter-lock
[pkgcore-pquery]: https://pkgcore.github.io/pkgcore/man/pquery.html
[gentoo-wiki-pkgcore]: https://wiki.gentoo.org/wiki/Pkgcore
