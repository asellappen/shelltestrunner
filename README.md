---
title: shelltestrunner docs
---

Home page: [http://hackage.haskell.org/package/shelltestrunner](http://hackage.haskell.org/package/shelltestrunner) -
[browse code](http://joyful.com/darcsweb/darcsweb.cgi?r=shelltestrunner;a=headblob;f=/shelltest.hs) -
[browse changes](http://joyful.com/darcsweb/darcsweb.cgi?r=shelltestrunner)

## Example

    $ cat sample.test
    # let's test cat
    cat
    <<<
    A
    >>>
    A
    >>>2
    >>>= 0
    $ shelltest sample.test
    :sample.test: [OK]

             Test Cases  Total      
     Passed  1           1          
     Failed  0           0          
     Total   1           1          

## Release notes

  * When you have multiple tests in a file, the `>>>=` field is now
    required as a delimiter. (You may need to add it to your existing
    tests.)  This means input and expected output can now contain lines
    beginning with `#`. Also tests may be separated by whitespace as well
    as comments.

  * Fixed: parsing could fail when input contained left angle brackets
  
  * Fixed: some test files generated an extra blank test at the end.

  * A new --diff option shows test failures as a unified diff when
    possible, including line numbers to help locate the problem.

**0.9 2010/9/3**

  * show plain non-ansi output by default, add --color option

  * better handling of non-ascii test data. We assume that non-ascii file
    paths, command-line arguments etc. are UTF-8 encoded on unix systems
    (cf http://www.dwheeler.com/essays/fixing-unix-linux-filenames.html),
    and that GHC 6.12 or greater is used. Then:

    - non-ascii test file paths should render correctly, eg in failure messages
    - non-ascii test commands should run correctly
    - non-ascii expected output should match correctly
    - non-ascii regular expressions should match correctly. (Caveat: not
      thoroughly tested, this may break certain regexps, )

  * use regex-tdfa instead of pcre-light for better windows compatibility
    To avoid a memory leak in current regex-tdfa, only regular expressions
    up to 300 characters in size are supported. Also, DOTALL is no longer
    enabled and probably fewer regexp constructs are supported.  There are
    still issues on windows/wine but in theory this will help.

  * tighten up dependencies

**0.8 2010/4/9**

  * rename executable to shelltest. The package might also be renamed at some point.

  * better built-in help

  * shell tests now include a full command line, making them more readable
    and self-contained. The --with option can be used to replace the first
    word with something else, unless the test command line begins with a
    space.

  * we also accept directory arguments, searching for test files below
    them, with two new options:
      --execdir        execute tested command in same directory as test file
      --extension=EXT  file extension of test files (default=.test)

**0.7 2010/3/5**

  * more robust parsing
    - --debug-parse parses test files and stops
    - regexps now support escaped forward slash (\/)
    - bad regexps now fail at startup
    - command-line arguments are required in a test, and may be blank
    - a >>>= is no longer required to separate multiple tests in a file
    - comments can be appended to delimiter lines
    - comments can appear at end of file
    - files need not have a final newline
    - files containing nothing, all comments, or valid tests are allowed; anything else is rejected
    - somewhat better errors
    - allow indented input

  * support negative (-) and negatively-matched (!) numeric exit codes

  * let . in regexps match newline

  * warn but continue when a test file fails to parse

  * output cleanups, trim large output

  * more flexible --implicit flag

  * switch to the more robust and faster pcre-light regexp lib

**0.6 2009/7/15**

  * allow multiple tests per file, handle bad executable better

**0.5 2009/7/14**

  * show failure output in proper order

**0.4 2009/7/14**

  * run commands in a more robust way to avoid hangs
    This fixes hanging when a command generates large output, and hopefully
    all other deadlocks. The output is consumed strictly. Thanks to Ganesh
    Sittampalam for his help with this.

  * --implicit-tests flag providing implicit tests for omitted fields

  * --debug flag

  * regular expression matching

  * disallow interspersed foreign options which confused parseargs

  * change comment character to #

**0.3 2009/7/11**

  * misc. bugfixes/improvements

**0.2 2009/7/10**

  * bugfix, build with -threaded

**0.1 2009/7/10**

  * shelltestrunner, a generic shell command stdout/stderr/exit status tester