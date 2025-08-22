### A Pluto.jl notebook ###
# v0.20.4

using Markdown
using InteractiveUtils

# ╔═╡ af508570-b20f-4dd3-a995-36c79fc41823
begin
	using PlutoUI, PlutoTeachingTools, PlutoTest
	using BenchmarkTools
end

# ╔═╡ 27667e0a-8ebc-4397-8ac3-33a0f19f6987
md"""
#  Astro 528, Lab 2, Exercise 2
## Unit Tests & Assertions
### (as demonstrated on Solving Kepler's equation)
"""


# ╔═╡ bedbe9b9-03be-4537-b938-89d2857d0cba
md"""
[Kepler's Equation](https://en.wikipedia.org/wiki/Kepler%27s_equation) relates the *mean anomaly* ($M$) and *eccentric anomaly* ($E$), two angles that can be used to specify where a body is along its orbit in the two-body (aka, Kepler) problem.  
```math
M = E - e \sin(E),
```
where $e$ is the orbital eccentricity.  The mean anomaly increases linearly with time, but the eccentric anomaly does not.
"""

# ╔═╡ 8116b382-c927-4563-8fde-dc034dd96ab9
md"2a.  Update the function `calc_mean_anom` below to compute the mean anomaly for a given eccentric anomaly and eccentricity."

# ╔═╡ c9eef6f8-4583-429b-a3ae-09f1ec8e5ecf
"""   `calc_mean_anom(ecc_anom, e)`

Calculate mean anomaly for a given eccentric anomaly and eccentricity.
"""
function calc_mean_anom(ecc_anom::Real, e::Real) 
	missing
end

# ╔═╡ 05cf7bc1-cc04-4679-9534-05834f097371
if !@isdefined(calc_mean_anom)
   func_not_defined(:calc_mean_anom)
else
	if !(length(methods(calc_mean_anom,[Float64,Float64])) >= 1)
		   keep_working(md"Your calc_mean_anom can't take two Float64's as arguments.")
	elseif ismissing(calc_mean_anom(1.0,0.5))
		still_missing()
	elseif calc_mean_anom(1.0,0.5) ≈ 0.5792645075960517
		correct()
	else
		keep_working()	
	end
end

# ╔═╡ 3ebe8069-11d3-4885-aec8-72e2f3f5f906
md"""Solving the Kepler Equation for $E$ given for a given $e$ and $M$ is critical to be able to determine where a body is at a given time.  Since it is a transendental equation (i.e., there is no closed form algebraic solution), it is solved itteratively.  Over the centuries, there have been numerous studies of how to solve the Kepler equation efficiently.  Below, I've coded up an implementation for you to help you get stared.  For this exercise, you don't need to understand the details of how the algorithm works.  Instead, we will focus on how we can use principles of modern software development to improve these functions via assertions and unit tests. 
"""

# ╔═╡ f6be4fa8-351a-4c1c-b389-b79f09db2a4b
md"## Starter code to solve Kepler's Equation"

# ╔═╡ 6421c10b-9429-45ef-8ffb-b5117fae9e58
"""
   `ecc_anom_init_guess_danby(mean_anomaly, eccentricity)`

Returns initial guess for the eccentric anomaly for use by itterative solvers of Kepler's equation for bound orbits.  

Based on "The Solution of Kepler's Equations - Part Three"
[Danby, J. M. A. (1987) Celestial Mechanics, Volume 40, Issue 3-4, pp. 303-312](https://ui.adsabs.harvard.edu/abs/1987CeMec..40..303D/abstract))
"""
function ecc_anom_init_guess_danby(M::Real, ecc::Real)
	@assert -2π<= M <= 2π
	@assert 0 <= ecc < 1.0
    if  M < zero(M)
		M += 2π
	end
    E = (M<π) ? M + 0.85*ecc : M - 0.85*ecc
end;

# ╔═╡ fbb8c035-da0d-45d0-856c-0668f2ef954f
"""
   `update_ecc_anom_laguerre(eccentric_anomaly_guess, mean_anomaly, eccentricity)`

Update the current guess for solution to Kepler's equation
  
Based on "An Improved Algorithm due to Laguerre for the Solution of Kepler's Equation"
[Conway, B. A.  (1986) Celestial Mechanics, Volume 39, Issue 2, pp.199-211](https://ui.adsabs.harvard.edu/abs/1986CeMec..39..199C/abstract)
"""
function update_ecc_anom_laguerre(E::Real, M::Real, ecc::Real)
    es, ec = ecc.*sincos(E)
    F = (E-es)-M
    Fp = one(M)-ec
    Fpp = es
    n = 5
    root = sqrt(abs((n-1)*((n-1)*Fp*Fp-n*F*Fpp)))
    denom = Fp>zero(E) ? Fp+root : Fp-root
    return E-n*F/denom
