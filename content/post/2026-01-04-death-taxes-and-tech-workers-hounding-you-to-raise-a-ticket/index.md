---
author: David Neuzerling
date: 2026-01-04
slug: death-taxes-and-tech-workers-hounding-you-to-raise-a-ticket
category: corporate
tags:
    - people_leadership
featured: "/img/featured/centaurs.webp"
title: Death, taxes, and tech workers hounding you to raise a ticket
---

Everyone hates ticketing systems. Everyone needs ticketing systems. Ticketing systems are often misused.

I rolled out a small-scale ticketing system recently for my team. Here are some thoughts.

# Tickets exist to make work scalable

There is always a default workflow system: you tap someone on the shoulder, or message them through Slack/Teams/Skype/IRC, and say "Hey, you got a second?". In the absence of any ticketing system --- and often in spite of any ticketing system --- people will revert to this approach. It's quick and easy.

Well, it's quick and easy for the requestor. The person on the receiving end of these ad hoc tasks won't benefit. If they do their job well then their reputation will spread and they'll receive more ad hoc work. They'll never get a continuous stretch of time to work on a task without another ad hoc interruption. They'll feel like they have a dozen bosses putting work on their plate.

Meanwhile, new team members won't have any work to do because no one is tapping on their shoulder.

Allowing stakeholders to directly assign work to individuals doesn't scale, drives people to burnout, and makes it impossible to onboard new team members. Ticketing systems give a single front door for incoming work. They're a weapon against ad hoc interruptions.

# Tickets exist to make sure work is observed

You can't improve the way your team works if you can't measure it. You need to be able to see the interruptions, the person who is snowed under with far more than one person can handle, and the "high priority" work that can actually wait a week.

I always recommend the book _Making Work Visible_ by Dominica Degrandis. It covers the five "time thieves" that prevent work from getting done, and explains how kanbans can be used to catch the time thieves. Ticketing systems and kanbans allow you to see the "too much work-in-progress" time thief in action, or the evidence the "neglected work" time thief leaves behind.

# Tickets exist to encourage people to phrase problems in their own words

Do you get frustrated when someone taps you on the shoulder and says "The widget machine is broken," offering no details, not so much as an error message? It's not a matter of competence or technical knowledge. It takes time to properly articulate a problem, and most people don't have a lot of time.

Ticketing systems force people to sit down and write out the problem they're experiencing. I'm not suggesting that you won't get tickets that simply say "the widget machine is broken". But it's less likely when people have to consciously describe the issue they're facing in a record system that looks somewhat official, as opposed to an informal conversation.

There's another side to this: ticketing systems give the requestor something to point to when their problems aren't adequately addressed.

Imagine a sick person describing their symptoms to the doctor. They mention "fatigue", and the doctor stops listening. The doctor matches "fatigue" to their internal decision trees, orders some blood tests, and dispenses platitudes about diet and exercise. The patient never gets to mention the snake bite on their ankle.

Experts see patterns that non-experts don't, and often jump to conclusions based on heuristics that probably work fine most of the time. Tickets are a defence against this. They're a record of a user's entire problem description, not just the parts that were matched against heuristics.

# Tickets do not exist to reduce workloads

Some ticketing systems have an ulterior motive: they exist to make it harder for people to request work. I've seen one form with 151 mandatory fields --- one for each of the original Pokémon, presumably. Perhaps the mentality is that most people will give up and only the most important requests will make it through.

This is not why ticketing systems exist. In fact, ticketing systems _cannot_ fulfill this purpose. Remember what I said earlier, about the default workflow system? If you make your ticketing system a brick wall, you'll just get people tapping you on the shoulder to make work happen instead.

Often the demand on a team outweighs that team's capacity. Ticketing systems are not the answer. Communication is. This means difficult conversations with stakeholders where you tell them that you don't have capacity for their request. It's uncomfortable, it's not fun, but it's a part of the job.

# Tickets do not exist to eliminate human interaction

Suppose you have a specific piece of information that is required for 5% of your work. If you don't put this on your intake form, you'll have to chase up that additional information 5% of the time. That means sending an email, opening a Slack chat, or tapping someone on the shoulder.

Perhaps you don't like this. So you put the question in your intake form and make it mandatory. Now, 95% of users are confronted with a field that isn't relevant to their request, and possibly confuses them. They do what every survey respondent does when faced with a strange mandatory field --- they put in a bunch of random letters or a random choice from the dropdown box.

Ticketing systems should give requestors an opportunity to describe the problem they're facing, but they don't exist to exhaustively list every possible piece of information needed to complete the task. Allow tickets to be incomplete, and fill in the gaps with a conversation.

# Tickets must handle failure gracefully

Tech workers don't write code with the assumption that it never fails. Yet they don't carry this attitude over to their ticketing systems. Ticketing systems are seen as infallible, and every error is the user doing something wrong.

Ticketing systems _will_ fail. There will always be some use case that was never anticipated, or some dependency that falls over. Ticketing systems need fallbacks just like code needs try-catch blocks.

A good fallback is an email address that goes to your team. It should be advertised at the bottom of every page, and preferably within the intake form itself. Some might balk at this: "But the whole point of the ticketing system is to stop emails!".

Fallbacks always exist. Backchannels always exist. Executive escalation always exists. The default workflow system I described earlier will always exist. "Should a fallback mechanism exist?" is the wrong question. "Should the team that owns the process have control over the fallback mechanism?" is the real question, and the answer is obvious.

Here's an uncomfortable anecdote: my experience is that you only need to email a tech worker three times before they give in and provide an alternative mechanism to a non-functional ticketing system. Don't do this to your team. Make the fallback mechanism official.

The people looking over the fallback email inbox must have the authority to circumvent the intake form. Their mandate is problem-solving, not process enforcement. Remember: ticketing systems do not exist to minimise communication.

Either create a formal fallback for your intake form, or deal with the multitude of informal fallbacks.

# Ticketing systems are a good thing for everyone

I created a lightweight ticketing system for my team: it's one field, minimum 100 characters, and a "submit" button. I'm not suggesting that all ticketing systems have to be so simple (I could probably add another few fields to encourage users to provide a bit more information) but the form is designed to be used, not to scare people away.

And if something goes wrong? If there's an issue that needs to be discussed and the form isn't appropriate? There's a link to a channel where people can speak to the team directly.

I'm not suggesting that we've solved all of our problems with this one weird trick. I'm not even suggesting we still haven't got work coming in through informal channels. But it's easier to onboard new starters and work is gracefully rerouted around people who are on leave.

Love them or hate them, ticketing systems must exist.
