---
author:
- David Neuzerling
date: 2025-06-02
execute:
  eval: false
  output: asis
jupyter: false
slug: wrangling-llm-output-with-langchain
category: code
featured: "/img/featured/skaven.webp"
title: Wrangling LLM output with LangChain
---

The toughest prediction any data scientist makes is deciding which tools are worth learning. The explosion of generative AI only makes this harder. My prediction: LangChain is here to stay or, at least, the patterns behind it are.

LangChain's job is to drag non-deterministic GenAI outputs into a deterministic world. Putting GenAI into real workloads demands the right mindset from a data scientist. We're not training the models that generate the answers; we're taking those answers and forcing them into a tightly defined realm.

LangChain does this by chaining GenAI prompts together with plain Python. The mindset here is: *I don't trust raw LLM output --- how do I mitigate that uncertainty?*

# Example 1: Creating Kanban titles

This is a great use case for generative AI. We're taking a user-provided description of a task or request and turning it into a title for its kanban card. The damage is low when the model gets it wrong, and the benefits --- while modest --- still matter: the greatest threat to any kanban is lack of use, and we should take any opportunity to make it easier to create cards.

Here's the general idea:

1.  Ask the LLM to create a kanban title, limited to 50 characters
2.  If goes over the 50 character limit, run that output through a second prompt to refine it further
3.  If that also fails, truncate the result to 50 characters using good old Python

No matter how much I tweak the prompt, the LLM *will* still sometimes return a title that's too long. Don't waste too much time trying to get the perfect prompt here. It's better to ask the LLM to fix its own mistakes.

Here's the setup. I'm assuming that an OpenAI key is set via an environment variable. I'm using OpenAI's GPT4.1-mini, but `llm` could be any model.

```python
import os
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.runnables import RunnableLambda
from langchain_core.output_parsers import StrOutputParser

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
MODEL_NAME = "gpt-4.1-mini"
MAX_CHARS = 50

llm = ChatOpenAI(model=MODEL_NAME, temperature=0.3, openai_api_key=OPENAI_API_KEY)
```

The first actual LLM step is defined below. Note the LangChain syntax: a prompt is combined with an LLM using the overloaded pipe (`|`) to create a `RunnableSequence`. The output is then turned into a string by piping into the `StrOutputParser`. At this point I haven't actually called the LLM --- and won't until I use the `invoke()` method. This just defines a prompt that's ready to run once the missing components are filled in.

```python
create_title_first_pass_prompt = ChatPromptTemplate.from_messages(
    [
        (
            "system",
            "You are creating a kanban card from a given task description."
            "Write a short, clear title for the card no more than {max_chars} characters."
            "Return just the title without reasoning or explanation.",
        ),
        ("human", "{description}"),
    ]
)
create_title_first_pass = create_title_first_pass_prompt | llm | StrOutputParser()
```

Now here's my first frustration with LangChain: logging. LangChain strongly encourages using [LangSmith](https://www.langchain.com/langsmith) for logging and traceability. This sends prompts and responses to a third-party service and, while I'm sure it's a fine product, I just wanted to see what was going on in my prompts. So I built some bare-bones logging myself.

There's a bug in my IDE that's affecting the standard `logging` module, so below I've opted for the time-honoured debugging method used by kings and scholars: `print` statements.

```python
def log_first_title_pass(output):
    print(f'First attempt at title: "{output}" ({len(output)} chars)')
    return output
```

The second prompt is only called upon when the response from the first prompt is greater than 50 characters. It asks the LLM to try again, reducing the length of the title.

```python
refine_title_prompt = ChatPromptTemplate.from_messages(
    [
        (
            "system",
            "You are shortening a given kanban title to no more than {max_chars} characters"
            "Return just the shortened title without reasoning or explanation.",
        ),
        ("human", "{title}"),
    ]
)
refine_title = refine_title_prompt | llm | StrOutputParser()


def maybe_refine(title: str) -> str:
    if len(title) > MAX_CHARS:
        refined = refine_title.invoke({"title": title, "max_chars": MAX_CHARS})
        print(f'Refined to: "{refined}" ({len(refined)} chars)')
        return refined
    else:
        print(f'Title accepted: "{title}" ({len(title)} chars)')
        return title
```

