---
title: "My Machine Learning Process (Mistakes Included)"
author: ~
date: '2022-01-24'
slug: my-machine-learning-process-mistakes-included
category: code
tags:
    - R
featured: "/img/featured/mistake.webp"
output: hugodown::md_document
rmd_hash: 8743f909ea5a0196

---

When I train a machine learning model in a blog post, I edit out all the mistakes. I make it seem like I had the perfect data I needed from the very start, and I never add a useless feature. This time, I want to train a model with all the mistakes and fruitless efforts included.

My goal here is to describe *my process of creating a model* rather than just presenting the final code.

The material in this post is adapted from a presentation I gave to [the Deakin Girl Geeks student society of Deakin University](https://www.dusa.org.au/clubs/deakin-girl-geeks-dgg).

## One of my favourite datasets: Pokémon

This Pokémon data comes from [a gist prepared by GitHub user simsketch](https://gist.github.com/simsketch/1a029a8d7fca1e4c142cbfd043a68f19). I manually corrected the last few rows as suggested in the comments/

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='kr'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='o'>(</span><span class='nv'><a href='https://tidyverse.tidyverse.org'>tidyverse</a></span><span class='o'>)</span>

<span class='nv'>pokemon</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://readr.tidyverse.org/reference/read_delim.html'>read_csv</a></span><span class='o'>(</span><span class='s'>"data/pokemon.csv"</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'>janitor</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/janitor/man/clean_names.html'>clean_names</a></span><span class='o'>(</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'><a href='https://dplyr.tidyverse.org/reference/mutate.html'>mutate</a></span><span class='o'>(</span>
    type1 <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/factor.html'>as.factor</a></span><span class='o'>(</span><span class='nv'>type1</span><span class='o'>)</span>,
    type2 <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/factor.html'>as.factor</a></span><span class='o'>(</span><span class='nv'>type2</span><span class='o'>)</span>,
    legendary <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/logical.html'>as.logical</a></span><span class='o'>(</span><span class='nv'>legendary</span><span class='o'>)</span>
  <span class='o'>)</span>

<span class='nv'>pokemon</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> <span class='nv'>colnames</span>
<span class='c'>#&gt;  [1] "number"         "code"           "serial"         "name"          </span>
<span class='c'>#&gt;  [5] "type1"          "type2"          "color"          "ability1"      </span>
<span class='c'>#&gt;  [9] "ability2"       "ability_hidden" "generation"     "legendary"     </span>
<span class='c'>#&gt; [13] "mega_evolution" "height"         "weight"         "hp"            </span>
<span class='c'>#&gt; [17] "atk"            "def"            "sp_atk"         "sp_def"        </span>
<span class='c'>#&gt; [21] "spd"            "total"</span></code></pre>

</div>

Pokémon have *types* describing the elements or categories with which they are most closely affiliated. Charmander, for example, is a lizard with a perpetual flame on its tail and so is a *Fire* Pokémon. There are 18 types in total.

Pokémon also have *stats* --- attributes that describe their strengths and weaknesses. These are usually abbreviated:

-   **hp**: *hit points*, a numerical representation of how much *health* the Pokémon has
-   **atk**: determines how much *physical damage* the Pokémon can deal
-   **sp. atk**: determines how much *special damage* the Pokémon can deal. Some abilities (or *moves*) are more supernatural in nature, like a breath of fire or a bolt of thunder, and so are considered *special*.
-   **def**: *defence*, a Pokémon's capacity to resist physical damage.
-   **sp. def**: *special defence*, a Pokémon's capacity to resist special damage.
-   **spd**: *speed*, how quickly a Pokémon can attack.

It makes sense then that a Fighting-type Pokémon might have stronger **atk** than a Fire-type Pokémon, whose moves are more likely to be *special*. The question is: from a Pokémon's stats or other features, can we determine its type?

## The advanced technique of actually looking at the data

I'm not proud of this, but I often find myself writing many lines of exploratory code before I actually *look* at the data. Due to its rarity, I call this an *advanced* technique.

Now that I have a question I'm trying to answer, the first step is to *look at the data*.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>pokemon</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span>
  <span class='nf'><a href='https://dplyr.tidyverse.org/reference/select.html'>select</a></span><span class='o'>(</span><span class='nv'>number</span>, <span class='nv'>name</span>, <span class='nv'>type1</span>, <span class='nv'>type2</span>, <span class='nv'>hp</span><span class='o'>:</span><span class='nv'>total</span>, <span class='nv'>color</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span>
  <span class='nf'><a href='https://rdrr.io/r/utils/head.html'>head</a></span><span class='o'>(</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span>
  <span class='nf'>knitr</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/knitr/man/kable.html'>kable</a></span><span class='o'>(</span><span class='s'>"html"</span><span class='o'>)</span>
</code></pre>
<table>
<thead>
<tr>
<th style="text-align:right;">
number
</th>
<th style="text-align:left;">
name
</th>
<th style="text-align:left;">
type1
</th>
<th style="text-align:left;">
type2
</th>
<th style="text-align:right;">
hp
</th>
<th style="text-align:right;">
atk
</th>
<th style="text-align:right;">
def
</th>
<th style="text-align:right;">
sp_atk
</th>
<th style="text-align:right;">
sp_def
</th>
<th style="text-align:right;">
spd
</th>
<th style="text-align:right;">
total
</th>
<th style="text-align:left;">
color
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
Bulbasaur
</td>
<td style="text-align:left;">
Grass
</td>
<td style="text-align:left;">
Poison
</td>
<td style="text-align:right;">
45
</td>
<td style="text-align:right;">
49
</td>
<td style="text-align:right;">
49
</td>
<td style="text-align:right;">
65
</td>
<td style="text-align:right;">
65
</td>
<td style="text-align:right;">
45
</td>
<td style="text-align:right;">
318
</td>
<td style="text-align:left;">
Green
</td>
</tr>
<tr>
<td style="text-align:right;">
2
</td>
<td style="text-align:left;">
Ivysaur
</td>
<td style="text-align:left;">
Grass
</td>
<td style="text-align:left;">
Poison
</td>
<td style="text-align:right;">
60
</td>
<td style="text-align:right;">
62
</td>
<td style="text-align:right;">
63
</td>
<td style="text-align:right;">
80
</td>
<td style="text-align:right;">
80
</td>
<td style="text-align:right;">
60
</td>
<td style="text-align:right;">
405
</td>
<td style="text-align:left;">
Green
</td>
</tr>
<tr>
<td style="text-align:right;">
3
</td>
<td style="text-align:left;">
Venusaur
</td>
<td style="text-align:left;">
Grass
</td>
<td style="text-align:left;">
Poison
</td>
<td style="text-align:right;">
80
</td>
<td style="text-align:right;">
82
</td>
<td style="text-align:right;">
83
</td>
<td style="text-align:right;">
100
</td>
<td style="text-align:right;">
100
</td>
<td style="text-align:right;">
80
</td>
<td style="text-align:right;">
525
</td>
<td style="text-align:left;">
Green
</td>
</tr>
<tr>
<td style="text-align:right;">
3
</td>
<td style="text-align:left;">
Mega Venusaur
</td>
<td style="text-align:left;">
Grass
</td>
<td style="text-align:left;">
Poison
</td>
<td style="text-align:right;">
80
</td>
<td style="text-align:right;">
100
</td>
<td style="text-align:right;">
123
</td>
<td style="text-align:right;">
122
</td>
<td style="text-align:right;">
120
</td>
<td style="text-align:right;">
80
</td>
<td style="text-align:right;">
625
</td>
<td style="text-align:left;">
Green
</td>
</tr>
<tr>
<td style="text-align:right;">
4
</td>
<td style="text-align:left;">
Charmander
</td>
<td style="text-align:left;">
Fire
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
39
</td>
<td style="text-align:right;">
52
</td>
<td style="text-align:right;">
43
</td>
<td style="text-align:right;">
60
</td>
<td style="text-align:right;">
50
</td>
<td style="text-align:right;">
65
</td>
<td style="text-align:right;">
309
</td>
<td style="text-align:left;">
Red
</td>
</tr>
<tr>
<td style="text-align:right;">
5
</td>
<td style="text-align:left;">
Charmeleon
</td>
<td style="text-align:left;">
Fire
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
58
</td>
<td style="text-align:right;">
64
</td>
<td style="text-align:right;">
58
</td>
<td style="text-align:right;">
80
</td>
<td style="text-align:right;">
65
</td>
<td style="text-align:right;">
80
</td>
<td style="text-align:right;">
405
</td>
<td style="text-align:left;">
Red
</td>
</tr>
</tbody>
</table>

</div>

### Always ask: what does one row of the data represent?

This is incredibly important --- if I don't know what one row of the data is, I can't progress any further. Those with database experience might ask a related question: what is the *primary key*?

A reasonable assumption is that every row is a Pokémon, and this would be wrong.

The Pokémon `number` seems like a good candidate here, but I can see that Venusaur and Mega Venusaur share a `number`. A mega evolution is a temporary transformation of a Pokémon. It seems that in the data I have here (and in the Pokémon universe more generally), mega evolutions are seen as variations of existing Pokémon.

The question that follows is whether I should include these mega evolutions or discard them. I'm going to keep them for now, since I think they're still relevant to the hypothesis.

I might then ask if `name` is a unique identifier, but this turns out to be false:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>pokemon</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span>
  <span class='nf'><a href='https://dplyr.tidyverse.org/reference/filter.html'>filter</a></span><span class='o'>(</span><span class='nv'>name</span> <span class='o'>==</span> <span class='s'>"Darmanitan"</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span>
  <span class='nf'><a href='https://dplyr.tidyverse.org/reference/select.html'>select</a></span><span class='o'>(</span><span class='nv'>number</span>, <span class='nv'>name</span>, <span class='nv'>type1</span>, <span class='nv'>type2</span>, <span class='nv'>hp</span><span class='o'>:</span><span class='nv'>total</span>, <span class='nv'>color</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span>
  <span class='nf'>knitr</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/knitr/man/kable.html'>kable</a></span><span class='o'>(</span><span class='s'>"html"</span><span class='o'>)</span>
</code></pre>
<table>
<thead>
<tr>
<th style="text-align:right;">
number
</th>
<th style="text-align:left;">
name
</th>
<th style="text-align:left;">
type1
</th>
<th style="text-align:left;">
type2
</th>
<th style="text-align:right;">
hp
</th>
<th style="text-align:right;">
atk
</th>
<th style="text-align:right;">
def
</th>
<th style="text-align:right;">
sp_atk
</th>
<th style="text-align:right;">
sp_def
</th>
<th style="text-align:right;">
spd
</th>
<th style="text-align:right;">
total
</th>
<th style="text-align:left;">
color
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
555
</td>
<td style="text-align:left;">
Darmanitan
</td>
<td style="text-align:left;">
Fire
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
105
</td>
<td style="text-align:right;">
140
</td>
<td style="text-align:right;">
55
</td>
<td style="text-align:right;">
30
</td>
<td style="text-align:right;">
55
</td>
<td style="text-align:right;">
95
</td>
<td style="text-align:right;">
480
</td>
<td style="text-align:left;">
Red
</td>
</tr>
<tr>
<td style="text-align:right;">
555
</td>
<td style="text-align:left;">
Darmanitan
</td>
<td style="text-align:left;">
Fire
</td>
<td style="text-align:left;">
Psychic
</td>
<td style="text-align:right;">
105
</td>
<td style="text-align:right;">
30
</td>
<td style="text-align:right;">
105
</td>
<td style="text-align:right;">
140
</td>
<td style="text-align:right;">
105
</td>
<td style="text-align:right;">
55
</td>
<td style="text-align:right;">
540
</td>
<td style="text-align:left;">
White
</td>
</tr>
<tr>
<td style="text-align:right;">
555
</td>
<td style="text-align:left;">
Darmanitan
</td>
<td style="text-align:left;">
Ice
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
105
</td>
<td style="text-align:right;">
140
</td>
<td style="text-align:right;">
55
</td>
<td style="text-align:right;">
30
</td>
<td style="text-align:right;">
55
</td>
<td style="text-align:right;">
95
</td>
<td style="text-align:right;">
480
</td>
<td style="text-align:left;">
White
</td>
</tr>
<tr>
<td style="text-align:right;">
555
</td>
<td style="text-align:left;">
Darmanitan
</td>
<td style="text-align:left;">
Ice
</td>
<td style="text-align:left;">
Fire
</td>
<td style="text-align:right;">
105
</td>
<td style="text-align:right;">
160
</td>
<td style="text-align:right;">
55
</td>
<td style="text-align:right;">
30
</td>
<td style="text-align:right;">
55
</td>
<td style="text-align:right;">
135
</td>
<td style="text-align:right;">
540
</td>
<td style="text-align:left;">
White
</td>
</tr>
</tbody>
</table>

</div>

This happens because Darmanitan has multiple *forms*. Some of these have different stats, but some have identical stats and different types. A natural question might be if name, types, and stats are enough to make each row unique. This is wrong:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>pokemon</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span>
  <span class='nf'><a href='https://dplyr.tidyverse.org/reference/filter.html'>filter</a></span><span class='o'>(</span><span class='nv'>name</span> <span class='o'>==</span> <span class='s'>"Burmy"</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span>
  <span class='nf'><a href='https://dplyr.tidyverse.org/reference/select.html'>select</a></span><span class='o'>(</span><span class='nv'>number</span>, <span class='nv'>name</span>, <span class='nv'>type1</span>, <span class='nv'>type2</span>, <span class='nv'>hp</span><span class='o'>:</span><span class='nv'>total</span>, <span class='nv'>color</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span>
  <span class='nf'>knitr</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/knitr/man/kable.html'>kable</a></span><span class='o'>(</span><span class='s'>"html"</span><span class='o'>)</span>
</code></pre>
<table>
<thead>
<tr>
<th style="text-align:right;">
number
</th>
<th style="text-align:left;">
name
</th>
<th style="text-align:left;">
type1
</th>
<th style="text-align:left;">
type2
</th>
<th style="text-align:right;">
hp
</th>
<th style="text-align:right;">
atk
</th>
<th style="text-align:right;">
def
</th>
<th style="text-align:right;">
sp_atk
</th>
<th style="text-align:right;">
sp_def
</th>
<th style="text-align:right;">
spd
</th>
<th style="text-align:right;">
total
</th>
<th style="text-align:left;">
color
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
412
</td>
<td style="text-align:left;">
Burmy
</td>
<td style="text-align:left;">
Bug
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
40
</td>
<td style="text-align:right;">
29
</td>
<td style="text-align:right;">
45
</td>
<td style="text-align:right;">
29
</td>
<td style="text-align:right;">
45
</td>
<td style="text-align:right;">
36
</td>
<td style="text-align:right;">
224
</td>
<td style="text-align:left;">
Green
</td>
</tr>
<tr>
<td style="text-align:right;">
412
</td>
<td style="text-align:left;">
Burmy
</td>
<td style="text-align:left;">
Bug
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
40
</td>
<td style="text-align:right;">
29
</td>
<td style="text-align:right;">
45
</td>
<td style="text-align:right;">
29
</td>
<td style="text-align:right;">
45
</td>
<td style="text-align:right;">
36
</td>
<td style="text-align:right;">
224
</td>
<td style="text-align:left;">
Brown
</td>
</tr>
<tr>
<td style="text-align:right;">
412
</td>
<td style="text-align:left;">
Burmy
</td>
<td style="text-align:left;">
Bug
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
40
</td>
<td style="text-align:right;">
29
</td>
<td style="text-align:right;">
45
</td>
<td style="text-align:right;">
29
</td>
<td style="text-align:right;">
45
</td>
<td style="text-align:right;">
36
</td>
<td style="text-align:right;">
224
</td>
<td style="text-align:left;">
Red
</td>
</tr>
</tbody>
</table>

</div>

These forms usually have a different appearance, hence the difference in colour for these entries for Burmy. Indeed, this turns out to be the explanation I'm looking for. This has to be verified manually, by using the [`janitor::get_dupes`](https://rdrr.io/pkg/janitor/man/get_dupes.html) function to investigate the dupes and looking up the Pokémon on [Bulbapedia](https://bulbapedia.bulbagarden.net).

I'll keep all of these rows as. Different forms of the same Pokémon can sometimes have different stats so it makes sense to treat each form as a separate Pokémon.

### Missing data and consistency

I want to take another look at the data now to consider any missing values, and if there are any obvious errors in the values.

<div class="highlight">

<table>
<thead>
<tr>
<th style="text-align:right;">
number
</th>
<th style="text-align:left;">
name
</th>
<th style="text-align:left;">
type1
</th>
<th style="text-align:left;">
type2
</th>
<th style="text-align:right;">
hp
</th>
<th style="text-align:right;">
atk
</th>
<th style="text-align:right;">
def
</th>
<th style="text-align:right;">
sp_atk
</th>
<th style="text-align:right;">
sp_def
</th>
<th style="text-align:right;">
spd
</th>
<th style="text-align:right;">
total
</th>
<th style="text-align:left;">
color
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
Bulbasaur
</td>
<td style="text-align:left;">
Grass
</td>
<td style="text-align:left;">
Poison
</td>
<td style="text-align:right;">
45
</td>
<td style="text-align:right;">
49
</td>
<td style="text-align:right;">
49
</td>
<td style="text-align:right;">
65
</td>
<td style="text-align:right;">
65
</td>
<td style="text-align:right;">
45
</td>
<td style="text-align:right;">
318
</td>
<td style="text-align:left;">
Green
</td>
</tr>
<tr>
<td style="text-align:right;">
2
</td>
<td style="text-align:left;">
Ivysaur
</td>
<td style="text-align:left;">
Grass
</td>
<td style="text-align:left;">
Poison
</td>
<td style="text-align:right;">
60
</td>
<td style="text-align:right;">
62
</td>
<td style="text-align:right;">
63
</td>
<td style="text-align:right;">
80
</td>
<td style="text-align:right;">
80
</td>
<td style="text-align:right;">
60
</td>
<td style="text-align:right;">
405
</td>
<td style="text-align:left;">
Green
</td>
</tr>
<tr>
<td style="text-align:right;">
3
</td>
<td style="text-align:left;">
Venusaur
</td>
<td style="text-align:left;">
Grass
</td>
<td style="text-align:left;">
Poison
</td>
<td style="text-align:right;">
80
</td>
<td style="text-align:right;">
82
</td>
<td style="text-align:right;">
83
</td>
<td style="text-align:right;">
100
</td>
<td style="text-align:right;">
100
</td>
<td style="text-align:right;">
80
</td>
<td style="text-align:right;">
525
</td>
<td style="text-align:left;">
Green
</td>
</tr>
<tr>
<td style="text-align:right;">
3
</td>
<td style="text-align:left;">
Mega Venusaur
</td>
<td style="text-align:left;">
Grass
</td>
<td style="text-align:left;">
Poison
</td>
<td style="text-align:right;">
80
</td>
<td style="text-align:right;">
100
</td>
<td style="text-align:right;">
123
</td>
<td style="text-align:right;">
122
</td>
<td style="text-align:right;">
120
</td>
<td style="text-align:right;">
80
</td>
<td style="text-align:right;">
625
</td>
<td style="text-align:left;">
Green
</td>
</tr>
<tr>
<td style="text-align:right;">
4
</td>
<td style="text-align:left;">
Charmander
</td>
<td style="text-align:left;">
Fire
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
39
</td>
<td style="text-align:right;">
52
</td>
<td style="text-align:right;">
43
</td>
<td style="text-align:right;">
60
</td>
<td style="text-align:right;">
50
</td>
<td style="text-align:right;">
65
</td>
<td style="text-align:right;">
309
</td>
<td style="text-align:left;">
Red
</td>
</tr>
<tr>
<td style="text-align:right;">
5
</td>
<td style="text-align:left;">
Charmeleon
</td>
<td style="text-align:left;">
Fire
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
58
</td>
<td style="text-align:right;">
64
</td>
<td style="text-align:right;">
58
</td>
<td style="text-align:right;">
80
</td>
<td style="text-align:right;">
65
</td>
<td style="text-align:right;">
80
</td>
<td style="text-align:right;">
405
</td>
<td style="text-align:left;">
Red
</td>
</tr>
</tbody>
</table>

</div>

There are two things I notice here:

-   `type2` can be missing, but `type1` *appears* to be present all the time (based on this very small sample). Are there any Pokémon without a type *at all*?
-   There's a `total` value, which I assume is the sum of all six stats. Is my assumption correct?

### Validating data assumptions makes me feel safer

I'll implement a quick function to validate this data, answering my two questions above.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>validate_pokemon</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>pokemon_data</span><span class='o'>)</span> <span class='o'>&#123;</span>
  <span class='nv'>total_mismatch</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/with.html'>with</a></span><span class='o'>(</span>
    <span class='nv'>pokemon_data</span>, 
    <span class='nv'>total</span> <span class='o'>!=</span> <span class='nv'>hp</span> <span class='o'>+</span> <span class='nv'>atk</span> <span class='o'>+</span> <span class='nv'>def</span> <span class='o'>+</span> <span class='nv'>sp_atk</span> <span class='o'>+</span> <span class='nv'>sp_def</span> <span class='o'>+</span> <span class='nv'>spd</span>
  <span class='o'>)</span>
  
  <span class='nv'>important_columns</span> <span class='o'>&lt;-</span> <span class='nv'>pokemon_data</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> <span class='nf'><a href='https://dplyr.tidyverse.org/reference/select.html'>select</a></span><span class='o'>(</span><span class='nv'>type1</span>, <span class='nv'>hp</span><span class='o'>:</span><span class='nv'>atk</span><span class='o'>)</span>
  
  <span class='o'>!</span><span class='nf'><a href='https://rdrr.io/r/base/any.html'>any</a></span><span class='o'>(</span><span class='nv'>total_mismatch</span><span class='o'>)</span> <span class='o'>&amp;&amp;</span> <span class='o'>!</span><span class='nf'><a href='https://rdrr.io/r/base/any.html'>any</a></span><span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/NA.html'>is.na</a></span><span class='o'>(</span><span class='nv'>important_columns</span><span class='o'>)</span><span class='o'>)</span>
<span class='o'>&#125;</span>

<span class='nf'>validate_pokemon</span><span class='o'>(</span><span class='nv'>pokemon</span><span class='o'>)</span>
<span class='c'>#&gt; [1] TRUE</span></code></pre>

</div>

Looks good! In a "real" situation I would go into much more detail, looking for as many potential problems as I can think of (for example, is `color` always present?). But combining all that logic into a single validation function is a good step, because I can insert this into any pipelines as a necessary step.

## Plot the data. Always.

Exploratory Data Analysis is about getting comfortable with the data. There's no algorithm for it. While I'm making only two graphs here, in a "real" situation this would be dozens of graphs (each with multiple failed attempts).

### Does more stats mean more powerful?

I'll consider the `total` stat amount, and determine if it actually does represent a Pokémon's strength. Certain Pokémon are considered "legendary" --- rare and more powerful than the average Pokémon. It makes sense that legendary Pokémon would have, on average, a higher `total` stat. And sure enough:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>pokemon</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'><a href='https://ggplot2.tidyverse.org/reference/ggplot.html'>ggplot</a></span><span class='o'>(</span>
    <span class='nf'><a href='https://ggplot2.tidyverse.org/reference/aes.html'>aes</a></span><span class='o'>(</span>
      x <span class='o'>=</span> <span class='nv'>total</span>,
      color <span class='o'>=</span> <span class='nv'>legendary</span>
    <span class='o'>)</span>
  <span class='o'>)</span> <span class='o'>+</span>
  <span class='nf'><a href='https://ggplot2.tidyverse.org/reference/geom_density.html'>geom_density</a></span><span class='o'>(</span>size <span class='o'>=</span> <span class='m'>1</span><span class='o'>)</span> <span class='o'>+</span>
  <span class='nf'><a href='https://ggplot2.tidyverse.org/reference/labs.html'>xlab</a></span><span class='o'>(</span><span class='s'>"Total stats"</span><span class='o'>)</span> <span class='o'>+</span>
  <span class='nf'><a href='https://ggplot2.tidyverse.org/reference/theme.html'>theme</a></span><span class='o'>(</span>
    axis.text.y <span class='o'>=</span> <span class='nf'><a href='https://ggplot2.tidyverse.org/reference/element.html'>element_blank</a></span><span class='o'>(</span><span class='o'>)</span>,
    axis.ticks.y <span class='o'>=</span> <span class='nf'><a href='https://ggplot2.tidyverse.org/reference/element.html'>element_blank</a></span><span class='o'>(</span><span class='o'>)</span>,
    legend.position <span class='o'>=</span> <span class='s'>"top"</span>
  <span class='o'>)</span>
</code></pre>
<img src="figs/stat-density-by-legendary-1.png" width="700px" style="display: block; margin: auto;" />

</div>

Sure enough, more stats means more powerful.

### Does the hypothesis make sense?

If my hypothesis is that stats matter to predict type, I should be able to plot something to show that this *makes sense*. I'm not looking for incontrovertible proof here. But if I can't find *something*, I may as well stop here.

Hypotheses don't come out of no where. Somewhere there's a anecdote or a feeling that a relationship exists before it's been formally investigated. In businesses that often comes from a domain expert --- someone who isn't necessarily an expert on data, but who knows the domain of the data better than any data scientist.

In this case, I've played enough Pokémon to know that Fire Pokémon tend to favour special attack and Fighting Pokémon favour (physical) attack.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>pokemon</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'><a href='https://dplyr.tidyverse.org/reference/filter.html'>filter</a></span><span class='o'>(</span>
    <span class='nv'>type1</span> <span class='o'><a href='https://rdrr.io/r/base/match.html'>%in%</a></span> <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='o'>(</span>
      <span class='s'>"Fire"</span>, <span class='s'>"Fighting"</span>
    <span class='o'>)</span>
  <span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'><a href='https://ggplot2.tidyverse.org/reference/ggplot.html'>ggplot</a></span><span class='o'>(</span><span class='nf'><a href='https://ggplot2.tidyverse.org/reference/aes.html'>aes</a></span><span class='o'>(</span>
      x <span class='o'>=</span> <span class='nv'>atk</span>,
      y <span class='o'>=</span> <span class='nv'>sp_atk</span>,
      color <span class='o'>=</span> <span class='nv'>type1</span>
  <span class='o'>)</span><span class='o'>)</span> <span class='o'>+</span>
  <span class='nf'><a href='https://ggplot2.tidyverse.org/reference/geom_point.html'>geom_point</a></span><span class='o'>(</span>size <span class='o'>=</span> <span class='m'>2</span><span class='o'>)</span> <span class='o'>+</span> 
  <span class='nf'><a href='https://ggplot2.tidyverse.org/reference/scale_manual.html'>scale_color_manual</a></span><span class='o'>(</span>
    values <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='o'>(</span>
      <span class='s'>"Fire"</span> <span class='o'>=</span> <span class='s'>"#F8766D"</span>,
      <span class='s'>"Fighting"</span> <span class='o'>=</span> <span class='s'>"#00BFC4"</span>
    <span class='o'>)</span>
  <span class='o'>)</span>
</code></pre>
<img src="figs/fire-fighting-stats-plot-1.png" width="700px" style="display: block; margin: auto;" />

</div>

There's a nice separation here that strongly suggests that --- for these two types, at least --- it's possible to use a Pokémon's stats to guess its primary type. I imagine drawing a in between the two groups as best I can, noting that there's no way to perfectly separate them. Depending on which side of the line the stats of a particular Pokémon falls I can classify it as either Fire or Fighting.

## Recap: What do I know?

I haven't given much thought to modelling yet. I've identified a question based on the data's *domain*, and then I explored the data by asking questions and validating assumptions. Modelling comes into the process late.

Here's what I know so far:

-   Pokémon have one or two types --- the primary (first) type is never missing
-   None of the stats are missing
-   `total` stats is a good measure of a Pokémon's strength
-   There's some relationship between primary type and stats

It's not time to model just yet. First I need to...

## Define a target metric

**Before** I start training any models, I need to know the *target metric* under which they'll be evaluated.

This question is impossible to answer here; my model is never going to be *used* for anything, so the choice of target metric can't be judged. So I'll keep it simple: under a candidate model, what percentage of type predictions are correct?

In a "real" situation, I would have other concerns. I would be asking about what happens when I get the prediction wrong, and what the benefits are when I get it right. These questions have no meaning here (there is no cost and no benefit to a model that is never put into practice), but they're crucial in real-life data science.

For example, consider a model that predicts the probability that it will rain. If I predict rain and get it wrong, I leave the house carrying an umbrella that I don't need --- no big deal. If I get it right, I get to keep my clothes dry. The cost of a false positive is small and the benefits of a true positive are high, so I might undervalue false negatives (by, say, carrying an umbrella at a 25% chance of rain instead of a 50% chance of rain).

### What makes a model *good enough*?

Now that I have my target metric, I need to know what counts as a good enough model. There's never a situation in which I have unlimited time to train the perfect model --- if nothing else, I'd get bored eventually. I need a stopping criterion.

Sometimes this is defined by the problem itself. For example, I might be required to demonstrate a certain financial benefit. Or I might have a time constraint and so I need to base my decisions on the best model I'm able to train in a given time.

Otherwise, for classification problems, I find it helps to consider a *naive algorithm* which predicts the most common class every time. The proportion of the most common class is also known as the *no-information rate*.

I need to calculate this rate *after* I split my data, and base it on the training data alone. This prevents me from making judgments based on the test data, and lets me compare my model's performance to the no-information rate of the data it was trained on.

The following function will calculate the no-information rate. The most common type is almost always Water, but this function doesn't assume that.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>no_information_rate</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>pokemon_data</span><span class='o'>)</span> <span class='o'>&#123;</span>
  <span class='nv'>pokemon_data</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span>
    <span class='nf'><a href='https://dplyr.tidyverse.org/reference/count.html'>count</a></span><span class='o'>(</span><span class='nv'>type1</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span>
    <span class='nf'><a href='https://dplyr.tidyverse.org/reference/mutate.html'>mutate</a></span><span class='o'>(</span>proportion <span class='o'>=</span> <span class='nv'>n</span> <span class='o'>/</span> <span class='nf'><a href='https://rdrr.io/r/base/sum.html'>sum</a></span><span class='o'>(</span><span class='nv'>n</span><span class='o'>)</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span>
    <span class='nf'><a href='https://dplyr.tidyverse.org/reference/top_n.html'>top_n</a></span><span class='o'>(</span><span class='m'>1</span>, <span class='nv'>proportion</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span>
    <span class='nf'><a href='https://dplyr.tidyverse.org/reference/pull.html'>pull</a></span><span class='o'>(</span><span class='nv'>proportion</span><span class='o'>)</span>
<span class='o'>&#125;</span></code></pre>

</div>

I should aim to beat this metric (preferably by a few percent) to be be convinced that my model has actually learnt *something*.

There are other criteria I need to pay attention too, though. I want to make sure that my predictions aren't concentrated on only one or two types. But with 18 types and 1048 rows, this may be tough. At some point I need to confront the problem I've been ignoring up until now: the number of classes is very small compared to the number of data points!

## Let's train a model!

*Now* I've done enough foundational work that I can train a model. I'm going to use the `tidymodels` meta-package, a favourite of mine:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='kr'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='o'>(</span><span class='nv'><a href='https://tidymodels.tidymodels.org'>tidymodels</a></span><span class='o'>)</span></code></pre>

</div>

I love random forests so that's what I'll use. A "proper" approach here would be to use a technique like cross-validation or train-validate-test split to compare multiple models, including multiple hyperparameter configurations for each model type. But I'm glossing over that for this post.

First, a simple train-test split. I'll train my model on `pokemon_train` and validate it on `pokemon_test`.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'><a href='https://rdrr.io/r/base/Random.html'>set.seed</a></span><span class='o'>(</span><span class='m'>12345</span><span class='o'>)</span>
<span class='nv'>pokemon_split</span> <span class='o'>&lt;-</span> <span class='nf'>initial_split</span><span class='o'>(</span><span class='nv'>pokemon</span>, strata <span class='o'>=</span> <span class='s'>"type1"</span>, prop <span class='o'>=</span> <span class='m'>0.7</span><span class='o'>)</span>
<span class='nv'>pokemon_train</span> <span class='o'>&lt;-</span> <span class='nf'>training</span><span class='o'>(</span><span class='nv'>pokemon_split</span><span class='o'>)</span>
<span class='nv'>pokemon_test</span> <span class='o'>&lt;-</span> <span class='nf'>testing</span><span class='o'>(</span><span class='nv'>pokemon_split</span><span class='o'>)</span>

<span class='nf'><a href='https://rdrr.io/r/base/nrow.html'>nrow</a></span><span class='o'>(</span><span class='nv'>pokemon_train</span><span class='o'>)</span>
<span class='c'>#&gt; [1] 733</span>

<span class='nf'><a href='https://rdrr.io/r/base/nrow.html'>nrow</a></span><span class='o'>(</span><span class='nv'>pokemon_test</span><span class='o'>)</span>
<span class='c'>#&gt; [1] 315</span></code></pre>

</div>

I now have a training set with 733 rows and a test set with 315 rows. I can use the function I prepared earlier to calculate the no-information rate.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'>no_information_rate</span><span class='o'>(</span><span class='nv'>pokemon_train</span><span class='o'>)</span>
<span class='c'>#&gt; [1] 0.1323329</span></code></pre>

</div>

This serves as a benchmark for my model. Here's the definition of the model, created with the `parsnip` package:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>pokemon_model</span> <span class='o'>&lt;-</span> <span class='nf'>rand_forest</span><span class='o'>(</span>
    trees <span class='o'>=</span> <span class='m'>200</span>,
    mtry <span class='o'>=</span> <span class='m'>3</span>
  <span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span>
  <span class='nf'>set_engine</span><span class='o'>(</span><span class='s'>"ranger"</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'>set_mode</span><span class='o'>(</span><span class='s'>"classification"</span><span class='o'>)</span>

<span class='nv'>pokemon_model</span>
<span class='c'>#&gt; Random Forest Model Specification (classification)</span>
<span class='c'>#&gt; </span>
<span class='c'>#&gt; Main Arguments:</span>
<span class='c'>#&gt;   mtry = 3</span>
<span class='c'>#&gt;   trees = 200</span>
<span class='c'>#&gt; </span>
<span class='c'>#&gt; Computational engine: ranger</span></code></pre>

</div>

At this point the model hasn't been fitted, so I had better fit it.

## First attempt - a failure that looks like a success

Data science is a string of failures and hopefully (but not always) a successful result. But I have to start with *a model* so that I can iterate. So I'll fit my model and see how it performs:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>fitted_pokemon_model</span> <span class='o'>&lt;-</span> <span class='nv'>pokemon_model</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> <span class='nf'>fit</span><span class='o'>(</span>
  <span class='nv'>type1</span> <span class='o'>~</span> <span class='nv'>hp</span> <span class='o'>+</span> <span class='nv'>atk</span> <span class='o'>+</span> <span class='nv'>def</span> <span class='o'>+</span> <span class='nv'>sp_atk</span> <span class='o'>+</span> <span class='nv'>sp_def</span> <span class='o'>+</span> <span class='nv'>spd</span>,
  data <span class='o'>=</span> <span class='nv'>pokemon_train</span>
<span class='o'>)</span>

<span class='nv'>first_attempt_accuracy</span> <span class='o'>&lt;-</span> <span class='nv'>pokemon_test</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'><a href='https://dplyr.tidyverse.org/reference/mutate.html'>mutate</a></span><span class='o'>(</span>
    predicted_type1 <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/stats/predict.html'>predict</a></span><span class='o'>(</span>
      <span class='nv'>fitted_pokemon_model</span>,
      <span class='nv'>pokemon_test</span>
    <span class='o'>)</span><span class='o'>$</span><span class='nv'>.pred_class</span>
  <span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span>
  <span class='nf'>accuracy</span><span class='o'>(</span><span class='nv'>type1</span>, <span class='nv'>predicted_type1</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'><a href='https://dplyr.tidyverse.org/reference/pull.html'>pull</a></span><span class='o'>(</span><span class='nv'>.estimate</span><span class='o'>)</span>

<span class='nv'>first_attempt_accuracy</span>
<span class='c'>#&gt; [1] 0.2031746</span></code></pre>

</div>

What a great result! 20.3% accuracy is better than the no-information rate of 13.2%. I'm clearly a great data scientist, and I can finally stop feeling insecure about my abilities.

### Except that's not a good result

A little pessimism is a good thing, and a good model should be met with scepticism. Doubly so if the model is a first attempt.

*Data leakage* is a situation in which data from the test set influences the training set, and so the model gets a peak into the test data that it shouldn't have. It can lead to *overfitting*, and it's sometimes extraordinarily difficult to detect.

Do you remember when you trained your first stock market model and got 99% accuracy? You imagined your life on your private island? And then you realised (or someone told you) that you needed to split your data into into two time periods so that the model couldn't see the future? That was data leakage causing over-fitting. There's no judgment from me here --- everyone has made this mistake, and most of us (myself included) continue to do so.

There are no time columns in my data; the source of the data leakage is more subtle than that. Pokémon belong to *families*. Charmander, upon reaching certain conditions, permanently changes into Charmeleon through a process known as *evolution*. Charmeleon eventually becomes Charizard. All three of these Pokémon belong to the "Charmander" family. It's reasonable to assume that the relationship between stats is similar for Pokémon in the same family.

Is my model learning that certain stat values are associated with certain types? Or is it learning to identify which Pokémon belong to which family, and then assuming that they all have the same type? That might be a fine model, but it detracts from my hypothesis.

### Finding new data:

My model doesn't contain information on Pokémon families. This is very common part of data science --- thinking I have all the data but then needing to find more. I used [the table from the Pokémon fandom wiki](https://pokemon.fandom.com/wiki/List_of_Pok%C3%A9mon_by_evolution) to associate a "family" with each Pokémon. The logic for these joins and some other minor corrections is stored [as a gist](https://gist.github.com/mdneuzerling/78a955dfa37087b90b6094911c9d03d5). The result is a CSV named "pokemon_with_families.csv".

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>pokemon</span> <span class='o'>&lt;-</span> <span class='nf'>readr</span><span class='nf'>::</span><span class='nf'><a href='https://readr.tidyverse.org/reference/read_delim.html'>read_csv</a></span><span class='o'>(</span><span class='s'>"data/pokemon_with_families.csv"</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'>janitor</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/janitor/man/clean_names.html'>clean_names</a></span><span class='o'>(</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'><a href='https://dplyr.tidyverse.org/reference/mutate.html'>mutate</a></span><span class='o'>(</span>
    type1 <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/factor.html'>as.factor</a></span><span class='o'>(</span><span class='nv'>type1</span><span class='o'>)</span>,
    type2 <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/factor.html'>as.factor</a></span><span class='o'>(</span><span class='nv'>type2</span><span class='o'>)</span>,
    legendary <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/logical.html'>as.logical</a></span><span class='o'>(</span><span class='nv'>legendary</span><span class='o'>)</span>
  <span class='o'>)</span>
<span class='c'>#&gt; <span style='font-weight: bold;'>Rows: </span><span style='color: #0000BB;'>1041</span> <span style='font-weight: bold;'>Columns: </span><span style='color: #0000BB;'>14</span></span>
<span class='c'>#&gt; <span style='color: #00BBBB;'>──</span> <span style='font-weight: bold;'>Column specification</span> <span style='color: #00BBBB;'>────────────────────────────────────────────────────────</span></span>
<span class='c'>#&gt; <span style='font-weight: bold;'>Delimiter:</span> ","</span>
<span class='c'>#&gt; <span style='color: #BB0000;'>chr</span> (5): name, type1, type2, family, color</span>
<span class='c'>#&gt; <span style='color: #00BB00;'>dbl</span> (8): number, hp, atk, def, sp_atk, sp_def, spd, total</span>
<span class='c'>#&gt; <span style='color: #BBBB00;'>lgl</span> (1): legendary</span>
<span class='c'>#&gt; </span>
<span class='c'>#&gt; <span style='color: #00BBBB;'>ℹ</span> Use <span style='color: #000000; background-color: #BBBBBB;'>`spec()`</span> to retrieve the full column specification for this data.</span>
<span class='c'>#&gt; <span style='color: #00BBBB;'>ℹ</span> Specify the column types or set <span style='color: #000000; background-color: #BBBBBB;'>`show_col_types = FALSE`</span> to quiet this message.</span></code></pre>

</div>

### Grouped train-test split

I'll re-split the data, this time ensuring that if a Pokémon from a given family is in `pokemon_train`, then *all* Pokémon in that family are in `pokemon_train`, and similarly for `pokemon_test`:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'><a href='https://rdrr.io/r/base/Random.html'>set.seed</a></span><span class='o'>(</span><span class='m'>12345</span><span class='o'>)</span>

<span class='nv'>train_families</span> <span class='o'>&lt;-</span> <span class='nv'>pokemon</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> <span class='nf'><a href='https://dplyr.tidyverse.org/reference/distinct.html'>distinct</a></span><span class='o'>(</span><span class='nv'>family</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'><a href='https://dplyr.tidyverse.org/reference/sample_n.html'>sample_frac</a></span><span class='o'>(</span><span class='m'>0.7</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> <span class='nf'><a href='https://dplyr.tidyverse.org/reference/pull.html'>pull</a></span><span class='o'>(</span><span class='nv'>family</span><span class='o'>)</span>

<span class='nv'>pokemon_train</span> <span class='o'>&lt;-</span> <span class='nv'>pokemon</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> <span class='nf'><a href='https://dplyr.tidyverse.org/reference/filter.html'>filter</a></span><span class='o'>(</span><span class='nv'>family</span> <span class='o'><a href='https://rdrr.io/r/base/match.html'>%in%</a></span> <span class='nv'>train_families</span><span class='o'>)</span>
<span class='nv'>pokemon_test</span> <span class='o'>&lt;-</span> <span class='nv'>pokemon</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> <span class='nf'><a href='https://dplyr.tidyverse.org/reference/filter.html'>filter</a></span><span class='o'>(</span><span class='o'>!</span><span class='o'>(</span><span class='nv'>family</span> <span class='o'><a href='https://rdrr.io/r/base/match.html'>%in%</a></span> <span class='nv'>train_families</span><span class='o'>)</span><span class='o'>)</span></code></pre>

</div>

This is a new training data set, so I have a new no-information rate:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'>no_information_rate</span><span class='o'>(</span><span class='nv'>pokemon_train</span><span class='o'>)</span>
<span class='c'>#&gt; [1] 0.14361</span></code></pre>

</div>

I'll try re-fitting the model on this newly split data:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>fitted_pokemon_model</span> <span class='o'>&lt;-</span> <span class='nv'>pokemon_model</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> <span class='nf'>fit</span><span class='o'>(</span>
  <span class='nv'>type1</span> <span class='o'>~</span> <span class='nv'>hp</span> <span class='o'>+</span> <span class='nv'>atk</span> <span class='o'>+</span> <span class='nv'>def</span> <span class='o'>+</span> <span class='nv'>sp_atk</span> <span class='o'>+</span> <span class='nv'>sp_def</span> <span class='o'>+</span> <span class='nv'>spd</span>,
  data <span class='o'>=</span> <span class='nv'>pokemon_train</span>
<span class='o'>)</span>

<span class='nv'>second_attempt_accuracy</span> <span class='o'>&lt;-</span> <span class='nv'>pokemon_test</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'><a href='https://dplyr.tidyverse.org/reference/mutate.html'>mutate</a></span><span class='o'>(</span>
    predicted_type1 <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/stats/predict.html'>predict</a></span><span class='o'>(</span>
      <span class='nv'>fitted_pokemon_model</span>,
      <span class='nv'>pokemon_test</span>
    <span class='o'>)</span><span class='o'>$</span><span class='nv'>.pred_class</span>
  <span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span>
  <span class='nf'>accuracy</span><span class='o'>(</span><span class='nv'>type1</span>, <span class='nv'>predicted_type1</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'><a href='https://dplyr.tidyverse.org/reference/pull.html'>pull</a></span><span class='o'>(</span><span class='nv'>.estimate</span><span class='o'>)</span>

<span class='nv'>second_attempt_accuracy</span>
<span class='c'>#&gt; [1] 0.141844</span></code></pre>

</div>

14.2% is not so impressive when the no-information rate is 14.4%. Data leakage can make a huge difference!

## A little bit of feature engineering

Feature engineering is the process of refining existing features or creating new ones to improve the accuracy of a model. Informally, it lets models use features the way a human being might see them.

I know that some Pokémon types are stronger than others. For example, Dragon Pokémon tend to be stronger than bug Pokémon. I can see that in the comparison of their `atk` and `sp_atk` below:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>plot_dragon_bug</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>pokemon_data</span><span class='o'>)</span> <span class='o'>&#123;</span>
  <span class='nv'>pokemon_data</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'><a href='https://dplyr.tidyverse.org/reference/filter.html'>filter</a></span><span class='o'>(</span>
    <span class='nv'>type1</span> <span class='o'><a href='https://rdrr.io/r/base/match.html'>%in%</a></span> <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='o'>(</span>
      <span class='s'>"Bug"</span>, <span class='s'>"Dragon"</span>
    <span class='o'>)</span>
  <span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'><a href='https://ggplot2.tidyverse.org/reference/ggplot.html'>ggplot</a></span><span class='o'>(</span><span class='nf'><a href='https://ggplot2.tidyverse.org/reference/aes.html'>aes</a></span><span class='o'>(</span>
      x <span class='o'>=</span> <span class='nv'>atk</span>,
      y <span class='o'>=</span> <span class='nv'>sp_atk</span>,
      color <span class='o'>=</span> <span class='nv'>type1</span>
  <span class='o'>)</span><span class='o'>)</span> <span class='o'>+</span>
  <span class='nf'><a href='https://ggplot2.tidyverse.org/reference/geom_point.html'>geom_point</a></span><span class='o'>(</span>size <span class='o'>=</span> <span class='m'>2</span><span class='o'>)</span> <span class='o'>+</span> 
  <span class='nf'><a href='https://ggplot2.tidyverse.org/reference/scale_manual.html'>scale_color_manual</a></span><span class='o'>(</span>
    values <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='o'>(</span>
      <span class='s'>"Dragon"</span> <span class='o'>=</span> <span class='s'>"#C77CFF"</span>,
      <span class='s'>"Bug"</span> <span class='o'>=</span> <span class='s'>"#7CAE00"</span>
    <span class='o'>)</span>
  <span class='o'>)</span>
<span class='o'>&#125;</span>

<span class='nv'>pokemon</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> <span class='nf'>plot_dragon_bug</span><span class='o'>(</span><span class='o'>)</span>
</code></pre>
<img src="figs/plot-before-scaling-1.png" width="700px" style="display: block; margin: auto;" />

</div>

It's possible that rather than considering absolute stats I need to consider *proportional* stats. That is, the proportion of attack, speed, etc. relative to a Pokémon's total stats. If this helps to separate the types I might be able to see that separation in a plot:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>pokemon_train</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span>
  <span class='nf'><a href='https://dplyr.tidyverse.org/reference/mutate.html'>mutate</a></span><span class='o'>(</span><span class='nf'><a href='https://dplyr.tidyverse.org/reference/across.html'>across</a></span><span class='o'>(</span><span class='nv'>hp</span><span class='o'>:</span><span class='nv'>spd</span>, <span class='kr'>function</span><span class='o'>(</span><span class='nv'>x</span><span class='o'>)</span> <span class='nv'>x</span> <span class='o'>/</span> <span class='nv'>total</span><span class='o'>)</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span>
  <span class='nf'>plot_dragon_bug</span><span class='o'>(</span><span class='o'>)</span>
</code></pre>
<img src="figs/plot-after-scaling-1.png" width="700px" style="display: block; margin: auto;" />

</div>

It's not a very convincing change. If a difference is there, it's a minor one. Still, I think it's enough to proceed with another attempt a model.

I need to introduce a preprocessing *recipe* using the `recipes` package, part of the `tidymodels` universe. This recipe tells R how to manipulate my data before modelling. Recipes are prepared based on the training data and applied to the test data to prevent data leakage that might occur from steps such as imputation and normalisation.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>preprocessing</span> <span class='o'>&lt;-</span> <span class='nf'>recipe</span><span class='o'>(</span>
  <span class='nv'>type1</span> <span class='o'>~</span> <span class='nv'>hp</span> <span class='o'>+</span> <span class='nv'>atk</span> <span class='o'>+</span> <span class='nv'>def</span> <span class='o'>+</span> <span class='nv'>sp_atk</span> <span class='o'>+</span> <span class='nv'>sp_def</span> <span class='o'>+</span> <span class='nv'>spd</span> <span class='o'>+</span> <span class='nv'>total</span>,
  data <span class='o'>=</span> <span class='nv'>pokemon_train</span>
<span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span>
  <span class='nf'>step_mutate</span><span class='o'>(</span>
    hp <span class='o'>=</span> <span class='nv'>hp</span> <span class='o'>/</span> <span class='nv'>total</span>,
    atk <span class='o'>=</span> <span class='nv'>atk</span> <span class='o'>/</span> <span class='nv'>total</span>,
    def <span class='o'>=</span> <span class='nv'>def</span> <span class='o'>/</span> <span class='nv'>total</span>,
    sp_atk <span class='o'>=</span> <span class='nv'>sp_atk</span> <span class='o'>/</span> <span class='nv'>total</span>,
    sp_def <span class='o'>=</span> <span class='nv'>sp_def</span> <span class='o'>/</span> <span class='nv'>total</span>,
    spd <span class='o'>=</span> <span class='nv'>spd</span> <span class='o'>/</span> <span class='nv'>total</span>
  <span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'>step_normalize</span><span class='o'>(</span><span class='nv'>total</span><span class='o'>)</span></code></pre>

</div>

The last step, which scales and centres the data, isn't strictly necessary for tree-based models. It may, however, make it easier to interpret stats.

In `tidymodels`, a `workflow` is a combination of a model and a recipe. It lets me combine my preprocessing and modelling steps into a single object that can be fit in one step.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>pokemon_workflow</span> <span class='o'>&lt;-</span> <span class='nf'>workflow</span><span class='o'>(</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span>
  <span class='nf'>add_recipe</span><span class='o'>(</span><span class='nv'>preprocessing</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'>add_model</span><span class='o'>(</span><span class='nv'>pokemon_model</span><span class='o'>)</span></code></pre>

</div>

I can now see if this extra bit of feature engineering will pay off:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>fitted_pokemon_workflow</span> <span class='o'>&lt;-</span> <span class='nv'>pokemon_workflow</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> <span class='nf'>fit</span><span class='o'>(</span><span class='nv'>pokemon_train</span><span class='o'>)</span>

<span class='nv'>third_attempt_accuracy</span> <span class='o'>&lt;-</span> <span class='nv'>pokemon_test</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'><a href='https://dplyr.tidyverse.org/reference/mutate.html'>mutate</a></span><span class='o'>(</span>
    predicted_type1 <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/stats/predict.html'>predict</a></span><span class='o'>(</span>
      <span class='nv'>fitted_pokemon_workflow</span>,
      <span class='nv'>pokemon_test</span>
    <span class='o'>)</span><span class='o'>$</span><span class='nv'>.pred_class</span>
  <span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span>
  <span class='nf'>accuracy</span><span class='o'>(</span><span class='nv'>type1</span>, <span class='nv'>predicted_type1</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'><a href='https://dplyr.tidyverse.org/reference/pull.html'>pull</a></span><span class='o'>(</span><span class='nv'>.estimate</span><span class='o'>)</span>
<span class='nv'>third_attempt_accuracy</span>
<span class='c'>#&gt; [1] 0.1347518</span></code></pre>

</div>

That's an accuracy of 13.5% compared to a no-information rate is 14.4%. That's disappointing! It looks like this scaling didn't do anything.

## MORE DATA

At this point I'm willing to give up on my hypothesis. I don't think that stats alone are enough to predict type. It may be a valid hypothesis for a smaller group of types, like Fire and Fighting, but the relationship doesn't seem to be there for the whole data set.

Giving up on a hypothesis means getting to try new hypotheses. I want to try adding `color`. It shouldn't come as a surprise that Grass Pokémon are often green and Fire Pokémon are often red. I'll redefine my preprocessing recipe and workflow to include `color` (here given its unfortunate US spelling):

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>preprocessing</span> <span class='o'>&lt;-</span> <span class='nf'>recipe</span><span class='o'>(</span>
  <span class='nv'>type1</span> <span class='o'>~</span> <span class='nv'>hp</span> <span class='o'>+</span> <span class='nv'>atk</span> <span class='o'>+</span> <span class='nv'>def</span> <span class='o'>+</span> <span class='nv'>sp_atk</span> <span class='o'>+</span> <span class='nv'>sp_def</span> <span class='o'>+</span> <span class='nv'>spd</span> <span class='o'>+</span> <span class='nv'>total</span> <span class='o'>+</span> <span class='nv'>color</span>,
  data <span class='o'>=</span> <span class='nv'>pokemon_train</span>
<span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span>
  <span class='nf'>step_mutate</span><span class='o'>(</span>
    hp <span class='o'>=</span> <span class='nv'>hp</span> <span class='o'>/</span> <span class='nv'>total</span>,
    atk <span class='o'>=</span> <span class='nv'>atk</span> <span class='o'>/</span> <span class='nv'>total</span>,
    def <span class='o'>=</span> <span class='nv'>def</span> <span class='o'>/</span> <span class='nv'>total</span>,
    sp_atk <span class='o'>=</span> <span class='nv'>sp_atk</span> <span class='o'>/</span> <span class='nv'>total</span>,
    sp_def <span class='o'>=</span> <span class='nv'>sp_def</span> <span class='o'>/</span> <span class='nv'>total</span>,
    spd <span class='o'>=</span> <span class='nv'>spd</span> <span class='o'>/</span> <span class='nv'>total</span>
  <span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'>step_normalize</span><span class='o'>(</span><span class='nv'>total</span><span class='o'>)</span>

<span class='nv'>pokemon_workflow</span> <span class='o'>&lt;-</span> <span class='nf'>workflow</span><span class='o'>(</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span>
  <span class='nf'>add_recipe</span><span class='o'>(</span><span class='nv'>preprocessing</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'>add_model</span><span class='o'>(</span><span class='nv'>pokemon_model</span><span class='o'>)</span></code></pre>

</div>

Hopefully this information, along with stats, should be enough to learn something about Pokémon types.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>fitted_pokemon_workflow</span> <span class='o'>&lt;-</span> <span class='nv'>pokemon_workflow</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> <span class='nf'>fit</span><span class='o'>(</span><span class='nv'>pokemon_train</span><span class='o'>)</span>

<span class='nv'>fourth_attempt_accuracy</span> <span class='o'>&lt;-</span> <span class='nv'>pokemon_test</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'><a href='https://dplyr.tidyverse.org/reference/mutate.html'>mutate</a></span><span class='o'>(</span>
    predicted_type1 <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/stats/predict.html'>predict</a></span><span class='o'>(</span>
      <span class='nv'>fitted_pokemon_workflow</span>,
      <span class='nv'>pokemon_test</span>
    <span class='o'>)</span><span class='o'>$</span><span class='nv'>.pred_class</span>
  <span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span>
  <span class='nf'>accuracy</span><span class='o'>(</span><span class='nv'>type1</span>, <span class='nv'>predicted_type1</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'><a href='https://dplyr.tidyverse.org/reference/pull.html'>pull</a></span><span class='o'>(</span><span class='nv'>.estimate</span><span class='o'>)</span></code></pre>

</div>

That's an accuracy of 23.8% compared to a no-information rate is 14.4%. Finally, a result that isn't terrible!

## Dig into the results and ask questions

I've made another mistake: I've reduced my model performance to a single metric. It's much more complicated than that. I need to gather some intuition about how my model performs, and a confusion matrix is a good visualisation for that:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>pokemon_test</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'><a href='https://dplyr.tidyverse.org/reference/mutate.html'>mutate</a></span><span class='o'>(</span>
    predicted <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/stats/predict.html'>predict</a></span><span class='o'>(</span>
      <span class='nv'>fitted_pokemon_workflow</span>,
      <span class='nv'>pokemon_test</span>
      <span class='o'>)</span><span class='o'>$</span><span class='nv'>.pred_class</span>
  <span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'>conf_mat</span><span class='o'>(</span><span class='nv'>type1</span>, <span class='nv'>predicted</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'><a href='https://ggplot2.tidyverse.org/reference/autoplot.html'>autoplot</a></span><span class='o'>(</span>type <span class='o'>=</span> <span class='s'>"heatmap"</span><span class='o'>)</span> <span class='o'>+</span> 
  <span class='nf'><a href='https://ggplot2.tidyverse.org/reference/theme.html'>theme</a></span><span class='o'>(</span>
    axis.text.x <span class='o'>=</span> <span class='nf'><a href='https://ggplot2.tidyverse.org/reference/element.html'>element_text</a></span><span class='o'>(</span>
      angle <span class='o'>=</span> <span class='m'>90</span>,
      vjust <span class='o'>=</span> <span class='m'>0.5</span>,
      hjust <span class='o'>=</span> <span class='m'>1</span>
    <span class='o'>)</span>
  <span class='o'>)</span>
</code></pre>
<img src="figs/confusion-matrix-1.png" width="700px" style="display: block; margin: auto;" />

</div>

What I want to see is a lot of dark squares along the diagonal. The diagonal squares are the *correct* predictions, with everything else a misprediction.

The model seems to have learnt something about bug and psychic proble, so it's not completely terrible. It's making a lot of mistakes around Water and Normal Pokémon. These are the most common types, so it makes sense that the model would bias them and then get it wrong.

I can also see that some types are rare. For example, there are no Flying Pokémon in the test data! This is because many Flying Pokémon actually have Flying as their *secondary* type, and so there are very few example of *primary* Flying Pokémon.

## Modelling strategy

What I've created here isn't a useful model, because we already know the types of all the Pokémon. What I've outlined is a *process* for training a model. That process is:

1.  work out what you're trying to answer
2.  look at your data
3.  define a metric
4.  decide what makes a model good enough
5.  split your data --- watch out for data leakage!
6.  get more data if you need it
7.  train and evaluate --- including visualisations!

And above all, recognise that data science is an iterative process in which success can only come after a long, disappointing chain of failures.

## Bonus: `vetiver`, a new approach for deploying R models

[Julia Silge](https://juliasilge.com/) of the [tidymodels](https://www.tidymodels.org/) team recently announced a new package for model deployment in R: [`vetiver`](https://vetiver.tidymodels.org). I have a model here and it's already a `tidymodels` workflow, so I thought this would be a good chance to quickly explore `vetiver`.

I'm going to need three more packages here: `vetiver` itself, the `pins` package for storing model artefacts, and `plumber` for hosting models as an API.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='kr'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='o'>(</span><span class='nv'><a href='https://vetiver.tidymodels.org/'>vetiver</a></span><span class='o'>)</span>
<span class='kr'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='o'>(</span><span class='nv'><a href='https://pins.rstudio.com/'>pins</a></span><span class='o'>)</span>
<span class='kr'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='o'>(</span><span class='nv'><a href='https://www.rplumber.io'>plumber</a></span><span class='o'>)</span></code></pre>

</div>

I've already got a workflow, so it's straightforward to turn it into a `vetiver` model:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>v</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://vetiver.tidymodels.org/reference/vetiver_model.html'>vetiver_model</a></span><span class='o'>(</span><span class='nv'>fitted_pokemon_workflow</span>, <span class='s'>"pokemon_rf"</span><span class='o'>)</span>
<span class='nv'>v</span>
<span class='c'>#&gt; </span>
<span class='c'>#&gt; ── <span style='font-style: italic;'>pokemon_rf</span> ─ <span style='color: #0000BB;'>&lt;butchered_workflow&gt;</span> model for deployment </span>
<span class='c'>#&gt; A ranger classification modeling workflow using 8 features</span></code></pre>

</div>

I'm going to host the model in a separate R process so that it can serve predictions to data in my current R process. For that I'll need somewhere to save the model so that I can access it between separate R processes. The local board from the `pins` package is suitable. This is a storage location that's local to my computer. If I wanted to save the model artefact to a particular location I would use `board_folder` instead, but in this case I don't care where the model is saved.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'><a href='https://pins.rstudio.com/reference/board_folder.html'>board_local</a></span><span class='o'>(</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> <span class='nf'><a href='https://vetiver.tidymodels.org/reference/vetiver_pin_write.html'>vetiver_pin_write</a></span><span class='o'>(</span><span class='nv'>v</span><span class='o'>)</span>
<span class='c'>#&gt; Creating new version '20220124T201636Z-f3f19'</span>
<span class='c'>#&gt; Writing to pin 'pokemon_rf'</span>
<span class='c'>#&gt; </span>
<span class='c'>#&gt; Create a Model Card for your published model</span>
<span class='c'>#&gt; * Model Cards provide a framework for transparent, responsible reporting</span>
<span class='c'>#&gt; * Use the vetiver `.Rmd` template as a place to start</span>
<span class='c'>#&gt; <span style='color: #555555;'>This message is displayed once per session.</span></span></code></pre>

</div>

I create the `start_plumber` function that loads the necessary packages and the model artefact, and starts serving it as an API using the `plumber` package. A heads up here that I'm being quite eager to load massive metapackages like `tidyverse` and `tidymodels`. This is generally a bad idea in production situations. If I were doing this "for real" I would want my start-up to be as lean as possible, so I would only load the bare minimum packages I need.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>start_plumber</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='o'>)</span> <span class='o'>&#123;</span>
  <span class='kr'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='o'>(</span><span class='nv'><a href='https://tidyverse.tidyverse.org'>tidyverse</a></span><span class='o'>)</span>
  <span class='kr'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='o'>(</span><span class='nv'><a href='https://tidymodels.tidymodels.org'>tidymodels</a></span><span class='o'>)</span>
  <span class='kr'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='o'>(</span><span class='nv'><a href='https://vetiver.tidymodels.org/'>vetiver</a></span><span class='o'>)</span>
  <span class='kr'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='o'>(</span><span class='nv'><a href='https://pins.rstudio.com/'>pins</a></span><span class='o'>)</span>
  <span class='kr'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='o'>(</span><span class='nv'><a href='https://www.rplumber.io'>plumber</a></span><span class='o'>)</span>
    
  <span class='nv'>v</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://vetiver.tidymodels.org/reference/vetiver_pin_write.html'>vetiver_pin_read</a></span><span class='o'>(</span><span class='nf'><a href='https://pins.rstudio.com/reference/board_folder.html'>board_local</a></span><span class='o'>(</span><span class='o'>)</span>, <span class='s'>"pokemon_rf"</span><span class='o'>)</span>
    
  <span class='nf'><a href='https://www.rplumber.io/reference/pr.html'>pr</a></span><span class='o'>(</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> <span class='nf'><a href='https://vetiver.tidymodels.org/reference/vetiver_pr_predict.html'>vetiver_pr_predict</a></span><span class='o'>(</span><span class='nv'>v</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> <span class='nf'><a href='https://www.rplumber.io/reference/pr_run.html'>pr_run</a></span><span class='o'>(</span>port <span class='o'>=</span> <span class='m'>8088</span><span class='o'>)</span>
<span class='o'>&#125;</span></code></pre>

</div>

Look at how straightforward it is to host a model with `vetiver` and `plumber`! I can actually take my model and start hosting a prediction endpoint in a single line of code. That's wonderful.

Now I need to serve the API. I'm going to use the `callr` package to create an R process in the background that will call this function and start waiting for invocations. This R process will exist until it either errors or I kill it.

<!-- For some reason, this doesn't work in R Markdown, but it works in RStudio. I don't want to troubleshoot this, so I'm going to fudge the cell outputs. -->

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>plumber_process</span> <span class='o'>&lt;-</span> <span class='nf'>callr</span><span class='nf'>::</span><span class='nf'><a href='https://callr.r-lib.org/reference/r_bg.html'>r_bg</a></span><span class='o'>(</span><span class='nv'>start_plumber</span><span class='o'>)</span></code></pre>

</div>

From within R I can use `vetiver_endpoint` to create an object that can be used with the `predict` generic, as if the endpoint were a model itself.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>endpoint</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://vetiver.tidymodels.org/reference/vetiver_endpoint.html'>vetiver_endpoint</a></span><span class='o'>(</span><span class='s'>"http://127.0.0.1:8088/predict"</span><span class='o'>)</span>
<span class='nv'>pokemon_test</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'><a href='https://rdrr.io/r/utils/head.html'>head</a></span><span class='o'>(</span><span class='m'>5</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'><a href='https://rdrr.io/r/stats/predict.html'>predict</a></span><span class='o'>(</span><span class='nv'>endpoint</span>, <span class='nv'>.</span><span class='o'>)</span>
<span class='c'>#&gt; # A tibble: 5 × 1</span>
<span class='c'>#&gt;   .pred_class</span>
<span class='c'>#&gt;   &lt;chr&gt;      </span>
<span class='c'>#&gt; 1 Bug        </span>
<span class='c'>#&gt; 2 Bug        </span>
<span class='c'>#&gt; 3 Psychic    </span>
<span class='c'>#&gt; 4 Bug        </span>
<span class='c'>#&gt; 5 Bug  </span></code></pre>

</div>

Of course, I can also query this endpoint outside of R. Here I'm going to use the `jsonlite` package to convert the first 5 rows of `pokemon_test` into a JSON, and the `httr` package to `POST` that JSON to the prediction endpoint. I'll then convert the JSON back into a tibble (data frame).

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>response</span> <span class='o'>&lt;-</span> <span class='nf'>httr</span><span class='nf'>::</span><span class='nf'><a href='https://httr.r-lib.org/reference/POST.html'>POST</a></span><span class='o'>(</span>
    <span class='s'>"http://127.0.0.1:8088/predict"</span>,
    body <span class='o'>=</span> <span class='nv'>pokemon_test</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> <span class='nf'><a href='https://rdrr.io/r/utils/head.html'>head</a></span><span class='o'>(</span><span class='m'>5</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> <span class='nf'>jsonlite</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/jsonlite/man/fromJSON.html'>toJSON</a></span><span class='o'>(</span><span class='o'>)</span>
<span class='o'>)</span>
<span class='nf'>httr</span><span class='nf'>::</span><span class='nf'><a href='https://httr.r-lib.org/reference/content.html'>content</a></span><span class='o'>(</span><span class='nv'>response</span>, as <span class='o'>=</span> <span class='s'>"text"</span>, encoding <span class='o'>=</span> <span class='s'>"UTF-8"</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span>
    <span class='nf'>jsonlite</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/jsonlite/man/fromJSON.html'>fromJSON</a></span><span class='o'>(</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
    <span class='nf'><a href='https://tibble.tidyverse.org/reference/as_tibble.html'>as_tibble</a></span><span class='o'>(</span><span class='o'>)</span>
<span class='c'>#&gt; # A tibble: 5 × 1</span>
<span class='c'>#&gt;   .pred_class</span>
<span class='c'>#&gt;   &lt;chr&gt;      </span>
<span class='c'>#&gt; 1 Bug        </span>
<span class='c'>#&gt; 2 Bug        </span>
<span class='c'>#&gt; 3 Psychic    </span>
<span class='c'>#&gt; 4 Bug        </span>
<span class='c'>#&gt; 5 Bug  </span></code></pre>

</div>

I could have submitted that `POST` request from anywhere on my local machine. I could query my API from a Python kernel running in Jupyter, or from the terminal.

As a clean-up step, I need to kill that Plumber process:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>plumber_process</span><span class='o'>$</span><span class='nf'>kill</span><span class='o'>(</span><span class='o'>)</span></code></pre>

</div>

I've only scratched the surface here but so far it looks like `vetiver` is a wonderful package. It accomplishes so much with an extraordinarily simple API. Thank you to Julia and the `tidymodels` team for their contribution to the R MLOps ecosystem!

------------------------------------------------------------------------

[The image at the top of this page is by George Becker](https://www.pexels.com/photo/1-1-3-text-on-black-chalkboard-374918/) and is used under the terms of [the Pexels License](https://www.pexels.com/license/).

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'>devtools</span><span class='nf'>::</span><span class='nf'><a href='https://r-lib.github.io/sessioninfo/reference/session_info.html'>session_info</a></span><span class='o'>(</span><span class='o'>)</span>
<span class='c'>#&gt; <span style='color: #00BBBB; font-weight: bold;'>─ Session info ───────────────────────────────────────────────────────────────</span></span>
<span class='c'>#&gt;  <span style='color: #555555; font-style: italic;'>setting </span> <span style='color: #555555; font-style: italic;'>value</span></span>
<span class='c'>#&gt;  version  R version 4.1.0 (2021-05-18)</span>
<span class='c'>#&gt;  os       macOS Big Sur 11.3</span>
<span class='c'>#&gt;  system   aarch64, darwin20</span>
<span class='c'>#&gt;  ui       X11</span>
<span class='c'>#&gt;  language (EN)</span>
<span class='c'>#&gt;  collate  en_AU.UTF-8</span>
<span class='c'>#&gt;  ctype    en_AU.UTF-8</span>
<span class='c'>#&gt;  tz       Australia/Melbourne</span>
<span class='c'>#&gt;  date     2022-01-25</span>
<span class='c'>#&gt;  pandoc   2.11.4 @ /Applications/RStudio.app/Contents/MacOS/pandoc/ (via rmarkdown)</span>
<span class='c'>#&gt; </span>
<span class='c'>#&gt; <span style='color: #00BBBB; font-weight: bold;'>─ Packages ───────────────────────────────────────────────────────────────────</span></span>
<span class='c'>#&gt;  <span style='color: #555555; font-style: italic;'>package     </span> <span style='color: #555555; font-style: italic;'>*</span> <span style='color: #555555; font-style: italic;'>version   </span> <span style='color: #555555; font-style: italic;'>date (UTC)</span> <span style='color: #555555; font-style: italic;'>lib</span> <span style='color: #555555; font-style: italic;'>source</span></span>
<span class='c'>#&gt;  assertthat     0.2.1      <span style='color: #555555;'>2019-03-21</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  backports      1.4.1      <span style='color: #555555;'>2021-12-13</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  bit            4.0.4      <span style='color: #555555;'>2020-08-04</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  bit64          4.0.5      <span style='color: #555555;'>2020-08-30</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  brio           1.1.3      <span style='color: #555555;'>2021-11-30</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  broom        * 0.7.11     <span style='color: #555555;'>2022-01-03</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  butcher        0.1.5      <span style='color: #555555;'>2021-06-28</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  cachem         1.0.6      <span style='color: #555555;'>2021-08-19</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  callr          3.7.0      <span style='color: #555555;'>2021-04-20</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  cellranger     1.1.0      <span style='color: #555555;'>2016-07-27</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  class          7.3-20     <span style='color: #555555;'>2022-01-13</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  cli            3.1.1      <span style='color: #555555;'>2022-01-20</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  codetools      0.2-18     <span style='color: #555555;'>2020-11-04</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  colorspace     2.0-2      <span style='color: #555555;'>2021-06-24</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  crayon         1.4.2      <span style='color: #555555;'>2021-10-29</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  DBI            1.1.2      <span style='color: #555555;'>2021-12-20</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  dbplyr         2.1.1      <span style='color: #555555;'>2021-04-06</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  desc           1.4.0      <span style='color: #555555;'>2021-09-28</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  devtools       2.4.3      <span style='color: #555555;'>2021-11-30</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  dials        * 0.0.10     <span style='color: #555555;'>2021-09-10</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  DiceDesign     1.9        <span style='color: #555555;'>2021-02-13</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  digest         0.6.29     <span style='color: #555555;'>2021-12-01</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  downlit        0.4.0      <span style='color: #555555;'>2021-10-29</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  dplyr        * 1.0.7      <span style='color: #555555;'>2021-06-18</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  ellipsis       0.3.2      <span style='color: #555555;'>2021-04-29</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  evaluate       0.14       <span style='color: #555555;'>2019-05-28</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  fansi          1.0.2      <span style='color: #555555;'>2022-01-14</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  farver         2.1.0      <span style='color: #555555;'>2021-02-28</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  fastmap        1.1.0      <span style='color: #555555;'>2021-01-25</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  forcats      * 0.5.1      <span style='color: #555555;'>2021-01-27</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  foreach        1.5.1      <span style='color: #555555;'>2020-10-15</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  fs             1.5.2      <span style='color: #555555;'>2021-12-08</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  furrr          0.2.3      <span style='color: #555555;'>2021-06-25</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  future         1.23.0     <span style='color: #555555;'>2021-10-31</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  future.apply   1.8.1      <span style='color: #555555;'>2021-08-10</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  generics       0.1.1      <span style='color: #555555;'>2021-10-25</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  ggplot2      * 3.3.5      <span style='color: #555555;'>2021-06-25</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  globals        0.14.0     <span style='color: #555555;'>2020-11-22</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  glue           1.6.1      <span style='color: #555555;'>2022-01-22</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  gower          0.2.2      <span style='color: #555555;'>2020-06-23</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  GPfit          1.0-8      <span style='color: #555555;'>2019-02-08</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  gtable         0.3.0      <span style='color: #555555;'>2019-03-25</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  hardhat        0.1.6      <span style='color: #555555;'>2021-07-14</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  haven          2.4.3      <span style='color: #555555;'>2021-08-04</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  highr          0.9        <span style='color: #555555;'>2021-04-16</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  hms            1.1.1      <span style='color: #555555;'>2021-09-26</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  htmltools      0.5.2      <span style='color: #555555;'>2021-08-25</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  httr           1.4.2      <span style='color: #555555;'>2020-07-20</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  hugodown       <span style='color: #BB00BB; font-weight: bold;'>0.0.0.9000</span> <span style='color: #555555;'>2021-09-18</span> <span style='color: #555555;'>[1]</span> <span style='color: #BB00BB; font-weight: bold;'>Github (r-lib/hugodown@168a361)</span></span>
<span class='c'>#&gt;  infer        * 1.0.0      <span style='color: #555555;'>2021-08-13</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  ipred          0.9-12     <span style='color: #555555;'>2021-09-15</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  iterators      1.0.13     <span style='color: #555555;'>2020-10-15</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  janitor        2.1.0      <span style='color: #555555;'>2021-01-05</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  jsonlite       1.7.3      <span style='color: #555555;'>2022-01-17</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  knitr          1.37       <span style='color: #555555;'>2021-12-16</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  labeling       0.4.2      <span style='color: #555555;'>2020-10-20</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  later          1.3.0      <span style='color: #555555;'>2021-08-18</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  lattice        0.20-45    <span style='color: #555555;'>2021-09-22</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  lava           1.6.10     <span style='color: #555555;'>2021-09-02</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  lhs            1.1.3      <span style='color: #555555;'>2021-09-08</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  lifecycle      1.0.1      <span style='color: #555555;'>2021-09-24</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  listenv        0.8.0      <span style='color: #555555;'>2019-12-05</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  lubridate      1.8.0      <span style='color: #555555;'>2021-10-07</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  magrittr       2.0.1      <span style='color: #555555;'>2020-11-17</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  MASS           7.3-55     <span style='color: #555555;'>2022-01-13</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  Matrix         1.4-0      <span style='color: #555555;'>2021-12-08</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  memoise        2.0.1      <span style='color: #555555;'>2021-11-26</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  modeldata    * 0.1.1      <span style='color: #555555;'>2021-07-14</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  modelr         0.1.8      <span style='color: #555555;'>2020-05-19</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  munsell        0.5.0      <span style='color: #555555;'>2018-06-12</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  nnet           7.3-17     <span style='color: #555555;'>2022-01-13</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  parallelly     1.30.0     <span style='color: #555555;'>2021-12-17</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  parsnip      * <span style='color: #BB00BB; font-weight: bold;'>0.1.7.9000</span> <span style='color: #555555;'>2021-10-11</span> <span style='color: #555555;'>[1]</span> <span style='color: #BB00BB; font-weight: bold;'>Github (tidymodels/parsnip@d1451da)</span></span>
<span class='c'>#&gt;  pillar         1.6.4      <span style='color: #555555;'>2021-10-18</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  pins         * 1.0.1      <span style='color: #555555;'>2021-12-15</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  pkgbuild       1.3.1      <span style='color: #555555;'>2021-12-20</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  pkgconfig      2.0.3      <span style='color: #555555;'>2019-09-22</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  pkgload        1.2.4      <span style='color: #555555;'>2021-11-30</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  plumber      * 1.1.0      <span style='color: #555555;'>2021-03-24</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  plyr           1.8.6      <span style='color: #555555;'>2020-03-03</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  prettyunits    1.1.1      <span style='color: #555555;'>2020-01-24</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  pROC           1.18.0     <span style='color: #555555;'>2021-09-03</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  processx       3.5.2      <span style='color: #555555;'>2021-04-30</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  prodlim        <span style='color: #BB00BB; font-weight: bold;'>2019.11.13</span> <span style='color: #555555;'>2019-11-17</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  promises       1.2.0.1    <span style='color: #555555;'>2021-02-11</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  ps             1.6.0      <span style='color: #555555;'>2021-02-28</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  purrr        * 0.3.4      <span style='color: #555555;'>2020-04-17</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  R6             2.5.1      <span style='color: #555555;'>2021-08-19</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  ranger         0.13.1     <span style='color: #555555;'>2021-07-14</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  rappdirs       0.3.3      <span style='color: #555555;'>2021-01-31</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  Rcpp           1.0.8      <span style='color: #555555;'>2022-01-13</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  readr        * 2.1.1      <span style='color: #555555;'>2021-11-30</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  readxl         1.3.1      <span style='color: #555555;'>2019-03-13</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  recipes      * 0.1.17     <span style='color: #555555;'>2021-09-27</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  remotes        2.4.2      <span style='color: #555555;'>2021-11-30</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  reprex         2.0.1      <span style='color: #555555;'>2021-08-05</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  rlang          0.4.12     <span style='color: #555555;'>2021-10-18</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  rmarkdown      2.11       <span style='color: #555555;'>2021-09-14</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  rpart          4.1-15     <span style='color: #555555;'>2019-04-12</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  rprojroot      2.0.2      <span style='color: #555555;'>2020-11-15</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  rsample      * 0.1.1      <span style='color: #555555;'>2021-11-08</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  rstudioapi     0.13       <span style='color: #555555;'>2020-11-12</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  rvest          1.0.2      <span style='color: #555555;'>2021-10-16</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  scales       * 1.1.1      <span style='color: #555555;'>2020-05-11</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  sessioninfo    1.2.2      <span style='color: #555555;'>2021-12-06</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  snakecase      0.11.0     <span style='color: #555555;'>2019-05-25</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  stringi        1.7.6      <span style='color: #555555;'>2021-11-29</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  stringr      * 1.4.0      <span style='color: #555555;'>2019-02-10</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  survival       3.2-13     <span style='color: #555555;'>2021-08-24</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  swagger        3.33.1     <span style='color: #555555;'>2020-10-02</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  testthat       3.1.2      <span style='color: #555555;'>2022-01-20</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  tibble       * 3.1.6      <span style='color: #555555;'>2021-11-07</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  tidymodels   * 0.1.4      <span style='color: #555555;'>2021-10-01</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  tidyr        * 1.1.4      <span style='color: #555555;'>2021-09-27</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  tidyselect     1.1.1      <span style='color: #555555;'>2021-04-30</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  tidyverse    * 1.3.1      <span style='color: #555555;'>2021-04-15</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  timeDate       <span style='color: #BB00BB; font-weight: bold;'>3043.102  </span> <span style='color: #555555;'>2018-02-21</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  tune         * 0.1.6      <span style='color: #555555;'>2021-07-21</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  tzdb           0.2.0      <span style='color: #555555;'>2021-10-27</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  usethis        2.1.5      <span style='color: #555555;'>2021-12-09</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  utf8           1.2.2      <span style='color: #555555;'>2021-07-24</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  vctrs          0.3.8      <span style='color: #555555;'>2021-04-29</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  vetiver      * <span style='color: #BB00BB; font-weight: bold;'>0.1.1.9000</span> <span style='color: #555555;'>2022-01-24</span> <span style='color: #555555;'>[1]</span> <span style='color: #BB00BB; font-weight: bold;'>Github (tidymodels/vetiver@7876706)</span></span>
<span class='c'>#&gt;  vroom          1.5.7      <span style='color: #555555;'>2021-11-30</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  webutils       1.1        <span style='color: #555555;'>2020-04-28</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  withr          2.4.3      <span style='color: #555555;'>2021-11-30</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  workflows    * 0.2.4      <span style='color: #555555;'>2021-10-12</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  workflowsets * 0.1.0      <span style='color: #555555;'>2021-07-22</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  xfun           0.29       <span style='color: #555555;'>2021-12-14</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  xml2           1.3.3      <span style='color: #555555;'>2021-11-30</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  yaml           2.2.1      <span style='color: #555555;'>2020-02-01</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  yardstick    * 0.0.9      <span style='color: #555555;'>2021-11-22</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt; </span>
<span class='c'>#&gt; <span style='color: #555555;'> [1] /Library/Frameworks/R.framework/Versions/4.1-arm64/Resources/library</span></span>
<span class='c'>#&gt; </span>
<span class='c'>#&gt; <span style='color: #00BBBB; font-weight: bold;'>──────────────────────────────────────────────────────────────────────────────</span></span></code></pre>

</div>

