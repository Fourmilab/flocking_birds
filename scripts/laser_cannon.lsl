    /*
                        Laser Cannon

                       by John Walker

        This script adds offensive capability to a flying model
        for Fourmilab Flocking Birds.  It was developed for use
        in the Attack and Defender Drones (that differ only in
        their name, which this script uses to control their
        behaviour), but can be adapted relatively straightforwardly
        to other models with different armament.

    */

    string ourName;                     // Our object name
    string ourKey;                      // Our key
    integer bird_number;                // Our bird number
    integer defender;                   // Are we a defender ?
    key owner;                          // UUID of owner
    key whoDat;                         // User with whom we're communicating
    key deployer;                       // ID of deployer who hatched us
    /* IF TRACE */
    integer trace = FALSE;              // Trace operations
    integer b1;                         // Used to trace only bird 1
    /* END TRACE */
    float probeRange = 2.5;             // Length of beam in metres
    float visualRange = 7;              // Visual (llSensor) range, metres
    float timerUpdate = 0.1;            // Timer tick rate

    integer birdChannel = -982449722;   // Channel for communicating with birds

    integer firing;                     // Are we currently firing ?
    float fireTime = 0.3;               // Length of shot
    float fireRechargeTime = 5;         // Recharge time after a shot
    float fireEnd;                      // End time of shot
    float fireNext = 0;                 // Time after shot when we can seek next target
    float fireVolume = 10;              // Volume for shot sound
    integer explode = TRUE;             // Generate explosion at impact point
    float pushImpulse = 0;              // Impulse with which we push hit avatars
    float damage = 0;                   // Inflict damage on avatars we hit ?

    integer bored = FALSE;              // Bored with current target ?
    float timeBored = 15;               // How long after which we become bored with target
    float timeBoredRand = 5;            // Random component of time bored
    float timeStartBored;               // Time we become bored with target
    float timeUnBored;                  // When we're no longer bored with target
    key kBored;                         // Key of avatar with which we're bored

    list targetsAgent;                  // List of avatar targets
    list targetsNPC;                    // List of NPC targets
    integer NPCs = TRUE;                // Target non-player characters ?
    integer NPCtoggle;                  // Toggle for NPC / avatar sensor probe

    integer noShootOwner = FALSE;       // Don't shoot at owner ?

    integer lBeam;                      // Link number of beam
    integer lFighter;                   // Link number of fighter
    vector beamColour;                  // Beam's colour
    float beamAlpha;                    // Beam initial alpha
    float beamGlow;                     // Beam initial glow

    vector currTarget = <-1, -1, -1>;   // Current target
    key currTgtKey = NULL_KEY;          // Key of current target

    //  Link messages

    integer LM_BI_TARGET = 11;          // Target detected

    /*  Find a linked prim from its name.  Avoids having to slavishly
        link prims in order in complex builds to reference them later
        by link number.  You should only call this once, in state_entry(),
        and then save the link numbers in global variables.  Returns the
        prim number or -1 if no such prim was found.  Caution: if there
        are more than one prim with the given name, the first will be
        returned without warning of the duplication.  */

    integer findLinkNumber(string pname) {
        integer i = llGetLinkNumber() != 0;
        integer n = llGetNumberOfPrims() + i;

        for (; i < n; i++) {
            if (llGetLinkName(i) == pname) {
                return i;
            }
        }
        return -1;
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

    //  showBeam  --  Show or hide the beam

    showBeam(float alpha) {
        float g = beamGlow;
        if (alpha == 0) {
            g = 0;
        }
        llSetLinkPrimitiveParamsFast(lBeam,
            [ PRIM_COLOR, 0, beamColour, alpha,
              PRIM_COLOR, 1, beamColour, alpha,
              PRIM_GLOW, 0, g,
              PRIM_GLOW, 1, g ]);
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
                lBeam = findLinkNumber("Laser cannon beam");
                lFighter = findLinkNumber("Tie Fighter");

                ourName = llGetObjectName();
                defender = ourName == "Defender Drone";
                deployer = llList2Key(llGetObjectDetails(ourKey,
                    [ OBJECT_REZZER_KEY ]), 0);
                /*  Set beam and highlight colour depending upon
                    our Attack/Defender role.  */
                if (defender) {
                    beamColour = < 0, 1, 0 >;
                    llSetLinkPrimitiveParamsFast(lFighter,
                        [ PRIM_COLOR, 1, < 0.18, 0.463, 0.212 >, 1 ]);  // Green
                } else {
                    beamColour = < 1, 0.25, 0.25 >;
                }
                beamAlpha = 0.5;
                beamGlow = 0.1;
                showBeam(0);
                firing = FALSE;
                llListen(birdChannel, "", deployer, "");  // Listen for commands from the deployer
                llSetTimerEvent(timerUpdate);   // Reset periodic update timer
                if (defender) {
                    llSensorRepeat("Attack Drone", NULL_KEY, SCRIPTED, visualRange, PI, 0.5);
                } else {
                //  Scan for objects of interest
                    if (NPCs) {
                        //  If we're also scanning for NPCs, run sensor from the timer
                        NPCtoggle = FALSE;
                        llSetTimerEvent(0.25);
                    } else {
                        llSensorRepeat("", NULL_KEY, AGENT, visualRange, PI, 0.25);
                    }
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

                /*  See if it's a Set auxiliary cannon command:
                        [ "AUX", bird_no, user_key, message, argn, args... ]  */
                if ((llList2String(msg, 0) == "AUX") &&
                    (llList2Integer(msg, 4) > 2) &&
                    abbrP(llList2String(msg, 6), "ca")) {
                    whoDat = llList2Key(msg, 2);
                    list args = llList2List(msg, 7, -1);
                    integer argn = llList2Integer(msg, 4) - 3;
                    string command = llList2String(args, 0);    // The command

                    /*  If "cannon" is followed by "attack" or "defender",
                        only process the command when we are in that role.  */

                    integer roleD = -1;
                    if (abbrP(command, "at")) {                 // Attack
                        roleD = FALSE;
                    } else if (abbrP(command, "de")) {          // Defender
                        roleD = TRUE;
                    }
                    if (roleD != -1) {
                        if (roleD != defender) {
                            return;
                        }
                        args = llList2List(args, 1, -1);
                        argn--;
                        command = llList2String(args, 0);       // The command
                    }

                    string sparam = llList2String(args, 1);     // First argument, for convenience
                    float fparam = (float) sparam;

                    //  Boredom timeF [timeR]       Set boredom fixed and optional random times
                    if (abbrP(command, "bo")) {
                        timeBored = fparam;
                        if (argn > 2) {
                            timeBoredRand = (float) llList2String(args, 2);
                        }

                    //  Damage n                    Damage hit avatars by n (0 to 100)
                    } else if (abbrP(command, "da")) {
                        damage = fparam;

                    //  Explode on/off              Produce explosion at hit point ?
                    } else if (abbrP(command, "ex")) {
                        explode = onOff(sparam);

                    //  NPCs on/off                 Detect marked non-player characters ?
                    } else if (abbrP(command, "np")) {
                        NPCs = onOff(sparam);
                        llSensorRemove();
                        llSetTimerEvent(timerUpdate);
                        //  Scan for objects of interest
                        if (NPCs) {
                            //  If we're also scanning for NPCs, run sensor from the timer
                            NPCtoggle = FALSE;
                            llSetTimerEvent(0.25);
                        } else {
                            llSensorRepeat("", NULL_KEY, AGENT, visualRange, PI, 0.5);
                        }

                    //  OwnerProtect on/off         Don't shoot owner ?
                    } else if (abbrP(command, "ow")) {
                        noShootOwner = onOff(sparam);

                    //  Push n                      Push avatars hit with impulse n
                    } else if (abbrP(command, "pu")) {
                        pushImpulse = fparam;

                    //  Range n                     Cannon firing range (metres)
                    } else if (abbrP(command, "ra")) {
                        probeRange = fparam;
                        //  Adjust displayed beam size to reflect firing range
                        vector cvel = llGetVel();
                        vector beamSize = llList2Vector(llGetLinkPrimitiveParams(lBeam,
                            [ PRIM_SIZE ]), 0);
                        beamSize.z = probeRange * 2;
                        //  Can't change size of physical prim, hence this two-step
                        llSetLinkPrimitiveParamsFast(lBeam,
                            [ PRIM_LINK_TARGET, LINK_ROOT, PRIM_PHYSICS, FALSE,
                              PRIM_LINK_TARGET, lBeam, PRIM_SIZE, beamSize,
                              PRIM_LINK_TARGET, LINK_ROOT, PRIM_PHYSICS, TRUE ]);
                        llSetVelocity(cvel, FALSE);

                    //  Sensor n                    Avatar sensor range, metres
                    } else if (abbrP(command, "se")) {
                        llSensorRemove();
                        visualRange = fparam;
                        if (visualRange > 0) {
                            if (defender) {
                                //  Look for attack drones
                                llSensorRepeat("Attack Drone", NULL_KEY, SCRIPTED, visualRange, PI, 0.5);
                            } else {
                                //  Look for avatars
                                llSensorRepeat("", NULL_KEY, AGENT, visualRange, PI, 0.5);
                            }
                        }

                    //  Trace on/off                Enable/disable trace output
                    /* IF TRACE */
                    } else if (abbrP(command, "tr")) {
                        trace = onOff(sparam);
                    /* END TRACE */

                    //  Volume v                    Volume of fire sound
                    } else if (abbrP(command, "vo")) {
                        fireVolume = fparam;

                    } else {
                        tawk("Unknown cannon setting.");
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

            //  Don't look for targets while the cannon is recharging

            if (t < fireNext) {
                return;
            }

            //  If boredom expired, start paying attention to target again

            if (!defender) {
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
            }

            //  Scan the sensor finds and build a list of nearby targets

            vector birdPos = llGetPos();

            for (i = 0; i < ndet; i++) {
                key k = llDetectedKey(i);
                /*  We include a potential target only if we're not bored
                    with it and, if noOwner is set, if it isn't our owner.  */
                if (((!noShootOwner) || (k != owner)) && ((!bored) || (k != kBored))) {
                    list det = llGetObjectDetails(k, [ OBJECT_NAME, OBJECT_POS ]);
                    string oname = llList2String(det, 0);
                    integer isNPC = FALSE;
                    /*  If this is not an avatar, test whether it is an NPC.
                        Note that if NPCs is not set, we don't need to do this
                        test because the sensor scan will return only avatars.  */
                    if (defender || (!NPCs) || (llList2String(det, 2) == "") ||
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
                            tawk("Drone " + (string) bird_number + " sees " + oname + " at " +
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
                    if ((!defender) && (timeBored > 0) && (!bored) && (t >= timeStartBored)) {
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
            if (currTarget != <-1, -1, -1>) {
                revokeTarget("not seen");
            }
        }

        /*  The timer is used to trigger casting a ray in the
            direction of the laser cannon and, if it hits one
            or more avatars trigger display of the beam, playing
            the shoot sound, and rezzing the Explosion object at
            the location of the hit.  */

        timer() {
            float t = llGetTime();

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
            }

            //  If firing, test if time to hide beam

            if (firing) {
                if (llGetTime() >= t) {
                    firing = FALSE;
                    showBeam(0);
                }
            }

            //  Cast a ray along the laser beam looking for targets

            if (t >= fireNext) {                    // Ignore if cannon recharging
                rotation r = llGetRot();
                vector p = llGetPos();
                float probeStart = 0;               // Start of beam in metres
                integer nhits = 0;
                float closest = 1e20;
                key ckey;
                vector cwhere;
                list rcr;
                integer rcstat;
                if (!defender) {
                    integer rej =  RC_REJECT_PHYSICAL | RC_REJECT_NONPHYSICAL;
                    integer maxhits = 1;
                    if (NPCs) {
                        rej = 0;
                        maxhits = 5;
                    }
                    rcr = llCastRay(p + <0, 0, probeStart> * r,
                        p + (< 0, 0, probeRange > * r),
                        [ RC_REJECT_TYPES, rej,
                          RC_MAX_HITS, maxhits ]);
                    rcstat = llList2Integer(rcr, -1);

                    //  Scan the hits and remember the position of the closest

                    if (rcstat > 0) {
                        integer i;
                        for (i = 0; i < rcstat; i++) {
                            key what = llList2Key(rcr, i * 2);
                            /*  Is this a hit on a valid target?  We exclude our owner
                                if noShootOwner is set, and always exclude an avatar
                                sitting on the drone.  If NPCs is set, we only include
                                objects whose name is "[NPC]".  */
                            if (((!noShootOwner) || (what != owner)) &&
                                (what != llAvatarOnSitTarget())) {
                                list odet = [ ];
                                string oname = "";
                                string octime = "";
                                if (NPCs) {
                                    odet = llGetObjectDetails(what,
                                        [OBJECT_NAME, OBJECT_CREATION_TIME ]);
                                    oname = llList2String(odet, 0);
                                    octime = llList2String(odet, 1);
                                }
                                /*  If NPCs is not set, we will only receive hits on
                                    valid targets from the ray cast.  If it is set, we
                                    must distinguish hits on targets from hits on other
                                    objects.  We do this by first checking the creation
                                    time, which will be the null string if the hit is
                                    on an avatar, which is a target.  Otherwise, we consider
                                    the hit on an object a target only if its object name is
                                    "[NPC]".  */

                                if ((!NPCs) || (octime == "") ||
                                    oname == "[NPC]") {
                                    vector where = llList2Vector(rcr, (i * 2) + 1);
                                    float dist = llVecDist(p, where);
                                    string which = "Ground";
                                    if (what != NULL_KEY) {
                                        which = llKey2Name(what);
                                    }
                                    nhits++;
                                    if (dist < closest) {
                                        closest = dist;
                                        ckey = what;
                                        cwhere = where;
                                    }
                                }
                            }
                        }
                    }
                }

                if (nhits > 0) {
                    firing = TRUE;
                    fireEnd = t + fireTime;
                    fireNext = t + fireRechargeTime;
                    showBeam(beamAlpha);

                    //  Son et lumière
                    if (fireVolume > 0) {
                        llPlaySound("Pew!", fireVolume);
                    }
                    if (explode) {
                        llRezObject("Explosion", cwhere, ZERO_VECTOR, ZERO_ROTATION, TRUE);
                    }

                    /*  If damage set and permitted here, inflict upon hit avatar.
                        We do this by rezzing an invisible  "Damage Bullet" next
                        to the avatar, which will immediately collide with it,
                        destroying itself and inflicting the damage.  */

                    if (damage > 0) {
                        vector hitctr = llList2Vector(llGetObjectDetails(ckey, [ OBJECT_POS ]), 0);
                        if ((llGetParcelFlags(hitctr) & PARCEL_FLAG_ALLOW_DAMAGE) != 0) {
                            llRezObject("Damage Bullet", hitctr + <0.1, 0.1, 0>,
                                ZERO_VECTOR, ZERO_ROTATION, (integer) llRound(damage * 1000));
                        }
                    }

                    /*  On collision with an avatar, administer a swift push.
                        We determine the direction and magnitude of the push
                        based upon the normalised direction vector from the
                        position of the impact and our current position and the
                        pushImpulse parameter.

                        The rather complex way push permissions work complicates
                        this matter.  We only push if pushImpulse is nonzero.  If
                        the parcel is set to No Pushing, then the owner (or group
                        member if the parcel is group-owner) can push, but others
                        cannot.  We apply all of these rules to decide whether to
                        push or treat this as a regular impact with a non-target.  */

                    if ((pushImpulse > 0) &&
                        (((llGetParcelFlags(cwhere) & PARCEL_FLAG_RESTRICT_PUSHOBJECT) == 0) ||
                        llOverMyLand(owner))) {
                        llPushObject(ckey, llVecNorm(cwhere - p) * pushImpulse,
                            ZERO_VECTOR, FALSE);
                    }

                    /*  If the avatar we hit is seated on a bird, send the bird
                        a EJECT message to kick it off with llUnSit().  Note that
                        Attack Drones do not hesitate to shoot avatars on other
                        Attac Drones: shooting avatars is what they do!  */

                    key seatedOn = llList2Key(llGetObjectDetails(ckey,
                        [ OBJECT_ROOT ]), 0);
                    if (seatedOn != ckey) {
                        llRegionSayTo(seatedOn, birdChannel,  llList2Json(JSON_ARRAY,
                            [ "EJECT", 0, bird_number, ckey, ourKey, deployer ]));
                    }
                } else {

                    /*  No hits on avatars.  Check for hits on hostile
                        drones.  */

                    string aggressor = "Defender Drone";
                    if (defender) {
                        aggressor = "Attack Drone";
                    }
                    rcr = llCastRay(p + <0, 0, probeStart> * r,
                        p + (< 0, 0, probeRange > * r),
                        [ RC_REJECT_TYPES,
                            RC_REJECT_AGENTS | RC_REJECT_NONPHYSICAL | RC_REJECT_LAND,
                          RC_DETECT_PHANTOM, TRUE,
                          RC_MAX_HITS, 3 ]);
                    rcstat = llList2Integer(rcr, -1);
                    nhits = 0;

                    //  Scan the hits and remember the position of the closest

                    closest = 1e20;
                    if (rcstat > 0) {
                        integer i;
                        for (i = 0; i < rcstat; i++) {
                            key what = llList2Key(rcr, i * 2);
                            if (what != ourKey) {
                                string which = llKey2Name(what);
                                if (which == aggressor) {
                                    vector where = llList2Vector(rcr, (i * 2) + 1);
                                    float dist = llVecDist(p, where);
                                    nhits++;
                                    if (dist < closest) {
                                        closest = dist;
                                        ckey = what;
                                        cwhere = where;
                                    }
                                }
//else { tawk("Bird " + (string) bird_number + " sees " + which); }
                            }
                        }

                        if (nhits > 0) {
//tawk("Bird " + (string) bird_number + " attacking " + llKey2Name(ckey) +
//    " " + llList2String(llGetObjectDetails(ckey, [ OBJECT_DESC ]), 0) +
//    " at " + (string) cwhere + ", range " + (string) closest);
                            firing = TRUE;
                            fireEnd = t + fireTime;
                            fireNext = t + fireRechargeTime;
                            showBeam(beamAlpha);

                            //  Son et lumière
                            if (fireVolume > 0) {
                                llPlaySound("Pew!", fireVolume);
                            }
                            //  Send hit message to attacked bird
                            llRegionSayTo(ckey, birdChannel,  llList2Json(JSON_ARRAY,
                                [ "HIT", 0, bird_number, ourKey ]));
                        }
                    }
                }
            }
        }
    }