There's a final step, which doesn't involve an LLM at all. If the output is *still* greater than 50 characters, just truncate the last few words. We also trim any trailing punctuation.

```python
def trim_title(title: str, max_chars: int = MAX_CHARS) -> str:
    if len(title) <= max_chars:
        return title

    trimmed = title[:max_chars].rstrip()
    if " " in trimmed:
        trimmed = trimmed[: trimmed.rfind(" ")].rstrip()

    trimmed_and_stripped = trimmed.rstrip(".,;:-–—")  # strip trailing punctuation

    if title != trimmed_and_stripped:
        print(
            f'Final title: "{trimmed_and_stripped}" ({len(trimmed_and_stripped)} chars)'
        )

    return trimmed_and_stripped
```

And now we can finally put all of these together into a chain. We kick off the process with the initial prompt. The rest are `RunnableLambdas`, which are LangChain's way of turning Python functions into composable steps that can be freely mixed with other LangChain components.

```python
create_title = (
    create_title_first_pass
    | RunnableLambda(log_first_title_pass)
    | RunnableLambda(maybe_refine)
    | RunnableLambda(trim_title)
)
```

Okay, time to test this out. I'll use the lengthy task description below. You can tell this is a test case because it's way more detailed than any kanban card I've seen in real life.

```python
description = (
    "I want to explore the relationship between the strength of the AUD and iron ore futures. "
    "I heard once in a Youtube video that the strength of the AUD is more or less the same as "
    "iron ore futures because of the country's dependence on mining exports. I think if we make "
    "some sort of line graph, perhaps comparing the AUD against the USD with spot prices for "
    "iron ore, we can check this claim. Also, is it possible to compare against any other"
    "mineral or gas exports? There might be some other commodity to think about."
)

create_title.invoke({"description": description, "max_chars": MAX_CHARS})

# First attempt at title: "Analyze AUD vs Iron Ore Futures & Other Commodities" (51 chars)
# Refined to: "Analyze AUD vs Iron Ore & Other Commodities" (43 chars)
```

Success! The first attempt fell just a bit over of the 50 character limit, but the second attempt was successful.

# Example 2: Detecting countries

Suppose every kanban card needs to be associated with a country. I might use a query like the below:

```python
which_country_prompt = (
    "Determine which country the user's query most likely relates to."
    "If you are unsure, return 'Unknown'"
)
which_country = ChatPromptTemplate.from_messages(
    [
        ("system", which_country_prompt),
        ("human", "{description}"),
    ]
)
```

The issue here is that I need to control the range of possible outputs. For example, I might want to enforce "United States" rather than "United States of America", or have a small list of possible countries with which a card might be associated.

LangChain works with Pydantic for enforcing a *structured output* on the LLM. First I'll define my list of countries. For now I'll just consider Australia and the United States, with an "Unknown" option for when the LLM isn't sure. The "Unknown" cards can then be picked up later by a human being and properly classified.

```python
from typing import Literal
from pydantic import BaseModel

COUNTRIES_IN_SCOPE = ["Australia", "United States", "Unknown"]

class Countries(BaseModel):
    country: Literal[*COUNTRIES_IN_SCOPE]
```

Now when I define my runnable I pipe the prompt into `llm.with_structured_output(Countries)` rather than simply `llm`. I have one final `RunnableLambda` which extracts the identified country from the result.

```python
def extract_country(countries_instance):
    return countries_instance.country

determine_country = (
    which_country
    | llm.with_structured_output(Countries)
    | RunnableLambda(extract_country)
)
```

When I invoke this prompt against my earlier example with `determine_country.invoke({"description": description})` the LLM picks up on the "AUD" currency and returns "Australia".

# Example 3: Running tests

Unit tests are a challenge for LLMs, as we're the output is non-deterministic. We're effectively testing a *distribution* of responses. Traditional unit tests, on the other hand, assume that the same input should always produce the same output.

