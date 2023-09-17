# DecqedMesher.jl

[![Build Status](https://github.com/richarddengli/DecqedMesher/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/richarddengli/DecqedMesher/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/richarddengli/DecqedMesher/branch/main/graph/badge.svg)](https://codecov.io/gh/richarddengli/DecqedMesher)

``DecqedMesher.jl`` is a Julia package for constructing primal and dual mesh objects present in the discrete exterior calculus formulation of quantum electrodynamics (DEC-QED). Eventually, ``DecqedMesher.jl`` will be integrated fully into the larger [``DEC-QED computational toolbox``](https://github.com/dnpham23/DEC-QED). Both ``DecqedMesher.jl`` and ``DEC-QED computational toolbox`` are under active development.

A detailed presentation of DEC-QED, its applications for modeling electromagnetic systems, and some results using the mesher within the computational toolbox are contained in the following references:
- [Flux-based three-dimensional electrodynamic modeling approach to superconducting circuits and materials](https://journals.aps.org/pra/abstract/10.1103/PhysRevA.107.053704)
- [Spectral Theory for Non-linear Superconducting Microwave Systems: Extracting Relaxation Rates and Mode Hybridization](https://arxiv.org/abs/2309.03435)

# Installation
`DecqedMesher.jl` is not currently registered in the official [Julia package registry](https://github.com/JuliaRegistries/General), but installation is simple and follows the directions listed [here](https://pkgdocs.julialang.org/v1/environments/#Using-someone-else's-project).

In the command prompt, navigate to the desired directory (via `cd`), and then clone the package via:
```
(shell) git clone https://github.com/richarddengli/DecqedMesher.jl.git
```

Start the Julia REPL and then enter into Pkg REPL (by typing `]`). Then call:
```
(@v1.9) pkg> activate DecqedMesher.jl
```

and also call:
```
(DecqedMesher) pkg> instantiate
```
to activate the package and prepare the project environment.

# Usage
The 2 user-facing functions in `DecqedMesher.jl` are `complete_dualmesh()` and `complete_dualmesh_2D()`, which take in as input a `.msh` file representing 3D and 2D meshes, respectively. Both functions return a length 4 tuple, containing the following information corresponding to the `.msh` file:
1. dual mesh information
2. primal mesh information
3. physical group names
4. elementary entities

In a `.jl` file, import `DecqedMesher.jl`:
```julia
.using DecqedMesher
```

To construct the dual mesh of a 3D mesh, use `complete_dualmesh("[/path/to/mesh]")`. For example, for a mesh file named `3D_testmesh.msh` in the current directory, use:
```julia
dualmesh, primalmesh, physicalnames_dict, all_entities_struct = complete_dualmesh("/3D_testmesh.msh")
```

Similarly, to construct the dual mesh of a 2D mesh, use `complete_dualmesh_2D("[/path/to/mesh]")`. For example, for a mesh file named `2D_testmesh.msh` in the current directory, use:
```julia
dualmesh, primalmesh, physicalnames_dict, all_entities_struct = complete_dualmesh("/3D_testmesh.msh")
```

# Authors and Acknowledgements
Richard Li, Dzung Pham, Nick Bronn, Thomas McConkey, Olivia Lanes, Hakan Türeci

The development for ``DecqedMesher`` started during the 2022 Undergraduate Research Internship at IBM and Princeton (QURIP), as part of a collaboration between the following groups:
- Türeci Group, Department of Electrical & Computer Engineering, Princeton University
- Qiskit Community Team, IBM Quantum

We also thank Abeer Vaishnav, Nathalie de Leon, Hwajung Kang, and the rest of the 2022 QURIP cohort for their support.