end;

# ╔═╡ d48ca14f-2b62-4f35-8c8a-07aa3563b579
"""
   `calc_ecc_anom_itterative_laguerre( mean_anomaly, eccentricity )`

Estimates eccentric anomaly for given mean_anomaly and eccentricity.
Optional parameter `tol` specifies tolerance (default 1e-8)
"""
function calc_ecc_anom(mean_anom::Real, ecc::Real; tol::Real = 1.0e-8)
  	@assert 0 <= ecc < 1.0
	@assert 1e-16 <= tol < 1
  	M = rem2pi(mean_anom,RoundNearest)  # Remainder after dividing by 2π
    E_old = E = ecc_anom_init_guess_danby(M,ecc)
    max_its_laguerre = 200
    for i in 1:max_its_laguerre
       E = update_ecc_anom_laguerre(E_old, M, ecc)
       if abs(E-E_old) < tol break end
	   E_old = E
    end
    return E
end;

# ╔═╡ 76c08fb3-89e1-4897-90f1-2f73ba298010
md"""

## Assertions

Sometimes a programmer calls a function with arguments that either don't make sense or represent a case that the function was not originally designed to handle properly. The worst possible function behavior in such a case is returning an incorrect result without any warning that something bad has happened. Returning an error at the end is better, but can make it difficult to figure out the problem. Generally, the earlier the problem is spotted, the easier it will be to fix the problem. Therefore, good developers often include assertions to verify that the function arguments are acceptable.  

For example, in `ecc_anom_init_guess_danby` above, we included an assertion that the eccentricity was positive-semidefinite and less than or equal to unity.  

2b. What other preconditions should be met for the inputs to the functions above?    What is about `calc_mean_anom` from 2a?
"""

# ╔═╡ 693371c4-8e35-4a8e-9fa2-8c0e441515ac
response_2b = missing  # md"YOUR RESPONSE"

# ╔═╡ 33f00289-8f32-4512-968e-d29fcd6968ff
if !@isdefined(response_2b)
   var_not_defined(:response_2b)
elseif ismissing(response_2b)
	still_missing()
else
	nothing
end

# ╔═╡ a3e0ad59-288a-423d-a7e9-ecadb055e0dc
md"2c. Update the code above to include at least one additional assertion."

# ╔═╡ e50297d5-8599-48dd-935e-0c3975e4e379
begin
	num_evals = 100
	mean_anoms_for_benchmarks = 2π*rand(num_evals)
	eccs_for_benchmarks = rand(num_evals)
end

# ╔═╡ c0a54587-86bf-4f6d-9e5c-574badc06865
md"2d.  Adding assertions creates extra work.  It's good to think about whether an assertion will result in a significant performance hit.  Benchmark your code before an after adding the assertions.  How does the typical run time compare?  What are the implications for whether it makes sense to leaves the assertions in a production code?"

# ╔═╡ 61db6108-8be6-4544-b1be-6e448d99748f
@benchmark calc_ecc_anom.($mean_anoms_for_benchmarks,$eccs_for_benchmarks)

# ╔═╡ a394967a-16cb-42fe-a1fc-797e108439d3
response_2d = missing

# ╔═╡ 6569d30f-0c9d-4533-a421-086fcf1b5f62
if !@isdefined(response_2d)
   var_not_defined(:response_2d)
elseif ismissing(response_2d)
	still_missing()
else
	nothing
end

# ╔═╡ 90471f40-c548-494f-84cb-871ee0f3f5f9
md"""
## Unit Tests
Units tests check that the post-conditions are met for at least some certain test inputs.  I'll demonstrate a couple of unit tests below.
"""

# ╔═╡ e1a70885-ac8b-4b4c-9080-92c3178f5a03
@test calc_ecc_anom(0,0.1) ≈ 0 atol = 1e-8

# ╔═╡ a6034884-89a1-43d7-b30e-f389ae2e05d3
@test calc_ecc_anom(Float64(π),0.5) ≈ π atol = 1e-8