One approach is to mock the responses, but this only tests that the mechanisms for calling the API are working. I want to know how my test cases will perform with an actual LLM.

First, I'll declare my test cases.

```python
# Example test cases
test_cases = [
    (
    {"description": "Determine the relationship between iron ore futures and the strength of the AUD"},
    "Australia",
    ), (
    {"description": "Austria won Eurovision in 2025"},
    "Unknown"
    ), (
    {
    "description": "Determine the relationship between iron ore futures and the greenback"},
    "United States",
    ), (
    {"description": "The Winner of the 1983 America's Cup"},
    "Australia"
    ),
]
```

I always start with the easiest test case, and the first one here is exactly that. The LLM needs to only link "AUD" with "Australia". The second test case is also straightforward --- the answer is "Austria", but since that's not in the list of possible outputs, it should return "Unknown".

The others get trickier. "Greenback" is another phrase for the US dollar, but small LLM models sometimes struggle to make the connection. The final example is a curve ball: Australia won the 1983 America's Cup, but since the text contains the word "America" the LLM may make a quick assumption.

Onto the testing itself, I'm going to go with an approach where I run the LLM against each test case **10 times**. There's nothing special about this number, but the core idea here is that the same input can succeed sometimes and fail others. Watch out for the costs here! Every test incurs 40 API calls (4 test cases, in batches of 10 each).

```python
import pytest
import asyncio

REPEAT_TESTS_N_TIMES = 10

@pytest.mark.asyncio
@pytest.mark.parametrize("input_data,expected_substring", test_cases)
async def test_determine_country(test_case, expected_country):
    inputs = [test_case] * REPEAT_TESTS_N_TIMES
    description = test_case["description"]
    results = await determine_country.abatch(inputs)

    failures = [
        result
        for i, result in enumerate(results)
        if not isinstance(result, str) or expected_country != result
    ]

    assert not failures, (
        f"{len(failures)}/{REPEAT_TESTS_N_TIMES} failures for prompt '{description}': expected '{expected_country}' but got {failures}"
    )
```

There are some new concepts within this code block. Rather than `invoke` I'm calling the `abatch` method (short for "asynchronous batch"). This, along with the `await` keyword, allows for the 10 API calls to be executed concurrently.

The first two test cases are fine. The first one to fail is this prompt, which fails to recognise the relationship between the "greenback" and America about 20% of the time, returning "Unknown" instead.

```python
# AssertionError: 2/10 failures for prompt 'Determine the relationship between
# iron ore futures and the greenback': expected 'United States' but got
# ['Unknown', 'Unknown']
```

The final prompt fails 100% of the time --- the model cannot recognise that the America's Cup isn't necessarily about the United States.

```python
# AssertionError: 10/10 failures for prompt 'The Winner of the 1983 America's
# Cup': expected 'Australia' but got ['United States', 'United States',
# 'United States', 'United States', 'United States', 'United States',
# 'United States', 'United States', 'United States', 'United States']
```

There are a few options to deal with this:

-   Remove the test case and *accept* the incorrect results. This is just for a Kanban intake, after all, so the world won't end if a card is miscategorised regardless of what your product manager tells you.
-   Similarly, I could allow some proportion of errors, but insist that my test cases pass at least x% of the time.
-   The first failure is the least concerning, since a result of "Unknown" is less significant than an actual mistake. Maybe a human can come along later and properly categorise those. I could permit "Unknowns" in my test results.
-   Tweak the prompt and hope for better results. I'm not claiming that my prompts are ideal, but I think I'd run into diminishing returns here.
-   I could lower the temperature to get slightly more predictable (but not necessarily more correct) results.
-   Use a bigger model. I'm using "gpt-4.1-mini", but I could switch that to "gpt-4.1". Anecdotally, that seems to fix *both* of the failing tests above, but the cost is roughly 5 times that of the mini model.

Dealing with LLMs means mitigating or accepting non-deterministic results from the model. It means trading off model size against API costs and latency, and considering the price of mistakes. While LLM technology and tools are evolving fast, these concepts should be comfortable territory for any data scientist.
