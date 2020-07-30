    /*
                    Flocking Bird Deployer

                        by John Walker
    */

    key owner;                          //  Owner UUID
    string ownerName;                   //  Name of owner

    integer commandChannel = 1785;      // Command channel in chat (birth year of J. J. Audubon)
    integer commandH;                   // Handle for command channel
    key whoDat = NULL_KEY;              // Avatar who sent command
    integer restrictAccess = 2;         // Access restriction: 0 none, 1 group, 2 owner
    integer echo = TRUE;                // Echo chat and script commands ?
    string helpFileName = "Fourmilab Flocking Birds User Guide"; // Help notecard name

    float REGION_SIZE = 256;            // Size of regions

    integer birdChannel = -982449722;   // Channel for communicating with birds
    integer birdChH;                    // Bird channel listener handle
    string ypres = "B?+:$$";            // It's pronounced "Wipers"

    integer siteIndex = 0;              // Index of last site deployed
    list birdParams = [ ];              // Initial properties of birds

    //  Settings

    float avoidFactor = 0.2;            // Velocity adjustment to avoid collision
    float centeringFactor = 1;          // Velocity adjustment toward centre of mass
    float edgeMargin = 0.2;             // Margin at edges of cage
    float lifeTime = 600;               // Bird lifetime in seconds
    float matchingFactor = 0.1;         // Velocity adjustment to match average velocity
    float minDistance = 0.5;            // Distance maintained from other birds
    float speedLimit = 2;               // Maximum flight velocity
    float timerUpdate = 0.1;            // Timer update interval
    float turnFactor = 1.5;             // Velocity to turn away from edge
    float visualRange = 1.5;            // Visual (llSensor) range, metres
    float targetFactor = 0.2;           // Authority of turn toward target

    integer actions = 63;               // Bird actions
                                        //      1   Constrain to cage
                                        //      2   Limit maximum speed
                                        //      4   Seek centre of mass
                                        //      8   Avoid collisions
                                        //     16   Match velocities
                                        //     32   Seek target
    integer trace = FALSE;              // Trace bird behaviour
    integer flatland = FALSE;           // Constrain motion to X-Y plane ?
    float chirp = 1.0472; // (60 deg)      Chirp on turn sharper than this (radians)
    float volume = 1;                   // Chirp volume
    integer paths = FALSE;              // Show particle trails from birds ?
    string modelName = "Fourmilab Bird";    // Name of model in inventory

    integer hidden = FALSE;             // Is the deployer hidden ?

    integer firstSiteIndex;             // Site index counter for timed deployment
    integer startSiteIndex;             // Start site index for a Hatch command
    integer ha_started;                 // Number of birds hatched and running
    vector cageCornerLow;               // Low corner of hatch region
    vector cageCornerHigh;              // High corner of hatch region

    //  gRand  -- Generate Gaussian random deviate with zero mean, unit variance

    integer gRiset = FALSE;
    float gRfset;

    float gRand() {
        float v1;
        float v2;
        float rsq;

        if (!gRiset) {
            do {
                v1 = llFrand(2) - 1;
                v2 = llFrand(2) - 1;
                rsq = (v1 * v1) + (v2 * v2);
            } while ((rsq >= 1) || (rsq == 0));
            float fac = llSqrt(-2 * (llLog(rsq) / rsq));
            gRfset = v1 * fac;
            gRiset = TRUE;
            return v2 * fac;
        } else {
            gRiset = FALSE;
            return gRfset;
        }
    }

    //  igRand  --  Generate inverse Gaussian random deviate

    float igRand(float mu, float lambda) {
        float v = gRand();
        float y = v * v;
        float x = mu + ((mu * mu * y) / (2 * lambda)) -
            ((mu / (2 * lambda)) * llSqrt((4 * mu * lambda * y) + (mu * mu * y * y)));
        float test = llFrand(1);
        if (test <= (mu / (mu + x))) {
            return x;
        }
        return (mu * mu) / x;
    }

    //  rSign  --  Return a random sign, 1 or -1

    integer rSign() {
        if (llFrand(1) <= 0.5) {
            return -1;
        }
        return 1;
    }

    vector randVec() {
        /*  Random unit vector by Marsaglia's method:
            Marsaglia, G. "Choosing a Point from the Surface
            of a Sphere." Ann. Math. Stat. 43, 645-646, 1972.  */
        integer outside = TRUE;

        while (outside) {
            float x1 = 1 - llFrand(2);
            float x2 = 1 - llFrand(2);
            if (((x1 * x1) + (x2 * x2)) < 1) {
                outside = FALSE;
                float x = 2 * x1 * llSqrt(1 - (x1 * x1) - (x2 * x2));
                float y = 2 * x2 * llSqrt(1 - (x1 * x1) - (x2 * x2));
                float z = 1 - 2 * ((x1 * x1) + (x2 * x2));
                return < x, y, z >;
            }
        }
        return ZERO_VECTOR;         // Can't happen, but idiot compiler errors otherwise
    }

    //  ef  --  Edit floats in string to parsimonious representation

    string eff(float f) {
        return ef((string) f);
    }

    string efv(vector v) {
        return ef((string) v);
    }

    string ef(string s) {
        integer p = llStringLength(s) - 1;

        while (p >= 0) {
            //  Ignore non-digits after numbers
            while ((p >= 0) &&
                   (llSubStringIndex("0123456789", llGetSubString(s, p, p)) < 0)) {
                p--;
            }
            //  Verify we have a sequence of digits and one decimal point
            integer o = p - 1;
            integer digits = 1;
            integer decimals = 0;
            while ((o >= 0) &&
                   (llSubStringIndex("0123456789.", llGetSubString(s, o, o)) >= 0)) {
                o--;
                if (llGetSubString(s, o, o) == ".") {
                    decimals++;
                } else {
                    digits++;
                }
            }
            if ((digits > 1) && (decimals == 1)) {
                //  Elide trailing zeroes
                while ((p >= 0) && (llGetSubString(s, p, p) == "0")) {
                    s = llDeleteSubString(s, p, p);
                    p--;
                }
                //  If we've deleted all the way to the decimal point, remove it
                if ((p >= 0) && (llGetSubString(s, p, p) == ".")) {
                    s = llDeleteSubString(s, p, p);
                    p--;
                }
                //  Done with this number.  Skip to next non digit or decimal
                while ((p >= 0) &&
                       (llSubStringIndex("0123456789.", llGetSubString(s, p, p)) >= 0)) {
                    p--;
                }
            } else {
                //  This is not a floating point number
                p = o;
            }
        }
        return s;
    }

    //  tawk  --  Send a message to the interacting user in chat

    tawk(string msg) {
        if (whoDat == NULL_KEY) {
            //  No known sender.  Say in nearby chat.
            llSay(PUBLIC_CHANNEL, msg);
        } else {
            /*  While debugging, when speaking to the owner, use llOwnerSay()
                rather than llRegionSayTo() to avoid the risk of a runaway
                blithering loop triggering the gag which can only be removed
                by a region restart.  */
            if (owner == whoDat) {
                llOwnerSay(msg);
            } else {
                llRegionSayTo(whoDat, PUBLIC_CHANNEL, msg);
            }
        }
    }

    /*  sendSettings  --  Send settings to bird(s).  If bird is
                          nonzero, the message is directed to
                          that specific bird.  If zero, it is
                          a broadcast to all birds, and the id
                          argument is ignored.  */

    sendSettings(key id, integer bird) {
        string msg = llList2Json(JSON_ARRAY, [ "SETTINGS", bird,
                        timerUpdate, visualRange, edgeMargin, turnFactor,
                        centeringFactor, minDistance, avoidFactor,
                        matchingFactor, speedLimit,
                        trace, actions, lifeTime, paths, flatland,
                        chirp, volume, targetFactor
                      ]);
        if (bird == 0) {
            llRegionSay(birdChannel, msg);
        } else {
            llRegionSayTo(id, birdChannel, msg);
        }
    }

    //  suitableParcel  --  Test if parcels are compatible

    integer suitableParcel(key ours, key other) {
        if (ours == other) {
            return TRUE;
        }
        return FALSE;
    }

    //  vecCompMul  --  Multiply vectors component-wise

    vector vecCompMul(vector a, vector b) {
        return <a.x * b.x, a.y * b.y, a.z * b.z>;
    }

    //  seekSuitableParcel  --  Walk along vector to find suitable corner within parcel

    vector seekSuitableParcel(vector corner, vector ndir, float step,
                vector deployerPos, key targetParcel) {
        if (trace) {
            tawk("seekSuitable Parcel " + efv(corner) + " ndir " +  efv(ndir) +
                " step " + eff(step) + " deployer " +  efv(deployerPos) +
                " target " + (string) targetParcel);
        }
        vector adir = <llFabs(ndir.x), llFabs(ndir.y), llFabs(ndir.z)>; // Search axis
        vector cdir = <1, 1, 1> - adir;         // Complement of search axis
        vector cpos = vecCompMul(deployerPos, cdir) + vecCompMul(corner, adir);   // Start position
        integer mod = FALSE;
        while (!suitableParcel(targetParcel, llList2Key(llGetParcelDetails(cpos,
            [ PARCEL_DETAILS_ID ]), 0))) {
            cpos += ndir * step;
            if (trace) {
                tawk("  Unsuitable:  trying " +  efv(cpos));
            }
            mod = TRUE;
        }
        if (mod) {
            if (trace) {
                tawk("  Parcel adjusted corner " +  efv(corner) + " ndir " +  efv(ndir) + " to " +
                    efv(vecCompMul(corner, cdir) + vecCompMul(cpos, adir)));
            }
            corner = vecCompMul(corner, cdir) + vecCompMul(cpos, adir);
        }
          else if (trace) { tawk("  within parcel; suitable."); }

        return corner;
    }

    /*  setCageCorners  --  Define corners of the cage within which
                            the bird will fly.  This is specified by
                            a box defined by the position of the
                            deployer, the horizontal radius of the
                            field of flight, and a vertical extent from
                            the deployer's altitude to cageHeight above
                            it.  We constrain this so that the computed
                            bounds do not extend outside the deployer's
                            region or into a parcel into which we cannot
                            fly.  */

    setCageCorners(vector deployerPos, float cageRadius, float cageHeight) {
        integer EDGE_AVOID_MARGIN = 2;              // Margin to avoid edges

        //  Compute requested corners of our cage
        cageCornerLow = deployerPos - < cageRadius, cageRadius, 0 >;
        cageCornerHigh = deployerPos + < cageRadius, cageRadius, cageHeight >;

        if (trace) {
            tawk("setCageCorners deployerPos " + efv(deployerPos) +
                " cageCornerLow " + efv(cageCornerLow) +
                " cageCornerHigh " + efv(cageCornerHigh));
        }

        //  First, restrict corners so they don't extend beyond the region

        if (cageCornerLow.x < EDGE_AVOID_MARGIN) {
            cageCornerLow.x = EDGE_AVOID_MARGIN;
            if (trace) { tawk("Region adjust cageCornerLow.x " + efv(cageCornerLow)); }
        }
        if (cageCornerLow.y < EDGE_AVOID_MARGIN) {
            cageCornerLow.y = EDGE_AVOID_MARGIN;
            if (trace) { tawk("Region adjust cageCornerLow.y " + efv(cageCornerLow)); }
        }
        if (cageCornerHigh.x > (REGION_SIZE - EDGE_AVOID_MARGIN)) {
            cageCornerHigh.x = REGION_SIZE - EDGE_AVOID_MARGIN;
            if (trace) { tawk("Region adjust cageCornerHigh.x " + efv(cageCornerHigh)); }
        }
        if (cageCornerHigh.y > (REGION_SIZE - EDGE_AVOID_MARGIN)) {
            cageCornerHigh.y = REGION_SIZE - EDGE_AVOID_MARGIN;
            if (trace) { tawk("Region adjust cageCornerHigh.y " + efv(cageCornerHigh)); }
        }

        /*  Next, verify that the (possibly region adjusted) corners
            are in the same parcel as the deployer.  If not, find a
            corner which is.  */

        key depParcel = llList2Key(llGetParcelDetails(deployerPos,
            [ PARCEL_DETAILS_ID ]), 0);
        /*  Walk from existing corners back toward deployer
            until we find a suitable point.  */
        cageCornerLow = seekSuitableParcel(cageCornerLow, <1, 0, 0>,
            EDGE_AVOID_MARGIN, deployerPos, depParcel);
        cageCornerLow = seekSuitableParcel(cageCornerLow, <0, 1, 0>,
            EDGE_AVOID_MARGIN, deployerPos, depParcel);
        cageCornerHigh = seekSuitableParcel(cageCornerHigh, <-1, 0, 0>,
            EDGE_AVOID_MARGIN, deployerPos, depParcel);
        cageCornerHigh = seekSuitableParcel(cageCornerHigh, <0, -1, 0>,
            EDGE_AVOID_MARGIN, deployerPos, depParcel);
        if (trace) {
            tawk("Adjusted " +
                " cageCornerLow " + efv(cageCornerLow) +
                " cageCornerHigh " + efv(cageCornerHigh));
        }
}

    //  checkAccess  --  Check if user has permission to send commands

    integer checkAccess(key id) {
        return (restrictAccess == 0) ||
               ((restrictAccess == 1) && llSameGroup(id)) ||
               (id == llGetOwner());
    }

    //  abbrP  --  Test if string matches abbreviation

    integer abbrP(string str, string abbr) {
        return abbr == llGetSubString(str, 0, llStringLength(abbr) - 1);
    }

    //  onOff  --  Parse an on/off parameter

    integer onOff(string param) {
        if (abbrP(param, "on")) {
            return TRUE;
        } else if (abbrP(param, "of")) {
            return FALSE;
        } else {
            tawk("Error: please specify on or off.");
            return -1;
        }
    }

    //  eOnOff  --  Edit an on/off parameter

    string eOnOff(integer p) {
        if (p) {
            return "on";
        }
        return "off";
    }

    /*  arg  --  Extract an argument with a default.  A
                 specification of "-" selects the default.  */

    string arg(list args, integer argn, integer narg, string def) {
        if (narg < argn) {
            string a = llList2String(args, narg);
            if (a != "-") {
                return a;
            }
        }
        return def;
    }

    /*  inventoryName  --   Extract inventory item name from Set subcmd.
                            This is a horrific kludge which allows
                            names to be upper and lower case.  It finds the
                            subcommand in the lower case command then
                            extracts the text that follows, trimming leading
                            and trailing blanks, from the upper and lower
                            case original command.   */

    string inventoryName(string subcmd, string lmessage, string message) {
        //  Find subcommand in Set subcmd ...
        integer dindex = llSubStringIndex(lmessage, subcmd);
        //  Advance past space after subcmd
        dindex += llSubStringIndex(llGetSubString(lmessage, dindex, -1), " ") + 1;
        //  Note that STRING_TRIM elides any leading and trailing spaces
        return llStringTrim(llGetSubString(message, dindex, -1), STRING_TRIM);
    }

    //  processCommand  --  Process a command

    integer processCommand(key id, string message, integer fromScript) {

        if (!checkAccess(id)) {
            llRegionSayTo(id, PUBLIC_CHANNEL,
                "You do not have permission to control this object.");
            return FALSE;
        }

        whoDat = id;            // Direct chat output to sender of command

        /*  If echo is enabled, echo command to sender unless
            prefixed with "@".  The command is prefixed with ">>"
            if entered from chat or "++" if from a script.  */

        integer echoCmd = TRUE;
        if (llGetSubString(llStringTrim(message, STRING_TRIM_HEAD), 0, 0) == "@") {
            echoCmd = FALSE;
            message = llGetSubString(llStringTrim(message, STRING_TRIM_HEAD), 1, -1);
        }
        if (echo && echoCmd) {
            string prefix = ">> ";
            if (fromScript) {
                prefix = "++ ";
            }
            tawk(prefix + message);                 // Echo command to sender
        }

        string lmessage = llToLower(llStringTrim(message, STRING_TRIM));
        list args = llParseString2List(lmessage, [" "], []);    // Command and arguments
        integer argn = llGetListLength(args);       // Number of arguments
        string command = llList2String(args, 0);    // The command
        string sparam = llList2String(args, 1);     // First argument, for convenience

        //  Access who                  Restrict chat command access to public/group/owner

        if (abbrP(command, "ac")) {
            string who = sparam;

            if (abbrP(who, "p")) {          // Public
                restrictAccess = 0;
            } else if (abbrP(who, "g")) {   // Group
                restrictAccess = 1;
            } else if (abbrP(who, "o")) {   // Owner
                restrictAccess = 2;
            } else {
                tawk("Unknown access restriction \"" + who +
                    "\".  Valid: public, group, owner.\n");
                return FALSE;
            }

        //  Auxiliary ....          Send parameters to other scripts

        } else if (abbrP(command, "au")) {
            /*  The original complete message in upper and
                lower case and the parsed parameters are sent
                to all birds on the birdChannel.  */
            llRegionSay(birdChannel, llList2Json(JSON_ARRAY,
                [ "AUX", 0, whoDat, message, argn ] + args));

        //  Boot                    Reset the script to initial settings

        } else if (abbrP(command, "bo")) {
            llResetScript();

        /*  Channel n               Change command channel.  Note that
                                    the channel change is lost on a
                                    script reset.  */
        } else if (abbrP(command, "ch")) {
            integer newch = (integer) sparam;
            if ((newch < 2)) {
                tawk("Invalid channel " + (string) newch + ".");
                return FALSE;
            } else {
                llListenRemove(commandH);
                commandChannel = newch;
                commandH = llListen(commandChannel, "", NULL_KEY, "");
                tawk("Listening on /" + (string) commandChannel);
            }

        //  Clear                   Clear chat for debugging

        } else if (abbrP(command, "cl")) {
            tawk("\n\n\n\n\n\n\n\n\n\n\n\n\n");

        //  Hatch                   Deploy birds

        } else if (abbrP(command, "ha")) {
            if (argn < 2) {
                tawk("Usage: hatch n_birds radius(5) height(5) maxvel(2) uniform/gaussian/igauss");
            } else {
                ha_nbirds = (integer) arg(args, argn, 1, "15");
                ha_radius = (float) arg(args, argn, 2, "5");
                ha_height = (float) arg(args, argn, 3, "5");
                ha_maxvel = (float) arg(args, argn, 4, "2");
                ha_randr = arg(args, argn, 5, "uniform");
                ha_started = 0;

                integer bogus = FALSE;
                if ((ha_radius <= 0) || (ha_radius >= REGION_SIZE)) {
                    tawk("Invalid radius: must be 0 < radius < " + (string) REGION_SIZE);
                    bogus = TRUE;
                }
                if ((ha_height <= 0) || (ha_height > 99)) {
                    tawk("Invalid height: must be 0 < height <= 99");
                    bogus = TRUE;
                }
                if (!(abbrP(ha_randr, "u") || abbrP(ha_randr, "g") || abbrP(ha_randr, "i"))) {
                    tawk("Invalid random distribution: must be uniform/gaussian/igauss");
                    bogus = TRUE;
                }

                if (!bogus) {
                    setCageCorners(llGetPos(), ha_radius, ha_height);
                    if (trace) {
                        vector cdim = cageCornerHigh - cageCornerLow;
                        tawk("Cage dimensions " + efv(cdim) + " area " + eff(cdim.x * cdim.y));
                    }

                    birdParams = [ ];               // Clear parameters from any previous hatch
                    firstSiteIndex = startSiteIndex = siteIndex;
                    if (ha_nbirds == 1) {
                        tawk("Hatching bird " + (string) (siteIndex + 1));
                    } else {
                        tawk("Hatching birds " + (string) (startSiteIndex + 1) +
                             "–" + (string) (startSiteIndex + ha_nbirds));
                    }
                    if (hidden == 2) {
                        llSetAlpha(0, ALL_SIDES);
                    }
                    //  Start timer to hatch birds
                    llSetTimerEvent(0.1);
                }
            }

        //  Help                    Give User Guide notecard to requester

        } else if (abbrP(command, "he")) {
            llGiveInventory(whoDat, helpFileName);  // Give requester the User Guide notecard

        //  Hide on/off/hatch           Hide/show the deployer

        } else if (abbrP(command, "hi")) {
            if (abbrP(sparam, "ha")) {
                hidden = 2;
            } else {
                integer hi = onOff(sparam);
                if (hi >= 0) {
                    hidden = hi;
                    llSetAlpha(1 - hidden, ALL_SIDES);
                }
            }

        //  Init                    Reinitialise birds in region

        } else if (abbrP(command, "in")) {
            llRegionSay(birdChannel,
                llList2Json(JSON_ARRAY, [ "RESET", 0, whoDat ]));

        //  List [ bird bird... ]   List birds in region or specific birds

        } else if (abbrP(command, "li")) {
            if (argn < 2) {
                llRegionSay(birdChannel,llList2Json(JSON_ARRAY, [ "LIST", 0 ]));
            } else {
                integer b;

                for (b = 1; b < argn; b++) {
                    llRegionSay(birdChannel,llList2Json(JSON_ARRAY,
                        [ "LIST", llList2Integer(args, b) ]));
                }
            }

        //  Remove                  Remove all birds

        } else if (abbrP(command, "re")) {
            llRegionSay(birdChannel,llList2Json(JSON_ARRAY, [ ypres ]));
            siteIndex = 0;
            birdParams = [ ];

        //  Set                     Set simulation parameter

        } else if (abbrP(command, "se")) {
            string svalue = llList2String(args, 2);
            float value = (float) svalue;
            integer changedSettings = FALSE;

            //  Actions n

            if (abbrP(sparam, "ac")) {
                /*  Actions:
                        1   Avoid edges of cage
                        2   Enforce maximum speed
                        4   Fly toward centre of mass nearby birds
                        8   Avoid collisions
                       16   Match velocities with nearby birds
                       32   Seek target  */
                actions = (integer) svalue;
                changedSettings = TRUE;

            //  Avoid n

            } else if (abbrP(sparam, "av")) {
                avoidFactor = value;
                changedSettings = TRUE;

            //  Centring n

            } else if (abbrP(sparam, "ce")) {
                centeringFactor = value;
                changedSettings = TRUE;

            //  Chirp n

            } else if (abbrP(sparam, "ch")) {
                chirp = value * DEG_TO_RAD;
                changedSettings = TRUE;

            //  Edges n

            } else if (abbrP(sparam, "ed")) {
                edgeMargin = value;
                changedSettings = TRUE;

            //  Flatland on/off

            } else if (abbrP(sparam, "fl")) {
                flatland = onOff(svalue);
                changedSettings = TRUE;

            //  Lifetime

            } else if (abbrP(sparam, "li")) {
                lifeTime = value;
                changedSettings = TRUE;

            //  Matching n

            } else if (abbrP(sparam, "ma")) {
                matchingFactor = value;
                changedSettings = TRUE;

            //  Mindist n

            } else if (abbrP(sparam, "mi")) {
                minDistance = value;
                changedSettings = TRUE;

            //  Model [ Model name ]

            } else if (abbrP(sparam, "mo")) {
                if (argn < 3) {
                    string s = "Available models: ";
                    integer n = llGetInventoryNumber(INVENTORY_OBJECT);
                    integer i;
                    for (i = 0; i < n; i++) {
                        s += "\n  " + (string) (i + 1) + ". " +
                            llGetInventoryName(INVENTORY_OBJECT, i);
                    }
                    tawk(s);
                } else {
                    string m = inventoryName("mo", lmessage, message);
                    if (llGetInventoryKey(m) == NULL_KEY) {
                        tawk("No model named \"" + m + "\".  Use \"Set model\" for listing.");
                        return FALSE;
                    }
                    modelName = m;
                }

            //  Paths on/off

            } else if (abbrP(sparam, "pa")) {
                paths = onOff(svalue);
                changedSettings = TRUE;

            //  Speedlimit n

            } else if (abbrP(sparam, "sp")) {
                speedLimit = value;
                changedSettings = TRUE;

            //  TargetFactor n

            } else if (abbrP(sparam, "ta")) {
                targetFactor = value;
                changedSettings = TRUE;

            //  Timer n

            } else if (abbrP(sparam, "ti")) {
                timerUpdate = value;
                changedSettings = TRUE;

            //  Trace on/off

            } else if (abbrP(sparam, "tr")) {
                trace = onOff(svalue);
                changedSettings = TRUE;

            //  Turning n

            } else if (abbrP(sparam, "tu")) {
                turnFactor = value;
                changedSettings = TRUE;

            //  Visualrange n

            } else if (abbrP(sparam, "vi")) {
                visualRange = value;
                changedSettings = TRUE;

            //  Volume n

            } else if (abbrP(sparam, "vo")) {
                volume = value;
                changedSettings = TRUE;

            } else {
                tawk("Invalid.  Set actions/avoidFactor/centringFactor/\n" +
                     "  chirp/edges/flatland/lifetime/matching.minDistance/\n" +
                     "  model/paths/speedLimit/targetFactor/timerUpdate/\n" +
                     "  trace/turning/visualRange/volume");
                return FALSE;
            }
            if (changedSettings) {
                sendSettings(NULL_KEY, 0);
            }

        //  Status

        } else if (abbrP(command, "st")) {
            integer mFree = llGetFreeMemory();
            integer mUsed = llGetUsedMemory();
            string hidemode = eOnOff(hidden);
            if (hidden == 2) {
                hidemode = "hatch";
            }
            tawk("Status:  Birds hatched " + (string) siteIndex +
                "\n  avoidFactor " + eff(avoidFactor) +
                "\n  centeringFactor " + eff(centeringFactor) +
                "\n  edgeMargin " + eff(edgeMargin) + " m" +
                "\n  lifeTime " + eff(lifeTime) + " s" +
                "\n  matchingFactor " + eff(matchingFactor) +
                "\n  minDistance " + eff(minDistance) + " m" +
                "\n  speedLimit " + eff(speedLimit) + " m/s" +
                "\n  targetFactor " + eff(targetFactor) +
                "\n  timerUpdate " + eff(timerUpdate) + " s" +
                "\n  turnFactor " + eff(turnFactor) + " m/s" +
                "\n  visualRange " + eff(visualRange) + " m\n" +

                "\n  actions " + (string) actions +
                "\n  trace " + eOnOff(trace) +
                "\n  flatland " + eOnOff(flatland) +
                "\n  chirp " + eff(llRound(chirp * RAD_TO_DEG)) + "°" +
                "\n  volume " + eff(volume) +
                "\n  paths " + eOnOff(paths) +
                "\n  model \"" + modelName + "\"" +
                "\n  hide " + hidemode +
                "\n  Script memory.  Free: " + (string) mFree +
                    "  Used: " + (string) mUsed + " (" +
                    (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)"
            );

        } else {
            tawk("Huh?  \"" + message + "\" undefined.  Chat /" +
                (string) commandChannel + " help for instructions.");
            return FALSE;
        }
        return TRUE;
    }

    //  hatchBird  --  Place a bird within the radius

    //  Arguments of most recent Hatch command
    integer ha_nbirds;
    float ha_radius;
    float ha_height;
    float ha_maxvel;
    string ha_randr;

    //  Shared properties of all birds hatched by one command
    float hatchRadius;
    float hatchHeight;
    float hatchMaxvel;
    vector hatchPos;

    integer hatchBird(integer birdno, float height, float maxvel, string randr) {

        vector pos = cageCornerLow + ((cageCornerHigh - cageCornerLow) / 2);
        vector where = <-1, -1, 0>;

        hatchRadius = llVecDist(cageCornerLow, cageCornerHigh) / 2;
        hatchHeight = height;
        hatchMaxvel = maxvel;
        hatchPos = pos;

        integer failures = 0;

        /*  Generate a random position within radius of our
            location, rejecting any which fall outside the
            boundaries of the cage.  */

        vector cageSize = (cageCornerHigh - cageCornerLow) / 2;
        while (where.x < 0) {
            float posx;
            float posy;
            float posz;

            if (abbrP(randr, "u")) {
                posx = llFrand(cageSize.x * 2) - cageSize.x;
                posy = llFrand(cageSize.y * 2) - cageSize.y;
            } else if (abbrP(randr, "g")) {
                posx = cageSize.x * gRand() * 0.5;
                posy = cageSize.y * gRand() * 0.5;
            } else if (abbrP(randr, "i")) {
                posx = cageSize.x * igRand(1, 1) * rSign();
                posy = cageSize.y * igRand(1, 1) * rSign();
            }

            if (flatland) {
                posz = 1;               // Fly one metre above deployer
            } else {
                posz = llFrand(height);
            }

            vector cand = pos + < posx, posy, posz >;

            //  Reject candidate outside the cage and try again
//  THIS SHOULDN'T BE POSSIBLE ANY MORE !!!
            if ((cand.x >= cageCornerLow.x) && (cand.x <= cageCornerHigh.x) &&
                (cand.y >= cageCornerLow.y) && (cand.y <= cageCornerHigh.y)) {
                where = cand;
            } else {
                failures++;
                if (failures > 10) {
                    //  Too many failures finding a site: give up
                    return FALSE;
                }
                if (trace) {
                    tawk("Hatch site candidate " + efv(cand) +
                         " failed attempt " + (string) failures);
                }
            }

        }

        //  Assign the bird a random initial velocity and save bounds.

        vector initialVel = randVec();

        if (flatland) {
            initialVel.z = 0;       // Force vertical velocity to zero
        }
        birdParams = birdParams + [ birdno, initialVel, where ];

        return TRUE;
    }

    default {

        on_rez(integer start_param) {
            llResetScript();
        }

        state_entry() {
            owner = llGetOwner();
            ownerName =  llKey2Name(owner);  //  Save name of owner

            siteIndex = 0;
            birdParams = [ ];

            hidden = FALSE;
            llSetAlpha(1, ALL_SIDES);

            //  Start listening on the command chat channel
            commandH = llListen(commandChannel, "", NULL_KEY, "");
            llOwnerSay("Listening on /" + (string) commandChannel);

            //  Start listening on the bird channel
            birdChH = llListen(birdChannel, "", NULL_KEY, "");
        }

        /*  The listen event handler processes messages from
            our chat control channel and messages from birds we've
            deployed.  */

        listen(integer channel, string name, key id, string message) {
//llOwnerSay("Listen channel " + (string) channel + " message " + message);
            if (channel == birdChannel) {
                list msg = llJson2List(message);
                string ccmd = llList2String(msg, 0);

                if (ccmd == "REZ") {
                    integer bird_number = llList2Integer(msg, 1);

                    /*  Now send the bird its randomly-generated initial
                        velocity and the boundaries of the flight zone.  */

                    integer i;
                    integer n = llGetListLength(birdParams);

                    for (i = 0; i < n; i += 3) {
                        if (llList2Integer(birdParams, i) == bird_number) {
                            llRegionSayTo(id, birdChannel,
                                llList2Json(JSON_ARRAY, [ "INIT", bird_number,
                                llList2Vector(birdParams, i + 1),       // Initial velocity vector
                                hatchMaxvel,                            // Initial maximum velocity
                                hatchPos,                               // Start position of deployer
                                hatchRadius,                            // Radius of deployment
                                hatchHeight,                            // Height of deployment zone
                                llList2Vector(birdParams, i + 2),       // Initial position
                                whoDat,                                 // User who hatched birds
                                trace,                                  // Trace flag
                                cageCornerLow, cageCornerHigh           // Corners of cage
                            ]));

                            //  Delete bird from birdParams
                            birdParams = llDeleteSubList(birdParams, i, i + 2);

                            //  Send initial settings
                            sendSettings(id, bird_number);
                            i = n;                  // Escape from loop

                            ha_started++;
                            if (ha_started >= ha_nbirds) {
                                siteIndex += ha_nbirds;
                                tawk("Hatching complete.");
                            }
                        }
                    }
                }
            } else {
                processCommand(id, message, FALSE);
            }
        }

        /*  We use the timer when hatching birds to avoid a blast
            of REZ messages from new birds overflowing the region
            message queue and being lost.  We deploy one bird from
            birdParams on each tick, leaving time for the script to
            receive and respond to incoming REZ messages as they
            arrive.  This also has the advantage that individual
            birds start to fly shortly after being hatched, as
            opposed to all birds starting at once after all have
            been deployed.  */

        timer() {
            if (firstSiteIndex < (startSiteIndex + ha_nbirds)) {
                firstSiteIndex++;
                //  Create entry for bird in birdParams
                integer success = hatchBird(firstSiteIndex, ha_height, ha_maxvel, ha_randr);
                if (!success) {
                    tawk("Failed hatching bird " + (string) firstSiteIndex +
                         ".  Abandoning hatch command.");
                    llSetTimerEvent(0);
                    return;
                }

                /*  Find information for our bird in birdParams.  We
                    can't simply index the list because we delete items
                    from it as birds hatch and report via the REZ message.  */
                integer i;
                integer j;
                integer n = llGetListLength(birdParams);
                for (j = 0; j < n; j += 3) {
                    if (llList2Integer(birdParams, j) == firstSiteIndex) {
                        i = j;
                        j = n;
                    }
                }
                integer bird_num = llList2Integer(birdParams, i);
                vector initialVel = llList2Vector(birdParams, i + 1);
                vector where = llList2Vector(birdParams, i + 2);

                /*  Now place the bird.  Since we can't llRezObject more
                    than ten metres from our current location, jump to
                    the rez location, create the bird, then jump back to
                    our original position.  */

                vector eggPos = llGetPos();
                llSetRegionPos(where);
                llRezObject(modelName, where, ZERO_VECTOR,
                    llAxisAngle2Rot(<0, 1, 0>, PI_BY_TWO) *
                        llRotBetween(<1, 0, 0>, initialVel), bird_num);
                llSetRegionPos(eggPos);
                llSetTimerEvent(0.25);
            } else {
                //  All done hatching birds
                if (hidden == 2) {
                    llSetAlpha(1, ALL_SIDES);
                }
                llSetTimerEvent(0);
            }
        }
    }