# ╔═╡ 9a89ccd7-f690-4dc1-9736-779aa7845ab2
aside(tip(md"In Pluto, Jupyter and VSCode (and probably many other modern IDEs), you can get unicode characters like ≈ by typing `\approx<tab>`."))

# ╔═╡ 48aed012-2da1-4a06-9404-a34cdd4b3eee
md"""
Note that testing equality or inequality is straightforward for integers, but dangerous for floating point numbers.  If a floating point number is equal to an integer, then it's generally ok, but I think it's better to always be cautious about testing floating  point numbers for equality.  Instead, you can test that two numbers are approximately equal using $≈$.  When testing that two numbers are approximately equal you need to specify a tolerance.  `atol` refers to an absolute tolerance, while `rtol` refers to a relative or fractional tolerance. For further information on using these, see the [Julia manual](https://docs.julialang.org/en/v1/stdlib/Test/index.html#Basic-Unit-Tests-1).  (Technically, we're using `PlutoTest.@test`, which in implemented in terms of `Test.@test`.
"""

# ╔═╡ b17e6d66-9a19-48a8-a6ba-c8d5145387f3
md"""
2e. What other unit tests could be useful for diagnosing any errors or non-robust behavior?  Write at least three new unit tests that help to check whether the above code is accurate.  After writing your first one, try to think of how to make the next ones more useful than just doing very similar tests over and over again.
Try think of a corner case where a non-robust algorithm might not be accurate.  
Explain your testing plan below.
"""

# ╔═╡ 4d6d13f7-47b0-4e8a-af69-3aa0a8cb8d2d
response_2e = missing

# ╔═╡ c5b8a22d-d47b-4f65-b90e-544e8b6c3a88
if !@isdefined(response_2e)
   var_not_defined(:response_2e)
elseif ismissing(response_2e)
	still_missing()
else
	nothing
end

# ╔═╡ 4ec0d903-4e3f-42d6-8853-86c848bb92ce
md"""
Check what happens when your tests run.  Do your functions pass all of them?  If not, correct the function (or the tests if necessary) and rerun the tests. """

# ╔═╡ 869e40bc-0679-4b20-acff-f8db6637a887
md"""
### Testing the assertions.
In this case, the assertions are probably pretty simple.  But sometimes, the assertions can be complicated enough that you'll need to test that they're working as intended.  When an assert statement is followed by an expression that evaluates to false, then it ["throws an exception"](https://docs.julialang.org/en/v1.0/manual/control-flow/#Exception-Handling-1).  We want to make sure that our code is throwing an exception when we pass our function invalid arguments.  I'll demonstrate with a test of passing an invalid eccentricity.
"""

# ╔═╡ dccdcf37-3354-4717-8cf3-b391bbaf6e9a
@test_throws AssertionError calc_ecc_anom(rand()*2π,-0.5) 

# ╔═╡ 94891c38-8e36-43f5-b0a6-9b8b38145ef9
md"""2f. Add tests to make sure that the assertions you added in 1c trigger as you intended them to."""


# ╔═╡ a9af0fa1-99af-447d-86ad-cb926f7b9de1
# INSERT YOUR TEST(S) HERE

# ╔═╡ 2ca10bfe-549b-4910-95a3-e68a292df0d6
md"""
## Continous Integration Testing.
Often, a well-intentioned programmer introduces a bug, but doesn't notice until long after the bug was written.  One way to reduce the risk of such bugs is to have an comprehensive set of unit tests that are applied _automatically_ each time a developer commits a change.  If some new code causes a test to fail, we want to know that promptly, so it can be fixed and before it causes scientists to lose time running the buggy code or trying to interpret results of a buggy code.

The '.github/workflows/test.yaml' file provided in this repository already provides instructions for GitHub.com to automatically run tests each time you commit changes and push them to GitHub.  The tests for this notebook are in `tests/test3.jl`.  

2g.  Add the tests that you wrote above to `tests/test2.jl`, so that they become part of your repository's _continuous integration_ testing.  Commit those changes to your local repository and push them to github.  Go to your repository on GitHub, click "Actions", then click "Test notebooks", then look at the line for most recent commit (at the top of the list).  Is there a green check or a red x?  If a red x, then click on the commit message for the most recent commit, and then click "test (v1.9, x86, ubuntu-latest)" to see the messages associated with that test run.  See if you can figure out why a test failed.  
(If this doesn't work the first time, then it's probably wise to move on to the next exercise and come back to this only if you have sufficient time."""

