#! /usr/bin/perl

    #               Linden Scripting Language Configurator

    #   This program allows maintenance of Linden Scripting Language
    #   (LSL) code which supports multiple configurations, where
    #   conditional compilation is specified by special comments in
    #   a way in which the script may be developed directly within
    #   LSL in any of its supported configurations without the need
    #   to re-run the configurator and import the script on every
    #   debug shot.
    #
    #   The configuration is specified by a file containing variable
    #   declarations whose right hand side can contain any Perl
    #   expression or function call.  Variable names are specified as
    #   alphanumerics (by convention, all capitals), without Perl's
    #   leading "$".  All configuration variables used in the code
    #   must be specified in the configuration file.
    #
    #   Conditional compilation is specified by comments of the form:
    #
    #       /* IF expression */
    #       /* END expression */
    #
    #   if the code is enabled and:
    #
    #       /* IF expression
    #        END expression */
    #
    #   if disabled.  These statements may be nested, and the expressions
    #   on the IF and END comments must match exactly.  Nested IF and END
    #   statements within disabled code have only the /* marker at the
    #   start.
    #
    #   You can include block comments within disabled code by writing
    #   the closing delimiter as *_/.  For example:
    #
    #       /* Block comment in disabled code *_/
    #
    #   If the code containing the comment is enabled, the closing comment
    #   delimiter will be converted to */.  Similarly closing delimiters
    #   of block comments in code which is being disabled will be
    #   converted to *_/.

    #                   by John Walker  --  March 2020
    #                This program is in the public domain.

    use strict;
    use warnings;

    use Text::Tabs;

    if (scalar(@ARGV) < 3) {
        print("usage: lslconf.pl config_file source_dir dest_dir\n");
        exit(0);
    }

    #   Read and process the configuration file, declaring
    #   variables in the "V::" namespace.

    open(CF, "<$ARGV[0]") || die("Cannot open configuration file $ARGV[0]");

    my $n = 0;
    while (my $l = <CF>) {
        $n++;
        $l =~ s/^\s+//;
        $l =~ s/\s+$//;
        $l =~ s/#[^"]*$//;
        if ($l ne "") {
            local $SIG{__WARN__} = sub { die($_[0]) };
            eval(exvars($l));
            if ($@) {
                die("Error on line $n of $ARGV[0]: $@");
            }
        }
    }

    close(CF);
    
    #   Now process LSL files in the source directory, placing
    #   the configured files in the destination directory.

    opendir(SD, $ARGV[1]) || die("Cannot open source directory $ARGV[1]");

    while (my $f = readdir(SD)) {
        if (($f !~ m/^\./) && ($f =~ m/\.lsl$/)) {
            my $df = "$ARGV[1]/$f";
            my $odf = "$ARGV[2]/$f";
print("$df -> $odf\n");
            open(FI, "<$df") || die("Cannot open input file $df");
            open(FO, ">$odf") || die("Cannot create output file $odf");

            $n = 0;                         # Line number
            my $on = 1;                     # Is this code on ?
            my $nest = 0;                   # Nesting of configuration blocks
            my $offnest = 0;                # Nesting level where we turned off
            my @exprstack = ();             # Stack of conditional expressions
            my @linestack = ();             # Stack of line numbers
            while (my $l = <FI>) {
                $n++;

                #   In the interest of code hygiene, we trim trailing
                #   spaces and expand tabs here.  This is not necessary
                #   for the mission of the program, but a convenience
                #   in not shipping ugly code.
                $l =~ s/\s+$//;
                $l = expand($l);

                if ($l =~ m:^\s*/\*\s+IF\s+(\S.*)$:) {  # IF block ?
                    #   Increment nesting of configuration switches
                    $nest++;                        # Increment nesting level

                    my $expr = $1;
                    $expr =~ s:\s*\*/$::;       # Trim trailing delimeter, if any
                    push(@exprstack, $expr);    # Push expression on stack
                    push(@linestack, $n);       # Stack line number of IF
                    my $v;
                    {
                        local $SIG{__WARN__} = sub { die($_[0]) };
                        $v = eval(exvars($expr));
                        if ($@) {
                            die("Error on line $n of $ARGV[0]: $@");
                        }
                    }
#print("$f $n. IF [$nest] ($expr) = $v\n");
                    if ($on) {
                        $on = $v;
                        if (!$on) {
                            $offnest = $nest;       # Nesting level where we turned off
                        }
                        print(FO "/* IF $expr " . ($on ? " */" : "") . "\n");
                    } else {
                        #   IF within disabled code block
                        $l =~ s:\s*\*/::;           # Must remove close comment delimiter
                        print(FO "$l\n");
                    }
                } elsif ($l =~ m|^\s*(?:/\*)?\s+END\s+(\S.*?)(?:\*/)?$|) { # END block ?
                    my $expr = $1;
                    $expr =~ s:^\s*\*/\s*::;        # Trim leading delimeter, if any
                    $expr =~ s/\s+$//;
#print("$f $n. END [$nest] ($expr)\n");
                    my $bexpr = pop(@exprstack);
                    my $bline = pop(@linestack);
                    if ($bexpr ne $expr) {
                        print("Badly nested conditionals: IF $bexpr at line $bline " .
                              "does not match END $expr at line $n\n");
                    }
                    if ($nest == $offnest) {        # If this matches nest where we turned off...
                        $on = 1;                    # ...turn back on
                        $l = " END $expr */";       # Make END delimiter close comment
                    }
                    $nest--;
                    if (!$on) {
                        $l =~ s:\s*\*/::;           # Must remove close comment delimiter
                    } else {
                        $l = "/* END $expr */";
                    }
                    print(FO "$l\n");
                } else {
                    #   Not a configuration statement: transcribe to output.
                    #   If there is a block comment within the disabled code,
                    #   we must keep the closing */ from ending the commented
                    #   out code.  Note that this assumes our coding style:
                    #   that block comments always end with */ as the last
                    #   nonblank characters on the final line of the comment.
                    #   If you don't adhere to this standard, your code will be
                    #   messed up if you include block comments in disabled code.
                    if ($on) {
                        $l =~ s|\*_/$|*/|;
                    } else {
                        $l =~ s|\*/$|*_/|;
                    }
                    print(FO "$l\n");
                }
            }

            close(FO);
            close(FI);

            if ($nest != 0) {
                print("$f: Bad conditional nesting: nest = $nest at end of file.\n");
            }
        }
    }

    closedir(SD);

    #   exvars  --  Expand variables into namespace references

    sub exvars {
        my ($expr) = @_;

        $expr =~ s/([A-Za-z]\w*)/\$V::$1/g;
        return $expr;
    }
