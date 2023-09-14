# DecqedMesher

[![Build Status](https://github.com/richarddengli/DecqedMesher/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/richarddengli/DecqedMesher/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/richarddengli/DecqedMesher/branch/main/graph/badge.svg)](https://codecov.io/gh/richarddengli/DecqedMesher)

``DecqedMesher`` is a Julia package for constructing primal and dual mesh objects present in the discrete exterior calculus formulation of quantum electrodynamics (DEC-QED). Eventually, ``DecqedMesher`` will be integrated into the larger [``DEC-QED computational toolbox``](https://github.com/dnpham23/DEC-QED). Both ``DecqedMesher`` and ``DEC-QED computational toolbox`` are under active development.

A detailed presentation of DEC-QED, its applications for modeling electromagnetic systems, and preliminary results using the computational toolbox are contained in the following references:
- [Flux-based three-dimensional electrodynamic modeling approach to superconducting circuits and materials](https://journals.aps.org/pra/abstract/10.1103/PhysRevA.107.053704)
- [Spectral Theory for Non-linear Superconducting Microwave Systems: Extracting Relaxation Rates and Mode Hybridization](https://arxiv.org/abs/2309.03435)

# Installation
Dependencies: 
StaticArrays, Combinatorics, LinearAlgebra, (Revise)

# Usage


# Authors and Acknowledgements
Richard Li, Dzung Pham, Nick Bronn, Thomas McConkey, Olivia Lanes, Hakan Türeci

The development for ``DecqedMesher`` started during the 2022 Undergraduate Research Internship at IBM and Princeton (QURIP), as part of a collaboration between the following groups:
- Türeci Group, Department of Electrical & Computer Engineering, Princeton University
- Qiskit Community Team, IBM Quantum

We also thank Abeer Vaishnav, Nathalie de Leon, Hwajung Kang, and the rest of the 2022 QURIP cohort for their support.
