### A Pluto.jl notebook ###
# v0.20.4

using Markdown
using InteractiveUtils

# ╔═╡ 885f5685-5239-42aa-942c-2b9bdf7df220
# For most simplicity, you can `using OrdinaryDiffEq`
# Or `using DifferentialEquations`
# This is done to cut the install size.
using OrdinaryDiffEqTsit5

# ╔═╡ f5c9ea83-6dba-4848-8340-1a8c772bd941
using Plots

# ╔═╡ e13c7d4f-4cdb-43d5-9f77-33401cb501e2
# Can simply do `using NonlinearSolve`
# We are pulling in the subset of just the first order methods (Newton methods)
# To decrease the installation and load times.
using NonlinearSolveFirstOrder

# ╔═╡ c7193526-d32f-4f2a-95aa-09e98b88b30b
using Optimization

# ╔═╡ 36985121-9fe5-4961-9ec2-3f5ee57cfaa1
using Zygote

# ╔═╡ ba06d75c-9f29-48c0-9db3-b3822568bf39
using StableRNGs # Make the RNG consistent across Julia versions

# ╔═╡ 6f04db2c-3c38-4244-8d70-22a15a7dd72e
using LinearAlgebra # norm is defined in the LinearAlgebra Base library

# ╔═╡ 8a3108d7-0bec-40d1-b5a9-e4deec2f88c0
using SciMLSensitivity

# ╔═╡ f860ea33-eb7c-43f6-a1b5-859b0b33d367
using OptimizationBBO

# ╔═╡ 6402bee8-18dd-4c1b-8616-d57030310503
using Turing

# ╔═╡ b122c127-53aa-45d5-997c-4fa2cb84d2ff
using StatsPlots

# ╔═╡ 45dc0462-d63c-11ef-0f62-e5d029618cc1
md"""
# Solving Inverse Problems in Julia: Introduction to Julia's SciML from Scratch

In these notes we will showcase how to solve inverse problems in Julia for
dynamic and steady state models. We will start all the way from scratch,
showing you how to first use the forward modeling tools NonlinearSolve.jl
and DifferentialEquations.jl for solving nonlinear systems, and then show how
to incorporate automatic differentiation, Optimization.jl and 
SciMLSensitivity.jl for optimizing complicated cost functions.

**No prior Julia experience necessary**

In particular we will show:

1. How to get started with Julia.
2. How to build models (differential equation, nonlinear system, and optimization) using Julia's SciML tools.
3. How to define and solve inverse problems over such models, both using optimization and Bayesian techniques.
4. What some of the problems are with the basic methods for solving inverse problems, setting up the next lectures which dive deeper in to the techniques to improve the robustness.

Thus this lecture will serve as a general template that can apply to any inverse problem. By the end of this lecture, you will feel like you could solve any inverse problem, but you will also understand that there might be some deeper details needed for solving the hard ones. The future lectures will thus build upon this template to show how to improve the robustness of certain portions for the cases where the problems get harder.
"""

# ╔═╡ ffcd2d10-4c6c-4eb9-a2ec-fbc1c0596838
md"""
## Getting Started with Julia

### Installing Julia

If you have never used Julia before, then the first thing is to get started with Julia! There are two recommended ways to do this. The simplest is to go to the Julia webpage [https://julialang.org/downloads/](https://julialang.org/downloads/) and download the binary. There will be a latest current release binary for every operating system: pop that in and you are good to go. 

Alternatively, you can download Julia via juliaup. Juliaup is a system that makes controlling and updating Julia very simple, and thus this is what we would recommend for most users. To download Juliaup, you can:

1. On Windows, download julia from the Julia store
2. On MacOSX, Linux, or FreeBSD, you can use the command `curl -fsSL https://install.julialang.org | sh`

Once juliaup is installed, you can manage your Julia installation from the terminal. The main commands to know are:

1. `juliaup help`: shows all of the commands
2. `juliaup update`: updates your Julia version
3. `juliaup default release`: defaults your Julia to use the latest released version.
4. `juliaup default lts`: defaults your Julia to use the long-term stable (LTS) release, currently 1.10.x.

We recommend that you stick to the current default `release`, though production scenarios may want to use LTS. Either way, once this is setup you can just use the command `julia` in your terminal and it should pop right up.

### Using the Package Manager

To use the package manager in Julia, simply hit `]`. You will see your terminal marker change to a blue `pkg>`. The main commands to know in the package manager mode are:

1. `help`: shows all of the commands
2. `st`: show all of your currently installed packages
3. `add PackageX`: adds package X
4. `rm PackageX`: removes package X
5. `activate MyEnv`: activates an environment
6. `instantiate .`: instantiates an environment at a given point.

You can also use the Julia Pkg.jl package, for example `using Pkg; Pkg.add("MyPackage")`.

### Using Pluto Notebooks

Pluto notebooks, such as the one these lecture notes are written in, are a notebook system designed specifically for Julia. Unlike Jupyter notebooks (which, reminder stands for Julia Python R notebooks!), Pluto notebooks are made with an emphasis on reproducible science. As such, it fixes a lot of the issues that arise with the irreproducibility commonly complained about with Jupyter notebooks, such as:

1. Being environment dependent: Jupyter notebook environments depend on your current installation and packages. Pluto notebooks tie the package management into the file. This means that a Pluto notebook is its own package environment, keeps track of package versions, and when opened will automatically install all of the packages to the right version to make sure it fully reproduces on the new computer.
2. Being run-order dependent: in a Jupyter notebook the user is in control of execution and may evaluate blocks out of order. This means that if you pick up a Jupyter notebook and have all of the same packages you can run the notebook from top to bottom and might not get the same answer as what was previously rendered. This is not possible with Pluto (except for differences in psudorandom numbers of course), as Pluto is a fully reactive execution engine, and thus any change in the entire notebook ensures that all downstream cells are automatically updated. This means it has more limitations than a normal Julia program, for example every name can only be used exactly once, but it means that every Pluto notebook is always guaranteed to be up to date.

Thus for reproducibility we will be using Pluto notebooks for these notes.

To get started with Pluto, simply install Pluto (`using Pkg; Pkg.add("Pluto")`) and then get it started: `using Pluto; Pluto.run()`. This will open the Pluto runner in your browser, and you can put the URL for a Pluto notebook in to open it on your computer. When you click edit it will make the document then live.

Note: when you first make this notebook live, it will download all of the required packages. This notebook has a lot of things in there so that might take awhile! Be patient as it's installing ~200 big packages, but they will be reused for the later lectures.
"""

# ╔═╡ 6d29e44b-3d70-4700-ad53-9e75df7ced0c
md"""
## Getting Started with Forward Modeling: NonlinearSolve.jl and DifferentialEquations.jl

Before showing how to build inverse models, we need to show how to build forward models. Building forward models in scientific applications usually comes down to one of two forms: a nonlinear system or a system of ordinary differential equations. While there are many other types, this covers a large swath of cases, and also covers extra cases since for example the semi-discretization of a partial differential equation also hits these cases, and thus we will stick to this set.

### Understanding the Relevant Parts of Julia's Package Ecosystem

The open source organization which builds the common numerical tools used throughout Julia is known as SciML. See its website at SciML.ai and its complete documentation at docs.sciml.ai. If you are new to Julia, you might immediately recognize that SciML has a larger scope than packages that you're used to since it's a collection of 200 packages, but a rough way to understand SciML is:

1. It's like Python's SciPy, covering the core numerical utilities like solving equations and building interpolations.
2. It's like PyTorch/Jax, in that it gives code that is compatible with automatic differentiation and can connect to machine learning libraries (we will use this in the inverse problem section), and its tooling is able to be used with GPUs.
3. It's like C++/Fortran core codes (SUNDIALS, MINPACK, etc.), where the methods are actually implemented in the libraries and there are many unique methods in the Julia SciML libraries that are not implemented anywhere else.
4. It's like PETSc/Trillinos in that there are utilities and interfaces covering each major domain, with some tooling written specifically for the system and other parts wrapping commonly used C++/Fortran methods to make them easily available. Additionally, the tooling is HPC-compatible with compatability with MPI and other distributed tooling.

Thus one simple way to explain it is, if SciPy was instead fully written in Python while also being efficient, and that code was fully compatible with automatic differentiation and machine learning libraries, meaning there are no "machine learning library specific packages" for similar functionality and everything is centralized to this one set.
"""

# ╔═╡ 51c67a4d-f49a-4bb5-a1c2-361ea0e8f20e
md"""
### Using DifferentialEquations.jl

DifferentialEquations.jl is a huge set of solvers (documentation: [https://docs.sciml.ai/DiffEqDocs/stable/](https://docs.sciml.ai/DiffEqDocs/stable/)), ~300 methods last time it was counted, with a wide range of tooling from 16th order symplectic integrators to SSP Runge-Kutta methods specifically designed for hyperbolic conservation laws. As such, it most likely has everything that you need, but you most likely don't need all of it. 

As such, for the purpose of keeping this notebook light we will simply pull in the subset of solvers which we plan to use. The documentation of the solver choices can be found at [https://docs.sciml.ai/DiffEqDocs/stable/solvers/ode_solve/](https://docs.sciml.ai/DiffEqDocs/stable/solvers/ode_solve/) and detailed documentation of the OrdinaryDiffEq subpackage structure can be found at [https://docs.sciml.ai/OrdinaryDiffEq/stable/](https://docs.sciml.ai/OrdinaryDiffEq/stable/). For your work, you will likely simply want to `using OrdinaryDiffEq`, which covers most of the "main methods". In this notebook we will specifically `using OrdinaryDiffEqTsit5` to only use/install the standard 5th order explicit Runge-Kutta method for this set of notes.
"""

# ╔═╡ ca453691-227c-44f1-8b48-8fb42c42d481
md"""
Now let's build our first differential equation. If you have not read the introduction tutorial in the DifferentialEquations.jl documentation, it is highly recommended. You can find the introduction tutorial at [https://docs.sciml.ai/DiffEqDocs/stable/getting_started/](https://docs.sciml.ai/DiffEqDocs/stable/getting_started/). Instead of using one of the examples from there, we will use the Lotka-Volterra ODE as our example as it's a nice example for demonstrating inverse problems as well.

The Lotka-Volterra system is defined as:

```math
\begin{align}
\frac{dx}{dt} &= \alpha x - \beta x y \\
\frac{dy}{dt} &= -\gamma y + \delta x y
\end{align}
```

with initial conditions ``x(0) = 1`` and ``y(0) = 1``, with parameters ``\alpha = 1``, ``\beta = 1.5``, ``\gamma = 3``, and ``\delta = 1``. We define the ODE system by first defining a function `f` that computes the derivative:
"""

# ╔═╡ 34efa390-0d6d-48dd-b08b-0c1bc391ffc2
md"""
We now define an ODEProblem according to the documentation. In Julia you can get the documentation for how to do things by using the help command `?`:
"""

# ╔═╡ 448dd6ac-0d7f-4c1f-a9ce-3f9a586951c1
function lotka_volterra!(du, u, p, t)
    x, y = u
    α, β, δ, γ = p
    du[1] = dx = α * x - β * x * y
    du[2] = dy = -δ * y + γ * x * y
end

# ╔═╡ 760b16ea-410f-4f46-ae44-f859de9b75e3
lotka_u0 = [1.0,1.0]

# ╔═╡ 27059e1a-5f0c-40ac-85ea-ff6ad8d7b68c
lotka_p = [1.0, 1.5, 3.0, 1.0]

# ╔═╡ 9ff83b76-86dd-4520-ac20-df1eb30cc1dd
lotka_tspan = (0.0, 10.0)

# ╔═╡ 1245a924-10c8-4170-b3a9-ce025c54319d
lotkaprob = ODEProblem(lotka_volterra!, lotka_u0, lotka_tspan,  lotka_p)

# ╔═╡ d2ac7dbe-a47a-4b50-a796-a04462f410cc
md"""
Now let's test out our Lotka-Volterra system and see if it gives the classic periodic pattern. We will use the Plots.jl system to show the results:
"""

# ╔═╡ 9ad843f4-0f54-4a4f-a83d-b29bedad37c3
lotka_sol = solve(lotkaprob, Tsit5())

# ╔═╡ 1e27f7dd-9d41-4fe9-b823-0013ef35927d
plot(lotka_sol)

# ╔═╡ 835c2922-37de-4e1b-b9ba-05a729eca801
plot(lotka_sol, idxs = (1,2))

# ╔═╡ 2ab07370-1cf4-41db-b197-295d4cfd6a68
md"""
We can see that we get a periodic system from both the timeseries solution and the phase plot. 

There is much more that can be said about solving differential equations, but let's leave it here for now and move onto the next part!
"""

# ╔═╡ cba31d00-0a4a-4dab-aada-507ec1244bb1
md"""

### Solving Nonlinear Systems with NonlinearSolve.jl

"""

# ╔═╡ e921a8b2-4fe8-41cb-8463-6297a7e1646d
md"""
NonlinearSolve.jl is similar to what you'd find with for example MATLAB's `fzero` or SciPy's `root` function. It has many improvements in terms of performance and robustness, see a full write up on arxiv at [https://arxiv.org/abs/2403.16341](https://arxiv.org/abs/2403.16341). Since many partial differential equaitions discretize into a nonlinear system of algebraic equations, we will showcase how to use this utility to define nonlinear systems and solve inverse problems over them.

First let's take a model which we wish to solve. Let's say we wish to solve the nonlinear system:

```math
\begin{align}
0 = A*u^2 - b
\end{align}
```

where ``A = [1.0, 2.0; 3.0, 4.0]`` and ``b = [1.0,2.0]``. We can follow the NonlinearSolve.jl documentation and solve this problem as follows:
"""

# ╔═╡ 17a15fc4-3bc3-4415-aa37-2520750e84a2
function simplenonlinear!(du,u,p)
	A = reshape(@view(p[1:4]), 2, 2)
	b = @view p[5:6]
	du .= A*u.^2 .- b
end

# ╔═╡ 745de76a-d18f-426f-a0e0-4fa318f833dd
md"""
Notice the `.` syntax in that expression. This is the Julia brodcast operator. It means, broadcast/map this operator over the whole array. So `a .* b` is element-wise multiplication, it's mapping the operator `*` over each element. On the other hand, `A*b` is matrix multiplication.

`.=` is the in-place assignment operator. I.e., instead of creating a new vector `du`, this writes to an exisiting vector `du`. Thus as seen before with the ODE, many Julia interfaces are in-place, like C++ and Fortran interfaces, to assign to existing vectors and decrease the memory load on GC. This is a performance thing, if you're interested more in performance see the lecture notes on [Optimizing Serial Code from the SciML Book](https://book.sciml.ai/notes/02-Optimizing_Serial_Code/).

Also note that we have setup `A` and `b` to be written from a parameter vector `p`. This is something we will exploit later for inverse problems.

But okay, now let's solve this system using a Trust-Region Newton method:
"""

# ╔═╡ 14f88d60-783b-4757-b20e-d3ada57f16f7
simpnon_u0 = [1.0,1.0]

# ╔═╡ bd4b5bc1-d7c2-4408-9f35-ac69d75c16fe
simpnon_p = [1.0,2.0,3.0,4.0,1.0,2.0]

# ╔═╡ 6e709ba7-725d-4085-8078-d813766086e0
simpnonprob = NonlinearProblem(simplenonlinear!, simpnon_u0, simpnon_p)

# ╔═╡ dc408f51-ce63-44a8-98fb-a7ccd0dedcc0
simpnonsol = solve(simpnonprob, TrustRegion())

# ╔═╡ 0c888118-c40b-43e5-9fe8-e3f6d553610c
simpnonsol.u

# ╔═╡ 9a1b4857-8687-47a5-84d9-314149e66f13
simpnonsol.resid

# ╔═╡ c725adf8-4bfa-4046-929f-65dfef8c2309
md"""

### Solving Optimization Problems with Optimization.jl

Before we move onto the inverse problems, we will explain one more forward model, and that's via optimization. Optimization models are models of the form:

```math
u^\ast = \min_u f(u)
```

i.e. find the ``u`` vector that minimizes some function. To demonstrate this, we will use Optimization.jl to find the solution of the function:

```math
f(u,p) = (p_1 - u_1)^2 + p_2 (u_2 - u_1^2)^2
```

where `p = [1.0, 100.0]`. This is done via the following definition
"""

# ╔═╡ 2c247d32-e215-48ac-95df-4c562333309f
simpleoptf(u, p) = (p[1] - u[1])^2 + p[2] * (u[2] - u[1]^2)^2

# ╔═╡ 0a83e463-7180-4f7e-8f93-37165d56aed8
simpleopt_p = [1.0, 100.0]

# ╔═╡ bbe5e86a-0e72-4ce2-aa95-1b80a070b3ac
md"""
For most optimizers we will then need to give them an initial condition. In this case we will just guess the solution [0.0,0.0]:
"""

# ╔═╡ ee4e03a6-1187-4de1-816c-9299debe54ed
simpleopt_u0 = zeros(2)

# ╔═╡ 2ff9c802-5562-4669-8045-d3bf40e42cd2
md"""
Now to perform the optimization with the method we wish to use we will need to endow the function with the ability to calculate derivatives, in particular many optimizers will want gradients. We can do this by telling it to use the Zygote automatic differentiation library for reverse-mode AD. We will go over what automatic differentiation is in future lectures, but for now understand this as a description of how the gradient function should be generated.
"""

# ╔═╡ 9d09b14b-af52-48e2-9c6c-446c398ed422
simpleoptfun = OptimizationFunction(simpleoptf, AutoZygote())

# ╔═╡ eaec431c-e7f3-49a7-a2a2-cb18d464348c
md"""
Now like before we build an OptimizationProblem and choose to solve this with some optimization method:
"""

# ╔═╡ 5e533d0a-5aaa-4e42-a420-fb3b3ccb5060
simpleoptprob = OptimizationProblem(simpleoptfun, simpleopt_u0, simpleopt_p)

# ╔═╡ 8b0256ff-c49c-468c-b140-1416e3e311ab
simpleopt_sol = solve(simpleoptprob, Optimization.LBFGS())

# ╔═╡ 34aa161d-4421-4344-b40f-e25a151a98e2
simpleopt_sol.u

# ╔═╡ f8a4e5ed-684e-4242-adce-9114576cbc68
simpleopt_sol.objective

# ╔═╡ 92c24e7c-deee-4b56-a64d-00748d7fe69a
md"""
We can see that it basically found a solution `[1.0,1.0]` to 13 digits of accuracy.
"""

# ╔═╡ d942a2d0-dc61-4b74-8702-789c54044300
md"""
## Solving Inverse Problems with Optimization

Now that we understand how to write models that can be solved, we will now showcase how to solve a few inverse problems. The most basic way to solve inverse problems is via optimization. In the optimization route, what you do is define a cost function ``C(p)`` which is a function of the parameters ``p`` which you wish to optimize. By definition, this cost functions is defined such that the inverse problem solution, i.e. the optimal parameters for the model ``p^\ast``, are given by:

```math
p^\ast = \min_p C(p)
```

or in otherwords, the parameters `p` which minimize the cost function. This is best explained through examples, so let's show a few simple examples.

### Inverse Problems on Differential Equations: Example via Parameter Estimation to Data

For our first inverse problem, we will solve a classic parameter estimation problem. A parameter estimation problem is generally a problem where you are given data which you want your model to fit, and the goal is to find the parameters of the model which case the model's prediction to best fit the data.

To demonstrate the parameter estimation problem, we will use a "test back" example. A test back example is an example of generating data via a model, so that way we know the true solution, and then see if we can recover the true parameters. To do this, let's create a dataset of the solution at the current values:
"""

# ╔═╡ 134afb44-b726-45d3-a2a0-002a7c433cfb
lotka_data_sol = solve(lotkaprob, Tsit5(), abstol=1e-8, reltol=1e-8, saveat = 0.5)

# ╔═╡ 8bbafc21-3f6b-4bce-9b41-56ba36b6a2b4
md"""
Notice that one major difference from the original solving process is that in this case we made sure to cause the solution to `saveat` every 0.5 points: when solving inverse problems it's paramount that we will have a clear definition on what data we are fitting and at what time points this data is to be found.

Now let's take the solution and turn it into a data matrix:
"""

# ╔═╡ 13a104ee-1af5-47f2-acf1-db5cd32ea37e
lotka_data = Array(lotka_data_sol)

# ╔═╡ 80f79d79-0432-46f9-9734-c598f061e87c
md"""
Let's plot these as scatter points over the original solution:
"""

# ╔═╡ 730d88c9-682b-4377-bae6-3b9e51f4c2d1
plot1 = plot(lotka_sol)

