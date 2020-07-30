    /*
                         Curiosity

                       by John Walker

        This script can be dropped into any flying model to make it
        "curious" about avatars in its vicinity.  It will regularly
        perform a sensor scan within its visual range and designate the
        closest avatar it sees as a target to the main Bird script.
        After concentrating on the same avatar for timeBored seconds,
        it becomes bored with that one and will consider other avatars
        for that interval, with both intervals adjusted by a number
        from 0 to timeBoredRand so they don't behave in lockstep.

    */

    string ourName;                     // Our object name
    string ourKey;                      // Our key
    integer bird_number;                // Our bird number
    key owner;                          // UUID of owner
    key whoDat;                         // User with whom we're communicating
    key deployer;                       // ID of deployer who hatched us
    /* IF TRACE */
    integer trace = FALSE;              // Trace operations
    integer b1;                         // Used to trace only bird 1
    /* END TRACE */
    float visualRange = 7;              // Visual (llSensor) range, metres

    integer birdChannel = -982449722;   // Channel for communicating with birds

    integer bored = FALSE;              // Bored with current target ?
    float timeBored = 15;               // How long after which we become bored with target
    float timeBoredRand = 5;            // Random component of time bored
    float timeStartBored;               // Time we become bored with target
    float timeUnBored;                  // When we're no longer bored with target
    key kBored;                         // Key of avatar with which we're bored

    list targetsAgent;                  // List of avatar targets
    list targetsNPC;                    // List of NPC targets

    integer noOwner = FALSE;            // Ignore the owner ?
    integer NPCs = TRUE;                // Curious about non-player characters ?
    integer NPCtoggle;                  // Toggle for NPC / avatar sensor probe

    vector currTarget = <-1, -1, -1>;   // Current target
    key currTgtKey = NULL_KEY;          // Key of current target

    //  Link messages

    integer LM_BI_TARGET = 11;          // Target detected

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

    //  revokeTarget  --  Revoke current target designation

    revokeTarget(string why) {
        currTarget = <-1, -1, -1>;
        currTgtKey = NULL_KEY;
        llMessageLinked(LINK_THIS, LM_BI_TARGET,
            llList2Json(JSON_ARRAY, [ 0, "(none)", currTarget ]), NULL_KEY);
        /* IF TRACE */
        if (trace && b1) {
            tawk("Bird " + (string) bird_number + " revoking target " + why + ".");
        }
        /* END TRACE */
    }

    default {
        on_rez(integer start_param) {
            //  If start_param is zero, this is a simple manual rez
            if (start_param > 0) {
                bird_number = start_param;
                ourKey = llGetKey();
                /* IF TRACE */
                b1 = bird_number == 1;
                /* END TRACE */

                ourName = llGetObjectName();
                deployer = llList2Key(llGetObjectDetails(ourKey, [ OBJECT_REZZER_KEY ]), 0);
                llListen(birdChannel, "", deployer, "");  // Listen for commands from the deployer
                //  Scan for objects of interest
                if (NPCs) {
                    //  If we're also scanning for NPCs, run sensor from the timer
                    NPCtoggle = FALSE;
                    llSetTimerEvent(0.1);
                } else {
                    llSensorRepeat("", NULL_KEY, AGENT, visualRange, PI, 0.25);
                }
            }
        }

        state_entry() {
            whoDat = owner = llGetOwner();
        }

        //  The listen event handles AUX commands from the deployer

        listen(integer channel, string name, key id, string message) {
            if ((channel == birdChannel) && (id == deployer)) {
                list msg = llJson2List(message);
//                string ccmd = llList2String(msg, 0);

                /*  See if it's a Set auxiliary curiosity command:
                        [ "AUX", bird_no, user_key, message, argn, args... ]  */
                if ((llList2String(msg, 0) == "AUX") &&
                    (llList2Integer(msg, 4) > 2) &&
                    abbrP(llList2String(msg, 6), "cu")) {
                    whoDat = llList2Key(msg, 2);
                    list args = llList2List(msg, 7, -1);
                    integer argn = llGetListLength(args);
                    string command = llList2String(args, 0);    // The command
                    string sparam = llList2String(args, 1);     // First argument, for convenience
                    float fparam = (float) sparam;

                    //  Boredom timeF [timeR]       Set boredom fixed and optional random times
                    if (abbrP(command, "bo")) {
                        timeBored = fparam;
                        if (argn > 2) {
                            timeBoredRand = (float) llList2String(args, 2);
                        }

                    //  NPCs on/off                 Detect marked non-player characters ?
                    } else if (abbrP(command, "np")) {
                        NPCs = onOff(sparam);
                        llSensorRemove();
                        llSetTimerEvent(0);
                        //  Scan for objects of interest
                        if (NPCs) {
                            //  If we're also scanning for NPCs, run sensor from the timer
                            NPCtoggle = FALSE;
                            llSetTimerEvent(0.25);
                        } else {
                            llSensorRepeat("", NULL_KEY, AGENT, visualRange, PI, 0.5);
                        }

                    //  OwnerIgnore on/off          Ignore owner ?
                    } else if (abbrP(command, "ow")) {
                        noOwner = onOff(sparam);

                    //  Sensor n                    Avatar sensor range, metres
                    } else if (abbrP(command, "se")) {
                        llSensorRemove();
                        visualRange = fparam;
                        if (visualRange > 0) {
                            llSensorRepeat("", NULL_KEY, AGENT, visualRange, PI, 0.5);
                        }

                    //  Trace on/off                Enable/disable trace output
                    /* IF TRACE */
                    } else if (abbrP(command, "tr")) {
                        trace = onOff(sparam);
                    /* END TRACE */

                    } else {
                        tawk("Unknown curiosity setting.");
                    }
                }
            }
        }

        //  Sensor scan results

        sensor(integer ndet) {
            integer i;
            float t = llGetTime();
            integer scanAgent = FALSE;
            integer scanNPC = FALSE;

            //  If boredom expired, start paying attention to target again

            if (bored && (t > timeUnBored)) {
                /* IF TRACE */
                if (trace && b1) {
                    tawk("Bird " + (string) bird_number +
                         " no longer bored with " + llKey2Name(kBored));
                }
                /* END TRACE */
                bored = FALSE;
                kBored = NULL_KEY;
            }

            //  Scan the sensor finds and build a list of nearby targets

            vector birdPos = llGetPos();

            for (i = 0; i < ndet; i++) {
                key k = llDetectedKey(i);
                /*  We include a potential target only if we're not bored
                    with it and, if noOwner is set, if it isn't our owner.  */
                if (((!noOwner) || (k != owner)) && ((!bored) || (k != kBored))) {
                    list det = llGetObjectDetails(k, [ OBJECT_NAME, OBJECT_POS, OBJECT_CREATION_TIME ]);
                    string oname = llList2String(det, 0);
                    integer isNPC = FALSE;
                    /*  If this is not an avatar, test whether it is an NPC.
                        Note that if NPCs is not set, we don't need to do this
                        test because the sensor scan will return only avatars.  */
                    if ((!NPCs) || (llList2String(det, 2) == "") ||
                        ((isNPC = (oname == "[NPC]")))) {
                        vector pos = llList2Vector(det, 1);
                        if (isNPC) {
                            if (!scanNPC) {
                                targetsNPC = [ ];
                            }
                            scanNPC = TRUE;
                            /* IF TRACE */
                            if (trace && b1) {
                                oname += " " + llList2String(llGetObjectDetails(k, [ OBJECT_DESC ]), 0);
                            }
                            /* END TRACE */
                        } else {
                            if (!scanAgent) {
                                targetsAgent = [ ];
                            }
                            scanAgent = TRUE;
                        }
                        /* IF TRACE */
                        if (trace && b1) {
                            tawk("Curious bird " + (string) bird_number + " sees " + oname + " at " +
                                (string) pos);
                        }
                        /* END TRACE */
                        if (scanNPC) {
                            targetsNPC += [ llVecDist(pos, birdPos), oname, pos, k ];
                        } else {
                            targetsAgent += [ llVecDist(pos, birdPos), oname, pos, k ];
                        }
                    }
                }
            }

            /*  Now we have a list of potential targets.  Find
                the closest and designate if new.  */

            list targets = targetsAgent + targetsNPC;
            integer nTargets = llGetListLength(targets);

//llOwnerSay("Targets: " + llList2CSV(targets));
            if (nTargets > 0) {
                /*  We found one or more potential targets.  Sort
                    the targets in order of distance, then process
                    the closest.  */
                if (nTargets > 4) {
                    //  More than one target: sort to find closest
                    targets = llListSort(targets, 4, TRUE);
                }
                key targetKey = llList2Key(targets, 3);
                vector targetPos = llList2Vector(targets, 2);

                /*  If this is a new target, start the timer for our becoming
                    bored with it.  If we're already bored with the previous
                    target, remain so until our boredom expires.  */
                if (targetKey != currTgtKey) {
                    currTgtKey = targetKey;
                    timeStartBored = t + timeBored + llFrand(timeBoredRand);
                    /* IF TRACE */
                    if (trace && b1) {
                        tawk("Bird " + (string) bird_number +
                            " designating new target " + llKey2Name(currTgtKey));
                    }
                    /* END TRACE */
                } else {
                    /*  This is the current target: has the time arrived
                        when we become bored with it?  */
                    if ((timeBored > 0) && (!bored) && (t >= timeStartBored)) {
                        bored = TRUE;
                        kBored = currTgtKey;
                        timeUnBored = timeStartBored + timeBored + llFrand(timeBoredRand);
                        /* IF TRACE */
                        if (trace && b1) {
                            tawk("Bird " + (string) bird_number +
                                " bored with target " + llKey2Name(kBored));
                        }
                        /* END TRACE */
                        revokeTarget(", bored");
                        //  Don't update position of target with which we're bored
                        return;
                    }
                }

                /*  If the target has moved since our last designation
                    (whether due to our choosing a new target, a different
                    target, or the current target itself moving), send the
                    new target location to the main Bird script.  */
                if (currTarget != targetPos) {
//tawk("Bird " + (string) bird_number + " target " + llList2String(targets, 1) +
//     " dist " + (string) llList2Float(targets, 0));
                    currTarget = targetPos;
                    llMessageLinked(LINK_THIS, LM_BI_TARGET,
                        llList2Json(JSON_ARRAY, llList2List(targets, 0, 2)), targetKey);
                }
            }
        }

        //  no_sensor() is called when a sensor scan finds nothing

        no_sensor() {
            //  If boredom expired, start paying attention to last target again
            if (bored && (llGetTime() > timeUnBored)) {
                /* IF TRACE */
                if (trace && b1) {
                    tawk("Bird " + (string) bird_number +
                        " no longer bored with " + llKey2Name(kBored));
                }
                bored = FALSE;
                kBored = NULL_KEY;
            }

            //  Clear out the previous target list of the kind we queried
            if (NPCtoggle) {
                targetsAgent = [ ];
            } else {
                targetsNPC = [ ];
            }

            //  Revoke target designation, if any
            if ((currTarget != <-1, -1, -1>) &&
                (llGetListLength(targetsAgent) == 0) &&
                (llGetListLength(targetsNPC) == 0)) {
                revokeTarget("not seen");
            }
        }

        /*  The timer is used to alternate sensor probes for avatars
            and NPCs when NPCs is set.  */

        timer() {
            /*  The reason we have to do this screwball alternating set of
                sensor queries and all of the related complexity it creates
                in the sensor() event handler is that while we can easily
                probe just for avatars (AGENT), when we're looking for NPCs,
                there's no characteristic which distinguishes them in general
                from birds.  Consequently, if we make a general probe which
                will pick up NPCs, it will also return all of the birds in
                the vicinity and, in the case of a crowded flock, saturate
                the maximum of 16 sensor returns with birds, causing us to
                miss NPCs.  To work around this, we require eligible NPCs
                to all be named "[NPC]" so we can query by name.  If you
                wish a further description of the NPC, place it in the
                description field, which can be anything.  */
            if (NPCs) {
                if (NPCtoggle) {
                    llSensor("[NPC]", NULL_KEY, ACTIVE | PASSIVE, visualRange, PI);
                } else {
                    llSensor("", NULL_KEY, AGENT, visualRange, PI);
                }
                NPCtoggle = !NPCtoggle;
            } else {
                llSetTimerEvent(0);
            }
        }
    }
