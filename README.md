[![Build Status](https://secure.travis-ci.org/damphyr/rutema.png)](http://travis-ci.org/damphyr/rutema) rutema [http://patir.rubyforge.org/rutema](http://patir.rubyforge.org/rutema)

rutema is a test execution tool.
It allows the  combination of  various test tools while it takes care of logging, reporting, archiving of results and formalizes execution of automated and manual tests.
It's purpose is to make testing in heterogeneous environments easier. 

###Why?
Require consistency, repeatability and reliability from your test infrastructure while gathering data on every run.

Whether running through a checklist of manual steps, or executing a sequence of fully automated commands we always want in the end to know if a test has failed, where it failed and what was the state of the system at that time.

rutema will gather all logs, timestamp them, store them and report on them. 

Using one of the database reporters we can then extract more information on the quality and state of our system by examining the behaviour of the tests over time.

For more information look at [http://patir.rubyforge.org/rutema](http://patir.rubyforge.org/rutema)

###The dry stuff
* Unified test execution environment for automated and manual tests
* Extensible reports and notifications in various formats (email, rss, pdf, html etc.)
* Comprehensive history of test execution
* A well defined way to create a project specific test specification format

## Synopsis:
See http://patir.rubyforge.org/rutema/examples.html for an introductory example.

## Installation:
* gem install rutema

## Dependencies
The core functionality of rutema depends on the following gems:
 * [patir](http://github.com/damphyr/patir)
 * [highline](http://highline.rubyforge.org/)

Depending on which parser or reporter is used though, further dependencies might be needed.
The reporters included in the gem depend on 
 * activerecord used by rutema/reporters/activerecord
 * [mailfactory](http://mailfactory.rubyforge.org/) used by rutema/reporters/email

## License:
(The MIT License)

Copyright (c) 2007-2012 Vassilis Rizopoulos

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