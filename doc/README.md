# Documentation

## Concepts

The main idea behind rutema is the expression of a software test in machine readable format including all information needed for human comprehension: title, description, metadata used for tracking the relationships of the test with the software it tests etc.

This becomes the rutema specification and it can be parsed and executed by a program/computer with little or no user intervention. Even if user input is required, the input method/sequence should be the same in every repetition of a test.

This consistency gives us reproducible results that help us localize errors faster.

When viewed over time, it helps us identify incosistencies in the system under test (things like race conditions) by eliminating the inconsistencies in the test environment.

The next logical step is to remove "administrative" tasks (like collecting test output, logs and creating reports) from the responsibility of the tester, automate them within rutema and let the tester concentrate on the semantics of the test.

## Heterogeneity

In any software development project there is a wide variety of testing tools available, depending on programming language and technology (desktop, web, mobile, embedded etc.).

rutema aims to provide a way to coordinate and combine existing tools, not to replace them. 

The rutema specification combines semantic information (the description, the title) conveying the purpose of a test, with management information (an ID, tracking information for requirements) and the implementation in one logical entity.

To be of any use the format of the specification must be machine readable but also human readable. Inadvertendly the choice leads to a text-based format. 

The core implementation presents a simple XML format that can be extended easily. XML in this case fullfills a role very close to it's original: annotate and structure text.

It should be noted that over the years there have been several different rutema specification formats in use (YAML, JSON, a DIY text format etc.) but the XML format offered in the core has been by far the easiest to manage and extend.

## Testing language

Every software development team develops it's own shorthand for communicating about the project. This is a mixture of technology and problem domain terminology. Process methodology and spoken language also have a large influence. Nobody says shift contents of variable B left by one bit, they say B times two.

The tendency is to group complicated sequences of actions under a single term compressing information. The more of those terms are in use the richer the domain specific language, or rather the project specific language.

rutema can be a tool to help codify the terms we use to describe a system so that we can use them to test the system. A project/domain/test specific language, which we will shorthand as DSL from now on.

A codified DSL is a powerful communication medium as it turns implicit knowledge into explicit terms and thus becomes the interface through which a team not only communicates in itself but also with outside stakeholders.
