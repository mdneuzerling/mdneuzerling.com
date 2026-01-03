---
title: "Advent of Code 2021: A Julia Journal - Part 2"
author: ~
date: '2021-12-19'
slug: advent-of-code-2021-a-julia-journal-part-2
category: code
tags:
    - julia
    - advent_of_code
featured: "/img/featured/journal2.webp"
output: hugodown::md_document

---

[Advent of Code](https://adventofcode.com/) is an advent calendar for programming puzzles. I decided to tackle this year's set of 50 puzzles in Julia and journal my experiences along the way. I'm a beginner in Julia so I thought this would help me improve my skills.

This post covers days 9 through 16.

## [Day 9: Bracket matching](https://adventofcode.com/2021/day/9)

> Syntax error in navigation subsystem on line: all of them

I over-engineered the heck out of this puzzle. I can't justify making this `struct` just to represent a bracket:

```julia
struct Bracket
    left::AbstractString
    right::AbstractString
    orientation::AbstractString
    function Bracket(left::AbstractString, right::AbstractString, orientation::AbstractString)
        if orientation ∉ ["left", "right"]
            throw(ArgumentError("orientation must be \"left\" or \"right\", got: $orientation"))
        end
        new(left, right, orientation)
    end
end
```

Although it does mean I can flip a bracket with `-bracket` by defining the unary operation:

```julia
function -(bracket::Bracket)
    if bracket.orientation == "left"
        return (Bracket(bracket.left, bracket.right, "right"))
    end
    Bracket(bracket.left, bracket.right, "left")
end
```

Overall I enjoyed this puzzle. And the overengineering did help. A key component was defining a function to iteratively remove the matching brackets, and being able to refer to the `orientation` of a bracket let me do this:

```julia
function strip_matching_brackets(brackets::Vector{Bracket})
    for i = 1:length(brackets)-1
        if brackets[i].orientation == "left" && brackets[i] == -brackets[i+1]
            stripped = [brackets[j] for j in 1:length(brackets) if j ∉ [i, i + 1]]
            return strip_matching_brackets(stripped)
        end
    end
    return brackets
end
```

And for the second part, in which I had to identify the right brackets needed to close a sequence of incomplete brackets, I could do this:

```julia
right_half = [-bracket for bracket in reverse(stripped)]
```

## [Day 11: Bioluminescent octopuses](https://adventofcode.com/2021/day/11)

> They seem to not like the Christmas lights on your submarine, so you turn them off for now.

I had a sense of satisfaction for writing code for part 1 that's so general that it took me about a minute to solve part 2. It's just a good feeling.

I designed an `increment` function that increased all entries of a matrix by 1, a `rollover` function that converted all values of a matrix greater than 9 to 0. These are neat one-liners in Julia thanks to my old friend loop fusion and the `@.` macro that makes it apply across the whole line:

```julia
increment(octopuses::Matrix{Int64}) = octopuses .+ 1
rollover(octopuses::Matrix{Int64}) = @. mod(min(octopuses, 10), 10)
```

The main work is done in the recursive `flash` function:

```julia
function flash(
    octopuses::Matrix{Int64},
    flashed::Vector{CartesianIndex{2}} = Vector{CartesianIndex{2}}()
)
    above_9 = findall(x -> x > 9, octopuses)
    new_flashes = above_9[(!in).(above_9, Ref(flashed))]
    if length(new_flashes) == 0
        return rollover(octopuses), flashed
    end
    octopuses += neighbours_matrix(new_flashes)
    octopuses, flashed = flash(octopuses, [flashed; new_flashes])
end
```

The `neighbourhood` function here calculates a 10*10 matrix of all 0 except for the neighbours of a given coordinate, which have value 1. When given a vector of coordinates, as what happens here, it sums the neighbour matrices of each coordinate. This is how a flashing octopus charges its neighbours.

It's not immediately clear to me what `above_9[(!in).(above_9, Ref(flashed))]` does; I need to think it through. The `!in` function is vectorised (Julia users tend to prefer the word _broadcasting_), but the `Ref` function is used to treat `flashed` as a scalar. This means that the each value of `above_9` is compared to the singular `flashed` value. The result is a Boolean vector, used to filter the elements of `above_9` to those that are not in `flashed`.

With all of this in place the `step` function was a nice one-liner:

```julia
step(octopuses::Matrix{Int64}) = octopuses |> increment |> flash
```

This function returns both the modified `octopuses` matrix and the vector of octopuses that flashed during the step. This would also work if the function returned only the number that flashed, but I'm not sure how type stability works with recursive functions, so I played it safe. With this return value the actual solutions could iterate through steps and use the returned vector of flashing octopuses to calculate whatever answer is needed.

## [Day 12: Plotting a course](https://adventofcode.com/2021/day/12)

> the only way to know if you've found the best path is to find all of them.

Graphs! I love it. Apart from a few stack overflow errors this was relatively straightforward. I decided to implement a special `Graph` struct with vertices and edges, although this is arguably not necessary.

The main function --- `traverse` --- has a Boolean keyword argument `allow_small_cave_revisit`. The function is recursive, branching out along every possible path and taking the set union of all paths ending at "end".

Part 2 of this puzzle allows a _single_ small cave to be visited once. To make this work I include the following piece of logic that checks for a duplicate small cave in the path travelled thus far. If one is detected, it switches instead to `allow_small_cave_revisit = false`:

```julia
if allow_small_cave_revisit && has_visited_a_small_cave_twice(updated_path)
    return traverse(graph, path_so_far, next_vertex; allow_small_cave_revisit = false)
end
```

This works because the `allow_small_cave_revisit = false` argument forbids the function from _adding_ a duplicate small cave to the path, but it doesn't enforce this constraint on the path travelled so far. Note also that we only need to check for dead ends if `allow_small_cave_revisit = false`, because in the `true` case we can always travel back along the path we came. The full function is shown below:

```julia
function traverse(
    graph::Graph,
    path_so_far = Vector{String}(),
    next_vertex = "start";
    allow_small_cave_revisit = false
)
    updated_path = [path_so_far; next_vertex]
    if next_vertex == "end"
        return Set([updated_path])
    end
    if allow_small_cave_revisit && has_visited_a_small_cave_twice(updated_path)
        return traverse(graph, path_so_far, next_vertex; allow_small_cave_revisit = false)
    end
    valid_neighbours = filter(candidate -> candidate != "start", neighbours(graph, next_vertex))
    if !allow_small_cave_revisit
        valid_neighbours = filter(
            candidate -> cave_size(candidate) == "large" || candidate ∉ updated_path,
            valid_neighbours
        )
        if length(valid_neighbours) == 0 # dead end
            return Set{Vector{String}}()
        end
    end
    branches = [
        traverse(graph, updated_path, neighbour; allow_small_cave_revisit = allow_small_cave_revisit)
        for neighbour in valid_neighbours
    ]
    return ∪(branches...)
end
```

I did notice in the graphs that large caves were always connected by small caves. This suggests that the graph can be represented another way, in which large caves are vertices and small caves are edges. I wasn't sure how that would simplify the solution, so I didn't pursue the idea.

## [Day 13 - Paper folding](https://adventofcode.com/2021/day/13)

> Congratulations on your purchase! To activate this infrared thermal imaging camera system, please enter the code found on page 1 of the manual.

Up until now I thought that the solutions to Advent of Code puzzles were always integers! For day 13 I had to print out coordinates that formed letters. This was new.

This is one of those days where even though my code worked, I feel like I'm missing an elegant way to do it. I implemented two functions --- `horizontal_fold` and `vertical_fold` --- that are almost identical. But the few differences make it such that combining the two would lead to some hideous branching and spaghetti code.

```julia
function horizontal_fold(coordinates::Vector{Tuple{Int64,Int64}}, fold_line::Int64)
    # fold up
    below_fold = [coordinate for coordinate in coordinates if coordinate[2] > fold_line]
    above_fold = coordinates[(!in).(coordinates, Ref(below_fold))]

    below_fold_x = [coordinate[1] for coordinate in below_fold]
    below_fold_y = [coordinate[2] for coordinate in below_fold]
    mirrored_y_coordinates = [fold_line - (y - fold_line) for y in below_fold_y]
    mirrored = collect(zip(below_fold_x, mirrored_y_coordinates))
    unique([above_fold; mirrored])
end
```

Having created a function to print the coordinates with unicode blocks, it was satisfying to see my answer to part 2 pop up:

```julia
julia> solve(13, 2)
███  █  █  ██  █    ███   ██  ███   ██ 
█  █ █  █ █  █ █    █  █ █  █ █  █ █  █
█  █ ████ █  █ █    █  █ █    █  █ █  █
███  █  █ ████ █    ███  █    ███  ████
█ █  █  █ █  █ █    █ █  █  █ █ █  █  █
█  █ █  █ █  █ ████ █  █  ██  █  █ █  █
```

## Day 14: This polymer grows quickly

"Simple pattern substitution," I thought to myself, deciding straight away that this would be an easy day.

It was not.

First of all, I defined an `Insertion` struct that would define the rules:

```julia
struct Insertion
    pattern::AbstractString
    insert::AbstractString
end
```

My first solution was naïve. I calculated the full string, and then counted the letters. For 10 iterations this was sufficient. The `substitute` function first determined which letter insertions were needed. It then iterated through the insertions, keeping track of an offset (as each new letter increased the positions of the remaining letters by 1):

```julia
function substitute(template::AbstractString, insertions::Vector{Insertion})
    characters_to_insert = Vector{Tuple{Int64,AbstractString}}()
    for i = 1:length(template)-1
        current_pair = template[i] * template[i+1]
        for insertion in insertions
            if current_pair == insertion.pattern
                push!(characters_to_insert, (i, insertion.insert))
                break
            end
        end
    end

    for i = 1:length(characters_to_insert)
        index, to_insert = characters_to_insert[i]
        offset = i - 1
        index_with_offset = index + offset
        template = insert_after(template, to_insert, index_with_offset)
    end

    return template
end
```

But of course, I ran out of memory for 40 iterations. I thought about compressing the template in some way: perhaps counting letters and then their occurrences. But the key realisation is that _the positions of the pairs of letters does not matter_. I thus tracked only the pairs themselves, along with the letter occurrences:

```julia
mutable struct CompressedTemplate
    pairs::Dict{Tuple{Char,Char},Int64}
    letter_counts::Dict{Char,Int64}
end
```

These pairs overlap, but that's okay. The new `substitute` function now takes a pair and --- if it matches an insertion rule --- splits it, increments the count of the two new pairs and decreases the count of the former pair. It also tracks the new letters each time:

```julia
function substitute(template::CompressedTemplate, insertions::Vector{Insertion})
    new_template = deepcopy(template)
    for insertion in insertions
        current_pattern = pair(insertion)
        occurrences = get(template.pairs, current_pattern, 0)

        pair_left, pair_right = new_pairs(insertion)
        new_template.pairs[pair_left] = get(new_template.pairs, pair_left, 0) + occurrences
        new_template.pairs[pair_right] = get(new_template.pairs, pair_right, 0) + occurrences
        new_template.pairs[current_pattern] = get(new_template.pairs, current_pattern, 0) - occurrences

        new_letter = only(insertion.insert)
        new_template.letter_counts[new_letter] = get(new_template.letter_counts, new_letter, 0) + occurrences
    end
    new_template
end
```

I went from running out of memory to solving part 2 so quickly that I didn't notice the execution time.

## Intermission: A gripe about Julia

I'm pretty positive when I speak of Julia but here's one annoyance: I have to restart the kernel _very_ often. If I defined a `struct` and then later chose to redefine it? Restart. If I accidentally defined a `pair` variable but then needed to define a `pair` function? Restart (that's right, you can't delete variables in Julia). And every restart means:

1. activating the project environment
1. loading the package
1. recovering the state of the REPL as it was before the restart
1. recovering my test input

I use the `Revise` package for automatically changing my environment in response to changes to my code, but it doesn't solve these problems. Actually, `Revise` isn't very useful at all. I'm working in submodules and I don't `export` many objects. I don't want to type `AOC2021.Day14.CompressedTemplate` every time when I can just type `CompressedTemplate`. So I define the working functions straight in the REPL.

What I'm missing in Julia is the equivalent of `devtools::load_all` in R. When I'm developing a package I want to load _every_ object, even if it isn't exported, and the fewer letters I need to type the better. I want a single, definitive action to reload differences, because that way I know if the reload fails and why. And then I can bind this to a keyboard shortcut like in R and focus on developing my code.

## [Day 15 - Suddenly needing to learn Dijkstra's algorithm](https://adventofcode.com/2021/day/15)

> the walls of the cave are covered in chitons, and it would be best not to bump any of them.

This is the first day that I really struggled. I had enough knowledge of the fundamentals of computer science to know that Dijkstra's algorithm existed, and that it could be used to find the shortest path between two vertices in an edge-weighted graph. But I had never used it before, let alone _implemented_ it.

I tried implementing the algorithm from Wikipedia. I was keeping track of all unchecked vertices with a vector, and distances with dictionaries. I initialised every distance to `2^63-1` (the largest value of a 64-bit integer), except for the distance from the source vertex which I set to 0. On each iteration I would find the vertex with the smallest distance and calculate the distance to its neighbours, continuing until I hit the target vertex.

This worked for part 1, but for part 2 the graph was 25 times as large. And it didn't look like my algorithm would finish in my lifetime.

I needed a way to store the distances such that I could easily retrieve the minimum one. Looking around the internet, I found a min binary heap would work here. Despite my weak understanding of, well, everything, I managed to implement it. Note in the code below that `neighbours` is a helper function that finds all in-bounds coordinates around a given point in a matrix:

```julia
function dijkstra(heatmap::Matrix{Int64})
    source = (1, 1) # top-left corner
    target = size(heatmap) # bottom-right corner

    risk_from_source = BinaryMinHeap{Tuple{Int64,Int64,Int64}}()
    push!(risk_from_source, (0, source...))

    counted = Vector{Tuple{Int64,Int64}}()

    while true
        risk, row, column = pop!(risk_from_source)
        vertex = (row, column)
        if vertex in counted
            continue
        end
        push!(counted, vertex)

        if vertex == target
            return risk
        end

        uncounted_neighbours = filter(v -> v ∉ counted, neighbours(heatmap, vertex))

        for neighbour in uncounted_neighbours
            neighbour_risk = risk + heatmap[neighbour...]
            push!(risk_from_source, (neighbour_risk, neighbour...))
        end
    end
end
```

This worked, but it was still fairly slow. It took 1--2 minutes to solve part 2. This is good enough to get the stars, but I'm still disappointed.

Profiling the code tells me that there's a slowness somewhere in a `getindex` operation, but that's still quite vague. Is it still the minimum distance retrieval that's slowing this down? The `if vertex in counted` branch? 

At this point I had a solution in a reasonable time frame and so I decided to give it a rest. Maybe this is something to revisit another day.

## [Day 16 - decoding BITS](https://adventofcode.com/2021/day/16)

> The transmission was sent using the Buoyancy Interchange Transmission System (BITS), a method of packing numeric expressions into a binary sequence

This puzzle wasn't necessarily _hard_, but it did require _hard work_. I went from my usual 2 unit tests each day to a total of 18 unit tests for day 16.

My approach for processing the bits was to make `extract` functions that returned a packet, along with the remaining bits once that packet had been removed from the start. For example, for literal operators:

```julia
function extract_literal_packet(packet_bitstring::AbstractString)
    last_bit = 11 # header + one group
    while packet_bitstring[last_bit-4] != '0'
        last_bit += 5
    end
    content = packet_bitstring[7:last_bit]
    groups = [content[i:min(i + 4, end)] for i = 1:5:length(content)]
    decoded = [group[2:end] for group in groups] |> join |> decimal
    packet = LiteralPacket(
        decoded,
        packet_bitstring[1:last_bit],
        last_bit,
        version(packet_bitstring[1:last_bit])
    )
    return packet, packet_bitstring[last_bit+1:end]
end
```

Julia's struct system was helpful here. I defined an abstract `Packet` type, of which `LiteralPacket` and `OperatorPacket` were concrete subtypes:

```julia
abstract type Packet end

struct LiteralPacket <: Packet
    decoded::Int64
    raw::String
    length::Int64
    version::Int64
end

struct OperatorPacket <: Packet
    subpackets::Vector{Packet}
    raw::String
    length::Int64
    version::Int64
    type_id::Int64
end
```

Defining a vector of a bespoke type in R is unthinkable without diving into C, but in Julia it's as easy as `Vector{Packet}()`.

My approach also lead to some neat ways to tackle the puzzle calculations. For part 1:

```julia
sum_versions(packet::LiteralPacket) = packet.version
function sum_versions(packet::OperatorPacket)
    packet.version + sum(sum_versions(subpacket) for subpacket in packet.subpackets)
end
```

And for part 2:

```julia
decode(packet::LiteralPacket) = packet.decoded
function decode(packet::OperatorPacket)
    operation = type_id_function[packet.type_id]
    operation([decode(subpacket) for subpacket in packet.subpackets])
end
```

That `type_id_function` dictionary was a constant I used to link the type ID of a packet to a Julia function. To be consistent, I made it such that all of the functions accepted vectors (even if only a vector length 2). It pleases the mathematician in me to be able to use both prefix and infix notation like this:

```julia
const type_id_function = Dict(
    0 => sum,
    1 => prod,
    2 => minimum,
    3 => maximum,
    # omit 4, which is reserved for literals
    # the following only ever contain two packets
    5 => x -> Int(>(x...)),
    6 => x -> Int(<(x...)),
    7 => x -> Int(==(x...)),
)
```

I helped myself debug the puzzle solution by defining a custom `show` method for my packet structs. This makes the tree-structure of the packets more obvious:

```julia
= <v4>
  + <v2>
    1 <v2>
    3 <v4>
  × <v6>
    2 <v0>
    2 <v2>
```

---

[The image at the top of this page is by Dom J](https://www.pexels.com/photo/white-notebook-and-yellow-pencil-45718/) and is used under the terms of the [the Pexels License](https://www.pexels.com/license/).