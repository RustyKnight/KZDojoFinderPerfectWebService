#KZDojoFinderPerfectWebServiceThis is a web service implementation for the DojoFinder App.

It's based on the [Server Side Swift](http://perfect.org/) project ([Perfect](https://github.com/PerfectlySoft/Perfect)) and is intended as a testing ground for a more fully fledge service.

Currently, it does not look like Perfect supports virtual host, which makes it show stopper in the long run, but it if that was corrected, it would a very strong contender for future development

Perfect has a Apache "mod" which would overcome the above limitations and can also run under Linux. Currently for my needs, getting Apache setup is beyond my scope, but may be in the future. As it stands, it's a neat way to get a simple testing service up and running