# ╔═╡ a93f0326-78ca-407d-aec2-5de318c002ca
tip(md"If a test does fail, then it may be useful to run the tests on Roar Collab or your local machine, so you get faster feedback on whether you're tests are performing as expected.  From your local repository's directory, you can run `julia --project=test test/test2.jl ` to run the tests.  Once you get those working, then commit the changes to your local repo, push to GitHub, and see if the new version of your code passes all its test.")

# ╔═╡ b760fedd-41ea-4784-845f-ede0163c0d12
md"## Setup & Helper Code"

# ╔═╡ 2e893623-2d05-48ac-b7c6-0ba167dc7419
ChooseDisplayMode()

# ╔═╡ bfdd8ecf-5f05-4056-a9d8-f3404774ff52
TableOfContents()

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
BenchmarkTools = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
PlutoTeachingTools = "661c6b06-c737-4d37-b85c-46df65de6f69"
PlutoTest = "cb4044da-4d16-4ffa-a6a3-8cad7f73ebdc"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
PlutoTest = "~0.2.2"
PlutoUI = "~0.7.52"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.2"
manifest_format = "2.0"
project_hash = "6babae6fb12ce9694e1952a3e44c8c5f8fcea5f2"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "6e1d2a35f2f90a4bc7c2ed98079b2ba09c35b83a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.3.2"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.2"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.BenchmarkTools]]
deps = ["Compat", "JSON", "Logging", "Printf", "Profile", "Statistics", "UUIDs"]
git-tree-sha1 = "e38fbc49a620f5d0b660d7f543db1009fe0f8336"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.6.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "67e11ee83a43eb71ddc950302c53bf33f0690dfe"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.12.1"

    [deps.ColorTypes.extensions]
    StyledStringsExt = "StyledStrings"

    [deps.ColorTypes.weakdeps]
    StyledStrings = "f489334b-da3d-4c2e-b8f0-e476e12c162b"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "0037835448781bb46feb39866934e243886d756a"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.18.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"
version = "1.11.0"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "05882d6995ae5c12bb5f36dd2ed3f61c98cbb172"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.5"

[[deps.Format]]
git-tree-sha1 = "9c68794ef81b08086aeb32eeaf33531668d5f5fc"
uuid = "1fa38f19-a742-5d3f-a2b9-30dd87b9d5f8"
version = "1.3.7"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "b6d6bfdd7ce25b0f9b2f6b3dd56b2673a66c8770"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.5"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.LaTeXStrings]]
git-tree-sha1 = "dda21b8cbd6a6c40d9d02a73230f9d70fed6918c"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.4.0"

[[deps.Latexify]]
deps = ["Format", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "OrderedCollections", "Requires"]
git-tree-sha1 = "52e1296ebbde0db845b356abbbe67fb82a0a116c"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.16.9"

    [deps.Latexify.extensions]
    DataFramesExt = "DataFrames"
    SparseArraysExt = "SparseArrays"
    SymEngineExt = "SymEngine"
    TectonicExt = "tectonic_jll"

    [deps.Latexify.weakdeps]
    DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    SymEngine = "123dc426-2d89-5057-bbad-38513e3affd8"
    tectonic_jll = "d7dd28d6-a5e6-559c-9131-7eb760cdacc5"

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

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.11.0"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

[[deps.MIMEs]]
git-tree-sha1 = "c64d943587f7187e751162b3b84445bbbd79f691"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "1.1.0"

[[deps.MacroTools]]
git-tree-sha1 = "1e0228a030642014fe5cfe68c2c0a818f9e3f522"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.16"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.6+0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"
version = "1.11.0"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.12.12"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.27+1"

[[deps.OrderedCollections]]
git-tree-sha1 = "05868e21324cede2207c6f0f466b4bfef6d5e7ee"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.8.1"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "7d2f8f21da5db6a806faf7b9b292296da42b2810"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.3"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.11.0"

    [deps.Pkg.extensions]
    REPLExt = "REPL"

    [deps.Pkg.weakdeps]
    REPL = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.PlutoTeachingTools]]
