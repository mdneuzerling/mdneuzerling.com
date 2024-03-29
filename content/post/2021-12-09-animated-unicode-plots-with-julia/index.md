---
title: "Animated Unicode Plots with Julia"
author: ~
date: '2021-12-09'
slug: animated-unicode-plots-with-julia
categories: [julia, bitesize]
tags:
    - julia
thumbnail: "/img/julia-animate.gif"
output: hugodown::md_document
rmd_hash: 739225c4463544dd

---

I love [Julia's `UnicodePlots.jl`](https://github.com/JuliaPlots/UnicodePlots.jl), a package for making pretty, colourful plots directly in the terminal. While playing around for Advent of Code I wrote a function to animate a sequence of Unicode plots. It's not much, but I couldn't find anything similar on Google so I thought I'd share.

The `move_up` helper function is the fiddly part; it moves the cursor to the start of where the plot begins so that a new plot can be printed right on top. After that I print the frames one after another, with a chosen delay, and finish by printin the final frame:

``` julia
using UnicodePlots

function move_up(s::AbstractString)
    move_up_n_lines(n) = "\u1b[$(n)F"
    # actually string_height - 1, but we're assuming cursor is on the last line
    string_height = length(collect(eachmatch(r"\n", s)))
    print(move_up_n_lines(string_height))
    nothing
end

function animate(plots; frame_delay = 0)
    print("\u001B[?25l") # hide cursor
    for frame in frames[1:end-1]
        print(frame)
        sleep(frame_delay)
        move_up(string(frame))
    end
    print(frames[end])
    print("\u001B[?25h") # visible cursor
    nothing
end
```

Now, to generate the example:

``` julia
function makeplot(x::Integer)
    lineplot(
        [-1, 2, 3, 7],
        [-1, floor(x / 2), 9, x],
        title = "Example Plot",
        name = "my line",
        xlabel = "x",
        ylabel = "y",
        border = :dotted,
        canvas = DotCanvas
    )
end

frames = [makeplot(i) for i in vcat(1:9, range(9, 1, step = -1))]
animate(frames; frame_delay = 0.1)
```

