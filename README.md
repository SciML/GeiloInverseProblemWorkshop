# Geilo Inverse Problem Workshop

This is a collection of lecture notes from the [Gelio Winter School 2025 on Solving Inverse Problems](https://www.sintef.no/projectweb/geilowinterschool/2025-inverse-problems/). It's a collection of Julia scripts and tutorials for handling inverse problems, along with slides going into detail on some of the discussion topics.

## Table of Contents

* [Lecture 1: Introduction to Solving Inverse Problems with Julia](https://github.com/SciML/GeiloInverseProblemWorkshop/blob/main/Lecture1_Solving_Inverse_Problems_in_Julia.jl) [HTML](https://sciml.github.io/GeiloInverseProblemWorkshop/Lecture1_Solving_Inverse_Problems_in_Julia)
* [Lecture 2 and 3: Differentiating Simulators: Automatic Differentiation and Adjoints on ODEs, PDEs, and other Nonlinear Systems]()
    * Lecture Notes: [Forward-Mode Automatic Differentiation (AD) via High Dimensional Algebras](https://book.sciml.ai/notes/08-Forward-Mode_Automatic_Differentiation_(AD)_via_High_Dimensional_Algebras/)
    * Lecture Notes: [Differentiable Programming and Neural Differential Equations](https://book.sciml.ai/notes/11-Differentiable_Programming_and_Neural_Differential_Equations/)
    * Live Lecture Notes: [PDF](https://github.com/SciML/GeiloInverseProblemWorkshop/blob/main/Geilo.pdf) [Lyx](https://github.com/SciML/GeiloInverseProblemWorkshop/blob/main/geilo_workshop.lyx) [TeX](https://github.com/SciML/GeiloInverseProblemWorkshop/blob/main/geilo_workshop.tex)
* [Lecture 4: Functional Inverse Problems, Scientific Machine Learning, and Differentiation in the Real World](https://docs.google.com/presentation/d/1Ksdyp_Cs5fzCk3re4I1thFrWcH1fxSYBT2MxET4xtpo/edit?usp=sharing)

## Using Pluto Notebooks

The notes are contained in Pluto notebooks. To open these notebooks, use a valid Julia installation and do:

```julia
using Pluto
Pluto.run()
```

See the rendered version of the first notebook if you need any help getting Julia installed and setup.