deps = ["Downloads", "HypertextLiteral", "Latexify", "Markdown", "PlutoUI"]
git-tree-sha1 = "85778cdf2bed372008e6646c64340460764a5b85"
uuid = "661c6b06-c737-4d37-b85c-46df65de6f69"
version = "0.4.5"

[[deps.PlutoTest]]
deps = ["HypertextLiteral", "InteractiveUtils", "Markdown", "Test"]
git-tree-sha1 = "17aa9b81106e661cffa1c4c36c17ee1c50a86eda"
uuid = "cb4044da-4d16-4ffa-a6a3-8cad7f73ebdc"
version = "0.2.2"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Downloads", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "fcfec547342405c7a8529ea896f98c0ffcc4931d"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.70"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "5aa36f7049a63a1528fe8f7c3f2113413ffd4e1f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.1"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "0f27480397253da18fe2c12a4ba4eb9eb208bf3d"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.5.0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.Profile]]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "62389eeff14780bfe55195b7204c0d8738436d64"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.1"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

    [deps.Statistics.weakdeps]
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
version = "1.11.0"

[[deps.Tricks]]
git-tree-sha1 = "372b90fe551c019541fafc6ff034199dc19c8436"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.12"

[[deps.URIs]]
git-tree-sha1 = "bef26fb046d031353ef97a82e3fdb6afe7f21b1a"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.6.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.11.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.59.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"
"""

# ╔═╡ Cell order:
# ╟─27667e0a-8ebc-4397-8ac3-33a0f19f6987
# ╟─bedbe9b9-03be-4537-b938-89d2857d0cba
# ╟─8116b382-c927-4563-8fde-dc034dd96ab9
# ╠═c9eef6f8-4583-429b-a3ae-09f1ec8e5ecf
# ╟─05cf7bc1-cc04-4679-9534-05834f097371
# ╟─3ebe8069-11d3-4885-aec8-72e2f3f5f906
# ╟─f6be4fa8-351a-4c1c-b389-b79f09db2a4b
# ╠═6421c10b-9429-45ef-8ffb-b5117fae9e58
# ╠═fbb8c035-da0d-45d0-856c-0668f2ef954f
# ╠═d48ca14f-2b62-4f35-8c8a-07aa3563b579
# ╟─76c08fb3-89e1-4897-90f1-2f73ba298010
# ╟─693371c4-8e35-4a8e-9fa2-8c0e441515ac
# ╟─33f00289-8f32-4512-968e-d29fcd6968ff
# ╟─a3e0ad59-288a-423d-a7e9-ecadb055e0dc
# ╠═e50297d5-8599-48dd-935e-0c3975e4e379
# ╟─c0a54587-86bf-4f6d-9e5c-574badc06865
# ╠═61db6108-8be6-4544-b1be-6e448d99748f
# ╠═a394967a-16cb-42fe-a1fc-797e108439d3
# ╟─6569d30f-0c9d-4533-a421-086fcf1b5f62
# ╟─90471f40-c548-494f-84cb-871ee0f3f5f9
# ╠═e1a70885-ac8b-4b4c-9080-92c3178f5a03
# ╠═a6034884-89a1-43d7-b30e-f389ae2e05d3
# ╟─9a89ccd7-f690-4dc1-9736-779aa7845ab2
# ╟─48aed012-2da1-4a06-9404-a34cdd4b3eee
# ╟─b17e6d66-9a19-48a8-a6ba-c8d5145387f3
# ╠═4d6d13f7-47b0-4e8a-af69-3aa0a8cb8d2d
# ╟─c5b8a22d-d47b-4f65-b90e-544e8b6c3a88
# ╟─4ec0d903-4e3f-42d6-8853-86c848bb92ce
# ╟─869e40bc-0679-4b20-acff-f8db6637a887
# ╠═dccdcf37-3354-4717-8cf3-b391bbaf6e9a
# ╟─94891c38-8e36-43f5-b0a6-9b8b38145ef9
# ╠═a9af0fa1-99af-447d-86ad-cb926f7b9de1
# ╟─2ca10bfe-549b-4910-95a3-e68a292df0d6
# ╟─a93f0326-78ca-407d-aec2-5de318c002ca
# ╟─b760fedd-41ea-4784-845f-ede0163c0d12
# ╠═2e893623-2d05-48ac-b7c6-0ba167dc7419
# ╠═af508570-b20f-4dd3-a995-36c79fc41823
# ╠═bfdd8ecf-5f05-4056-a9d8-f3404774ff52
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
