## rutema
[![Build Status](https://secure.travis-ci.org/damphyr/rutema.png)](http://travis-ci.org/damphyr/rutema) [![Coverage Status](https://coveralls.io/repos/damphyr/rutema/badge.svg)](https://coveralls.io/r/damphyr/rutema) [![Code Climate](https://codeclimate.com/github/damphyr/rutema.png)](https://codeclimate.com/github/damphyr/rutema) ![doc status](http://inch-ci.org/github/damphyr/rutema.svg?branch=master) [![Gem Version](https://badge.fury.io/rb/rutema.svg)](https://badge.fury.io/rb/rutema)

rutema [http://github.com/damphyr/rutema](http://github.com/damphyr/rutema)

rutema is a test execution tool and a framework for organizing and managing test execution across different tools.

It enables the combination of different test tools while it takes care of logging, reporting, archiving of results and formalizes execution of automated and manual tests.

It's purpose is to make testing in heterogeneous environments easier. 

### Why?

Require consistency, repeatability and reliability from your test infrastructure while gathering data on every run.

Whether running through a checklist of manual steps, or executing a sequence of fully automated commands we always want to know if a test has failed, where it failed and what was the state of the system at that time.

rutema will gather all logs, timestamp them, store them and report on them. 

Rutema core provides a reference implementation of a parser for a simple but extensible XML test specification format which works well out of the box but the framework provides clearly defined interfaces so you can write the parser for your own format and add reporters that log wherever is needed.

### The dry stuff

* Unified test execution environment for automated and manual tests
* Extensible reports and notifications in various formats (email, rss, pdf, html etc.)
* A well defined way to create a project specific test specification format

### Further Reading

* [Configuring rutema](doc/CONFIGURATION.md)
* An [example](doc/EXAMPLE.md) of a (very simple) testing DSL with rutema 
* High level [description](README.md) of the concepts behind rutema

## Installation

* gem install rutema

## Dependencies

The core functionality of rutema depends on the following gems:
 * [patir](http://github.com/damphyr/patir)
 * [highline](http://highline.rubyforge.org/)

## License

(The MIT License)

Copyright (c) 2007-2020 Vassilis Rizopoulos

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
