# xamplr-gen

xamplr-gen is part of a set of software tools that supports development of ruby applications.

It consists of three gems hosted on gemcutter, source code on github.

* [xamplr-pp](http://github.com/hutch/xamplr-pp) -- this is a pure ruby pull parser
* [xamplr](http://github.com/hutch/xamplr) -- this is the xampl runtime
* [xamplr-gen](http://github.com/hutch/xamplr-gen) -- this is the code generator

There is an additional fourth github repository containing
examples and documentation that will be coming soon.

Yes, that means that there's no documentation. And no examples. I agree,
this is a very bad situation.

For more information, see [the xampl page on xampl.com](http://xampl.com/so/xampl/), and/or [the weblog 'So.'](http://xampl.com/so/)

## Installation:

> sudo gem install xamplr-gen

This will install all three gems.

NOTE: if you have installed hutch-xamplr or hutch-xamplr-pp then
you should uninstall them. For some reason, in certain circumstances,
these might be loaded or partially loaded when trying to use xampl.
If you don't you'll experience strange exceptions with hutch-xamplr
or hutch-xamplr-pp on the stack trace.


## License:

xamplr-pp and xamlpr are both licensed under the LGPLv3.

xamplr-gen is licensed under AGPLv3

An alternative license may be negotiated, contact me (hutch@xampl.com)

Copyright (c) 2002-2010 Bob Hutchison.