# ╔═╡ b9a8e9e3-f17e-425b-86c8-6e836932735c
scatter!(plot1, lotka_data_sol.t, lotka_data')

# ╔═╡ dbfe82fd-6b79-434e-a0c5-591a9f3990c6
md"""
To make this more realistic, let's add some noise to the data
"""

# ╔═╡ 1f2212b0-d6b3-42e1-8864-8588aacab5c4
rng = StableRNG(100)

# ╔═╡ c07e6522-1c78-491f-bffa-70bf0c11dea5
lotka_data_noisy = abs.(Array(lotka_data_sol) + 0.35randn(rng, size(lotka_data)))

# ╔═╡ a5a3d044-eddc-4c79-bf0f-2d6753a16e07
begin
	plot2 = plot(lotka_sol)
	scatter!(plot2, lotka_data_sol.t, lotka_data_noisy')
end

# ╔═╡ de5354a6-b8cd-4871-b9b3-2bd3be6bee17
md"""
Now to write our loss function, we will need to write a routine that changes our parameters and then re-solves the model with new parameters. We can do this using the `remake` method provided in SciML. This allows you to change a `prob` by only overriding what is changed. Our `remake` and `solve` function then looks like:
"""

# ╔═╡ a6668c04-6b54-45df-951e-4dff659ae152
function lotka_prediction(p; saveat = 0.5)
	_prob = remake(lotkaprob, p = p)
	sol = solve(_prob, Tsit5(); saveat, abstol=1e-8, reltol=1e-8)
end

# ╔═╡ 9723e36d-7ec4-4c0d-bab3-13ee372b7515
plot(lotka_prediction([1.0,2.0,3.0,4.0]))

# ╔═╡ 50f8441b-6a5b-4b3b-8846-29894388bf6f
md"""
A small note: the reason why the lines are so jagged is because we're only saving the solution now at 0.5. When used without `saveat`, the ODE solver returns a continuous solution that satisfies the tolerance and includes an interpolation that gives accurate predictions between solver stepping points. When we change to saveat, it only saves the desired points at high accuracy, but for plotting it still contains a linear interpolation by default. To give a better view of what's going on continuously, we can pass an empty `saveat = ()` for better plots.
"""

# ╔═╡ 10338166-3f7a-4479-9089-1437b8a82a6e
begin
	plot3 = plot(lotka_prediction([1.0,2.0,3.0,4.0], saveat = ()))
	scatter!(plot3, lotka_data_sol.t, lotka_data_noisy')
end

# ╔═╡ d8fd5015-6cdc-4f4f-80eb-b16e21f0e908
md"""
We can see that using the dummy parameters `[1.0,2.0,3.0,4.0]` that we are nowhere close to the data points (i.e. the data generated from the model with `[1.0,1.5,3.0,1.5]`). Our goal is to automatically start from these bad parameters and let a mathematical routine find the correct parameters. We can do this by defining a loss function. What we want is that the line goes through each data point. Thus we want `sol(t) - data(t) = 0`. What we can do is define our loss function to be the sum of the normed differences between every output and every data point:
"""

# ╔═╡ 3d580d10-9fe1-48ff-b563-d7e267205e8c
function lotka_loss(p; noise = true)
	if noise
		norm(Array(lotka_prediction(p)) - lotka_data_noisy)
	else
		norm(Array(lotka_prediction(p)) - lotka_data)
	end
end

# ╔═╡ 981ba39c-6328-4577-bc9a-5574dcc634d9
md"""
This gives us a scalar measurement for "how bad our parameters are". As a check, we should have a minimum of near zero when we have the correct parameters:
"""

# ╔═╡ 5765470f-44a3-4911-9aec-d029ee7f87b3
lotka_realp_loss = lotka_loss([1.0,1.5,3.0,1.0])

# ╔═╡ f71e8884-5829-4346-8bde-43ea1947d7f5
md"""
As a sanity check, let's check the loss function when there is no noise in the data:
"""

# ╔═╡ cb5be726-5287-4519-a199-14a27246726e
norm(Array(lotka_prediction([1.0,1.5,3.0,1.0])) - lotka_data)

# ╔═╡ f38d3cec-65ea-4999-867a-984b23b9fe21
md"""
Thus the reason that the loss value with the real parameters that generated the data is $lotka_realp_loss instead of 0.0 is because of the noise in the data.
"""

# ╔═╡ bed65c9b-cad3-48c2-aac5-5dc201a15558
md"""
Now in order to solve this optimization, i.e. find the `p` that case `lotka_loss` to be minimized, we will define an OptimizationProblem like before. But now in this case we will stack our solvers: i.e. our optimization will be defined where the function we are optimizing is a function that is solving our differential equation. This is done simply by:
"""

# ╔═╡ dba58f1a-6340-4242-8b1a-482dd50e8d11
paramest_fun = OptimizationFunction((p,θ)->lotka_loss(p), AutoZygote())

# ╔═╡ 08389217-2791-469e-ae48-e7efdc0de493
paramest_prob = OptimizationProblem(paramest_fun, [1.0,2.0,3.0,4.0], lb = [0.1, 0.1, 0.1, 0.1], ub = [4.0, 4.0, 4.0, 4.0])

# ╔═╡ 49175b07-6c2e-4a13-86f7-8c5e5047e553
md"""
Notice that we had to pull in the SciMLSensitivity.jl library. If you forgot it, then you would've gotten the error message:

```
Compatibility with reverse-mode automatic differentiation requires SciMLSensitivity.jl.

Please install SciMLSensitivity.jl and do `using SciMLSensitivity`/`import SciMLSensitivity`

for this functionality. For more details, see https://sensitivity.sciml.ai/dev/.
```

This is because this library is required for defining the local sensitivity analysis (i.e. rules for calculating gradients of) the SciML solvers, such as the ODE solver. This will be the topic of the future lectures, but for now just add this and automatic differentiation of the solvers will magically work.
"""

# ╔═╡ 7ad1e21f-2c72-415c-9d9c-c0ee35ab44e6
md"""
Notice here that the state ``u`` of our optimization problem is the ``p`` parameters of our ODE. The parameters of our optimization problem, ``\theta``, would be hyperparmaeters of the optimization. In this case we don't have any so we simply ignore them. But this shows how you could define inverse problems over inverse problems, not a topic we will address in this workshop.

But okay, now like before we use a nonlinear optimizer to solve this problem:
"""

# ╔═╡ e6413dda-3ebb-49c1-9dfb-a340321e86c6
paramestopt_sol = solve(paramest_prob, Optimization.LBFGS())

# ╔═╡ a6c0695e-6c29-4992-b7dd-dcab7aeea3f1
md"""
Note: If you didn't set the tolerance to be lower in the ODE solver, this solve might've been unstable. This is because the accuracy of the solve effects the accuracy of the gradient and thus the stability of the optimization process. This is a mathematical detail that will be discussed in a future lecture of the workshop.

But okay, we got a solution! Let's look at it:
"""

# ╔═╡ a5e5b6bf-1fe9-4462-a5e3-c30bf656a6cd
paramestopt_sol.u

# ╔═╡ f9749dde-697a-40aa-a0e7-47edc8fc778f
paramestopt_sol.objective

# ╔═╡ 08617e66-a04f-464a-a1b1-31ad7d44f491
md"""
Oh wow that's not that great!
"""

# ╔═╡ 68fc5732-e059-44a3-a8d5-3428cb6c36d1
md"""
#### Understanding the Difficulties of Optimization

Let's investigate this a bit. How does the fit look?
"""

# ╔═╡ 099f04f0-8f67-425c-a395-0d2dd20925b1
begin
	plot4 = plot(lotka_prediction(paramestopt_sol.u, saveat = ()))
	scatter!(plot4, lotka_data_sol.t, lotka_data_noisy')
end

# ╔═╡ 598a4615-f77a-4167-9bf1-62aa25218b17
md"""
What happened? Why did it stop there? Is the optimizer bad? To investigate, let's try a different optimizer:
"""

# ╔═╡ 0d3e1592-5535-4c62-a1a2-82fb11109ce4
bboparamest_sol = solve(paramest_prob, BBO_adaptive_de_rand_1_bin_radiuslimited(), maxiters = 10000)

# ╔═╡ b30eb1b1-b355-4f3e-980a-dd98b2d9d1d4
bboparamest_sol.u

# ╔═╡ 764b48c6-8427-4e1d-8ec7-59126a020e71
begin
	plot5 = plot(lotka_prediction(bboparamest_sol.u, saveat = ()))
	scatter!(plot5, lotka_data_sol.t, lotka_data_noisy')
end

# ╔═╡ d1897917-14ae-418a-a1b5-e7d47e58a8dd
md"""
This optimizer got much closer! In fact, if we didn't have noise in the data it recovers the exact parameters:
"""

# ╔═╡ 3231de71-277a-4a13-b3ae-220650089f8b
noiseless_paramest_fun = OptimizationFunction((p,θ)->lotka_loss(p; noise=false), AutoZygote())

# ╔═╡ c82ea0b1-f5dd-45be-ad89-4746d31109a8
noiseless_paramest_prob = OptimizationProblem(noiseless_paramest_fun, [1.0,2.0,3.0,4.0], lb = [0.1, 0.1, 0.1, 0.1], ub = [4.0, 4.0, 4.0, 4.0])

# ╔═╡ 6572ab63-4428-4d4b-8ba2-37820d1403cc
bbo_noiselessparamest_sol = solve(noiseless_paramest_prob, BBO_adaptive_de_rand_1_bin_radiuslimited(), maxiters = 10000)

# ╔═╡ 14cf3698-fb1b-44bc-89b1-98d8fdf29723
bbo_noiselessparamest_sol.u

# ╔═╡ aa7d1c43-0d78-462b-93d0-090d2bbdff31
md"""
That's almost exactly the right solution! Meanwhile our other method:
"""

# ╔═╡ 241cb0fa-9e3e-4291-a3b8-e0d1246c9d2f
local_paramestopt_sol = solve(noiseless_paramest_prob, Optimization.LBFGS())

# ╔═╡ e2ee3937-32f2-4caa-9509-a0418fb36135
local_paramestopt_sol.u

# ╔═╡ a3497c89-f8c8-4468-bfb3-430e3fe07071
md"""
Even without noise this method did not do well. So does that mean `BBO_adaptive_de_rand_1_bin_radiuslimited` is just better? Not necessarily. Let's look at the stats of the solution process:
"""

# ╔═╡ 0fa7450e-4c48-40f5-8785-cd0ab7a8c4f7
bbo_noiselessparamest_sol.stats

# ╔═╡ ff48c782-955d-4e7d-be0f-0f7db2c011ae
local_paramestopt_sol.stats

# ╔═╡ 19f1b4f6-e42c-45c3-8e4a-2f6c623fa65e
md"""
From this we can see that the global optimizer required solving the ODE with $(bbo_noiselessparamest_sol.stats.fevals) evaluations of the cost function. That's solving >10,000 ODEs! The other method is meanwhile using $(local_paramestopt_sol.stats.fevals) evaluations. The reason is because this BBO method is a blackbox global optimization method while `Optimization.LBFGS` is a local gradient-based optimization method. Local optimization methods are much faster, orders of magnitude faster, but can get stuck in local minima, while Global optimization methods require hundreds of thousands (and more, millions) of iterations in order to converge, but are generally more robust at avoiding local minima. It's a trade-off, but the global optimization methods scale poorly to more expensive problems and in particular high-dimensional parameter spaces. Because our model is sufficiently small this solved perfectly fine, but it's not something that can always be used!

To demonstrate that this is an issue with local minima, we can use the local minimizer with a different loss value. To make this more clear we will use the noiseless data.
"""

# ╔═╡ 66e393f7-4120-46e1-925c-11367c3b6d4c
noiseless_paramest_prob_newu0 = OptimizationProblem(noiseless_paramest_fun, [1.0,2.0,3.0,3.0], lb = [0.1, 0.1, 0.1, 0.1], ub = [4.0, 4.0, 4.0, 4.0])

# ╔═╡ a6b84344-a03d-4575-bb56-9ba2ba37a3f7
local_paramestopt_newu0_sol = solve(noiseless_paramest_prob_newu0, Optimization.LBFGS())

# ╔═╡ 18e5b654-10e9-4df9-95b5-62624d694b9f
local_paramestopt_newu0_sol.u

# ╔═╡ 48f71f49-44c3-4424-824e-63a0f975bd38
local_paramestopt_newu0_sol.objective

# ╔═╡ 3b48ff74-df66-4a6d-aca0-fcf2b855cb23
md"""
Notice I made a small tweak to the initial condition of the parameter estimation: `[1.0,2.0,3.0,3.0]` instead of `[1.0,2.0,3.0,4.0]`, and suddenly we got the right answer! And we get it really fast too:
"""

# ╔═╡ 1c913f13-6a33-4161-a9e4-7e439f1ebf70
local_paramestopt_newu0_sol.stats

# ╔═╡ 757546ff-9c2a-442c-9b71-b4b30c48cdfa
md"""
We can see that by only changing the last initial condition we can "fix" the local optimization. Just $(local_paramestopt_newu0_sol.stats.fevals) solves of our ODE gives us the solution now. This would be the best solution if our initial guess was good enough!

In order to see this local optima phonomena, we can slice the cost function and perturb just one of the parameters, and plot the cost function as that parameter changes:
"""

# ╔═╡ ecaaea3c-f399-42d7-a56a-033a0f6b4a8b
function loss_changing_1st(p1)
	lotka_loss([p1,1.5,3.0,1.0]; noise=false)
end

# ╔═╡ f87f8a17-a706-497e-94d4-e6e6f7601f37
p1s = 0.01:0.01:5.0

# ╔═╡ 79d4d09a-d1a2-45a9-bb02-ae05a24b4f1d
plot(p1s, loss_changing_1st.(p1s), yaxis="Loss Value", xaxis="p1", title="Loss given p1, where all other parameters are exact")

# ╔═╡ 790110fe-ad24-4a71-a2c7-8446e0441985
md"""
This of course raises a bunch of interesting questions:

1. Can we do local methods with many starting points? Yes, these are multistart methods.
2. Can we make global optimization more efficient? Yes there are all sorts of algorithms here.
3. Can we mix global optimization and gradient-based methods? This is one branch of research.
4. Can we make difficult models solve quicker and then just use the global optimizers? This is the space of surrogates and reduced order methods which other lecturers will cover.
5. Can we define loss functions which have less local minima? This will be one of the later lectures.
6. How does the automatic differentiation choice effect scaling, accuracy, and stability? That will be the next lecture.

And so on and so forth. So this is just the most basic of solutions to the parameter estimation problem, but shows all of the steps in full.
"""

# ╔═╡ b79609cd-bb10-49ad-91eb-5de46325d0e0
md"""
### Generalizing to Other Inverse Problems: Inverse Problems on Nonlinear Systems

Now that we have seen inverse problems on differential equations, it should be readily apparent how to generalize inverse problems to all other kinds of mathematical equations. Basically, you take the method for solving that type of equation and put it inside of an optimization loop. As we noted above, there are many mathematical/computational questions to be asked about whether this process will converge to the right solution, whether it will be computationally efficient, etc., but procedurally as code it's "easy" to generalize this to any method.

To show this, let's now do the same for an inverse problem on the Brusselator PDE.

#### Description of the Steady State Brusselator PDE

**If you are not familiar with PDEs, feel free to skip this section. It's simply defining a nonlinear system.**

The Brusselator PDE is defined on a unit square periodic domain as follows:

```math
\begin{align}
\frac{\partial U}{\partial t} &= 1 + U^2V - 4.4U + \alpha \nabla^2 U + f(x, y, t),\\
\frac{\partial V}{\partial t} &= 3.4U - U^2V + \alpha \nabla^2 V,
\end{align}
```

and thus its steady state is:

```math
\begin{align}
0 &= 1 + U^2V - 4.4U + \alpha \nabla^2 U + f(x, y, t),\\
0 &= 3.4U - U^2V + \alpha \nabla^2 V,
\end{align}
```

where

```math
f(x, y, t) = \begin{cases}
5 & \quad \text{if } (x-0.3)^2+(y-0.6)^2 ≤ 0.1^2 \text{ and } t ≥ 1.1\\
0 & \quad \text{else}
\end{cases}, \mathrm{and}
```

$\nabla^2 = \frac{\partial^2}{\partial x^2} + \frac{\partial^2}{\partial y^2}$ is the two dimensional Laplacian operator. The above equations are to be solved for a time interval $t \in [0, 11.5]$ subject to the initial conditions

```math
\begin{align}
U(x, y, 0) &= 22\cdot (y(1-y))^{3/2} \\
V(x, y, 0) &= 27\cdot (x(1-x))^{3/2}
\end{align},
```

and the periodic boundary conditions

```math
\begin{align}
U(x+1,y,t) &= U(x,y,t) \\
V(x,y+1,t) &= V(x,y,t).
\end{align}
```

To solve this PDE, we will discretize it into a system of ODEs with the finite
difference method. We discretize the unit square domain with `N` grid points in each direction.
`U[i,j]` and `V[i,j]` then represent the value of the discretized field at a given point in time, i.e.

```
U[i,j] = U(i*dx,j*dy)
V[i,j] = V(i*dx,j*dy)
```

where `dx = dy = 1/N`. To implement our ODE system, we collect both `U` and `V` in a single array `u` of size `(N,N,2)` with `u[i,j,1] = U[i,j]` and `u[i,j,2] = V[i,j]`. This approach can be easily generalized to PDEs with larger number of field variables.

Using a three-point stencil, the Laplacian operator discretizes into a tridiagonal matrix with elements `[1 -2 1]` and a `1` in the top, bottom, left, and right corners coming from the periodic boundary conditions. The nonlinear terms are implemented pointwise in a straightforward manner.

tl;dr, the set of nonlinear equations is:
"""

# ╔═╡ 421dbe2a-a689-4390-9d0b-b4528d11f4af
N = 8

# ╔═╡ 8186418e-d332-41da-b6ae-d90964c28c08
xyd_brusselator = range(0, stop = 1, length = N)

# ╔═╡ f3685420-ec96-4cdc-aa9a-f3f0cf948b1e
brusselator_f(x, y) = (((x - 0.3)^2 + (y - 0.6)^2) <= 0.1^2) * 5.0

# ╔═╡ 95bebbd8-7e5d-4e7a-a2a8-68b546614c0e
limit(a, N) = a == N + 1 ? 1 : a == 0 ? N : a

# ╔═╡ 169aa5f4-a85d-4e53-8442-f47757456726
function brusselator_2d_loop(_du, _u, p)
    A, B, alpha = p
	dx = step(xyd_brusselator)
    alpha = alpha / dx^2
	u = reshape(_u, N, N, 2)
	du = reshape(_du, N, N, 2)
	
    @inbounds for I in CartesianIndices((N, N))
        i, j = Tuple(I)
        x, y = xyd_brusselator[I[1]], xyd_brusselator[I[2]]
        ip1, im1, jp1, jm1 = limit(i + 1, N), limit(i - 1, N), limit(j + 1, N),
        limit(j - 1, N)
        du[i, j, 1] = alpha * (u[im1, j, 1] + u[ip1, j, 1] + u[i, jp1, 1] + u[i, jm1, 1] -
                       4u[i, j, 1]) +
                      B +
                      u[i, j, 1]^2 * u[i, j, 2] - (A + 1) * u[i, j, 1] + brusselator_f(x, y)
        du[i, j, 2] = alpha * (u[im1, j, 2] + u[ip1, j, 2] + u[i, jp1, 2] + u[i, jm1, 2] -
                       4u[i, j, 2]) + A * u[i, j, 1] - u[i, j, 1]^2 * u[i, j, 2]
    end
end

# ╔═╡ 490d7195-a878-4634-8f2b-a51463976d44
bruss_p = [3.4, 1.0, 10.0]

# ╔═╡ 4d3dd038-5cdf-44ad-9fcc-22353e55961f
function init_brusselator_2d(xyd)
    N = length(xyd)
    u = zeros(N, N, 2)
    for I in CartesianIndices((N, N))
        x = xyd[I[1]]
        y = xyd[I[2]]
        u[I, 1] = 22 * (y * (1 - y))^(3 / 2)
        u[I, 2] = 27 * (x * (1 - x))^(3 / 2)
    end
    u
end

# ╔═╡ f66493ab-dddb-46fa-9305-80f7625e8f88
bruss_u0 = vec(init_brusselator_2d(xyd_brusselator))

# ╔═╡ 664a2a56-58d6-42bf-89c3-15307834d633
prob_brusselator_2d = NonlinearProblem(
    brusselator_2d_loop, bruss_u0, bruss_p; abstol = 1e-10, reltol = 1e-10
)

# ╔═╡ 8d46da5d-e59d-47e4-af1a-b8b33a8b57a7
md"""
We can solve this system with the chosen parameters:
"""

# ╔═╡ 3bc2d2d7-863c-4f59-9918-4eb3944ac0ec
bruss_sol = solve(prob_brusselator_2d, NewtonRaphson())

# ╔═╡ 14ee0daf-95f5-4e54-8ccc-ea1df5a52157
md"""
But now we can ask a question. That question doesn't have to be "fit the data", it can be anything about the solution. The solution here is the steady state values for `(u,v)`. Let's ask the question: for what values of the parameters is the norm of `u` equal to the norm of `v`? We can see that in our first solution, the `u` is much smaller than the `v`, so for what parameters is that not true?

For this PDE, the steady state that's found is an unstable steady state with a periodic orbit around it, and thus this would be asking when the periodic orbit is relatively circular, but simplified a bit.

But okay, whether or not we justify this question, how would we code up a method to solve it? We can do that as follows:
"""

# ╔═╡ 95cd9037-5985-4c45-bbe8-e20a5e244b5f
function bruss_optcost(p, θ)
	_prob = remake(prob_brusselator_2d, p=p)
	new_bruss_sol = solve(_prob, NewtonRaphson(), verbose = false)
	u = reshape(new_bruss_sol.u, N, N, 2)
	abs2(norm(u[:,:,1]) - norm(u[:,:,2]))
end

# ╔═╡ 8ffc8473-1c74-4ba2-bd6c-5f8aa1223f10
brussoptf = OptimizationFunction(bruss_optcost, AutoZygote())

# ╔═╡ 943a4e6f-1cbb-4800-aade-6bd398d966a3
md"""
Note that we are taking the `abs2` here (squaring the result) in order to ensure that the result is always positive, and thus the minimum is where the norms are equal. Now we setup an optimization to find the parameters for which this works:
"""

# ╔═╡ 22bdc1e6-ce8d-41bd-a257-d015202f468d
bruss_opt = OptimizationProblem(brussoptf, [3.4, 1.0, 10.0], lb = [0.1, 0.1, 0.1], ub = [20.0, 20.0, 20.0])

# ╔═╡ 22f0edf0-d358-4d40-ad1a-78e251cdc809
bruss_opt_sol = solve(bruss_opt, BBO_adaptive_de_rand_1_bin_radiuslimited(), maxiters=300)

# ╔═╡ 7a49a79c-95b5-4dbc-b979-4c753a75e86e
bruss_opt_sol.objective

# ╔═╡ b0b10ca7-0dca-4359-9fe5-f60b375f3413
bruss_opt_sol.u

# ╔═╡ 522a37fb-a2f7-4758-8e32-02c8058c8df3
md"""
This solution looks really good!
"""

# ╔═╡ db0b2561-7a02-427f-9a9c-a3943947da4c
begin 
	_prob = remake(prob_brusselator_2d, p=bruss_opt_sol.u)
	new_bruss_sol = solve(_prob, NewtonRaphson(), verbose = false)
	u = reshape(new_bruss_sol.u, N, N, 2)
end

# ╔═╡ 0351b05b-c63d-4a7a-a20b-e6e72b835bec
md"""

### Solving Inverse Problems via Bayesian Methods

All of the above shows how to use optimization methods for solving the inverse problem. The other major branch of methods are the Bayesian methods. Bayesian methods or other probabilistic methods give an estimate of uncertainty around the inverse problem solution. This is good because, as seen with the parameter estimation example, it can be tricky to know if your solution is any good. In particular, you don't expect to have exactly the right parameters if you have noise, but how much off are they likely to be? Bayesian probabilistic estimates help give you this information by, instead of giving you an exact value for the parameters, it instead gives you a probability distribution for the best parameters.

Mathematically, the difference between these two approaches can be tremendous. But computationally with a probabilsitic programming framework. For this we will using Turing.jl
"""

# ╔═╡ 0bfd1396-c569-4ac9-b92a-f535e533ba50
md"""
Now, instead of defining an objective function, we define a likelihood function. A likelihood function measures how likely parameters are: the closer to the data the simulation is, the more likely the parameters should be. We can do this using the Turing model syntax as follows:
"""

# ╔═╡ c479f931-f403-4c93-bc63-14a01f19718b
@model function fitlv(data)
    # Prior distributions.
    σ ~ InverseGamma(2, 3)
    α ~ truncated(Normal(1.0, 0.5); lower=0.5, upper=2.5)
    β ~ truncated(Normal(2.0, 0.5); lower=0, upper=2)
    γ ~ truncated(Normal(3.0, 0.5); lower=1, upper=4)
    δ ~ truncated(Normal(3.0, 0.5); lower=0, upper=2)

    # Simulate Lotka-Volterra model. 
    p = [α, β, γ, δ]
	predicted = lotka_prediction(p)

    # Observations.
    for i in 1:length(predicted)
        data[:, i] ~ MvNormal(predicted[:,i], σ^2 * I)
    end

    return nothing
end

# ╔═╡ 1a5be3f3-9d6c-45f0-963a-8e19e65c0f3a
model = fitlv(lotka_data_noisy)

# ╔═╡ e479984b-579c-4cdd-9f69-6d7b0db8202e
chain = sample(model, NUTS(), MCMCSerial(), 1000, 3; progress=false)

# ╔═╡ 4db2c565-7c96-41c9-8480-e07d107f12d3
plot(chain)

# ╔═╡ 9677c213-4af4-48bc-9c49-b7907f478f8d
md"""
For more information on understanding the Bayesian results, it is highly recommended you check out the Bayesian estimation of differential equations tutorial at [https://turinglang.org/docs/tutorials/bayesian-differential-equations/](https://turinglang.org/docs/tutorials/bayesian-differential-equations/).

From the plots above we can see how chains have converged, and thus we are getting resonable probability distributions for the parameters. The chains are thus a sample-based estimate of the probability distribution: the probability of being in an area matches the probability of seeing a given parameter. Thus the areas where a given value is in the chain more often has a higher probability. The parameter distributions on the right side above are slides of the marginal density estimates from this information, generated by a kernel density estimate.

We can get summary statistics about the chain as follows:
"""

# ╔═╡ 243b7f0b-2f0c-4373-ae98-ce234562f87a
summarize(chain)

# ╔═╡ 60118730-1525-43fd-b1ff-b675b6a20e42
md"""
What's σ? For the likelihood function we chose to use a normally distributed likelihood, where the variance is σ. Thus σ is a hyperparameter of our cost function for the variance at each data point, or an estimate for the intrinsic noise in the data. We can see it's a fairly good estimate for the size of the noise that we had added!
"""

# ╔═╡ 33adf452-e528-4cbc-88a7-d81bac52e124
md"""
If time allows, we can go over the details about how the HMC/NUTS algorithm works, but in a sense it's the probabilistic generalization of gradient-based optimization. And we can see it gives similar estimates to the parameters on the noisy data as before. To double check how it did without noise we can see:
"""

# ╔═╡ d6001516-314b-4f9c-9929-61cd2e2e4e98
model_nonoise = fitlv(lotka_data)

# ╔═╡ 3c20fb0d-ffba-4df6-bc21-175823894867
chain_nonoise = sample(model_nonoise, NUTS(), MCMCSerial(), 1000, 3; progress=false)

# ╔═╡ d2868575-d779-436e-97a1-c524b775899d
plot(chain_nonoise)

# ╔═╡ f448e44b-66ee-42db-99a1-1a9ad1b92d23
summarize(chain_nonoise)

# ╔═╡ 583d4aa9-0193-49b1-8350-7b2715041f39
md"""
We can see it's right on the dot!
"""

# ╔═╡ 38de9bfc-ea00-43c2-af5b-08fb031e1861
md"""

## Investigating Identifiability in Inverse Problems

Now that you have the basic techniques for solving inverse problems, you might want to ask the question, how do I know I got "the right answer"? To motivate this question better, let's go back to our parameter estimation problem. In that case, we assumed that we had data for the time series of `[x,y]`. However, in most scientific context that is unreasonable: it's highly unlikely that you have data for every state in your system. Instead you likely only have partial data. If you only observed part of the system, will you still recover the right parameters? 

Let's see this in action with our Lotka-Volterra system. Let's assume that we only observe the ``x`` values. Thus we could do this by simply changing our cost function:
"""

# ╔═╡ bf8cdb2b-e77c-4a9c-97c0-ab57e8fc6e6b
function lotka_loss_partially_observed(p)
	norm(Array(lotka_prediction(p))[1,:] - lotka_data[1,:])
end

# ╔═╡ cd427bf5-afbd-4e92-9def-c5f5e7bea416
paramest_partial_fun = OptimizationFunction((p,θ)->lotka_loss_partially_observed(p), AutoZygote())

# ╔═╡ 5755fb3c-24d5-45b2-a10c-a1010c27df4f
paramest_partial_prob = OptimizationProblem(paramest_partial_fun, [1.0,2.0,3.0,3.0], lb = [0.1, 0.1, 0.1, 0.1], ub = [4.0, 4.0, 4.0, 4.0])

# ╔═╡ 70fbd8fd-fda4-426d-8a6f-d1f8fa303200
md"""
Notice we are using the exact same setup as the local optimization that previously converged, i.e. the "fixed" or better initial conditions. Let's see how this does:
"""

# ╔═╡ bd129656-3273-4725-afe5-f9ff04afda23
local_paramestopt_partial_sol = solve(paramest_partial_prob, BBO_adaptive_de_rand_1_bin_radiuslimited(), maxiters = 10000)

# ╔═╡ 97118579-0ae9-4078-b6f4-4ad4a6a54901
local_paramestopt_partial_sol.objective

# ╔═╡ fdd91eab-f5af-43f5-9cf2-3311e7eea56c
md"""
We see that even the global optimization does not recover the correct parameters anymore, but it does give a solution that does exactly what we asked for:
"""

# ╔═╡ e662f173-84ad-438e-afe8-a1e1e82d38c6
begin
	plot7 = plot(lotka_prediction(local_paramestopt_partial_sol.u, saveat = ()))
	scatter!(plot7, lotka_data_sol.t, lotka_data')
end

# ╔═╡ f9ac099c-8fc8-45b4-b0b6-6e47985a5880
md"""
We see that we got the right parameters! That's basically changing things about `y` also changes things about `x` in a way that is uniquely defined, and thus data about the timeseries of `x` is sufficient to understand the full system.

When should we expect this to be true? When should we not expect this to be true? This is the question of identifiability and will be discussed in future lectures if time allows.
"""

# ╔═╡ 3bf58446-ddff-4dd8-a3f6-1ac9822a930f
md"""
## Conclusion

In this lecture we showed how to solving forward and inverse problems using Julia. We see that with Julia's SciML infrastructure we can use methods that are compatible with automatic differentiation in order to generate the gradients automatically in a way that is compatible with both the optimization and the Bayesian inference libraries. We showed how to use both optimization and Bayesian inference to solve inverse problems on ODEs, nonlinear systems, and one can guess how this would generalize to all sorts of codes. Thus it's safe to say that if you understood this lecture, then you understand how to solve inverse problems! Case closed, workshop done.

But... then what's left? Well, what we saw a little bit in this lecture is that solving inverse problems can run into problems. Thus there are many questions about how to design inverse problems and solve them in a way that is faster and more robust. These questions are:

1. How is the gradient calculated, how do we ensure it's accurate, and how do we ensure it's calculated fast?
2. How do we design better cost functions that remove local minima?
3. How do we know if we have given the system sufficient data to solve the inverse problem, i.e. that we know we have the correct solution and that there is only one correct solution?
4. How do we build better optimizers that can converge "better", i.e. ignore or skip local optima?

There are many questions as to how to take the basic template here and "do it better". That's the rest of the workshop.
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
NonlinearSolveFirstOrder = "5959db7a-ea39-4486-b5fe-2dd0bf03d60d"
Optimization = "7f7a1694-90dd-40f0-9382-eb1efda571ba"
OptimizationBBO = "3e6eede4-6085-4f62-9a71-46d9bc1eb92b"
OrdinaryDiffEqTsit5 = "b1df2697-797e-41e3-8120-5422d3b24e4a"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
SciMLSensitivity = "1ed8b502-d754-442c-8d5d-10ac956f44a1"
StableRNGs = "860ef19b-820b-49d6-a774-d7a799459cd3"
StatsPlots = "f3b207a7-027a-5e70-b257-86293d7955fd"
Turing = "fce5fe82-541a-59a6-adf8-730c64b5f9a0"
Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[compat]
NonlinearSolveFirstOrder = "~1.2.0"
Optimization = "~4.0.5"
OptimizationBBO = "~0.4.0"
OrdinaryDiffEqTsit5 = "~1.1.0"
Plots = "~1.40.9"
SciMLSensitivity = "~7.72.0"
StableRNGs = "~1.0.2"
StatsPlots = "~0.15.7"
Turing = "~0.35.5"
Zygote = "~0.6.75"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.2"
manifest_format = "2.0"
project_hash = "050da0e2cf88caaa72c321e71293534b4bec8d5c"

[[deps.ADTypes]]
git-tree-sha1 = "72af59f5b8f09faee36b4ec48e014a79210f2f4f"
uuid = "47edcb42-4c32-4615-8424-f2b9edc5f35b"
version = "1.11.0"
weakdeps = ["ChainRulesCore", "ConstructionBase", "EnzymeCore"]

    [deps.ADTypes.extensions]
    ADTypesChainRulesCoreExt = "ChainRulesCore"
    ADTypesConstructionBaseExt = "ConstructionBase"
    ADTypesEnzymeCoreExt = "EnzymeCore"

[[deps.AbstractFFTs]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "d92ad398961a3ed262d8bf04a1a2b8340f915fef"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.5.0"
weakdeps = ["ChainRulesCore", "Test"]

    [deps.AbstractFFTs.extensions]
    AbstractFFTsChainRulesCoreExt = "ChainRulesCore"
    AbstractFFTsTestExt = "Test"

[[deps.AbstractMCMC]]
deps = ["BangBang", "ConsoleProgressMonitor", "Distributed", "FillArrays", "LogDensityProblems", "Logging", "LoggingExtras", "ProgressLogging", "Random", "StatsBase", "TerminalLoggers", "Transducers"]
git-tree-sha1 = "aa469a7830413bd4c855963e3f648bd9d145c2c3"
uuid = "80f14c24-f653-4e6a-9b94-39d6b0f70001"
version = "5.6.0"

[[deps.AbstractPPL]]
deps = ["AbstractMCMC", "Accessors", "DensityInterface", "JSON", "Random"]
git-tree-sha1 = "bdb19638644450ee1b0fd63740381835069d34b9"
uuid = "7a57a42e-76ec-4ea3-a279-07e840d6d9cf"
version = "0.9.0"

[[deps.AbstractTrees]]
git-tree-sha1 = "2d9c9a55f9c93e8887ad391fbae72f8ef55e1177"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.4.5"

[[deps.Accessors]]
deps = ["CompositionsBase", "ConstructionBase", "InverseFunctions", "MacroTools"]
git-tree-sha1 = "e93c42e833e6d4bd28be7b3b56d8deb99fd51f25"
uuid = "7d9f7c33-5ae7-4f3b-8dc6-eff91059b697"
version = "0.1.40"

    [deps.Accessors.extensions]
    AxisKeysExt = "AxisKeys"
    DatesExt = "Dates"
    IntervalSetsExt = "IntervalSets"
    LinearAlgebraExt = "LinearAlgebra"
    StaticArraysExt = "StaticArrays"
    StructArraysExt = "StructArrays"
    TestExt = "Test"
    UnitfulExt = "Unitful"

    [deps.Accessors.weakdeps]
    AxisKeys = "94b1ba4f-4ee9-5380-92f1-94cde586c3c5"
    Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
    IntervalSets = "8197267c-284f-5f27-9208-e0e47529a953"
    LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
    Requires = "ae029012-a4dd-5104-9daa-d747884805df"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"
    StructArrays = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
    Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.Adapt]]
deps = ["LinearAlgebra", "Requires"]
git-tree-sha1 = "50c3c56a52972d78e8be9fd135bfb91c9574c140"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "4.1.1"
weakdeps = ["StaticArrays"]

    [deps.Adapt.extensions]
    AdaptStaticArraysExt = "StaticArrays"

[[deps.AdvancedHMC]]
deps = ["AbstractMCMC", "ArgCheck", "DocStringExtensions", "InplaceOps", "LinearAlgebra", "LogDensityProblems", "LogDensityProblemsAD", "ProgressMeter", "Random", "Requires", "Setfield", "SimpleUnPack", "Statistics", "StatsBase", "StatsFuns"]
git-tree-sha1 = "6f6a228808fe00ad05b47d74747c800d3df18acb"
uuid = "0bf59076-c3b1-5ca4-86bd-e02cd72cde3d"
version = "0.6.4"

    [deps.AdvancedHMC.extensions]
    AdvancedHMCCUDAExt = "CUDA"
    AdvancedHMCMCMCChainsExt = "MCMCChains"
    AdvancedHMCOrdinaryDiffEqExt = "OrdinaryDiffEq"

    [deps.AdvancedHMC.weakdeps]
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    MCMCChains = "c7f686f2-ff18-58e9-bc7b-31028e88f75d"
    OrdinaryDiffEq = "1dea7af3-3e70-54e6-95c3-0bf5283fa5ed"

[[deps.AdvancedMH]]
deps = ["AbstractMCMC", "Distributions", "DocStringExtensions", "FillArrays", "LinearAlgebra", "LogDensityProblems", "Random", "Requires"]
git-tree-sha1 = "6e3d18037861bf220ed77f1a2c5f24a21a68d4b7"
uuid = "5b7e9947-ddc0-4b3f-9b55-0d8042f74170"
version = "0.8.5"
weakdeps = ["DiffResults", "ForwardDiff", "MCMCChains", "StructArrays"]

    [deps.AdvancedMH.extensions]
    AdvancedMHForwardDiffExt = ["DiffResults", "ForwardDiff"]
    AdvancedMHMCMCChainsExt = "MCMCChains"
    AdvancedMHStructArraysExt = "StructArrays"

[[deps.AdvancedPS]]
deps = ["AbstractMCMC", "Distributions", "Random", "Random123", "Requires", "SSMProblems", "StatsFuns"]
git-tree-sha1 = "5dcd3de7e7346f48739256e71a86d0f96690b8c8"
uuid = "576499cb-2369-40b2-a588-c64705576edc"
version = "0.6.0"
weakdeps = ["Libtask"]

    [deps.AdvancedPS.extensions]
    AdvancedPSLibtaskExt = "Libtask"

[[deps.AdvancedVI]]
deps = ["ADTypes", "Bijectors", "DiffResults", "Distributions", "DistributionsAD", "DocStringExtensions", "ForwardDiff", "LinearAlgebra", "ProgressMeter", "Random", "Requires", "StatsBase", "StatsFuns", "Tracker"]
git-tree-sha1 = "e45e57cea1879400952fe34b0cbc971950408af8"
uuid = "b5ca4192-6429-45e5-a2d9-87aec30a685c"
version = "0.2.11"

    [deps.AdvancedVI.extensions]
    AdvancedVIEnzymeExt = ["Enzyme"]
    AdvancedVIFluxExt = ["Flux"]
    AdvancedVIReverseDiffExt = ["ReverseDiff"]
    AdvancedVIZygoteExt = ["Zygote"]

    [deps.AdvancedVI.weakdeps]
    Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"
    Flux = "587475ba-b771-5e3f-ad9e-33799f191a9c"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.AliasTables]]
deps = ["PtrArrays", "Random"]
git-tree-sha1 = "9876e1e164b144ca45e9e3198d0b689cadfed9ff"
uuid = "66dad0bd-aa9a-41b7-9441-69ab47430ed8"
version = "1.1.3"

[[deps.ArgCheck]]
git-tree-sha1 = "680b3b8759bd4c54052ada14e52355ab69e07876"
uuid = "dce04be8-c92d-5529-be00-80e4d2c0e197"
version = "2.4.0"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.2"

[[deps.Arpack]]
deps = ["Arpack_jll", "Libdl", "LinearAlgebra", "Logging"]
git-tree-sha1 = "9b9b347613394885fd1c8c7729bfc60528faa436"
uuid = "7d9fca2a-8960-54d3-9f78-7d1dccf2cb97"
version = "0.5.4"

[[deps.Arpack_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "OpenBLAS_jll", "Pkg"]
git-tree-sha1 = "5ba6c757e8feccf03a1554dfaf3e26b3cfc7fd5e"
uuid = "68821587-b530-5797-8361-c406ea357684"
version = "3.5.1+1"

[[deps.ArrayInterface]]
deps = ["Adapt", "LinearAlgebra"]
git-tree-sha1 = "017fcb757f8e921fb44ee063a7aafe5f89b86dd1"
uuid = "4fba245c-0d91-5ea0-9b3e-6abc04ee57a9"
version = "7.18.0"

    [deps.ArrayInterface.extensions]
    ArrayInterfaceBandedMatricesExt = "BandedMatrices"
    ArrayInterfaceBlockBandedMatricesExt = "BlockBandedMatrices"
    ArrayInterfaceCUDAExt = "CUDA"
    ArrayInterfaceCUDSSExt = "CUDSS"
    ArrayInterfaceChainRulesCoreExt = "ChainRulesCore"
    ArrayInterfaceChainRulesExt = "ChainRules"
    ArrayInterfaceGPUArraysCoreExt = "GPUArraysCore"
    ArrayInterfaceReverseDiffExt = "ReverseDiff"
    ArrayInterfaceSparseArraysExt = "SparseArrays"
    ArrayInterfaceStaticArraysCoreExt = "StaticArraysCore"
    ArrayInterfaceTrackerExt = "Tracker"

    [deps.ArrayInterface.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    BlockBandedMatrices = "ffab5731-97b5-5995-9138-79e8c1846df0"
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    CUDSS = "45b445bb-4962-46a0-9369-b4df9d0f772e"
    ChainRules = "082447d4-558c-5d27-93f4-14fc19e9eca2"
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    GPUArraysCore = "46192b85-c4d5-4398-a991-12ede77f4527"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    StaticArraysCore = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"

[[deps.ArrayLayouts]]
deps = ["FillArrays", "LinearAlgebra"]
git-tree-sha1 = "2bf6e01f453284cb61c312836b4680331ddfc44b"
uuid = "4c555306-a7a7-4459-81d9-ec55ddd5c99a"
version = "1.11.0"
weakdeps = ["SparseArrays"]

    [deps.ArrayLayouts.extensions]
    ArrayLayoutsSparseArraysExt = "SparseArrays"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Atomix]]
deps = ["UnsafeAtomics"]
git-tree-sha1 = "c3b238aa28c1bebd4b5ea4988bebf27e9a01b72b"
uuid = "a9b6321e-bd34-4604-b9c9-b65b8de01458"
version = "1.0.1"

    [deps.Atomix.extensions]
    AtomixCUDAExt = "CUDA"
    AtomixMetalExt = "Metal"
    AtomixoneAPIExt = "oneAPI"

    [deps.Atomix.weakdeps]
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    Metal = "dde4c033-4e86-420c-a63e-0dd931031962"
    oneAPI = "8f75cd03-7ff8-4ecb-9b8f-daf728133b1b"

[[deps.AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "01b8ccb13d68535d73d2b0c23e39bd23155fb712"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.1.0"

[[deps.AxisArrays]]
deps = ["Dates", "IntervalSets", "IterTools", "RangeArrays"]
git-tree-sha1 = "16351be62963a67ac4083f748fdb3cca58bfd52f"
uuid = "39de3d68-74b9-583c-8d2d-e117c070f3a9"
version = "0.4.7"

[[deps.BangBang]]
deps = ["Accessors", "ConstructionBase", "InitialValues", "LinearAlgebra", "Requires"]
git-tree-sha1 = "e2144b631226d9eeab2d746ca8880b7ccff504ae"
uuid = "198e06fe-97b7-11e9-32a5-e1d131e6ad66"
version = "0.4.3"

    [deps.BangBang.extensions]
    BangBangChainRulesCoreExt = "ChainRulesCore"
    BangBangDataFramesExt = "DataFrames"
    BangBangStaticArraysExt = "StaticArrays"
    BangBangStructArraysExt = "StructArrays"
    BangBangTablesExt = "Tables"
    BangBangTypedTablesExt = "TypedTables"

    [deps.BangBang.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"
    StructArrays = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
    Tables = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
    TypedTables = "9d95f2ec-7b3d-5a63-8d20-e2491e220bb9"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.Baselet]]
git-tree-sha1 = "aebf55e6d7795e02ca500a689d326ac979aaf89e"
uuid = "9718e550-a3fa-408a-8086-8db961cd8217"
version = "0.1.1"

[[deps.Bijectors]]
deps = ["ArgCheck", "ChainRulesCore", "ChangesOfVariables", "Distributions", "DocStringExtensions", "Functors", "InverseFunctions", "IrrationalConstants", "LinearAlgebra", "LogExpFunctions", "MappedArrays", "Random", "Reexport", "Roots", "SparseArrays", "Statistics"]
git-tree-sha1 = "60696d397c569dcb647718e7d7359677d265154d"
uuid = "76274a88-744f-5084-9051-94815aaf08c4"
version = "0.15.3"

    [deps.Bijectors.extensions]
    BijectorsDistributionsADExt = "DistributionsAD"
    BijectorsEnzymeCoreExt = "EnzymeCore"
    BijectorsForwardDiffExt = "ForwardDiff"
    BijectorsLazyArraysExt = "LazyArrays"
    BijectorsMooncakeExt = "Mooncake"
    BijectorsReverseDiffExt = "ReverseDiff"
    BijectorsTrackerExt = "Tracker"
    BijectorsZygoteExt = "Zygote"

    [deps.Bijectors.weakdeps]
    DistributionsAD = "ced4e74d-a319-5a8a-b0ac-84af2272839c"
    EnzymeCore = "f151be2c-9106-41f4-ab19-57ee4f262869"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    LazyArrays = "5078a376-72f3-5289-bfd5-ec5146d43c02"
    Mooncake = "da2b9cff-9c12-43a0-ae48-6db2b0edb7d6"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.BitFlags]]
git-tree-sha1 = "0691e34b3bb8be9307330f88d1a3c3f25466c24d"
uuid = "d1d4a3ce-64b1-5f1a-9ba4-7e7e69966f35"
version = "0.1.9"

[[deps.BitTwiddlingConvenienceFunctions]]
deps = ["Static"]
git-tree-sha1 = "f21cfd4950cb9f0587d5067e69405ad2acd27b87"
uuid = "62783981-4cbd-42fc-bca8-16325de8dc4b"
version = "0.1.6"

[[deps.BlackBoxOptim]]
deps = ["CPUTime", "Compat", "Distributed", "Distributions", "JSON", "LinearAlgebra", "Printf", "Random", "Requires", "SpatialIndexing", "StatsBase"]
git-tree-sha1 = "9c203a2515b5eeab8f2987614d2b1db83ef03542"
uuid = "a134a8b2-14d6-55f6-9291-3336d3ab0209"
version = "0.6.3"
weakdeps = ["HTTP", "Sockets"]

    [deps.BlackBoxOptim.extensions]
    BlackBoxOptimRealtimePlotServerExt = ["HTTP", "Sockets"]

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "8873e196c2eb87962a2048b3b8e08946535864a1"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+4"

[[deps.CEnum]]
git-tree-sha1 = "389ad5c84de1ae7cf0e28e381131c98ea87d54fc"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.5.0"

[[deps.CPUSummary]]
deps = ["CpuId", "IfElse", "PrecompileTools", "Static"]
git-tree-sha1 = "5a97e67919535d6841172016c9530fd69494e5ec"
uuid = "2a0fbf3d-bb9c-48f3-b0a9-814d99fd7ab9"
version = "0.2.6"

[[deps.CPUTime]]
git-tree-sha1 = "2dcc50ea6a0a1ef6440d6eecd0fe3813e5671f45"
uuid = "a9c8d775-2e2e-55fc-8582-045d282d599e"
version = "1.0.0"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "009060c9a6168704143100f36ab08f06c2af4642"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.18.2+1"

[[deps.Cassette]]
git-tree-sha1 = "f8764df8d9d2aec2812f009a1ac39e46c33354b8"
uuid = "7057c7e9-c182-5462-911a-8362d720325c"
version = "0.3.14"

[[deps.ChainRules]]
deps = ["Adapt", "ChainRulesCore", "Compat", "Distributed", "GPUArraysCore", "IrrationalConstants", "LinearAlgebra", "Random", "RealDot", "SparseArrays", "SparseInverseSubset", "Statistics", "StructArrays", "SuiteSparse"]
git-tree-sha1 = "4312d7869590fab4a4f789e97bd82f0a04eaaa05"
uuid = "082447d4-558c-5d27-93f4-14fc19e9eca2"
version = "1.72.2"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra"]
git-tree-sha1 = "1713c74e00545bfe14605d2a2be1712de8fbcb58"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.25.1"
weakdeps = ["SparseArrays"]

    [deps.ChainRulesCore.extensions]
    ChainRulesCoreSparseArraysExt = "SparseArrays"

[[deps.ChangesOfVariables]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "799b25ca3a8a24936ae7b5c52ad194685fc3e6ef"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.9"
weakdeps = ["InverseFunctions", "Test"]

    [deps.ChangesOfVariables.extensions]
    ChangesOfVariablesInverseFunctionsExt = "InverseFunctions"
    ChangesOfVariablesTestExt = "Test"

[[deps.CloseOpenIntervals]]
deps = ["Static", "StaticArrayInterface"]
git-tree-sha1 = "05ba0d07cd4fd8b7a39541e31a7b0254704ea581"
uuid = "fb6a15b2-703c-40df-9091-08a04967cfa9"
version = "0.1.13"

[[deps.Clustering]]
deps = ["Distances", "LinearAlgebra", "NearestNeighbors", "Printf", "Random", "SparseArrays", "Statistics", "StatsBase"]
git-tree-sha1 = "3e22db924e2945282e70c33b75d4dde8bfa44c94"
uuid = "aaaa29a8-35af-508c-8bc3-b662a17a0fe5"
version = "0.15.8"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "bce6804e5e6044c6daab27bb533d1295e4a2e759"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.6"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "PrecompileTools", "Random"]
git-tree-sha1 = "c785dfb1b3bfddd1da557e861b919819b82bbe5b"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.27.1"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "c7acce7a7e1078a20a285211dd73cd3941a871d6"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.12.0"
weakdeps = ["StyledStrings"]

    [deps.ColorTypes.extensions]
    StyledStringsExt = "StyledStrings"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "Requires", "Statistics", "TensorCore"]
git-tree-sha1 = "8b3b6f87ce8f65a2b4f857528fd8d70086cd72b1"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.11.0"
weakdeps = ["SpecialFunctions"]

    [deps.ColorVectorSpace.extensions]
    SpecialFunctionsExt = "SpecialFunctions"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "64e15186f0aa277e174aa81798f7eb8598e0157e"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.13.0"

[[deps.Combinatorics]]
git-tree-sha1 = "08c8b6831dc00bfea825826be0bc8336fc369860"
uuid = "861a8166-3701-5b0c-9a16-15d98fcdc6aa"
version = "1.0.2"

[[deps.CommonSolve]]
git-tree-sha1 = "0eee5eb66b1cf62cd6ad1b460238e60e4b09400c"
uuid = "38540f10-b2f7-11e9-35d8-d573e4eb0ff2"
version = "0.2.4"

[[deps.CommonSubexpressions]]
deps = ["MacroTools"]
git-tree-sha1 = "cda2cfaebb4be89c9084adaca7dd7333369715c5"
uuid = "bbf7d656-a473-5ed7-a52c-81e309532950"
version = "0.3.1"

[[deps.CommonWorldInvalidations]]
git-tree-sha1 = "ae52d1c52048455e85a387fbee9be553ec2b68d0"
uuid = "f70d9fcc-98c5-4d4a-abd7-e4cdeebd8ca8"
version = "1.0.0"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "8ae8d32e09f0dcf42a36b90d4e17f5dd2e4c4215"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.16.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.CompositionsBase]]
git-tree-sha1 = "802bb88cd69dfd1509f6670416bd4434015693ad"
uuid = "a33af91c-f02d-484b-be07-31d278c5ca2b"
version = "0.1.2"
weakdeps = ["InverseFunctions"]

    [deps.CompositionsBase.extensions]
    CompositionsBaseInverseFunctionsExt = "InverseFunctions"

[[deps.ConcreteStructs]]
git-tree-sha1 = "f749037478283d372048690eb3b5f92a79432b34"
uuid = "2569d6c7-a4a2-43d3-a901-331e8e4be471"
version = "0.2.3"

[[deps.ConcurrentUtilities]]
deps = ["Serialization", "Sockets"]
git-tree-sha1 = "f36e5e8fdffcb5646ea5da81495a5a7566005127"
uuid = "f0e56b4a-5159-44fe-b623-3e5288b988bb"
version = "2.4.3"

[[deps.ConsoleProgressMonitor]]
deps = ["Logging", "ProgressMeter"]
git-tree-sha1 = "3ab7b2136722890b9af903859afcf457fa3059e8"
uuid = "88cd18e8-d9cc-4ea6-8889-5259c0d15c8b"
version = "0.1.2"

[[deps.ConstructionBase]]
git-tree-sha1 = "76219f1ed5771adbb096743bff43fb5fdd4c1157"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.5.8"
weakdeps = ["IntervalSets", "LinearAlgebra", "StaticArrays"]

    [deps.ConstructionBase.extensions]
    ConstructionBaseIntervalSetsExt = "IntervalSets"
    ConstructionBaseLinearAlgebraExt = "LinearAlgebra"
    ConstructionBaseStaticArraysExt = "StaticArrays"

[[deps.Contour]]
git-tree-sha1 = "439e35b0b36e2e5881738abc8857bd92ad6ff9a8"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.6.3"

[[deps.CpuId]]
deps = ["Markdown"]
git-tree-sha1 = "fcbb72b032692610bfbdb15018ac16a36cf2e406"
uuid = "adafc99b-e345-5852-983c-f28acb93d879"
version = "0.3.1"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "1d0a14036acb104d9e89698bd408f63ab58cdc82"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.20"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.Dbus_jll]]
deps = ["Artifacts", "Expat_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "fc173b380865f70627d7dd1190dc2fce6cc105af"
uuid = "ee1fde0b-3d02-5ea6-8484-8dfef6360eab"
version = "1.14.10+0"

[[deps.DefineSingletons]]
git-tree-sha1 = "0fba8b706d0178b4dc7fd44a96a92382c9065c2c"
uuid = "244e2a9f-e319-4986-a169-4d1fe445cd52"
version = "0.1.2"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
git-tree-sha1 = "9e2f36d3c96a820c678f2f1f1782582fcf685bae"
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"
version = "1.9.1"

[[deps.DensityInterface]]
deps = ["InverseFunctions", "Test"]
git-tree-sha1 = "80c3e8639e3353e5d2912fb3a1916b8455e2494b"
uuid = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
version = "0.4.0"

[[deps.DiffEqBase]]
deps = ["ArrayInterface", "ConcreteStructs", "DataStructures", "DocStringExtensions", "EnumX", "EnzymeCore", "FastBroadcast", "FastClosures", "FastPower", "ForwardDiff", "FunctionWrappers", "FunctionWrappersWrappers", "LinearAlgebra", "Logging", "Markdown", "MuladdMacro", "Parameters", "PreallocationTools", "PrecompileTools", "Printf", "RecursiveArrayTools", "Reexport", "SciMLBase", "SciMLOperators", "SciMLStructures", "Setfield", "Static", "StaticArraysCore", "Statistics", "TruncatedStacktraces"]
git-tree-sha1 = "b1e23a7fe7371934d9d538114a7e7166c1d09e05"
uuid = "2b5f629d-d688-5b77-993f-72d75c75574e"
version = "6.161.0"

    [deps.DiffEqBase.extensions]
    DiffEqBaseCUDAExt = "CUDA"
    DiffEqBaseChainRulesCoreExt = "ChainRulesCore"
    DiffEqBaseDistributionsExt = "Distributions"
    DiffEqBaseEnzymeExt = ["ChainRulesCore", "Enzyme"]
    DiffEqBaseGeneralizedGeneratedExt = "GeneralizedGenerated"
    DiffEqBaseMPIExt = "MPI"
    DiffEqBaseMeasurementsExt = "Measurements"
    DiffEqBaseMonteCarloMeasurementsExt = "MonteCarloMeasurements"
    DiffEqBaseReverseDiffExt = "ReverseDiff"
    DiffEqBaseSparseArraysExt = "SparseArrays"
    DiffEqBaseTrackerExt = "Tracker"
    DiffEqBaseUnitfulExt = "Unitful"

    [deps.DiffEqBase.weakdeps]
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    Distributions = "31c24e10-a181-5473-b8eb-7969acd0382f"
    Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"
    GeneralizedGenerated = "6b9d7cbe-bcb9-11e9-073f-15a7a543e2eb"
    MPI = "da04e1cc-30fd-572f-bb4f-1f8673147195"
    Measurements = "eff96d63-e80a-5855-80a2-b1b0885c5ab7"
    MonteCarloMeasurements = "0987c9cc-fe09-11e8-30f0-b96dd679fdca"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.DiffEqCallbacks]]
deps = ["ConcreteStructs", "DataStructures", "DiffEqBase", "DifferentiationInterface", "Functors", "LinearAlgebra", "Markdown", "RecipesBase", "RecursiveArrayTools", "SciMLBase", "StaticArraysCore"]
git-tree-sha1 = "f6bc598f21c7bf2f7885cff9b3c9078e606ab075"
uuid = "459566f4-90b8-5000-8ac3-15dfb0a30def"
version = "4.2.2"

[[deps.DiffEqNoiseProcess]]
deps = ["DiffEqBase", "Distributions", "GPUArraysCore", "LinearAlgebra", "Markdown", "Optim", "PoissonRandom", "QuadGK", "Random", "Random123", "RandomNumbers", "RecipesBase", "RecursiveArrayTools", "ResettableStacks", "SciMLBase", "StaticArraysCore", "Statistics"]
git-tree-sha1 = "880d1fcf95e6492a4e7d65c2866dbdbf6580d4f8"
uuid = "77a26b50-5914-5dd7-bc55-306e6241c503"
version = "5.24.0"
weakdeps = ["ReverseDiff"]

    [deps.DiffEqNoiseProcess.extensions]
    DiffEqNoiseProcessReverseDiffExt = "ReverseDiff"

[[deps.DiffResults]]
deps = ["StaticArraysCore"]
git-tree-sha1 = "782dd5f4561f5d267313f23853baaaa4c52ea621"
uuid = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
version = "1.1.0"

[[deps.DiffRules]]
deps = ["IrrationalConstants", "LogExpFunctions", "NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "23163d55f885173722d1e4cf0f6110cdbaf7e272"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.15.1"

[[deps.DifferentiationInterface]]
deps = ["ADTypes", "LinearAlgebra"]
git-tree-sha1 = "5df172ce4e9da710603591f48c7af74eef288892"
uuid = "a0c0ee7d-e4b9-4e03-894e-1c5f64a51d63"
version = "0.6.28"

    [deps.DifferentiationInterface.extensions]
    DifferentiationInterfaceChainRulesCoreExt = "ChainRulesCore"
    DifferentiationInterfaceDiffractorExt = "Diffractor"
    DifferentiationInterfaceEnzymeExt = ["EnzymeCore", "Enzyme"]
    DifferentiationInterfaceFastDifferentiationExt = "FastDifferentiation"
    DifferentiationInterfaceFiniteDiffExt = "FiniteDiff"
    DifferentiationInterfaceFiniteDifferencesExt = "FiniteDifferences"
    DifferentiationInterfaceForwardDiffExt = ["ForwardDiff", "DiffResults"]
    DifferentiationInterfaceMooncakeExt = "Mooncake"
    DifferentiationInterfacePolyesterForwardDiffExt = "PolyesterForwardDiff"
    DifferentiationInterfaceReverseDiffExt = ["ReverseDiff", "DiffResults"]
    DifferentiationInterfaceSparseArraysExt = "SparseArrays"
    DifferentiationInterfaceSparseMatrixColoringsExt = "SparseMatrixColorings"
    DifferentiationInterfaceStaticArraysExt = "StaticArrays"
    DifferentiationInterfaceSymbolicsExt = "Symbolics"
    DifferentiationInterfaceTrackerExt = "Tracker"
    DifferentiationInterfaceZygoteExt = ["Zygote", "ForwardDiff"]

    [deps.DifferentiationInterface.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    DiffResults = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
    Diffractor = "9f5e2b26-1114-432f-b630-d3fe2085c51c"
    Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"
    EnzymeCore = "f151be2c-9106-41f4-ab19-57ee4f262869"
    FastDifferentiation = "eb9bf01b-bf85-4b60-bf87-ee5de06c00be"
    FiniteDiff = "6a86dc24-6348-571c-b903-95158fe2bd41"
    FiniteDifferences = "26cc04aa-876d-5657-8c51-4c34ba976000"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    Mooncake = "da2b9cff-9c12-43a0-ae48-6db2b0edb7d6"
    PolyesterForwardDiff = "98d1487c-24ca-40b6-b7ab-df2af84e126b"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    SparseMatrixColorings = "0a514795-09f3-496d-8182-132a7b665d35"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"
    Symbolics = "0c5d862f-8b57-4792-8d23-62f2024744c7"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.Distances]]
deps = ["LinearAlgebra", "Statistics", "StatsAPI"]
git-tree-sha1 = "c7e3a542b999843086e2f29dac96a618c105be1d"
uuid = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
version = "0.10.12"
weakdeps = ["ChainRulesCore", "SparseArrays"]

    [deps.Distances.extensions]
    DistancesChainRulesCoreExt = "ChainRulesCore"
    DistancesSparseArraysExt = "SparseArrays"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"
version = "1.11.0"

[[deps.Distributions]]
deps = ["AliasTables", "FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SpecialFunctions", "Statistics", "StatsAPI", "StatsBase", "StatsFuns"]
git-tree-sha1 = "7901a6117656e29fa2c74a58adb682f380922c47"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.116"
weakdeps = ["ChainRulesCore", "DensityInterface", "Test"]

    [deps.Distributions.extensions]
    DistributionsChainRulesCoreExt = "ChainRulesCore"
    DistributionsDensityInterfaceExt = "DensityInterface"
    DistributionsTestExt = "Test"

[[deps.DistributionsAD]]
deps = ["Adapt", "ChainRules", "ChainRulesCore", "Compat", "Distributions", "FillArrays", "LinearAlgebra", "PDMats", "Random", "Requires", "SpecialFunctions", "StaticArrays", "StatsFuns", "ZygoteRules"]
git-tree-sha1 = "02c2e6e6a137069227439fe884d729cca5b70e56"
uuid = "ced4e74d-a319-5a8a-b0ac-84af2272839c"
version = "0.6.57"
weakdeps = ["ForwardDiff", "LazyArrays", "ReverseDiff", "Tracker"]

    [deps.DistributionsAD.extensions]
    DistributionsADForwardDiffExt = "ForwardDiff"
    DistributionsADLazyArraysExt = "LazyArrays"
    DistributionsADReverseDiffExt = "ReverseDiff"
    DistributionsADTrackerExt = "Tracker"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.DynamicPPL]]
deps = ["ADTypes", "AbstractMCMC", "AbstractPPL", "Accessors", "BangBang", "Bijectors", "Compat", "ConstructionBase", "Distributions", "DocStringExtensions", "InteractiveUtils", "LinearAlgebra", "LogDensityProblems", "LogDensityProblemsAD", "MacroTools", "OrderedCollections", "Random", "Requires", "Test"]
git-tree-sha1 = "5c2bc37cbc946902e1af5ae8486f24bb585d20cb"
uuid = "366bfd00-2699-11ea-058f-f148b4cae6d8"
version = "0.32.2"

    [deps.DynamicPPL.extensions]
    DynamicPPLChainRulesCoreExt = ["ChainRulesCore"]
    DynamicPPLEnzymeCoreExt = ["EnzymeCore"]
    DynamicPPLForwardDiffExt = ["ForwardDiff"]
    DynamicPPLJETExt = ["JET"]
    DynamicPPLMCMCChainsExt = ["MCMCChains"]
    DynamicPPLMooncakeExt = ["Mooncake"]
    DynamicPPLZygoteRulesExt = ["ZygoteRules"]

    [deps.DynamicPPL.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    EnzymeCore = "f151be2c-9106-41f4-ab19-57ee4f262869"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    JET = "c3a54625-cd67-489e-a8e7-0a5a0ff4e31b"
    MCMCChains = "c7f686f2-ff18-58e9-bc7b-31028e88f75d"
    Mooncake = "da2b9cff-9c12-43a0-ae48-6db2b0edb7d6"
    ZygoteRules = "700de1a5-db45-46bc-99cf-38207098b444"

[[deps.EllipticalSliceSampling]]
deps = ["AbstractMCMC", "ArrayInterface", "Distributions", "Random", "Statistics"]
git-tree-sha1 = "e611b7fdfbfb5b18d5e98776c30daede41b44542"
uuid = "cad2338a-1db2-11e9-3401-43bc07c9ede2"
version = "2.0.0"

[[deps.EnumX]]
git-tree-sha1 = "bdb1942cd4c45e3c678fd11569d5cccd80976237"
uuid = "4e289a0a-7415-4d19-859d-a7e5c4648b56"
version = "1.0.4"

[[deps.Enzyme]]
deps = ["CEnum", "EnzymeCore", "Enzyme_jll", "GPUCompiler", "LLVM", "Libdl", "LinearAlgebra", "ObjectFile", "PrecompileTools", "Preferences", "Printf", "Random", "SparseArrays"]
git-tree-sha1 = "f39747b06eb299ca32c237d8423f092a8391e60f"
uuid = "7da242da-08ed-463a-9acd-ee780be4f1d9"
version = "0.13.28"

    [deps.Enzyme.extensions]
    EnzymeBFloat16sExt = "BFloat16s"
    EnzymeChainRulesCoreExt = "ChainRulesCore"
    EnzymeGPUArraysCoreExt = "GPUArraysCore"
    EnzymeLogExpFunctionsExt = "LogExpFunctions"
    EnzymeSpecialFunctionsExt = "SpecialFunctions"
    EnzymeStaticArraysExt = "StaticArrays"

    [deps.Enzyme.weakdeps]
    BFloat16s = "ab4f0b2a-ad5b-11e8-123f-65d77653426b"
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    GPUArraysCore = "46192b85-c4d5-4398-a991-12ede77f4527"
    LogExpFunctions = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
    SpecialFunctions = "276daf66-3868-5448-9aa4-cd146d93841b"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.EnzymeCore]]
git-tree-sha1 = "0cdb7af5c39e92d78a0ee8d0a447d32f7593137e"
uuid = "f151be2c-9106-41f4-ab19-57ee4f262869"
version = "0.8.8"
weakdeps = ["Adapt"]

    [deps.EnzymeCore.extensions]
    AdaptExt = "Adapt"

[[deps.Enzyme_jll]]
deps = ["Artifacts", "JLLWrappers", "LazyArtifacts", "Libdl", "TOML"]
git-tree-sha1 = "b81b0143399acd84a2ed2a1fa0b4ab55e25ee625"
uuid = "7cc45869-7501-5eee-bdea-0790c847d4ef"
version = "0.0.172+0"

[[deps.EpollShim_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8a4be429317c42cfae6a7fc03c31bad1970c310d"
uuid = "2702e6a9-849d-5ed8-8c21-79e8b8f9ee43"
version = "0.0.20230411+1"

[[deps.ExceptionUnwrapping]]
deps = ["Test"]
git-tree-sha1 = "d36f682e590a83d63d1c7dbd287573764682d12a"
uuid = "460bff9d-24e4-43bc-9d9f-a8973cb893f4"
version = "0.1.11"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e51db81749b0777b2147fbe7b783ee79045b8e99"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.6.4+3"

[[deps.ExprTools]]
git-tree-sha1 = "27415f162e6028e81c72b82ef756bf321213b6ec"
uuid = "e2ba6199-217a-4e67-a87a-7c52f15ade04"
version = "0.1.10"

[[deps.Expronicon]]
deps = ["MLStyle", "Pkg", "TOML"]
git-tree-sha1 = "fc3951d4d398b5515f91d7fe5d45fc31dccb3c9b"
uuid = "6b7a57c9-7cc1-4fdf-b7f5-e857abae3636"
version = "0.8.5"

[[deps.FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "53ebe7511fa11d33bec688a9178fac4e49eeee00"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.2"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "PCRE2_jll", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "466d45dc38e15794ec7d5d63ec03d776a9aff36e"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.4+1"

[[deps.FFTW]]
deps = ["AbstractFFTs", "FFTW_jll", "LinearAlgebra", "MKL_jll", "Preferences", "Reexport"]
git-tree-sha1 = "4820348781ae578893311153d69049a93d05f39d"
uuid = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
version = "1.8.0"

[[deps.FFTW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4d81ed14783ec49ce9f2e168208a12ce1815aa25"
uuid = "f5851436-0d7a-5f13-b9de-f02708fd171a"
version = "3.3.10+3"

[[deps.FastBroadcast]]
deps = ["ArrayInterface", "LinearAlgebra", "Polyester", "Static", "StaticArrayInterface", "StrideArraysCore"]
git-tree-sha1 = "ab1b34570bcdf272899062e1a56285a53ecaae08"
uuid = "7034ab61-46d4-4ed7-9d0f-46aef9175898"
version = "0.3.5"

[[deps.FastClosures]]
git-tree-sha1 = "acebe244d53ee1b461970f8910c235b259e772ef"
uuid = "9aa1b823-49e4-5ca5-8b0f-3971ec8bab6a"
version = "0.3.2"

[[deps.FastLapackInterface]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "cbf5edddb61a43669710cbc2241bc08b36d9e660"
uuid = "29a986be-02c6-4525-aec4-84b980013641"
version = "2.0.4"

[[deps.FastPower]]
git-tree-sha1 = "58c3431137131577a7c379d00fea00be524338fb"
uuid = "a4df4552-cc26-4903-aec0-212e50a0e84b"
version = "1.1.1"

    [deps.FastPower.extensions]
    FastPowerEnzymeExt = "Enzyme"
    FastPowerForwardDiffExt = "ForwardDiff"
    FastPowerMeasurementsExt = "Measurements"
    FastPowerMonteCarloMeasurementsExt = "MonteCarloMeasurements"
    FastPowerReverseDiffExt = "ReverseDiff"
    FastPowerTrackerExt = "Tracker"

    [deps.FastPower.weakdeps]
    Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    Measurements = "eff96d63-e80a-5855-80a2-b1b0885c5ab7"
    MonteCarloMeasurements = "0987c9cc-fe09-11e8-30f0-b96dd679fdca"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"
version = "1.11.0"

[[deps.FillArrays]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "6a70198746448456524cb442b8af316927ff3e1a"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "1.13.0"
weakdeps = ["PDMats", "SparseArrays", "Statistics"]

    [deps.FillArrays.extensions]
    FillArraysPDMatsExt = "PDMats"
    FillArraysSparseArraysExt = "SparseArrays"
    FillArraysStatisticsExt = "Statistics"

[[deps.FiniteDiff]]
deps = ["ArrayInterface", "LinearAlgebra", "Setfield"]
git-tree-sha1 = "84e3a47db33be7248daa6274b287507dd6ff84e8"
uuid = "6a86dc24-6348-571c-b903-95158fe2bd41"
version = "2.26.2"

    [deps.FiniteDiff.extensions]
    FiniteDiffBandedMatricesExt = "BandedMatrices"
    FiniteDiffBlockBandedMatricesExt = "BlockBandedMatrices"
    FiniteDiffSparseArraysExt = "SparseArrays"
    FiniteDiffStaticArraysExt = "StaticArrays"

    [deps.FiniteDiff.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    BlockBandedMatrices = "ffab5731-97b5-5995-9138-79e8c1846df0"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "05882d6995ae5c12bb5f36dd2ed3f61c98cbb172"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.5"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Zlib_jll"]
git-tree-sha1 = "21fac3c77d7b5a9fc03b0ec503aa1a6392c34d2b"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.15.0+0"

[[deps.Format]]
git-tree-sha1 = "9c68794ef81b08086aeb32eeaf33531668d5f5fc"
uuid = "1fa38f19-a742-5d3f-a2b9-30dd87b9d5f8"
version = "1.3.7"

[[deps.ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions"]
git-tree-sha1 = "a2df1b776752e3f344e5116c06d75a10436ab853"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.38"
weakdeps = ["StaticArrays"]

    [deps.ForwardDiff.extensions]
    ForwardDiffStaticArraysExt = "StaticArrays"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "786e968a8d2fb167f2e4880baba62e0e26bd8e4e"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.13.3+1"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "846f7026a9decf3679419122b49f8a1fdb48d2d5"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.16+0"

[[deps.FunctionProperties]]
deps = ["Cassette", "DiffRules"]
git-tree-sha1 = "bf7c740307eb0ee80e05d8aafbd0c5a901578398"
uuid = "f62d2435-5019-4c03-9749-2d4c77af0cbc"
version = "0.1.2"

[[deps.FunctionWrappers]]
git-tree-sha1 = "d62485945ce5ae9c0c48f124a84998d755bae00e"
uuid = "069b7b12-0de2-55c6-9aab-29f3d0a68a2e"
version = "1.1.3"

[[deps.FunctionWrappersWrappers]]
deps = ["FunctionWrappers"]
git-tree-sha1 = "b104d487b34566608f8b4e1c39fb0b10aa279ff8"
uuid = "77dc65aa-8811-40c2-897b-53d922fa7daf"
version = "0.1.3"

[[deps.Functors]]
deps = ["Compat", "ConstructionBase", "LinearAlgebra", "Random"]
git-tree-sha1 = "60a0339f28a233601cb74468032b5c302d5067de"
uuid = "d9f16b24-f501-4c13-a1f2-28368ffc5196"
version = "0.5.2"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"
version = "1.11.0"

[[deps.GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll", "libdecor_jll", "xkbcommon_jll"]
git-tree-sha1 = "fcb0584ff34e25155876418979d4c8971243bb89"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.4.0+2"

[[deps.GPUArrays]]
deps = ["Adapt", "GPUArraysCore", "KernelAbstractions", "LLVM", "LinearAlgebra", "Printf", "Random", "Reexport", "ScopedValues", "Serialization", "Statistics"]
git-tree-sha1 = "86a185085bffbafb11c046f676ee876597b76b66"
uuid = "0c68f7d7-f131-5f86-a1c3-88cf8149b2d7"
version = "11.2.0"

[[deps.GPUArraysCore]]
deps = ["Adapt"]
git-tree-sha1 = "83cf05ab16a73219e5f6bd1bdfa9848fa24ac627"
uuid = "46192b85-c4d5-4398-a991-12ede77f4527"
version = "0.2.0"

[[deps.GPUCompiler]]
deps = ["ExprTools", "InteractiveUtils", "LLVM", "Libdl", "Logging", "PrecompileTools", "Preferences", "Scratch", "Serialization", "TOML", "TimerOutputs", "UUIDs"]
git-tree-sha1 = "72408a76694e87e735f515a499ba1e069d232d39"
uuid = "61eb1bfa-7361-4325-ad38-22787b887f55"
version = "1.0.1"

[[deps.GR]]
deps = ["Artifacts", "Base64", "DelimitedFiles", "Downloads", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Preferences", "Printf", "Qt6Wayland_jll", "Random", "Serialization", "Sockets", "TOML", "Tar", "Test", "p7zip_jll"]
git-tree-sha1 = "424c8f76017e39fdfcdbb5935a8e6742244959e8"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.73.10"

[[deps.GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "FreeType2_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Qt6Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "b90934c8cb33920a8dc66736471dc3961b42ec9f"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.73.10+0"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE2_jll", "Zlib_jll"]
git-tree-sha1 = "b0036b392358c80d2d2124746c2bf3d48d457938"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.82.4+0"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "01979f9b37367603e2848ea225918a3b3861b606"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+1"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "ConcurrentUtilities", "Dates", "ExceptionUnwrapping", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "OpenSSL", "PrecompileTools", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "c67b33b085f6e2faf8bf79a61962e7339a81129c"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.10.15"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll"]
git-tree-sha1 = "55c53be97790242c29031e5cd45e8ac296dadda3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "8.5.0+0"

[[deps.HashArrayMappedTries]]
git-tree-sha1 = "2eaa69a7cab70a52b9687c8bf950a5a93ec895ae"
uuid = "076d061b-32b6-4027-95e0-9a2c6f6d7e74"
version = "0.2.0"

[[deps.HostCPUFeatures]]
deps = ["BitTwiddlingConvenienceFunctions", "IfElse", "Libdl", "Static"]
git-tree-sha1 = "8e070b599339d622e9a081d17230d74a5c473293"
uuid = "3e5b6fbb-0976-4d2c-9146-d79de83f2fb0"
version = "0.1.17"

[[deps.HypergeometricFunctions]]
deps = ["LinearAlgebra", "OpenLibm_jll", "SpecialFunctions"]
git-tree-sha1 = "b1c2585431c382e3fe5805874bda6aea90a95de9"
uuid = "34004b35-14d8-5ef3-9330-4cdb6864b03a"
version = "0.3.25"

[[deps.IRTools]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "950c3717af761bc3ff906c2e8e52bd83390b6ec2"
uuid = "7869d1d1-7146-5819-86e3-90919afe41df"
version = "0.4.14"

[[deps.IfElse]]
git-tree-sha1 = "debdd00ffef04665ccbb3e150747a77560e8fad1"
uuid = "615f187c-cbe4-4ef1-ba3b-2fcf58d6d173"
version = "0.1.1"

[[deps.InitialValues]]
git-tree-sha1 = "4da0f88e9a39111c2fa3add390ab15f3a44f3ca3"
uuid = "22cec73e-a1b8-11e9-2c92-598750a2cf9c"
version = "0.3.1"

[[deps.InplaceOps]]
deps = ["LinearAlgebra", "Test"]
git-tree-sha1 = "50b41d59e7164ab6fda65e71049fee9d890731ff"
uuid = "505f98c9-085e-5b2c-8e89-488be7bf1f34"
version = "0.3.0"

[[deps.IntelOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "LazyArtifacts", "Libdl"]
git-tree-sha1 = "10bd689145d2c3b2a9844005d01087cc1194e79e"
uuid = "1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"
version = "2024.2.1+0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.Interpolations]]
deps = ["Adapt", "AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "88a101217d7cb38a7b481ccd50d21876e1d1b0e0"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.15.1"
weakdeps = ["Unitful"]

    [deps.Interpolations.extensions]
    InterpolationsUnitfulExt = "Unitful"

[[deps.IntervalSets]]
git-tree-sha1 = "dba9ddf07f77f60450fe5d2e2beb9854d9a49bd0"
uuid = "8197267c-284f-5f27-9208-e0e47529a953"
version = "0.7.10"
weakdeps = ["Random", "RecipesBase", "Statistics"]

    [deps.IntervalSets.extensions]
    IntervalSetsRandomExt = "Random"
    IntervalSetsRecipesBaseExt = "RecipesBase"
    IntervalSetsStatisticsExt = "Statistics"

[[deps.InverseFunctions]]
git-tree-sha1 = "a779299d77cd080bf77b97535acecd73e1c5e5cb"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.17"
weakdeps = ["Dates", "Test"]

    [deps.InverseFunctions.extensions]
    InverseFunctionsDatesExt = "Dates"
    InverseFunctionsTestExt = "Test"

[[deps.InvertedIndices]]
git-tree-sha1 = "6da3c4316095de0f5ee2ebd875df8721e7e0bdbe"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.3.1"

[[deps.IrrationalConstants]]
git-tree-sha1 = "630b497eafcc20001bba38a4651b327dcfc491d2"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.2"

[[deps.IterTools]]
git-tree-sha1 = "42d5f897009e7ff2cf88db414a389e5ed1bdd023"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.10.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLFzf]]
deps = ["Pipe", "REPL", "Random", "fzf_jll"]
git-tree-sha1 = "71b48d857e86bf7a1838c4736545699974ce79a2"
uuid = "1019f520-868f-41f5-a6de-eb00f4b6a39c"
version = "0.1.9"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "a007feb38b422fbdab534406aeca1b86823cb4d6"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.7.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "eac1206917768cb54957c65a615460d87b455fc1"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "3.1.1+0"

[[deps.KLU]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse_jll"]
git-tree-sha1 = "07649c499349dad9f08dde4243a4c597064663e9"
uuid = "ef3ab10e-7fda-4108-b977-705223b18434"
version = "0.6.0"

[[deps.KernelAbstractions]]
deps = ["Adapt", "Atomix", "InteractiveUtils", "MacroTools", "PrecompileTools", "Requires", "StaticArrays", "UUIDs"]
git-tree-sha1 = "b9a838cd3028785ac23822cded5126b3da394d1a"
uuid = "63c18a36-062a-441e-b654-da1e3ab1ce7c"
version = "0.9.31"
weakdeps = ["EnzymeCore", "LinearAlgebra", "SparseArrays"]

    [deps.KernelAbstractions.extensions]
    EnzymeExt = "EnzymeCore"
    LinearAlgebraExt = "LinearAlgebra"
    SparseArraysExt = "SparseArrays"

[[deps.KernelDensity]]
deps = ["Distributions", "DocStringExtensions", "FFTW", "Interpolations", "StatsBase"]
git-tree-sha1 = "7d703202e65efa1369de1279c162b915e245eed1"
uuid = "5ab0869b-81aa-558d-bb23-cbf5423bbe9b"
version = "0.6.9"

[[deps.Krylov]]
deps = ["LinearAlgebra", "Printf", "SparseArrays"]
git-tree-sha1 = "4f20a2df85a9e5d55c9e84634bbf808ed038cabd"
uuid = "ba0b0d4f-ebba-5204-a429-3ac8c609bfb7"
version = "0.9.8"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "170b660facf5df5de098d866564877e119141cbd"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.2+0"

[[deps.LBFGSB]]
deps = ["L_BFGS_B_jll"]
git-tree-sha1 = "e2e6f53ee20605d0ea2be473480b7480bd5091b5"
uuid = "5be7bae1-8223-5378-bac3-9e7378a2f6e6"
version = "0.4.1"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "aaafe88dccbd957a8d82f7d05be9b69172e0cee3"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "4.0.1+0"

[[deps.LLVM]]
deps = ["CEnum", "LLVMExtra_jll", "Libdl", "Preferences", "Printf", "Unicode"]
git-tree-sha1 = "d422dfd9707bec6617335dc2ea3c5172a87d5908"
uuid = "929cbde3-209d-540e-8aea-75f648917ca0"
version = "9.1.3"

    [deps.LLVM.extensions]
    BFloat16sExt = "BFloat16s"

    [deps.LLVM.weakdeps]
    BFloat16s = "ab4f0b2a-ad5b-11e8-123f-65d77653426b"

[[deps.LLVMExtra_jll]]
deps = ["Artifacts", "JLLWrappers", "LazyArtifacts", "Libdl", "TOML"]
git-tree-sha1 = "05a8bd5a42309a9ec82f700876903abce1017dd3"
uuid = "dad2f222-ce93-54a1-a47d-0025e8a3acab"
version = "0.0.34+0"

[[deps.LLVMOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "78211fb6cbc872f77cad3fc0b6cf647d923f4929"
uuid = "1d63c593-3942-5779-bab2-d838dc0a180e"
version = "18.1.7+0"

[[deps.LRUCache]]
git-tree-sha1 = "b3cc6698599b10e652832c2f23db3cab99d51b59"
uuid = "8ac3fa9e-de4c-5943-b1dc-09c6b5f20637"
version = "1.6.1"
weakdeps = ["Serialization"]

    [deps.LRUCache.extensions]
    SerializationExt = ["Serialization"]

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "854a9c268c43b77b0a27f22d7fab8d33cdb3a731"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.2+3"

[[deps.L_BFGS_B_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "77feda930ed3f04b2b0fbb5bea89e69d3677c6b0"
uuid = "81d17ec3-03a1-5e46-b53e-bddc35a13473"
version = "3.0.1+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "dda21b8cbd6a6c40d9d02a73230f9d70fed6918c"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.4.0"

[[deps.Latexify]]
deps = ["Format", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "OrderedCollections", "Requires"]
git-tree-sha1 = "ce5f5621cac23a86011836badfedf664a612cee4"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.16.5"

    [deps.Latexify.extensions]
    DataFramesExt = "DataFrames"
    SparseArraysExt = "SparseArrays"
    SymEngineExt = "SymEngine"

    [deps.Latexify.weakdeps]
    DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    SymEngine = "123dc426-2d89-5057-bbad-38513e3affd8"

[[deps.LayoutPointers]]
deps = ["ArrayInterface", "LinearAlgebra", "ManualMemory", "SIMDTypes", "Static", "StaticArrayInterface"]
git-tree-sha1 = "a9eaadb366f5493a5654e843864c13d8b107548c"
uuid = "10f19ff3-798f-405d-979b-55457f8fc047"
version = "0.1.17"

[[deps.LazyArrays]]
deps = ["ArrayLayouts", "FillArrays", "LinearAlgebra", "MacroTools", "SparseArrays"]
git-tree-sha1 = "f289bee714e11708df257c57514585863aa02b33"
uuid = "5078a376-72f3-5289-bfd5-ec5146d43c02"
version = "2.3.1"

    [deps.LazyArrays.extensions]
    LazyArraysBandedMatricesExt = "BandedMatrices"
    LazyArraysBlockArraysExt = "BlockArrays"
    LazyArraysBlockBandedMatricesExt = "BlockBandedMatrices"
    LazyArraysStaticArraysExt = "StaticArrays"

    [deps.LazyArrays.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    BlockArrays = "8e7c35d0-a365-5155-bbbb-fb81a777f24e"
    BlockBandedMatrices = "ffab5731-97b5-5995-9138-79e8c1846df0"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"
version = "1.11.0"

[[deps.LeftChildRightSiblingTrees]]
deps = ["AbstractTrees"]
git-tree-sha1 = "fb6803dafae4a5d62ea5cab204b1e657d9737e7f"
uuid = "1d6d02ad-be62-4b6b-8a6d-2f90e265016e"
version = "0.2.0"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.6.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"
version = "1.11.0"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.7.2+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "27ecae93dd25ee0909666e6835051dd684cc035e"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+2"

[[deps.Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll"]
git-tree-sha1 = "8be878062e0ffa2c3f67bb58a595375eda5de80b"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.11.0+0"

[[deps.Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "ff3b4b9d35de638936a525ecd36e86a8bb919d11"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.7.0+0"

[[deps.Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "df37206100d39f79b3376afb6b9cee4970041c61"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.51.1+0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "61dfdba58e585066d8bce214c5a51eaa0539f269"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.17.0+1"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "84eef7acd508ee5b3e956a2ae51b05024181dee0"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.40.2+2"

[[deps.Libtask]]
deps = ["FunctionWrappers", "LRUCache", "LinearAlgebra", "Statistics"]
git-tree-sha1 = "902ece54b0cb5c5413a8a15db0ad2aa2ec4172d2"
uuid = "6f1fad26-d15e-5dc8-ae53-837a1d7b8c9f"
version = "0.8.8"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "XZ_jll", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "4ab7581296671007fc33f07a721631b8855f4b1d"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.7.1+0"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "edbf5309f9ddf1cab25afc344b1e8150b7c832f9"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.40.2+2"

[[deps.LineSearch]]
deps = ["ADTypes", "CommonSolve", "ConcreteStructs", "FastClosures", "LinearAlgebra", "MaybeInplace", "SciMLBase", "SciMLJacobianOperators", "StaticArraysCore"]
git-tree-sha1 = "97d502765cc5cf3a722120f50da03c2474efce04"
uuid = "87fe0de2-c867-4266-b59a-2f0a94fc965b"
version = "0.1.4"
weakdeps = ["LineSearches"]

    [deps.LineSearch.extensions]
    LineSearchLineSearchesExt = "LineSearches"

[[deps.LineSearches]]
deps = ["LinearAlgebra", "NLSolversBase", "NaNMath", "Parameters", "Printf"]
git-tree-sha1 = "e4c3be53733db1051cc15ecf573b1042b3a712a1"
uuid = "d3d80556-e9d4-5f37-9878-2ab0fcc64255"
version = "7.3.0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.11.0"

[[deps.LinearSolve]]
deps = ["ArrayInterface", "ChainRulesCore", "ConcreteStructs", "DocStringExtensions", "EnumX", "FastLapackInterface", "GPUArraysCore", "InteractiveUtils", "KLU", "Krylov", "LazyArrays", "Libdl", "LinearAlgebra", "MKL_jll", "Markdown", "PrecompileTools", "Preferences", "RecursiveFactorization", "Reexport", "SciMLBase", "SciMLOperators", "Setfield", "SparseArrays", "Sparspak", "StaticArraysCore", "UnPack"]
git-tree-sha1 = "9d5872d134bd33dd3e120767004f760770958863"
uuid = "7ed4a6bd-45f5-4d41-b270-4a48e9bafcae"
version = "2.38.0"

    [deps.LinearSolve.extensions]
    LinearSolveBandedMatricesExt = "BandedMatrices"
    LinearSolveBlockDiagonalsExt = "BlockDiagonals"
    LinearSolveCUDAExt = "CUDA"
    LinearSolveCUDSSExt = "CUDSS"
    LinearSolveEnzymeExt = "EnzymeCore"
    LinearSolveFastAlmostBandedMatricesExt = "FastAlmostBandedMatrices"
    LinearSolveHYPREExt = "HYPRE"
    LinearSolveIterativeSolversExt = "IterativeSolvers"
    LinearSolveKernelAbstractionsExt = "KernelAbstractions"
    LinearSolveKrylovKitExt = "KrylovKit"
    LinearSolveMetalExt = "Metal"
    LinearSolvePardisoExt = "Pardiso"
    LinearSolveRecursiveArrayToolsExt = "RecursiveArrayTools"

    [deps.LinearSolve.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    BlockDiagonals = "0a1fb500-61f7-11e9-3c65-f5ef3456f9f0"
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    CUDSS = "45b445bb-4962-46a0-9369-b4df9d0f772e"
    EnzymeCore = "f151be2c-9106-41f4-ab19-57ee4f262869"
    FastAlmostBandedMatrices = "9d29842c-ecb8-4973-b1e9-a27b1157504e"
    HYPRE = "b5ffcf37-a2bd-41ab-a3da-4bd9bc8ad771"
    IterativeSolvers = "42fd0dbc-a981-5370-80f2-aaf504508153"
    KernelAbstractions = "63c18a36-062a-441e-b654-da1e3ab1ce7c"
    KrylovKit = "0b1a1467-8014-51b9-945f-bf0ae24f4b77"
    Metal = "dde4c033-4e86-420c-a63e-0dd931031962"
    Pardiso = "46dd5b70-b6fb-5a00-ae2d-e8fea33afaf2"
    RecursiveArrayTools = "731186ca-8d62-57ce-b412-fbd966d074cd"

[[deps.LogDensityProblems]]
deps = ["ArgCheck", "DocStringExtensions", "Random"]
git-tree-sha1 = "4e0128c1590d23a50dcdb106c7e2dbca99df85c0"
uuid = "6fdf6af0-433a-55f7-b3ed-c6c6e0b8df7c"
version = "2.1.2"

[[deps.LogDensityProblemsAD]]
deps = ["DocStringExtensions", "LogDensityProblems"]
git-tree-sha1 = "a10e798ac8c44fe1594ad7d6e02898e16e4eafa3"
uuid = "996a588d-648d-4e1f-a8f0-a84b347e47b1"
version = "1.13.0"

    [deps.LogDensityProblemsAD.extensions]
    LogDensityProblemsADADTypesExt = "ADTypes"
    LogDensityProblemsADDifferentiationInterfaceExt = ["ADTypes", "DifferentiationInterface"]
    LogDensityProblemsADEnzymeExt = "Enzyme"
    LogDensityProblemsADFiniteDifferencesExt = "FiniteDifferences"
    LogDensityProblemsADForwardDiffBenchmarkToolsExt = ["BenchmarkTools", "ForwardDiff"]
    LogDensityProblemsADForwardDiffExt = "ForwardDiff"
    LogDensityProblemsADReverseDiffExt = "ReverseDiff"
    LogDensityProblemsADTrackerExt = "Tracker"
    LogDensityProblemsADZygoteExt = "Zygote"

    [deps.LogDensityProblemsAD.weakdeps]
    ADTypes = "47edcb42-4c32-4615-8424-f2b9edc5f35b"
    BenchmarkTools = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
    DifferentiationInterface = "a0c0ee7d-e4b9-4e03-894e-1c5f64a51d63"
    Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"
    FiniteDifferences = "26cc04aa-876d-5657-8c51-4c34ba976000"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "13ca9e2586b89836fd20cccf56e57e2b9ae7f38f"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.29"
weakdeps = ["ChainRulesCore", "ChangesOfVariables", "InverseFunctions"]

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

[[deps.LoggingExtras]]
deps = ["Dates", "Logging"]
git-tree-sha1 = "f02b56007b064fbfddb4c9cd60161b6dd0f40df3"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "1.1.0"

[[deps.LoopVectorization]]
deps = ["ArrayInterface", "CPUSummary", "CloseOpenIntervals", "DocStringExtensions", "HostCPUFeatures", "IfElse", "LayoutPointers", "LinearAlgebra", "OffsetArrays", "PolyesterWeave", "PrecompileTools", "SIMDTypes", "SLEEFPirates", "Static", "StaticArrayInterface", "ThreadingUtilities", "UnPack", "VectorizationBase"]
git-tree-sha1 = "8084c25a250e00ae427a379a5b607e7aed96a2dd"
uuid = "bdcacae8-1622-11e9-2a5c-532679323890"
version = "0.12.171"
weakdeps = ["ChainRulesCore", "ForwardDiff", "SpecialFunctions"]

    [deps.LoopVectorization.extensions]
    ForwardDiffExt = ["ChainRulesCore", "ForwardDiff"]
    SpecialFunctionsExt = "SpecialFunctions"

[[deps.MCMCChains]]
deps = ["AbstractMCMC", "AxisArrays", "Dates", "Distributions", "IteratorInterfaceExtensions", "KernelDensity", "LinearAlgebra", "MCMCDiagnosticTools", "MLJModelInterface", "NaturalSort", "OrderedCollections", "PrettyTables", "Random", "RecipesBase", "Statistics", "StatsBase", "StatsFuns", "TableTraits", "Tables"]
git-tree-sha1 = "cd7aee22384792c726e19f2a22dc060b886edded"
uuid = "c7f686f2-ff18-58e9-bc7b-31028e88f75d"
version = "6.0.7"

[[deps.MCMCDiagnosticTools]]
deps = ["AbstractFFTs", "DataAPI", "DataStructures", "Distributions", "LinearAlgebra", "MLJModelInterface", "Random", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns", "Tables"]
git-tree-sha1 = "a586f05dd16a50c490ed95415b2a829b8cf5d57f"
uuid = "be115224-59cd-429b-ad48-344e309966f0"
version = "0.3.14"

[[deps.MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "oneTBB_jll"]
git-tree-sha1 = "f046ccd0c6db2832a9f639e2c669c6fe867e5f4f"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2024.2.0+0"

[[deps.MLJModelInterface]]
deps = ["Random", "ScientificTypesBase", "StatisticalTraits"]
git-tree-sha1 = "ceaff6618408d0e412619321ae43b33b40c1a733"
uuid = "e80e1ace-859a-464e-9ed9-23947d8ae3ea"
version = "1.11.0"

[[deps.MLStyle]]
git-tree-sha1 = "bc38dff0548128765760c79eb7388a4b37fae2c8"
uuid = "d8e11817-5142-5d16-987a-aa16d5891078"
version = "0.4.17"

[[deps.MacroTools]]
git-tree-sha1 = "72aebe0b5051e5143a079a4685a46da330a40472"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.15"

[[deps.ManualMemory]]
git-tree-sha1 = "bcaef4fc7a0cfe2cba636d84cda54b5e4e4ca3cd"
uuid = "d125e4d3-2237-4719-b19c-fa641b8a4667"
version = "0.1.8"

[[deps.MappedArrays]]
git-tree-sha1 = "2dab0221fe2b0f2cb6754eaa743cc266339f527e"
uuid = "dbb5928d-eab1-5f90-85c2-b9b0edb7c900"
version = "0.4.2"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MaybeInplace]]
deps = ["ArrayInterface", "LinearAlgebra", "MacroTools"]
git-tree-sha1 = "54e2fdc38130c05b42be423e90da3bade29b74bd"
uuid = "bb5d69b7-63fc-4a16-80bd-7e42200c7bdb"
version = "0.1.4"
weakdeps = ["SparseArrays"]

    [deps.MaybeInplace.extensions]
    MaybeInplaceSparseArraysExt = "SparseArrays"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "NetworkOptions", "Random", "Sockets"]
git-tree-sha1 = "c067a280ddc25f196b5e7df3877c6b226d390aaf"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.9"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.6+0"

[[deps.Measures]]
git-tree-sha1 = "c13304c81eec1ed3af7fc20e75fb6b26092a1102"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.2"

[[deps.MicroCollections]]
deps = ["Accessors", "BangBang", "InitialValues"]
git-tree-sha1 = "44d32db644e84c75dab479f1bc15ee76a1a3618f"
uuid = "128add7d-3638-4c79-886c-908ea0c25c34"
version = "0.2.0"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "ec4f7fbeab05d7747bdf98eb74d130a2a2ed298d"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.2.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"
version = "1.11.0"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.12.12"

[[deps.MuladdMacro]]
git-tree-sha1 = "cac9cc5499c25554cba55cd3c30543cff5ca4fab"
uuid = "46d2c3a1-f734-5fdb-9937-b9b9aeba4221"
version = "0.2.4"

[[deps.MultivariateStats]]
deps = ["Arpack", "Distributions", "LinearAlgebra", "SparseArrays", "Statistics", "StatsAPI", "StatsBase"]
git-tree-sha1 = "816620e3aac93e5b5359e4fdaf23ca4525b00ddf"
uuid = "6f286f6a-111f-5878-ab1e-185364afe411"
version = "0.10.3"

[[deps.NLSolversBase]]
deps = ["DiffResults", "Distributed", "FiniteDiff", "ForwardDiff"]
git-tree-sha1 = "a0b464d183da839699f4c79e7606d9d186ec172c"
uuid = "d41bc354-129a-5804-8e4c-c37616107c6c"
version = "7.8.3"

[[deps.NNlib]]
deps = ["Adapt", "Atomix", "ChainRulesCore", "GPUArraysCore", "KernelAbstractions", "LinearAlgebra", "Random", "Statistics"]
git-tree-sha1 = "bdc9d30f151590aca0af22690f5ab7dc18a551cb"
uuid = "872c559c-99b0-510c-b3b7-b6c96a88d5cd"
version = "0.9.27"

    [deps.NNlib.extensions]
    NNlibAMDGPUExt = "AMDGPU"
    NNlibCUDACUDNNExt = ["CUDA", "cuDNN"]
    NNlibCUDAExt = "CUDA"
    NNlibEnzymeCoreExt = "EnzymeCore"
    NNlibFFTWExt = "FFTW"
    NNlibForwardDiffExt = "ForwardDiff"

    [deps.NNlib.weakdeps]
    AMDGPU = "21141c5a-9bdb-4563-92ae-f87d6854732e"
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    EnzymeCore = "f151be2c-9106-41f4-ab19-57ee4f262869"
    FFTW = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    cuDNN = "02a925ec-e4fe-4b08-9a7e-0d78e3d38ccd"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "030ea22804ef91648f29b7ad3fc15fa49d0e6e71"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.3"

[[deps.NamedArrays]]
deps = ["Combinatorics", "DataStructures", "DelimitedFiles", "InvertedIndices", "LinearAlgebra", "Random", "Requires", "SparseArrays", "Statistics"]
git-tree-sha1 = "58e317b3b956b8aaddfd33ff4c3e33199cd8efce"
uuid = "86f7a689-2022-50b4-a561-43c23ac3c673"
version = "0.10.3"

[[deps.NaturalSort]]
git-tree-sha1 = "eda490d06b9f7c00752ee81cfa451efe55521e21"
uuid = "c020b1a1-e9b0-503a-9c33-f039bfc54a85"
version = "1.0.0"

[[deps.NearestNeighbors]]
deps = ["Distances", "StaticArrays"]
git-tree-sha1 = "8a3271d8309285f4db73b4f662b1b290c715e85e"
uuid = "b8a86587-4115-5ab1-83bc-aa920d37bbce"
version = "0.4.21"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.NonlinearSolveBase]]
deps = ["ADTypes", "Adapt", "ArrayInterface", "CommonSolve", "Compat", "ConcreteStructs", "DifferentiationInterface", "EnzymeCore", "FastClosures", "LinearAlgebra", "Markdown", "MaybeInplace", "Preferences", "Printf", "RecursiveArrayTools", "SciMLBase", "SciMLJacobianOperators", "SciMLOperators", "StaticArraysCore", "SymbolicIndexingInterface", "TimerOutputs"]
git-tree-sha1 = "5bca24ce7b0c034dcbdc6ad6d658b02e0eed566e"
uuid = "be0214bd-f91f-a760-ac4e-3421ce2b2da0"
version = "1.4.0"

    [deps.NonlinearSolveBase.extensions]
    NonlinearSolveBaseBandedMatricesExt = "BandedMatrices"
    NonlinearSolveBaseDiffEqBaseExt = "DiffEqBase"
    NonlinearSolveBaseForwardDiffExt = "ForwardDiff"
    NonlinearSolveBaseLineSearchExt = "LineSearch"
    NonlinearSolveBaseLinearSolveExt = "LinearSolve"
    NonlinearSolveBaseSparseArraysExt = "SparseArrays"
    NonlinearSolveBaseSparseMatrixColoringsExt = "SparseMatrixColorings"

    [deps.NonlinearSolveBase.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    DiffEqBase = "2b5f629d-d688-5b77-993f-72d75c75574e"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    LineSearch = "87fe0de2-c867-4266-b59a-2f0a94fc965b"
    LinearSolve = "7ed4a6bd-45f5-4d41-b270-4a48e9bafcae"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    SparseMatrixColorings = "0a514795-09f3-496d-8182-132a7b665d35"

[[deps.NonlinearSolveFirstOrder]]
deps = ["ADTypes", "ArrayInterface", "CommonSolve", "ConcreteStructs", "DiffEqBase", "FiniteDiff", "ForwardDiff", "LineSearch", "LinearAlgebra", "LinearSolve", "MaybeInplace", "NonlinearSolveBase", "PrecompileTools", "Reexport", "SciMLBase", "SciMLJacobianOperators", "Setfield", "StaticArraysCore"]
git-tree-sha1 = "a1ea35ab0bcc99753e26d574ba1e339f19d100fa"
uuid = "5959db7a-ea39-4486-b5fe-2dd0bf03d60d"
version = "1.2.0"

[[deps.ObjectFile]]
deps = ["Reexport", "StructIO"]
git-tree-sha1 = "dfcc26739b1ffa3ab51fb16f01ba7eb144f7bc50"
uuid = "d8793406-e978-5875-9003-1fc021f44a92"
version = "0.4.3"

[[deps.Observables]]
git-tree-sha1 = "7438a59546cf62428fc9d1bc94729146d37a7225"
uuid = "510215fc-4207-5dde-b226-833fc4488ee2"
version = "0.5.5"

[[deps.OffsetArrays]]
git-tree-sha1 = "5e1897147d1ff8d98883cda2be2187dcf57d8f0c"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.15.0"
weakdeps = ["Adapt"]

    [deps.OffsetArrays.extensions]
    OffsetArraysAdaptExt = "Adapt"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.27+1"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+2"

[[deps.OpenSSL]]
deps = ["BitFlags", "Dates", "MozillaCACerts_jll", "OpenSSL_jll", "Sockets"]
git-tree-sha1 = "38cb508d080d21dc1128f7fb04f20387ed4c0af4"
uuid = "4d8831e6-92b7-49fb-bdf8-b643e874388c"
version = "1.4.3"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "7493f61f55a6cce7325f197443aa80d32554ba10"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.0.15+3"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1346c9208249809840c91b26703912dff463d335"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.6+0"

[[deps.Optim]]
deps = ["Compat", "FillArrays", "ForwardDiff", "LineSearches", "LinearAlgebra", "NLSolversBase", "NaNMath", "Parameters", "PositiveFactorizations", "Printf", "SparseArrays", "StatsBase"]
git-tree-sha1 = "ab7edad78cdef22099f43c54ef77ac63c2c9cc64"
uuid = "429524aa-4258-5aef-a3af-852621145aeb"
version = "1.10.0"

    [deps.Optim.extensions]
    OptimMOIExt = "MathOptInterface"

    [deps.Optim.weakdeps]
    MathOptInterface = "b8f27783-ece8-5eb3-8dc8-9495eed66fee"

[[deps.Optimisers]]
deps = ["ChainRulesCore", "Functors", "LinearAlgebra", "Random", "Statistics"]
git-tree-sha1 = "53ff746a3a2b232a37dbcd262ac8bbb2b18202b8"
uuid = "3bd65402-5787-11e9-1adc-39752487f4e2"
version = "0.4.4"
weakdeps = ["Adapt", "EnzymeCore"]

    [deps.Optimisers.extensions]
    OptimisersAdaptExt = ["Adapt"]
    OptimisersEnzymeCoreExt = "EnzymeCore"

[[deps.Optimization]]
deps = ["ADTypes", "ArrayInterface", "ConsoleProgressMonitor", "DocStringExtensions", "LBFGSB", "LinearAlgebra", "Logging", "LoggingExtras", "OptimizationBase", "Printf", "ProgressLogging", "Reexport", "SciMLBase", "SparseArrays", "TerminalLoggers"]
git-tree-sha1 = "4b59eef21418fbdf28afbe2d7e945d8efbe5057d"
uuid = "7f7a1694-90dd-40f0-9382-eb1efda571ba"
version = "4.0.5"

[[deps.OptimizationBBO]]
deps = ["BlackBoxOptim", "Optimization", "Reexport"]
git-tree-sha1 = "62d34beecb9af84159045cfe2b09691b0fb66598"
uuid = "3e6eede4-6085-4f62-9a71-46d9bc1eb92b"
version = "0.4.0"

[[deps.OptimizationBase]]
deps = ["ADTypes", "ArrayInterface", "DifferentiationInterface", "DocStringExtensions", "FastClosures", "LinearAlgebra", "PDMats", "Reexport", "Requires", "SciMLBase", "SparseArrays", "SparseConnectivityTracer", "SparseMatrixColorings"]
git-tree-sha1 = "9e8569bc1c511c425fdc63f7ee41f2da057f8662"
uuid = "bca83a33-5cc9-4baa-983d-23429ab6bcbb"
version = "2.4.0"

    [deps.OptimizationBase.extensions]
    OptimizationEnzymeExt = "Enzyme"
    OptimizationFiniteDiffExt = "FiniteDiff"
    OptimizationForwardDiffExt = "ForwardDiff"
    OptimizationMLDataDevicesExt = "MLDataDevices"
    OptimizationMLUtilsExt = "MLUtils"
    OptimizationMTKExt = "ModelingToolkit"
    OptimizationReverseDiffExt = "ReverseDiff"
    OptimizationSymbolicAnalysisExt = "SymbolicAnalysis"
    OptimizationZygoteExt = "Zygote"

    [deps.OptimizationBase.weakdeps]
    Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"
    FiniteDiff = "6a86dc24-6348-571c-b903-95158fe2bd41"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    MLDataDevices = "7e8f7934-dd98-4c1a-8fe8-92b47a384d40"
    MLUtils = "f1d291b0-491e-4a28-83b9-f70985020b54"
    ModelingToolkit = "961ee093-0014-501f-94e3-6117800e7a78"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    SymbolicAnalysis = "4297ee4d-0239-47d8-ba5d-195ecdf594fe"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.OptimizationOptimJL]]
deps = ["Optim", "Optimization", "PrecompileTools", "Reexport", "SparseArrays"]
git-tree-sha1 = "980ec7190741db164a2923dc42d6f1e7ce2cc434"
uuid = "36348300-93cb-4f02-beb5-3c3902f8871e"
version = "0.4.1"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6703a85cb3781bd5909d48730a67205f3f31a575"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.3+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "12f1439c4f986bb868acda6ea33ebc78e19b95ad"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.7.0"

[[deps.OrdinaryDiffEqCore]]
deps = ["ADTypes", "Accessors", "Adapt", "ArrayInterface", "DataStructures", "DiffEqBase", "DocStringExtensions", "EnumX", "FastBroadcast", "FastClosures", "FastPower", "FillArrays", "FunctionWrappersWrappers", "InteractiveUtils", "LinearAlgebra", "Logging", "MacroTools", "MuladdMacro", "Polyester", "PrecompileTools", "Preferences", "RecursiveArrayTools", "Reexport", "SciMLBase", "SciMLOperators", "SciMLStructures", "SimpleUnPack", "Static", "StaticArrayInterface", "StaticArraysCore", "SymbolicIndexingInterface", "TruncatedStacktraces"]
git-tree-sha1 = "72c77ae685fddb6291fff22dba13f4f32602475c"
uuid = "bbf590c4-e513-4bbe-9b18-05decba2e5d8"
version = "1.14.1"
weakdeps = ["EnzymeCore"]

    [deps.OrdinaryDiffEqCore.extensions]
    OrdinaryDiffEqCoreEnzymeCoreExt = "EnzymeCore"

[[deps.OrdinaryDiffEqTsit5]]
deps = ["DiffEqBase", "FastBroadcast", "LinearAlgebra", "MuladdMacro", "OrdinaryDiffEqCore", "PrecompileTools", "Preferences", "RecursiveArrayTools", "Reexport", "Static", "TruncatedStacktraces"]
git-tree-sha1 = "96552f7d4619fabab4038a29ed37dd55e9eb513a"
uuid = "b1df2697-797e-41e3-8120-5422d3b24e4a"
version = "1.1.0"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.42.0+1"

[[deps.PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "949347156c25054de2db3b166c52ac4728cbad65"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.31"

[[deps.Pango_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "FriBidi_jll", "Glib_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "ed6834e95bd326c52d5675b4181386dfbe885afb"
uuid = "36c8627f-9965-5494-a995-c6b170f724f3"
version = "1.55.5+0"

[[deps.Parameters]]
deps = ["OrderedCollections", "UnPack"]
git-tree-sha1 = "34c0e9ad262e5f7fc75b10a9952ca7692cfc5fbe"
uuid = "d96e819e-fc66-5662-9728-84c9c7592b0a"
version = "0.12.3"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "8489905bcdbcfac64d1daa51ca07c0d8f0283821"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.1"

[[deps.Pipe]]
git-tree-sha1 = "6842804e7867b115ca9de748a0cf6b364523c16d"
uuid = "b98c9c47-44ae-5843-9183-064241ee97a0"
version = "1.3.0"

[[deps.Pixman_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "LLVMOpenMP_jll", "Libdl"]
git-tree-sha1 = "35621f10a7531bc8fa58f74610b1bfb70a3cfc6b"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.43.4+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.11.0"
weakdeps = ["REPL"]

    [deps.Pkg.extensions]
    REPLExt = "REPL"

[[deps.PlotThemes]]
deps = ["PlotUtils", "Statistics"]
git-tree-sha1 = "41031ef3a1be6f5bbbf3e8073f210556daeae5ca"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "3.3.0"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "PrecompileTools", "Printf", "Random", "Reexport", "StableRNGs", "Statistics"]
git-tree-sha1 = "3ca9a356cd2e113c420f2c13bea19f8d3fb1cb18"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.4.3"

[[deps.Plots]]
deps = ["Base64", "Contour", "Dates", "Downloads", "FFMPEG", "FixedPointNumbers", "GR", "JLFzf", "JSON", "LaTeXStrings", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "Pkg", "PlotThemes", "PlotUtils", "PrecompileTools", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "RelocatableFolders", "Requires", "Scratch", "Showoff", "SparseArrays", "Statistics", "StatsBase", "TOML", "UUIDs", "UnicodeFun", "UnitfulLatexify", "Unzip"]
git-tree-sha1 = "dae01f8c2e069a683d3a6e17bbae5070ab94786f"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.40.9"

    [deps.Plots.extensions]
    FileIOExt = "FileIO"
    GeometryBasicsExt = "GeometryBasics"
    IJuliaExt = "IJulia"
    ImageInTerminalExt = "ImageInTerminal"
    UnitfulExt = "Unitful"

    [deps.Plots.weakdeps]
    FileIO = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
    GeometryBasics = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
    IJulia = "7073ff75-c697-5162-941a-fcdaad2a7d2a"
    ImageInTerminal = "d8c32880-2388-543b-8c61-d9f865259254"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.PoissonRandom]]
deps = ["Random"]
git-tree-sha1 = "a0f1159c33f846aa77c3f30ebbc69795e5327152"
uuid = "e409e4f3-bfea-5376-8464-e040bb5c01ab"
version = "0.4.4"

[[deps.Polyester]]
deps = ["ArrayInterface", "BitTwiddlingConvenienceFunctions", "CPUSummary", "IfElse", "ManualMemory", "PolyesterWeave", "Static", "StaticArrayInterface", "StrideArraysCore", "ThreadingUtilities"]
git-tree-sha1 = "6d38fea02d983051776a856b7df75b30cf9a3c1f"
uuid = "f517fe37-dbe3-4b94-8317-1923a5111588"
version = "0.7.16"

[[deps.PolyesterWeave]]
deps = ["BitTwiddlingConvenienceFunctions", "CPUSummary", "IfElse", "Static", "ThreadingUtilities"]
git-tree-sha1 = "645bed98cd47f72f67316fd42fc47dee771aefcd"
uuid = "1d0040c9-8b98-4ee7-8388-3f51789ca0ad"
version = "0.2.2"

[[deps.PositiveFactorizations]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "17275485f373e6673f7e7f97051f703ed5b15b20"
uuid = "85a6dd25-e78a-55b7-8502-1745935b8125"
version = "0.2.4"

[[deps.PreallocationTools]]
deps = ["Adapt", "ArrayInterface", "ForwardDiff"]
git-tree-sha1 = "6c62ce45f268f3f958821a1e5192cf91c75ae89c"
uuid = "d236fae5-4411-538c-8e31-a6e3d9e00b46"
version = "0.4.24"
weakdeps = ["ReverseDiff"]

    [deps.PreallocationTools.extensions]
    PreallocationToolsReverseDiffExt = "ReverseDiff"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "5aa36f7049a63a1528fe8f7c3f2113413ffd4e1f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.1"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "9306f6085165d270f7e3db02af26a400d580f5c6"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.3"

[[deps.PrettyTables]]
deps = ["Crayons", "LaTeXStrings", "Markdown", "PrecompileTools", "Printf", "Reexport", "StringManipulation", "Tables"]
git-tree-sha1 = "1101cd475833706e4d0e7b122218257178f48f34"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "2.4.0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.ProgressLogging]]
deps = ["Logging", "SHA", "UUIDs"]
git-tree-sha1 = "80d919dee55b9c50e8d9e2da5eeafff3fe58b539"
uuid = "33c8b6b6-d38a-422a-b730-caa89a2f386c"
version = "0.1.4"

[[deps.ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "8f6bc219586aef8baf0ff9a5fe16ee9c70cb65e4"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.10.2"

[[deps.PtrArrays]]
git-tree-sha1 = "77a42d78b6a92df47ab37e177b2deac405e1c88f"
uuid = "43287f4e-b6f4-7ad1-bb20-aadabca52c3d"
version = "1.2.1"

[[deps.Qt6Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Vulkan_Loader_jll", "Xorg_libSM_jll", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_cursor_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "libinput_jll", "xkbcommon_jll"]
git-tree-sha1 = "492601870742dcd38f233b23c3ec629628c1d724"
uuid = "c0090381-4147-56d7-9ebc-da0b1113ec56"
version = "6.7.1+1"

[[deps.Qt6Declarative_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Qt6Base_jll", "Qt6ShaderTools_jll"]
git-tree-sha1 = "e5dd466bf2569fe08c91a2cc29c1003f4797ac3b"
uuid = "629bc702-f1f5-5709-abd5-49b8460ea067"
version = "6.7.1+2"

[[deps.Qt6ShaderTools_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Qt6Base_jll"]
git-tree-sha1 = "1a180aeced866700d4bebc3120ea1451201f16bc"
uuid = "ce943373-25bb-56aa-8eca-768745ed7b5a"
version = "6.7.1+1"

[[deps.Qt6Wayland_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Qt6Base_jll", "Qt6Declarative_jll"]
git-tree-sha1 = "729927532d48cf79f49070341e1d918a65aba6b0"
uuid = "e99dba38-086e-5de3-a5b1-6e4c66e897c3"
version = "6.7.1+1"

[[deps.QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "cda3b045cf9ef07a08ad46731f5a3165e56cf3da"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.11.1"
weakdeps = ["Enzyme"]

    [deps.QuadGK.extensions]
    QuadGKEnzymeExt = "Enzyme"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "StyledStrings", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.Random123]]
deps = ["Random", "RandomNumbers"]
git-tree-sha1 = "4743b43e5a9c4a2ede372de7061eed81795b12e7"
uuid = "74087812-796a-5b5d-8853-05524746bad3"
version = "1.7.0"

[[deps.RandomNumbers]]
deps = ["Random"]
git-tree-sha1 = "c6ec94d2aaba1ab2ff983052cf6a606ca5985902"
uuid = "e6cf234a-135c-5ec9-84dd-332b85af5143"
version = "1.6.0"

[[deps.RangeArrays]]
git-tree-sha1 = "b9039e93773ddcfc828f12aadf7115b4b4d225f5"
uuid = "b3c3ace0-ae52-54e7-9d0b-2c1406fd6b9d"
version = "0.3.2"

[[deps.Ratios]]
deps = ["Requires"]
git-tree-sha1 = "1342a47bf3260ee108163042310d26f2be5ec90b"
uuid = "c84ed2f1-dad5-54f0-aa8e-dbefe2724439"
version = "0.4.5"
weakdeps = ["FixedPointNumbers"]

    [deps.Ratios.extensions]
    RatiosFixedPointNumbersExt = "FixedPointNumbers"

[[deps.RealDot]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "9f0a1b71baaf7650f4fa8a1d168c7fb6ee41f0c9"
uuid = "c1ae055f-0cd5-4b69-90a6-9a35b1a98df9"
version = "0.1.0"

[[deps.RecipesBase]]
deps = ["PrecompileTools"]
git-tree-sha1 = "5c3d09cc4f31f5fc6af001c250bf1278733100ff"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.3.4"

[[deps.RecipesPipeline]]
deps = ["Dates", "NaNMath", "PlotUtils", "PrecompileTools", "RecipesBase"]
git-tree-sha1 = "45cf9fd0ca5839d06ef333c8201714e888486342"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.6.12"

[[deps.RecursiveArrayTools]]
deps = ["Adapt", "ArrayInterface", "DocStringExtensions", "GPUArraysCore", "IteratorInterfaceExtensions", "LinearAlgebra", "RecipesBase", "StaticArraysCore", "Statistics", "SymbolicIndexingInterface", "Tables"]
git-tree-sha1 = "32f824db4e5bab64e25a12b22483a30a6b813d08"
uuid = "731186ca-8d62-57ce-b412-fbd966d074cd"
version = "3.27.4"

    [deps.RecursiveArrayTools.extensions]
    RecursiveArrayToolsFastBroadcastExt = "FastBroadcast"
    RecursiveArrayToolsForwardDiffExt = "ForwardDiff"
    RecursiveArrayToolsMeasurementsExt = "Measurements"
    RecursiveArrayToolsMonteCarloMeasurementsExt = "MonteCarloMeasurements"
    RecursiveArrayToolsReverseDiffExt = ["ReverseDiff", "Zygote"]
    RecursiveArrayToolsSparseArraysExt = ["SparseArrays"]
    RecursiveArrayToolsStructArraysExt = "StructArrays"
    RecursiveArrayToolsTrackerExt = "Tracker"
    RecursiveArrayToolsZygoteExt = "Zygote"

    [deps.RecursiveArrayTools.weakdeps]
    FastBroadcast = "7034ab61-46d4-4ed7-9d0f-46aef9175898"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    Measurements = "eff96d63-e80a-5855-80a2-b1b0885c5ab7"
    MonteCarloMeasurements = "0987c9cc-fe09-11e8-30f0-b96dd679fdca"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    StructArrays = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.RecursiveFactorization]]
deps = ["LinearAlgebra", "LoopVectorization", "Polyester", "PrecompileTools", "StrideArraysCore", "TriangularSolve"]
git-tree-sha1 = "6db1a75507051bc18bfa131fbc7c3f169cc4b2f6"
uuid = "f2c3362d-daeb-58d1-803e-2bc74f2840b4"
version = "0.2.23"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "ffdaf70d81cf6ff22c2b6e733c900c3321cab864"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "1.0.1"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.ResettableStacks]]
deps = ["StaticArrays"]
git-tree-sha1 = "256eeeec186fa7f26f2801732774ccf277f05db9"
uuid = "ae5879a3-cd67-5da8-be7f-38c6eb64a37b"
version = "1.1.1"

[[deps.ReverseDiff]]
deps = ["ChainRulesCore", "DiffResults", "DiffRules", "ForwardDiff", "FunctionWrappers", "LinearAlgebra", "LogExpFunctions", "MacroTools", "NaNMath", "Random", "SpecialFunctions", "StaticArrays", "Statistics"]
git-tree-sha1 = "cc6cd622481ea366bb9067859446a8b01d92b468"
uuid = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
version = "1.15.3"

[[deps.Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "852bd0f55565a9e973fcfee83a84413270224dc4"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.8.0"

[[deps.Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "58cdd8fb2201a6267e1db87ff148dd6c1dbd8ad8"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.5.1+0"

[[deps.Roots]]
deps = ["Accessors", "CommonSolve", "Printf"]
git-tree-sha1 = "f233e0a3de30a6eed170b8e1be0440f732fdf456"
uuid = "f2b01f46-fcfa-551c-844a-d8ac1e96c665"
version = "2.2.4"

    [deps.Roots.extensions]
    RootsChainRulesCoreExt = "ChainRulesCore"
    RootsForwardDiffExt = "ForwardDiff"
    RootsIntervalRootFindingExt = "IntervalRootFinding"
    RootsSymPyExt = "SymPy"
    RootsSymPyPythonCallExt = "SymPyPythonCall"

    [deps.Roots.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    IntervalRootFinding = "d2bf35a9-74e0-55ec-b149-d360ff49b807"
    SymPy = "24249f21-da20-56a4-8eb1-6a02cf4ae2e6"
    SymPyPythonCall = "bc8888f7-b21e-4b7c-a06a-5d9c9496438c"

[[deps.RuntimeGeneratedFunctions]]
deps = ["ExprTools", "SHA", "Serialization"]
git-tree-sha1 = "04c968137612c4a5629fa531334bb81ad5680f00"
uuid = "7e49a35a-f44a-4d26-94aa-eba1b4ca6b47"
version = "0.5.13"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SIMDTypes]]
git-tree-sha1 = "330289636fb8107c5f32088d2741e9fd7a061a5c"
uuid = "94e857df-77ce-4151-89e5-788b33177be4"
version = "0.1.0"

[[deps.SLEEFPirates]]
deps = ["IfElse", "Static", "VectorizationBase"]
git-tree-sha1 = "456f610ca2fbd1c14f5fcf31c6bfadc55e7d66e0"
uuid = "476501e8-09a2-5ece-8869-fb82de89a1fa"
version = "0.6.43"

[[deps.SSMProblems]]
deps = ["AbstractMCMC"]
git-tree-sha1 = "f640e4e8343c9d5f470e2f6ca6ce79f708ab6376"
uuid = "26aad666-b158-4e64-9d35-0e672562fa48"
version = "0.1.1"

[[deps.SciMLBase]]
deps = ["ADTypes", "Accessors", "ArrayInterface", "CommonSolve", "ConstructionBase", "Distributed", "DocStringExtensions", "EnumX", "Expronicon", "FunctionWrappersWrappers", "IteratorInterfaceExtensions", "LinearAlgebra", "Logging", "Markdown", "PrecompileTools", "Preferences", "Printf", "RecipesBase", "RecursiveArrayTools", "Reexport", "RuntimeGeneratedFunctions", "SciMLOperators", "SciMLStructures", "StaticArraysCore", "Statistics", "SymbolicIndexingInterface"]
git-tree-sha1 = "3e5a9c5d6432b77a271646b4ada2573f239ac5c4"
uuid = "0bca4576-84f4-4d90-8ffe-ffa030f20462"
version = "2.70.0"

    [deps.SciMLBase.extensions]
    SciMLBaseChainRulesCoreExt = "ChainRulesCore"
    SciMLBaseMakieExt = "Makie"
    SciMLBasePartialFunctionsExt = "PartialFunctions"
    SciMLBasePyCallExt = "PyCall"
    SciMLBasePythonCallExt = "PythonCall"
    SciMLBaseRCallExt = "RCall"
    SciMLBaseZygoteExt = "Zygote"

    [deps.SciMLBase.weakdeps]
    ChainRules = "082447d4-558c-5d27-93f4-14fc19e9eca2"
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    Makie = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"
    PartialFunctions = "570af359-4316-4cb7-8c74-252c00c2016b"
    PyCall = "438e738f-606a-5dbb-bf0a-cddfbfd45ab0"
    PythonCall = "6099a3de-0909-46bc-b1f4-468b9a2dfc0d"
    RCall = "6f49c342-dc21-5d91-9882-a32aef131414"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.SciMLJacobianOperators]]
deps = ["ADTypes", "ArrayInterface", "ConcreteStructs", "ConstructionBase", "DifferentiationInterface", "FastClosures", "LinearAlgebra", "SciMLBase", "SciMLOperators"]
git-tree-sha1 = "f66048bb969e67bd7d1bdd03cd0b81219642bbd0"
uuid = "19f34311-ddf3-4b8b-af20-060888a46c0e"
version = "0.1.1"

[[deps.SciMLOperators]]
deps = ["Accessors", "ArrayInterface", "DocStringExtensions", "LinearAlgebra", "MacroTools"]
git-tree-sha1 = "6149620767866d4b0f0f7028639b6e661b6a1e44"
uuid = "c0aeaf25-5076-4817-a8d5-81caf7dfa961"
version = "0.3.12"
weakdeps = ["SparseArrays", "StaticArraysCore"]

    [deps.SciMLOperators.extensions]
    SciMLOperatorsSparseArraysExt = "SparseArrays"
    SciMLOperatorsStaticArraysCoreExt = "StaticArraysCore"

[[deps.SciMLSensitivity]]
deps = ["ADTypes", "Accessors", "Adapt", "ArrayInterface", "ChainRulesCore", "DiffEqBase", "DiffEqCallbacks", "DiffEqNoiseProcess", "Distributions", "Enzyme", "FastBroadcast", "FiniteDiff", "ForwardDiff", "FunctionProperties", "FunctionWrappersWrappers", "Functors", "GPUArraysCore", "LinearAlgebra", "LinearSolve", "Markdown", "PreallocationTools", "QuadGK", "Random", "RandomNumbers", "RecursiveArrayTools", "Reexport", "ReverseDiff", "SciMLBase", "SciMLJacobianOperators", "SciMLOperators", "SciMLStructures", "StaticArrays", "StaticArraysCore", "Statistics", "SymbolicIndexingInterface", "Tracker", "Zygote"]
git-tree-sha1 = "9eff93778a5c61244027bfe9c4f016153bbbf156"
uuid = "1ed8b502-d754-442c-8d5d-10ac956f44a1"
version = "7.72.0"

    [deps.SciMLSensitivity.extensions]
    SciMLSensitivityMooncakeExt = "Mooncake"

    [deps.SciMLSensitivity.weakdeps]
    Mooncake = "da2b9cff-9c12-43a0-ae48-6db2b0edb7d6"

[[deps.SciMLStructures]]
deps = ["ArrayInterface"]
git-tree-sha1 = "0444a37a25fab98adbd90baa806ee492a3af133a"
uuid = "53ae85a6-f571-4167-b2af-e1d143709226"
version = "1.6.1"

[[deps.ScientificTypesBase]]
git-tree-sha1 = "a8e18eb383b5ecf1b5e6fc237eb39255044fd92b"
uuid = "30f210dd-8aff-4c5f-94ba-8e64358c1161"
version = "3.0.0"

[[deps.ScopedValues]]
deps = ["HashArrayMappedTries", "Logging"]
git-tree-sha1 = "1147f140b4c8ddab224c94efa9569fc23d63ab44"
uuid = "7e506255-f358-4e82-b7e4-beb19740aa63"
version = "1.3.0"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "3bac05bc7e74a75fd9cba4295cde4045d9fe2386"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.2.1"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "712fb0231ee6f9120e005ccd56297abbc053e7e0"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.4.8"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.Setfield]]
deps = ["ConstructionBase", "Future", "MacroTools", "StaticArraysCore"]
git-tree-sha1 = "e2cc6d8c88613c05e1defb55170bf5ff211fbeac"
uuid = "efcf1570-3423-57d1-acb7-fd33fddbac46"
version = "1.1.1"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"
version = "1.11.0"

[[deps.Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[deps.SimpleBufferStream]]
git-tree-sha1 = "f305871d2f381d21527c770d4788c06c097c9bc1"
uuid = "777ac1f9-54b0-4bf8-805c-2214025038e7"
version = "1.2.0"

[[deps.SimpleUnPack]]
git-tree-sha1 = "58e6353e72cde29b90a69527e56df1b5c3d8c437"
uuid = "ce78b400-467f-4804-87d8-8f486da07d0a"
version = "1.1.0"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"
version = "1.11.0"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "66e0a8e672a0bdfca2c3f5937efb8538b9ddc085"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.1"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.11.0"

[[deps.SparseConnectivityTracer]]
deps = ["ADTypes", "DocStringExtensions", "FillArrays", "LinearAlgebra", "Random", "SparseArrays"]
git-tree-sha1 = "010b3c44301805d1ede9159f449a351d61172aa6"
uuid = "9f842d2f-2579-4b1d-911e-f412cf18a3f5"
version = "0.6.9"

    [deps.SparseConnectivityTracer.extensions]
    SparseConnectivityTracerDataInterpolationsExt = "DataInterpolations"
    SparseConnectivityTracerLogExpFunctionsExt = "LogExpFunctions"
    SparseConnectivityTracerNNlibExt = "NNlib"
    SparseConnectivityTracerNaNMathExt = "NaNMath"
    SparseConnectivityTracerSpecialFunctionsExt = "SpecialFunctions"

    [deps.SparseConnectivityTracer.weakdeps]
    DataInterpolations = "82cc6244-b520-54b8-b5a6-8a565e85f1d0"
    LogExpFunctions = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
    NNlib = "872c559c-99b0-510c-b3b7-b6c96a88d5cd"
    NaNMath = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
    SpecialFunctions = "276daf66-3868-5448-9aa4-cd146d93841b"

[[deps.SparseInverseSubset]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "52962839426b75b3021296f7df242e40ecfc0852"
uuid = "dc90abb0-5640-4711-901d-7e5b23a2fada"
version = "0.1.2"

[[deps.SparseMatrixColorings]]
deps = ["ADTypes", "DataStructures", "DocStringExtensions", "LinearAlgebra", "Random", "SparseArrays"]
git-tree-sha1 = "76b44c879661552d64f382acf66faa29ab56b3d9"
uuid = "0a514795-09f3-496d-8182-132a7b665d35"
version = "0.4.10"
weakdeps = ["Colors"]

    [deps.SparseMatrixColorings.extensions]
    SparseMatrixColoringsColorsExt = "Colors"

[[deps.Sparspak]]
deps = ["Libdl", "LinearAlgebra", "Logging", "OffsetArrays", "Printf", "SparseArrays", "Test"]
git-tree-sha1 = "342cf4b449c299d8d1ceaf00b7a49f4fbc7940e7"
uuid = "e56a9233-b9d6-4f03-8d0f-1825330902ac"
version = "0.3.9"

[[deps.SpatialIndexing]]
git-tree-sha1 = "84efe17c77e1f2156a7a0d8a7c163c1e1c7bdaed"
uuid = "d4ead438-fe20-5cc5-a293-4fd39a41b74c"
version = "0.1.6"

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "64cca0c26b4f31ba18f13f6c12af7c85f478cfde"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.5.0"
weakdeps = ["ChainRulesCore"]

    [deps.SpecialFunctions.extensions]
    SpecialFunctionsChainRulesCoreExt = "ChainRulesCore"

[[deps.SplittablesBase]]
deps = ["Setfield", "Test"]
git-tree-sha1 = "e08a62abc517eb79667d0a29dc08a3b589516bb5"
uuid = "171d559e-b47b-412a-8079-5efa626c420e"
version = "0.1.15"

[[deps.StableRNGs]]
deps = ["Random"]
git-tree-sha1 = "83e6cce8324d49dfaf9ef059227f91ed4441a8e5"
uuid = "860ef19b-820b-49d6-a774-d7a799459cd3"
version = "1.0.2"

[[deps.Static]]
deps = ["CommonWorldInvalidations", "IfElse", "PrecompileTools"]
git-tree-sha1 = "87d51a3ee9a4b0d2fe054bdd3fc2436258db2603"
uuid = "aedffcd0-7271-4cad-89d0-dc628f76c6d3"
version = "1.1.1"

[[deps.StaticArrayInterface]]
deps = ["ArrayInterface", "Compat", "IfElse", "LinearAlgebra", "PrecompileTools", "Static"]
git-tree-sha1 = "96381d50f1ce85f2663584c8e886a6ca97e60554"
uuid = "0d7ed370-da01-4f52-bd93-41d350b8b718"
version = "1.8.0"
weakdeps = ["OffsetArrays", "StaticArrays"]

    [deps.StaticArrayInterface.extensions]
    StaticArrayInterfaceOffsetArraysExt = "OffsetArrays"
    StaticArrayInterfaceStaticArraysExt = "StaticArrays"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "PrecompileTools", "Random", "StaticArraysCore"]
git-tree-sha1 = "47091a0340a675c738b1304b58161f3b0839d454"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.9.10"
weakdeps = ["ChainRulesCore", "Statistics"]

    [deps.StaticArrays.extensions]
    StaticArraysChainRulesCoreExt = "ChainRulesCore"
    StaticArraysStatisticsExt = "Statistics"

[[deps.StaticArraysCore]]
git-tree-sha1 = "192954ef1208c7019899fbf8049e717f92959682"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.3"

[[deps.StatisticalTraits]]
deps = ["ScientificTypesBase"]
git-tree-sha1 = "542d979f6e756f13f862aa00b224f04f9e445f11"
uuid = "64bff920-2084-43da-a3e6-9bb72801c0c9"
version = "3.4.0"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"
weakdeps = ["SparseArrays"]

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1ff449ad350c9c4cbc756624d6f8a8c3ef56d3ed"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.7.0"

[[deps.StatsBase]]
deps = ["AliasTables", "DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "29321314c920c26684834965ec2ce0dacc9cf8e5"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.34.4"

[[deps.StatsFuns]]
deps = ["HypergeometricFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "b423576adc27097764a90e163157bcfc9acf0f46"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "1.3.2"
weakdeps = ["ChainRulesCore", "InverseFunctions"]

    [deps.StatsFuns.extensions]
    StatsFunsChainRulesCoreExt = "ChainRulesCore"
    StatsFunsInverseFunctionsExt = "InverseFunctions"

[[deps.StatsPlots]]
deps = ["AbstractFFTs", "Clustering", "DataStructures", "Distributions", "Interpolations", "KernelDensity", "LinearAlgebra", "MultivariateStats", "NaNMath", "Observables", "Plots", "RecipesBase", "RecipesPipeline", "Reexport", "StatsBase", "TableOperations", "Tables", "Widgets"]
git-tree-sha1 = "3b1dcbf62e469a67f6733ae493401e53d92ff543"
uuid = "f3b207a7-027a-5e70-b257-86293d7955fd"
version = "0.15.7"

[[deps.StrideArraysCore]]
deps = ["ArrayInterface", "CloseOpenIntervals", "IfElse", "LayoutPointers", "LinearAlgebra", "ManualMemory", "SIMDTypes", "Static", "StaticArrayInterface", "ThreadingUtilities"]
git-tree-sha1 = "f35f6ab602df8413a50c4a25ca14de821e8605fb"
uuid = "7792a7ef-975c-4747-a70f-980b88e8d1da"
version = "0.5.7"

[[deps.StringManipulation]]
deps = ["PrecompileTools"]
git-tree-sha1 = "a6b1675a536c5ad1a60e5a5153e1fee12eb146e3"
uuid = "892a3eda-7b42-436c-8928-eab12a02cf0e"
version = "0.4.0"

[[deps.StructArrays]]
deps = ["ConstructionBase", "DataAPI", "Tables"]
git-tree-sha1 = "9537ef82c42cdd8c5d443cbc359110cbb36bae10"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.6.21"
weakdeps = ["Adapt", "GPUArraysCore", "KernelAbstractions", "LinearAlgebra", "SparseArrays", "StaticArrays"]

    [deps.StructArrays.extensions]
    StructArraysAdaptExt = "Adapt"
    StructArraysGPUArraysCoreExt = ["GPUArraysCore", "KernelAbstractions"]
    StructArraysLinearAlgebraExt = "LinearAlgebra"
    StructArraysSparseArraysExt = "SparseArrays"
    StructArraysStaticArraysExt = "StaticArrays"

[[deps.StructIO]]
git-tree-sha1 = "c581be48ae1cbf83e899b14c07a807e1787512cc"
uuid = "53d494c1-5632-5724-8f4c-31dff12d585f"
version = "0.3.1"

[[deps.StyledStrings]]
uuid = "f489334b-da3d-4c2e-b8f0-e476e12c162b"
version = "1.11.0"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.7.0+0"

[[deps.SymbolicIndexingInterface]]
deps = ["Accessors", "ArrayInterface", "RuntimeGeneratedFunctions", "StaticArraysCore"]
git-tree-sha1 = "fd2d4f0499f6bb4a0d9f5030f5c7d61eed385e03"
uuid = "2efcf032-c050-4f8e-a9bb-153293bab1f5"
version = "0.3.37"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableOperations]]
deps = ["SentinelArrays", "Tables", "Test"]
git-tree-sha1 = "e383c87cf2a1dc41fa30c093b2a19877c83e1bc1"
uuid = "ab02a1b2-a7df-11e8-156e-fb1833f50b87"
version = "1.2.0"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "OrderedCollections", "TableTraits"]
git-tree-sha1 = "598cd7c1f68d1e205689b1c2fe65a9f85846f297"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.12.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.TerminalLoggers]]
deps = ["LeftChildRightSiblingTrees", "Logging", "Markdown", "Printf", "ProgressLogging", "UUIDs"]
git-tree-sha1 = "f133fab380933d042f6796eda4e130272ba520ca"
uuid = "5d786b92-1e48-4d6f-9151-6b4477ca9bed"
version = "0.1.7"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
version = "1.11.0"

[[deps.ThreadingUtilities]]
deps = ["ManualMemory"]
git-tree-sha1 = "eda08f7e9818eb53661b3deb74e3159460dfbc27"
uuid = "8290d209-cae3-49c0-8002-c8c24d57dab5"
version = "0.5.2"

[[deps.TimerOutputs]]
deps = ["ExprTools", "Printf"]
git-tree-sha1 = "d7298ebdfa1654583468a487e8e83fae9d72dac3"
uuid = "a759f4b9-e2f1-59dc-863e-4aeb61b1ea8f"
version = "0.5.26"

[[deps.Tracker]]
deps = ["Adapt", "ChainRulesCore", "DiffRules", "ForwardDiff", "Functors", "LinearAlgebra", "LogExpFunctions", "MacroTools", "NNlib", "NaNMath", "Optimisers", "Printf", "Random", "Requires", "SpecialFunctions", "Statistics"]
git-tree-sha1 = "c266e49953dadd0923caa17b3ea464ab6b97b3f2"
uuid = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"
version = "0.2.37"
weakdeps = ["PDMats"]

    [deps.Tracker.extensions]
    TrackerPDMatsExt = "PDMats"

[[deps.TranscodingStreams]]
git-tree-sha1 = "0c45878dcfdcfa8480052b6ab162cdd138781742"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.11.3"

[[deps.Transducers]]
deps = ["Accessors", "ArgCheck", "BangBang", "Baselet", "CompositionsBase", "ConstructionBase", "DefineSingletons", "Distributed", "InitialValues", "Logging", "Markdown", "MicroCollections", "Requires", "SplittablesBase", "Tables"]
git-tree-sha1 = "7deeab4ff96b85c5f72c824cae53a1398da3d1cb"
uuid = "28d57a85-8fef-5791-bfe6-a80928e7c999"
version = "0.4.84"

    [deps.Transducers.extensions]
    TransducersAdaptExt = "Adapt"
    TransducersBlockArraysExt = "BlockArrays"
    TransducersDataFramesExt = "DataFrames"
    TransducersLazyArraysExt = "LazyArrays"
    TransducersOnlineStatsBaseExt = "OnlineStatsBase"
    TransducersReferenceablesExt = "Referenceables"

    [deps.Transducers.weakdeps]
    Adapt = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
    BlockArrays = "8e7c35d0-a365-5155-bbbb-fb81a777f24e"
    DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
    LazyArrays = "5078a376-72f3-5289-bfd5-ec5146d43c02"
    OnlineStatsBase = "925886fa-5bf2-5e8e-b522-a9147a512338"
    Referenceables = "42d2dcc6-99eb-4e98-b66c-637b7d73030e"

[[deps.TriangularSolve]]
deps = ["CloseOpenIntervals", "IfElse", "LayoutPointers", "LinearAlgebra", "LoopVectorization", "Polyester", "Static", "VectorizationBase"]
git-tree-sha1 = "be986ad9dac14888ba338c2554dcfec6939e1393"
uuid = "d5829a12-d9aa-46ab-831f-fb7c9ab06edf"
version = "0.2.1"

[[deps.TruncatedStacktraces]]
deps = ["InteractiveUtils", "MacroTools", "Preferences"]
git-tree-sha1 = "ea3e54c2bdde39062abf5a9758a23735558705e1"
uuid = "781d530d-4396-4725-bb49-402e4bee1e77"
version = "1.4.0"

[[deps.Turing]]
deps = ["ADTypes", "AbstractMCMC", "Accessors", "AdvancedHMC", "AdvancedMH", "AdvancedPS", "AdvancedVI", "BangBang", "Bijectors", "Compat", "DataStructures", "Distributions", "DistributionsAD", "DocStringExtensions", "DynamicPPL", "EllipticalSliceSampling", "ForwardDiff", "Libtask", "LinearAlgebra", "LogDensityProblems", "LogDensityProblemsAD", "MCMCChains", "NamedArrays", "Optimization", "OptimizationOptimJL", "OrderedCollections", "Printf", "Random", "Reexport", "SciMLBase", "SpecialFunctions", "Statistics", "StatsAPI", "StatsBase", "StatsFuns"]
git-tree-sha1 = "d1b261f1a37d5daed651ef6f332d09b9cf22823d"
uuid = "fce5fe82-541a-59a6-adf8-730c64b5f9a0"
version = "0.35.5"

    [deps.Turing.extensions]
    TuringDynamicHMCExt = "DynamicHMC"
    TuringOptimExt = "Optim"

    [deps.Turing.weakdeps]
    DynamicHMC = "bbc10e6e-7c05-544b-b16e-64fede858acb"
    Optim = "429524aa-4258-5aef-a3af-852621145aeb"

[[deps.URIs]]
git-tree-sha1 = "67db6cc7b3821e19ebe75791a9dd19c9b1188f2b"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.Unitful]]
deps = ["Dates", "LinearAlgebra", "Random"]
git-tree-sha1 = "c0667a8e676c53d390a09dc6870b3d8d6650e2bf"
uuid = "1986cc42-f94f-5a68-af5c-568840ba703d"
version = "1.22.0"
weakdeps = ["ConstructionBase", "InverseFunctions"]

    [deps.Unitful.extensions]
    ConstructionBaseUnitfulExt = "ConstructionBase"
    InverseFunctionsUnitfulExt = "InverseFunctions"

[[deps.UnitfulLatexify]]
deps = ["LaTeXStrings", "Latexify", "Unitful"]
git-tree-sha1 = "975c354fcd5f7e1ddcc1f1a23e6e091d99e99bc8"
uuid = "45397f5d-5981-4c77-b2b3-fc36d6e9b728"
version = "1.6.4"

[[deps.UnsafeAtomics]]
git-tree-sha1 = "b13c4edda90890e5b04ba24e20a310fbe6f249ff"
uuid = "013be700-e6cd-48c3-b4a1-df204f14c38f"
version = "0.3.0"
weakdeps = ["LLVM"]

    [deps.UnsafeAtomics.extensions]
    UnsafeAtomicsLLVM = ["LLVM"]

[[deps.Unzip]]
git-tree-sha1 = "ca0969166a028236229f63514992fc073799bb78"
uuid = "41fe7b60-77ed-43a1-b4f0-825fd5a5650d"
version = "0.2.0"

[[deps.VectorizationBase]]
deps = ["ArrayInterface", "CPUSummary", "HostCPUFeatures", "IfElse", "LayoutPointers", "Libdl", "LinearAlgebra", "SIMDTypes", "Static", "StaticArrayInterface"]
git-tree-sha1 = "4ab62a49f1d8d9548a1c8d1a75e5f55cf196f64e"
uuid = "3d5dd08c-fd9d-11e8-17fa-ed2836048c2f"
version = "0.21.71"

[[deps.Vulkan_Loader_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Wayland_jll", "Xorg_libX11_jll", "Xorg_libXrandr_jll", "xkbcommon_jll"]
git-tree-sha1 = "2f0486047a07670caad3a81a075d2e518acc5c59"
uuid = "a44049a8-05dd-5a78-86c9-5fde0876e88c"
version = "1.3.243+0"

[[deps.Wayland_jll]]
deps = ["Artifacts", "EpollShim_jll", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "85c7811eddec9e7f22615371c3cc81a504c508ee"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.21.0+2"

[[deps.Wayland_protocols_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "5db3e9d307d32baba7067b13fc7b5aa6edd4a19a"
uuid = "2381bf8a-dfd0-557d-9999-79630e7b1b91"
version = "1.36.0+0"

[[deps.Widgets]]
deps = ["Colors", "Dates", "Observables", "OrderedCollections"]
git-tree-sha1 = "e9aeb174f95385de31e70bd15fa066a505ea82b9"
uuid = "cc8bc4a8-27d6-5769-a93b-9d913e69aa62"
version = "0.6.7"

[[deps.WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "c1a7aa6219628fcd757dede0ca95e245c5cd9511"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "1.0.0"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Zlib_jll"]
git-tree-sha1 = "a2fccc6559132927d4c5dc183e3e01048c6dcbd6"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.13.5+0"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "7d1671acbe47ac88e981868a078bd6b4e27c5191"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.42+0"

[[deps.XZ_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "beef98d5aad604d9e7d60b2ece5181f7888e2fd6"
uuid = "ffd25f8a-64ca-5728-b0f7-c24cf3aae800"
version = "5.6.4+0"

[[deps.Xorg_libICE_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "326b4fea307b0b39892b3e85fa451692eda8d46c"
uuid = "f67eecfb-183a-506d-b269-f58e52b52d7c"
version = "1.1.1+0"

[[deps.Xorg_libSM_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libICE_jll"]
git-tree-sha1 = "3796722887072218eabafb494a13c963209754ce"
uuid = "c834827a-8449-5923-a945-d239c165b7dd"
version = "1.2.4+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "9dafcee1d24c4f024e7edc92603cedba72118283"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.8.6+3"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "2b0e27d52ec9d8d483e2ca0b72b3cb1a8df5c27a"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.11+3"

[[deps.Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "807c226eaf3651e7b2c468f687ac788291f9a89b"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.3+0"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "02054ee01980c90297412e4c809c8694d7323af3"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.4+3"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "d7155fea91a4123ef59f42c4afb5ab3b4ca95058"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.6+3"

[[deps.Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "6fcc21d5aea1a0b7cce6cab3e62246abd1949b86"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "6.0.0+0"

[[deps.Xorg_libXi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libXext_jll", "Xorg_libXfixes_jll"]
git-tree-sha1 = "984b313b049c89739075b8e2a94407076de17449"
uuid = "a51aa0fd-4e3c-5386-b890-e753decda492"
version = "1.8.2+0"

[[deps.Xorg_libXinerama_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libXext_jll"]
git-tree-sha1 = "a1a7eaf6c3b5b05cb903e35e8372049b107ac729"
uuid = "d1454406-59df-5ea1-beac-c340f2130bc3"
version = "1.1.5+0"

[[deps.Xorg_libXrandr_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libXext_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "b6f664b7b2f6a39689d822a6300b14df4668f0f4"
uuid = "ec84b674-ba8e-5d96-8ba1-2a689ba10484"
version = "1.5.4+0"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "a490c6212a0e90d2d55111ac956f7c4fa9c277a6"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.11+1"

[[deps.Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "fee57a273563e273f0f53275101cd41a8153517a"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.1+3"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "1a74296303b6524a0472a8cb12d3d87a78eb3612"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.17.0+3"

[[deps.Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "dbc53e4cf7701c6c7047c51e17d6e64df55dca94"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.1.2+1"

[[deps.Xorg_xcb_util_cursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_jll", "Xorg_xcb_util_renderutil_jll"]
git-tree-sha1 = "04341cb870f29dcd5e39055f895c39d016e18ccd"
uuid = "e920d4aa-a673-5f3a-b3d7-f755a4d47c43"
version = "0.1.4+0"

[[deps.Xorg_xcb_util_image_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "0fab0a40349ba1cba2c1da699243396ff8e94b97"
uuid = "12413925-8142-5f55-bb0e-6d7ca50bb09b"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll"]
git-tree-sha1 = "e7fd7b2881fa2eaa72717420894d3938177862d1"
uuid = "2def613f-5ad1-5310-b15b-b15d46f528f5"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_keysyms_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "d1151e2c45a544f32441a567d1690e701ec89b00"
uuid = "975044d2-76e6-5fbe-bf08-97ce7c6574c7"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_renderutil_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "dfd7a8f38d4613b6a575253b3174dd991ca6183e"
uuid = "0d47668e-0667-5a69-a72c-f761630bfb7e"
version = "0.3.9+1"

[[deps.Xorg_xcb_util_wm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "e78d10aab01a4a154142c5006ed44fd9e8e31b67"
uuid = "c22f9ab0-d5fe-5066-847c-f4bb1cd4e361"
version = "0.4.1+1"

[[deps.Xorg_xkbcomp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "ab2221d309eda71020cdda67a973aa582aa85d69"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.6+1"

[[deps.Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "691634e5453ad362044e2ad653e79f3ee3bb98c3"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.39.0+0"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "b9ead2d2bdb27330545eb14234a2e300da61232e"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.5.0+3"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "622cf78670d067c738667aaa96c553430b65e269"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.7+0"

[[deps.Zygote]]
deps = ["AbstractFFTs", "ChainRules", "ChainRulesCore", "DiffRules", "Distributed", "FillArrays", "ForwardDiff", "GPUArrays", "GPUArraysCore", "IRTools", "InteractiveUtils", "LinearAlgebra", "LogExpFunctions", "MacroTools", "NaNMath", "PrecompileTools", "Random", "Requires", "SparseArrays", "SpecialFunctions", "Statistics", "ZygoteRules"]
git-tree-sha1 = "0b3c944f5d2d8b466c5d20a84c229c17c528f49e"
uuid = "e88e6eb3-aa80-5325-afca-941959d7151f"
version = "0.6.75"
weakdeps = ["Colors", "Distances", "Tracker"]

    [deps.Zygote.extensions]
    ZygoteColorsExt = "Colors"
    ZygoteDistancesExt = "Distances"
    ZygoteTrackerExt = "Tracker"

[[deps.ZygoteRules]]
deps = ["ChainRulesCore", "MacroTools"]
git-tree-sha1 = "27798139afc0a2afa7b1824c206d5e87ea587a00"
uuid = "700de1a5-db45-46bc-99cf-38207098b444"
version = "0.2.5"

[[deps.eudev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "gperf_jll"]
git-tree-sha1 = "431b678a28ebb559d224c0b6b6d01afce87c51ba"
uuid = "35ca27e7-8b34-5b7f-bca9-bdc33f59eb06"
version = "3.2.9+0"

[[deps.fzf_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6e50f145003024df4f5cb96c7fce79466741d601"
uuid = "214eeab7-80f7-51ab-84ad-2988db7cef09"
version = "0.56.3+0"

[[deps.gperf_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0ba42241cb6809f1a278d0bcb976e0483c3f1f2d"
uuid = "1a1c6b14-54f6-533d-8383-74cd7377aa70"
version = "3.1.1+1"

[[deps.libaom_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "522c1df09d05a71785765d19c9524661234738e9"
uuid = "a4ae2306-e953-59d6-aa16-d00cac43593b"
version = "3.11.0+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "e17c115d55c5fbb7e52ebedb427a0dca79d4484e"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.2+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.11.0+0"

[[deps.libdecor_jll]]
deps = ["Artifacts", "Dbus_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "Pango_jll", "Wayland_jll", "xkbcommon_jll"]
git-tree-sha1 = "9bf7903af251d2050b467f76bdbe57ce541f7f4f"
uuid = "1183f4f0-6f2a-5f1a-908b-139f9cdfea6f"
version = "0.2.2+0"

[[deps.libevdev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "141fe65dc3efabb0b1d5ba74e91f6ad26f84cc22"
uuid = "2db6ffa8-e38f-5e21-84af-90c45d0032cc"
version = "1.11.0+0"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8a22cf860a7d27e4f3498a0fe0811a7957badb38"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.3+0"

[[deps.libinput_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "eudev_jll", "libevdev_jll", "mtdev_jll"]
git-tree-sha1 = "ad50e5b90f222cfe78aa3d5183a20a12de1322ce"
uuid = "36db933b-70db-51c0-b978-0f229ee0e533"
version = "1.18.0+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "d7b5bbf1efbafb5eca466700949625e07533aff2"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.45+1"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "490376214c4721cdaca654041f635213c6165cb3"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+2"

[[deps.mtdev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "814e154bdb7be91d78b6802843f76b6ece642f11"
uuid = "009596ad-96f7-51b1-9f1b-5ce2d5e8a71e"
version = "1.1.6+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.59.0+0"

[[deps.oneTBB_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "7d0ea0f4895ef2f5cb83645fa689e52cb55cf493"
uuid = "1317d2d5-d96f-522e-a858-c73665f53c3e"
version = "2021.12.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"

[[deps.xkbcommon_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll", "Wayland_protocols_jll", "Xorg_libxcb_jll", "Xorg_xkeyboard_config_jll"]
git-tree-sha1 = "63406453ed9b33a0df95d570816d5366c92b7809"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "1.4.1+2"
"""

# ╔═╡ Cell order:
# ╟─45dc0462-d63c-11ef-0f62-e5d029618cc1
# ╟─ffcd2d10-4c6c-4eb9-a2ec-fbc1c0596838
# ╟─6d29e44b-3d70-4700-ad53-9e75df7ced0c
# ╟─51c67a4d-f49a-4bb5-a1c2-361ea0e8f20e
# ╠═885f5685-5239-42aa-942c-2b9bdf7df220
# ╟─ca453691-227c-44f1-8b48-8fb42c42d481
# ╟─34efa390-0d6d-48dd-b08b-0c1bc391ffc2
# ╠═448dd6ac-0d7f-4c1f-a9ce-3f9a586951c1
# ╠═760b16ea-410f-4f46-ae44-f859de9b75e3
# ╠═27059e1a-5f0c-40ac-85ea-ff6ad8d7b68c
# ╠═9ff83b76-86dd-4520-ac20-df1eb30cc1dd
# ╠═1245a924-10c8-4170-b3a9-ce025c54319d
# ╟─d2ac7dbe-a47a-4b50-a796-a04462f410cc
# ╠═9ad843f4-0f54-4a4f-a83d-b29bedad37c3
# ╠═f5c9ea83-6dba-4848-8340-1a8c772bd941
# ╠═1e27f7dd-9d41-4fe9-b823-0013ef35927d
# ╠═835c2922-37de-4e1b-b9ba-05a729eca801
# ╟─2ab07370-1cf4-41db-b197-295d4cfd6a68
# ╟─cba31d00-0a4a-4dab-aada-507ec1244bb1
# ╟─e921a8b2-4fe8-41cb-8463-6297a7e1646d
# ╠═e13c7d4f-4cdb-43d5-9f77-33401cb501e2
# ╠═17a15fc4-3bc3-4415-aa37-2520750e84a2
# ╟─745de76a-d18f-426f-a0e0-4fa318f833dd
# ╠═14f88d60-783b-4757-b20e-d3ada57f16f7
# ╠═bd4b5bc1-d7c2-4408-9f35-ac69d75c16fe
# ╠═6e709ba7-725d-4085-8078-d813766086e0
# ╠═dc408f51-ce63-44a8-98fb-a7ccd0dedcc0
# ╠═0c888118-c40b-43e5-9fe8-e3f6d553610c
# ╠═9a1b4857-8687-47a5-84d9-314149e66f13
# ╟─c725adf8-4bfa-4046-929f-65dfef8c2309
# ╠═c7193526-d32f-4f2a-95aa-09e98b88b30b
# ╠═2c247d32-e215-48ac-95df-4c562333309f
# ╠═0a83e463-7180-4f7e-8f93-37165d56aed8
# ╟─bbe5e86a-0e72-4ce2-aa95-1b80a070b3ac
# ╠═ee4e03a6-1187-4de1-816c-9299debe54ed
# ╟─2ff9c802-5562-4669-8045-d3bf40e42cd2
# ╠═36985121-9fe5-4961-9ec2-3f5ee57cfaa1
# ╠═9d09b14b-af52-48e2-9c6c-446c398ed422
# ╟─eaec431c-e7f3-49a7-a2a2-cb18d464348c
# ╠═5e533d0a-5aaa-4e42-a420-fb3b3ccb5060
# ╠═8b0256ff-c49c-468c-b140-1416e3e311ab
# ╠═34aa161d-4421-4344-b40f-e25a151a98e2
# ╠═f8a4e5ed-684e-4242-adce-9114576cbc68
# ╟─92c24e7c-deee-4b56-a64d-00748d7fe69a
# ╟─d942a2d0-dc61-4b74-8702-789c54044300
# ╠═134afb44-b726-45d3-a2a0-002a7c433cfb
# ╟─8bbafc21-3f6b-4bce-9b41-56ba36b6a2b4
# ╠═13a104ee-1af5-47f2-acf1-db5cd32ea37e
# ╟─80f79d79-0432-46f9-9734-c598f061e87c
# ╠═730d88c9-682b-4377-bae6-3b9e51f4c2d1
# ╠═b9a8e9e3-f17e-425b-86c8-6e836932735c
# ╟─dbfe82fd-6b79-434e-a0c5-591a9f3990c6
# ╠═ba06d75c-9f29-48c0-9db3-b3822568bf39
# ╠═1f2212b0-d6b3-42e1-8864-8588aacab5c4
# ╠═c07e6522-1c78-491f-bffa-70bf0c11dea5
# ╠═a5a3d044-eddc-4c79-bf0f-2d6753a16e07
# ╟─de5354a6-b8cd-4871-b9b3-2bd3be6bee17
# ╠═a6668c04-6b54-45df-951e-4dff659ae152
# ╠═9723e36d-7ec4-4c0d-bab3-13ee372b7515
# ╟─50f8441b-6a5b-4b3b-8846-29894388bf6f
# ╠═10338166-3f7a-4479-9089-1437b8a82a6e
# ╟─d8fd5015-6cdc-4f4f-80eb-b16e21f0e908
# ╠═6f04db2c-3c38-4244-8d70-22a15a7dd72e
# ╠═3d580d10-9fe1-48ff-b563-d7e267205e8c
# ╟─981ba39c-6328-4577-bc9a-5574dcc634d9
# ╠═5765470f-44a3-4911-9aec-d029ee7f87b3
# ╟─f71e8884-5829-4346-8bde-43ea1947d7f5
# ╠═cb5be726-5287-4519-a199-14a27246726e
# ╟─f38d3cec-65ea-4999-867a-984b23b9fe21
# ╟─bed65c9b-cad3-48c2-aac5-5dc201a15558
# ╠═8a3108d7-0bec-40d1-b5a9-e4deec2f88c0
# ╠═dba58f1a-6340-4242-8b1a-482dd50e8d11
# ╠═08389217-2791-469e-ae48-e7efdc0de493
# ╟─49175b07-6c2e-4a13-86f7-8c5e5047e553
# ╟─7ad1e21f-2c72-415c-9d9c-c0ee35ab44e6
# ╠═e6413dda-3ebb-49c1-9dfb-a340321e86c6
# ╟─a6c0695e-6c29-4992-b7dd-dcab7aeea3f1
# ╠═a5e5b6bf-1fe9-4462-a5e3-c30bf656a6cd
# ╠═f9749dde-697a-40aa-a0e7-47edc8fc778f
# ╟─08617e66-a04f-464a-a1b1-31ad7d44f491
# ╟─68fc5732-e059-44a3-a8d5-3428cb6c36d1
# ╠═099f04f0-8f67-425c-a395-0d2dd20925b1
# ╟─598a4615-f77a-4167-9bf1-62aa25218b17
# ╠═f860ea33-eb7c-43f6-a1b5-859b0b33d367
# ╠═0d3e1592-5535-4c62-a1a2-82fb11109ce4
# ╠═b30eb1b1-b355-4f3e-980a-dd98b2d9d1d4
# ╠═764b48c6-8427-4e1d-8ec7-59126a020e71
# ╟─d1897917-14ae-418a-a1b5-e7d47e58a8dd
# ╠═3231de71-277a-4a13-b3ae-220650089f8b
# ╠═c82ea0b1-f5dd-45be-ad89-4746d31109a8
# ╠═6572ab63-4428-4d4b-8ba2-37820d1403cc
# ╠═14cf3698-fb1b-44bc-89b1-98d8fdf29723
# ╟─aa7d1c43-0d78-462b-93d0-090d2bbdff31
# ╠═241cb0fa-9e3e-4291-a3b8-e0d1246c9d2f
# ╠═e2ee3937-32f2-4caa-9509-a0418fb36135
# ╟─a3497c89-f8c8-4468-bfb3-430e3fe07071
# ╠═0fa7450e-4c48-40f5-8785-cd0ab7a8c4f7
# ╠═ff48c782-955d-4e7d-be0f-0f7db2c011ae
# ╟─19f1b4f6-e42c-45c3-8e4a-2f6c623fa65e
# ╠═66e393f7-4120-46e1-925c-11367c3b6d4c
# ╠═a6b84344-a03d-4575-bb56-9ba2ba37a3f7
# ╠═18e5b654-10e9-4df9-95b5-62624d694b9f
# ╠═48f71f49-44c3-4424-824e-63a0f975bd38
# ╟─3b48ff74-df66-4a6d-aca0-fcf2b855cb23
# ╠═1c913f13-6a33-4161-a9e4-7e439f1ebf70
# ╟─757546ff-9c2a-442c-9b71-b4b30c48cdfa
# ╠═ecaaea3c-f399-42d7-a56a-033a0f6b4a8b
# ╠═f87f8a17-a706-497e-94d4-e6e6f7601f37
# ╠═79d4d09a-d1a2-45a9-bb02-ae05a24b4f1d
# ╟─790110fe-ad24-4a71-a2c7-8446e0441985
# ╟─b79609cd-bb10-49ad-91eb-5de46325d0e0
# ╠═421dbe2a-a689-4390-9d0b-b4528d11f4af
# ╠═8186418e-d332-41da-b6ae-d90964c28c08
# ╠═f3685420-ec96-4cdc-aa9a-f3f0cf948b1e
# ╠═95bebbd8-7e5d-4e7a-a2a8-68b546614c0e
# ╠═169aa5f4-a85d-4e53-8442-f47757456726
# ╠═490d7195-a878-4634-8f2b-a51463976d44
# ╠═4d3dd038-5cdf-44ad-9fcc-22353e55961f
# ╠═f66493ab-dddb-46fa-9305-80f7625e8f88
# ╠═664a2a56-58d6-42bf-89c3-15307834d633
# ╟─8d46da5d-e59d-47e4-af1a-b8b33a8b57a7
# ╠═3bc2d2d7-863c-4f59-9918-4eb3944ac0ec
# ╟─14ee0daf-95f5-4e54-8ccc-ea1df5a52157
# ╠═95cd9037-5985-4c45-bbe8-e20a5e244b5f
# ╠═8ffc8473-1c74-4ba2-bd6c-5f8aa1223f10
# ╟─943a4e6f-1cbb-4800-aade-6bd398d966a3
# ╠═22bdc1e6-ce8d-41bd-a257-d015202f468d
# ╠═22f0edf0-d358-4d40-ad1a-78e251cdc809
# ╠═7a49a79c-95b5-4dbc-b979-4c753a75e86e
# ╠═b0b10ca7-0dca-4359-9fe5-f60b375f3413
# ╟─522a37fb-a2f7-4758-8e32-02c8058c8df3
# ╠═db0b2561-7a02-427f-9a9c-a3943947da4c
# ╟─0351b05b-c63d-4a7a-a20b-e6e72b835bec
# ╠═6402bee8-18dd-4c1b-8616-d57030310503
# ╟─0bfd1396-c569-4ac9-b92a-f535e533ba50
# ╠═c479f931-f403-4c93-bc63-14a01f19718b
# ╠═1a5be3f3-9d6c-45f0-963a-8e19e65c0f3a
# ╠═e479984b-579c-4cdd-9f69-6d7b0db8202e
# ╠═b122c127-53aa-45d5-997c-4fa2cb84d2ff
# ╠═4db2c565-7c96-41c9-8480-e07d107f12d3
# ╟─9677c213-4af4-48bc-9c49-b7907f478f8d
# ╠═243b7f0b-2f0c-4373-ae98-ce234562f87a
# ╟─60118730-1525-43fd-b1ff-b675b6a20e42
# ╟─33adf452-e528-4cbc-88a7-d81bac52e124
# ╠═d6001516-314b-4f9c-9929-61cd2e2e4e98
# ╠═3c20fb0d-ffba-4df6-bc21-175823894867
# ╠═d2868575-d779-436e-97a1-c524b775899d
# ╠═f448e44b-66ee-42db-99a1-1a9ad1b92d23
# ╟─583d4aa9-0193-49b1-8350-7b2715041f39
# ╟─38de9bfc-ea00-43c2-af5b-08fb031e1861
# ╠═bf8cdb2b-e77c-4a9c-97c0-ab57e8fc6e6b
# ╠═cd427bf5-afbd-4e92-9def-c5f5e7bea416
# ╠═5755fb3c-24d5-45b2-a10c-a1010c27df4f
# ╟─70fbd8fd-fda4-426d-8a6f-d1f8fa303200
# ╠═bd129656-3273-4725-afe5-f9ff04afda23
# ╠═97118579-0ae9-4078-b6f4-4ad4a6a54901
# ╟─fdd91eab-f5af-43f5-9cf2-3311e7eea56c
# ╠═e662f173-84ad-438e-afe8-a1e1e82d38c6
# ╟─f9ac099c-8fc8-45b4-b0b6-6e47985a5880
# ╟─3bf58446-ddff-4dd8-a3f6-1ac9822a930f
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
