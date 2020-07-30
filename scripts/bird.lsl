    /*
                           Fourmilab Bird

                           by John Walker

    */

    string ourName;                     // Our object name
    key owner;                          // UUID of owner
    key deployer;                       // ID of deployer who hatched us
    integer initState = 0;              // Initialisation state
    vector prAxis = <0, 0, 1>;          // Principal axis (direction of flight)

    vector birdPos;                     // Current bird position
    vector birdVel;                     // Current bird direction (normalised)
    integer velChanged;                 // Velocity changed

    list birds;                         // Other birds nearby

    integer birdChannel = -982449722;   // Channel for communicating with birds
    string ypres = "B?+:$$";            // It's pronounced "Wipers"

    //  Cage dimensions and corners in region co-ordinates from deployer

    vector initialPos;                  // Initial bird position
    vector deployerPos;                 // Deployer position (centre of cage)
    vector initialVelDir;               // Initial velocity (normalised)
    float initialVelMag;                // Initial speed m/sec
    float cageRadius;                   // Length and breadth of cage
    float cageHeight;                   // Height of cage
    vector cageCornerLow;               // Low co-ordinate cage corner
    vector cageCornerHigh;              // High co-ordinate cage corner
    vector cageEdgeLow;                 // Low co-ordinate cage edge
    vector cageEdgeHigh;                // High co-ordinate cage edge
    integer flatland;                   // Are we constrained to X-Y plane ?
    float chirp;                        // Chirp on sharp turn (radians)
    float volume;                       // Volume for chirps
    string chirpName = "";              // Name of chirp sound clip in inventory
    float chirpLength = 0.6;            // Length of chirp sound clip, seconds
    float chirpReady;                   // When can we next chirp ?

    /*  The following settings control the behaviour of the bird.
        They are all set by a SETTINGS message on BirdChannel.  */

    integer actions;                    // Which behaviours are enabled ?
                                        //      1   Constrain to cage
                                        //      2   Limit maximum speed
                                        //      4   Seek centre of mass
                                        //      8   Avoid collisions
                                        //     16   Match velocities
                                        //     32   Seek target
    float avoidFactor;                  // Velocity adjustment to avoid collision
    float centeringFactor;              // Velocity adjustment toward centre of mass
    float edgeMargin;                   // Margin at edges of cage
    float lifeTime;                     // Lifetime in seconds
    float matchingFactor;               // Velocity adjustment to match average velocity
    float minDistance;                  // Distance maintained from other birds
    float speedLimit;                   // Maximum flight velocity
    float timerUpdate;                  // Timer update interval
    float turnFactor;                   // Velocity to turn away from edge
    float visualRange;                  // Visual (llSensor) range, metres
    float targetFactor;                 // Authority of turn toward target

    vector currTarget;                  // Current target

    /*  Standard colour names and RGB values.  This is
        based upon the resistor colour code.  */

    list colours = [
        "black",   <0, 0, 0>,                   // 0
        "brown",   <0.3176, 0.149, 0.1529>,     // 1
        "red",     <0.8, 0, 0>,                 // 2
        "orange",  <0.847, 0.451, 0.2784>,      // 3
        "yellow",  <0.902, 0.788, 0.3176>,      // 4
        "green",   <0.3216, 0.5608, 0.3961>,    // 5
        "blue",    <0.00588, 0.3176, 0.5647>,   // 6
        "violet",  <0.4118, 0.4039, 0.8078>,    // 7
        "grey",    <0.4902, 0.4902, 0.4902>,    // 8
        "white",   <1, 1, 1>                    // 9

//      "silver",  <0.749, 0.745, 0.749>,       // 10%
//      "gold",    <0.7529, 0.5137, 0.1529>     // 5%
    ];

    float alpha = 1;                    // Transparency of faces

    integer bird_number;                // Our bird number
    float startTime;                    // Time we were hatched
    vector pathColour;                  // Colour of particle trail, if enabled

    key whoDat;                         // User with whom we're communicating
    integer paths;                      // Draw particle trail behind birds ?
    /* IF TRACE */
    integer trace = FALSE;              // Trace operations
    integer b1;                         // Used to trace only bird 1
    /* END TRACE */
    integer notifyVel = FALSE;          // Notify other scripts of velocity changes ?

    //  Link messages

    integer LM_BI_TARGET = 11;          // Target detected
    integer LM_BI_VELOCITY = 12;        // Notification of change in velocity
    integer LM_BI_VELREQ = 13;          // Request velocity notification

    /* IF TRACE */

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
    /* END TRACE */

    /*  flRotBetween  --  Re-implementation of llRotBetween() which
                          actually works.

                          Written by Moon Metty, optimized by Strife Onizuka.
                          This version keeps the axis in the XY-plane, in the
                          case of anti-parallel vectors (unlike the current
                          LL implementation).  -- Moon Metty  */

    rotation flRotBetween(vector a, vector b) {
        //  Product of lengths of argument vectors
        float aabb = llSqrt((a * a) * (b * b));
        if (aabb != 0) {
            //  Normalised dot product of arguments (cosine of angle between)
            float ab = (a * b) / aabb;
            //  Normalised cross product of arguments
            vector c = < (a.y * b.z - a.z * b.y) / aabb,
                         (a.z * b.x - a.x * b.z) / aabb,
                         (a.x * b.y - a.y * b.x) / aabb >;
            //  Squared of length of the normalised cross product (sine of angle between)
            float cc = c * c;
            //  Test for parallel or anti-parallel arguments
            if (cc != 0) {
                //  Not (anti)parallel
                float s;
                if (ab > -0.707107) {
                    //  Use cosine to compute s element of quartenion
                    s = 1 + ab;
                } else {
                    //  Use sine to compute s element of quarternion
                    s = cc / (1 + llSqrt(1 - cc)); // use the sine to adjust the s-element
                }
                float m = llSqrt(cc + s * s); // the magnitude of the quaternion
                return <c.x / m, c.y / m, c.z / m, s / m>; // return the normalized quaternion
            }
            if (ab > 0) {
                //  Arguments are parallel or anti-parallel
                return ZERO_ROTATION;
            }
            //  Length of first argument projected onto the X-Y plane
            float m = llSqrt(a.x * a.x + a.y * a.y);
            if (m != 0) {
                /*  Arguments are not both parallel to the X-Y plane:
                    rotate around an axis in the X-Y plane.  */
                return <a.y / m, -a.x / m, 0, 0>; // return a rotation with the axis in the X-Y plane
            }
            /*  Otherwise, both arguments are parallel to the Z axis.
                Rotate around the X axis.  */
            return <1, 0, 0, 0>;
        }
        //  Arguments are too small: return zero rotation
        return ZERO_ROTATION;
    }

    //  avoidEdges  --  Adjust velocity to avoid edges of the cage

    avoidEdges() {
        if (actions & 1) {
            if (birdPos.x <= cageEdgeLow.x) {
                birdVel.x += turnFactor;
                velChanged = TRUE;
                /* IF TRACE */
                if (trace && b1) {
                    tawk("Bird " + (string) bird_number + " avoid X- edge.  Pos: " +
                        efv(birdPos - deployerPos));
                }
                /* END TRACE */
            } else if (birdPos.x >= cageEdgeHigh.x) {
                birdVel.x -= turnFactor;
                velChanged = TRUE;
                /* IF TRACE */
                if (trace && b1) {
                    tawk("Bird " + (string) bird_number + " avoid X+ edge.  Pos: " +
                        efv(birdPos - deployerPos));
                }
                /* END TRACE */
            }
            if (birdPos.y <= cageEdgeLow.y) {
                birdVel.y += turnFactor;
                velChanged = TRUE;
                /* IF TRACE */
                if (trace && b1) {
                    tawk("Bird " + (string) bird_number + " avoid Y- edge.  Pos: " +
                        efv(birdPos - deployerPos));
                }
                /* END TRACE */
            } else if (birdPos.y >= cageEdgeHigh.y) {
                birdVel.y -= turnFactor;
                velChanged = TRUE;
                /* IF TRACE */
                if (trace && b1) {
                    tawk("Bird " + (string) bird_number + " avoid Y+ edge.  Pos: " +
                        efv(birdPos - deployerPos));
                }
                /* END TRACE */
            }
            if (birdPos.z <= cageEdgeLow.z) {
                birdVel.z += turnFactor;
                velChanged = TRUE;
                /* IF TRACE */
                if (trace && b1) {
                    tawk("Bird " + (string) bird_number + " avoid Z- edge.  Pos: " +
                        efv(birdPos - deployerPos));
                }
                /* END TRACE */
            } else if (birdPos.z >= cageEdgeHigh.z) {
                birdVel.z -= turnFactor;
                velChanged = TRUE;
                /* IF TRACE */
                if (trace && b1) {
                    tawk("Bird " + (string) bird_number + " avoid Z+ edge.  Pos: " +
                        efv(birdPos - deployerPos));
                }
                /* END TRACE */
            }
        }
    }

    //  maxSpeed  --  Constrain speed to maximum

    maxSpeed() {
        if (actions & 2) {
            float speed = llVecMag(birdVel);
            if (speed > (speedLimit * 0.001)) {
                birdVel = llVecNorm(birdVel) * speedLimit;
                /* IF TRACE */
                if (trace && b1) {
                    tawk("Bird " + (string) bird_number + " speed limit enforced.  Was " +
                        eff(speed) + ", now " + eff(speedLimit) + ".");
                }
                /* END TRACE */
            }
        }
    }

    //  flyCentreMass  --  Fly toward the centre of mass of nearby birds

    flyCentreMass() {
        if (actions & 4) {
            integer i;
            integer nabes = 0;
            vector ctrMass = ZERO_VECTOR;

            for (i = 0; i < llGetListLength(birds); i += 4) {
                if (llList2Float(birds, i) <= visualRange) {
                    ctrMass += llList2Vector(birds, i + 2);
                    nabes++;
                }
            }

            if (nabes > 0) {
                ctrMass /= nabes;
                birdVel += (ctrMass - birdPos) * centeringFactor;
                velChanged = TRUE;
                /* IF TRACE */
                if (trace && b1) {
                    tawk("Bird " + (string) bird_number + " fly centre " +
                        efv((ctrMass - birdPos) * centeringFactor) + ".");
                }
                /* END TRACE */
            }
        }
    }

    //  avoidCollisions  --  Avoid collisions with nearby birds

    avoidCollisions() {
        if (actions & 8) {
            integer i;
            vector dodge = ZERO_VECTOR;

            for (i = 0; i < llGetListLength(birds); i += 4) {
                if (llList2Float(birds, i) <= minDistance) {
                    dodge += birdPos - llList2Vector(birds, i + 2);
                    velChanged = TRUE;
                    /* IF TRACE */
                    if (trace && b1) {
                        tawk("Bird " + (string) bird_number + " dodge bird " +
                            (string) llList2Integer(birds, i + 1) + " " +
                            efv((birdPos - llList2Vector(birds, i + 2)) * avoidFactor) + ".");
                    }
                    /* END TRACE */
                }
            }
            birdVel += dodge * avoidFactor;
        }
    }

    //  matchVelocities  --  Match velocities of nearby birds

    matchVelocities() {
        if (actions & 16) {
            integer i;
            integer nabes = 0;
            vector meanVel = ZERO_VECTOR;

            for (i = 0; i < llGetListLength(birds); i += 4) {
                if (llList2Float(birds, i) <= visualRange) {
                    meanVel += llList2Vector(birds, i + 3);
                    nabes++;
                }
            }

            if (nabes > 0) {
                meanVel /= nabes;
                birdVel += (meanVel - birdVel) * matchingFactor;
                velChanged = TRUE;
                /* IF TRACE */
                if (trace && b1) {
                    tawk("Bird " + (string) bird_number + " match velocity with " +
                        (string) nabes + " neighbours " +
                        efv((meanVel - birdVel) * matchingFactor) + ".");
                }
                /* END TRACE */
            }
        }
    }


    //  flyTarget  --  Fly toward the target

    flyTarget() {
        if (actions & 32) {
            if (currTarget.x >= 0) {
                birdVel += (currTarget - birdPos) * targetFactor;
                velChanged = TRUE;
                /* IF TRACE */
                if (trace && b1) {
                    tawk("Bird " + (string) bird_number + " fly target " +
                        efv((currTarget - birdPos) * targetFactor) + ".");
                }
                /* END TRACE */
            }
        }
    }


    //  updateVelocity  --  Update velocity and bearing of bird

    updateVelocity(vector bVel) {
        if (flatland) {
            bVel.z = 0;         // Force Z velocity to 0 to avoid round-off
        }
        vector bVelN = llVecNorm(bVel);         // Normalised bird velocity
        vector cfwd = llRot2Up(llGetRot());     // Current pointing direction
        float turnang = llAcos(bVelN * cfwd);   // Current turn angle

        //  If we're turning sufficiently sharply, chirp
        if ((chirp > 0) && (volume > 0) && (chirpName != "")) {
            if (turnang >= chirp) {
                float t = llGetTime();
                if (t > chirpReady) {
                    llPlaySound(chirpName, volume);
                    chirpReady = t + chirpLength;
                }
            }
        }
        llSetVelocity(bVel, FALSE);
        if (llVecMag(bVel) > 0.01) {
            //  Only set bearing if actually moving
            rotation vdir = flRotBetween(prAxis, bVelN);
            vector vdown = llRot2Fwd(vdir);
            /*  We want to keep the model "feet down" in region
                co-ordinates.  If it's feet up, rotate 180 degrees
                around the principal axis to put feet down.  */
            if (vdown.z > 0) {
                vdir =  llAxisAngle2Rot(prAxis, PI) * vdir;
            }
            llRotLookAt(vdir, 1, 0.4);
        }
        /*  If another script has requested it, notify of change in
            velocity and turn direction.  */
        if (notifyVel) {
            llMessageLinked(LINK_THIS, LM_BI_VELOCITY,
                llList2Json(JSON_ARRAY, [ bVel, turnang ]), NULL_KEY);
        }
    }

    default {

        state_entry() {
            whoDat = owner = llGetOwner();
        }

        on_rez(integer start_param) {
            initState = 0;
            //  If start_param is zero, this is a simple manual rez
            if (start_param > 0) {
                bird_number = start_param;
                /* IF TRACE */
                b1 = bird_number == 1;
                /* END TRACE */

                ourName = llGetObjectName();
                deployer = llList2Key(llGetObjectDetails(llGetKey(),
                                         [ OBJECT_REZZER_KEY ]), 0);

                /*  Set colour of faces based upon bird number.  If
                    our description is "Universal Flying Object" and
                    we're the root prim of a link set, hide this link
                    so only the model to which we've been linked will
                    show.  In that case, we don't modify the colour of
                    the model based upon bird number.  */

                if ((llGetLinkNumber() == LINK_ROOT) &&
                    (llSubStringIndex(llList2String(llGetLinkPrimitiveParams(LINK_ROOT,
                        [ PRIM_DESC ]), 0), "Universal Flying Object")) >= 0) {
                    llSetLinkPrimitiveParamsFast(LINK_THIS,
                        [ PRIM_COLOR, ALL_SIDES, ZERO_VECTOR, 0 ]);
                    prAxis = <0, 0, 1>;             // All UFO models use a Z principal axis
                } else {
                    //  If this is the simple bird silhouette, set top and bottom colour
                    pathColour = llList2Vector(colours, (bird_number % 10) * 2 + 1);
                    llSetLinkPrimitiveParamsFast(LINK_THIS,
                        [ PRIM_COLOR, 2, llList2Vector(colours,
                            ((bird_number % 100) / 10) * 2 + 1), alpha,
                          PRIM_COLOR, 4, pathColour, alpha ]
                    );
                }

                //  Process principal axis specification in the prim's description
                string pdesc = llList2String(llGetLinkPrimitiveParams(LINK_THIS,
                                                [ PRIM_DESC ]), 0);
                integer pdi = llSubStringIndex(pdesc, "ax=<");
                if (pdi >= 0) {
                    prAxis = (vector) llGetSubString(pdesc, pdi + 3,
                        pdi + llSubStringIndex(llGetSubString(pdesc, pdi, -1), ">"));
                }

                //  Mark no target designated
                currTarget = <-1, -1, -1>;

                //  Change the prim's description to its bird number
                string desc = "Bird " + (string) bird_number;
                llSetLinkPrimitiveParamsFast(LINK_THIS,
                    [ PRIM_DESC, desc ]);

                llSetBuoyancy(1);       // Set buoyancy of object: 0 = fall, 1 = float
                llSetStatus(STATUS_PHYSICS | STATUS_PHANTOM | STATUS_DIE_AT_EDGE, TRUE);

                //  Set sit target

                llSitTarget(<-0.8, 0, 0>, llAxisAngle2Rot(<0, 1, 0>, -PI_BY_TWO));
                llSetCameraEyeOffset(<-1.2, 0, -1.2>);
                llSetCameraAtOffset(<-1, 0, 1>);

                /*  Get name of chirp sound clip.  If there is more than
                    one clip in the inventory, each bird chooses one at
                    random.  We exclude sounds that contain "!", which
                    are reserved for use by other scripts in the object.  */

                integer n = llGetInventoryNumber(INVENTORY_SOUND);
                if (n > 0) {
                    if (n > 1) {
                        integer j = -1;
                        while (j < 0) {
                            integer c = (integer) llFrand(n);
                            if (llSubStringIndex(llGetInventoryName(INVENTORY_SOUND, c), "!") == -1) {
                                j = c;
                            }
                        }
                        n = j;
                    } else {
                        n = 0;
                    }
                    chirpName = llGetInventoryName(INVENTORY_SOUND, n);
                    integer l = llSubStringIndex(chirpName, ", time ");
                    if (l > 0) {
                        chirpLength = (float) llGetSubString(chirpName, l + 7, -1);
                    }
                }

                //  Listen for messages from deployer and other birds
                llListen(birdChannel, "", NULL_KEY, "");

                //  Inform the deployer that we are now listening
                llRegionSayTo(deployer, birdChannel,
                    llList2Json(JSON_ARRAY, [ "REZ", bird_number ]));

                chirpReady = 0;

                initState = 1;          // Waiting for SETTINGS and INIT
            }
        }

        //  The listen event handles message from the deployer and other birds

        listen(integer channel, string name, key id, string message) {

            if (channel == birdChannel) {
                list msg = llJson2List(message);
                string ccmd = llList2String(msg, 0);

                if (id == deployer) {

                    //  Message from Deployer

                    //  ypres  --  Destroy bird

                    if (ccmd == ypres) {
                        llDie();

                    //  LIST  --  List bird information

                    } else if (ccmd == "LIST") {
                        integer bnreq = llList2Integer(msg, 1);

                        if ((bnreq == 0) || (bnreq == bird_number)) {
                            string ccode = llList2String(colours, (bird_number % 10) * 2) + "/" +
                                           llList2String(colours, ((bird_number % 100) / 10) * 2);
                            integer mFree = llGetFreeMemory();
                            integer mUsed = llGetUsedMemory();

                            tawk("Bird " + (string) bird_number +
                                 " (" + ccode + ")" +
                                 "  Position: " + efv(llGetPos()) +
                                 "  Velocity: " + efv(llGetVel()) +
                                 "  Speed: " + eff(llVecMag(llGetVel())) +
                                 "\n    Script memory.  Free: " + (string) mFree +
                                    "  Used: " + (string) mUsed + " (" +
                                    (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)"
                                );
                        }

                    //  INIT  --  Set initial parameters after creation

                    } else if (ccmd == "INIT") {
                        if (bird_number == llList2Integer(msg, 1)) {
                            initialVelDir = (vector) llList2String(msg, 2);
                            initialVelMag = llList2Float(msg, 3);
                            deployerPos = (vector) llList2String(msg, 4);
                            cageRadius = llList2Float(msg, 5);
                            cageHeight = llList2Float(msg, 6);
                            initialPos = (vector) llList2String(msg, 7);
                            whoDat = llList2Key(msg, 8);
                            trace = llList2Integer(msg, 9);
                            cageCornerLow = (vector) llList2String(msg, 10);
                            cageCornerHigh = (vector) llList2String(msg, 11);
                            /* IF TRACE */
                            if (trace && b1) {
                                tawk("Bird " + (string) bird_number + " init: " + llList2CSV(msg));
                            }
                            /* END TRACE */

                            /* IF TRACE */
                            if (trace && b1) {
                                tawk("  Ready bird " + (string) bird_number +
                                     "\n    cageCornerLow " + efv(cageCornerLow) +
                                     "\n    cageCornerHigh " + efv(cageCornerHigh) +
                                     "\n    initialVelDir " + efv(initialVelDir) +
                                     "\n    initialVelMag " + eff(initialVelMag));
                            }
                            /* END TRACE */

                            initState = 2;                  // INIT received, waiting for SETTINGS
                        }

                    //  RESET  --  Restore initial position and velocity

                    } else if (ccmd == "RESET") {
                        llSetVelocity(ZERO_VECTOR, FALSE);
                        llLookAt(initialPos, 0.5, 0.5);
                        llMoveToTarget(initialPos, 0.05);
                        llSleep(0.25);
                        llStopLookAt();
                        llStopMoveToTarget();
                        updateVelocity(initialVelDir * initialVelMag);

                    //  SETTINGS  --  Set behavioural parameters

                    } else if (ccmd == "SETTINGS") {
                        integer bn = llList2Integer(msg, 1);
                        if ((bn == 0) || (bn == bird_number)) {
                            timerUpdate = llList2Float(msg, 2);
                            visualRange = llList2Float(msg, 3);
                            edgeMargin = llList2Float(msg, 4);
                            turnFactor = llList2Float(msg, 5);
                            centeringFactor = llList2Float(msg, 6);
                            minDistance = llList2Float(msg, 7);
                            avoidFactor = llList2Float(msg, 8);
                            matchingFactor = llList2Float(msg, 9);
                            speedLimit = llList2Float(msg, 10);
                            trace = llList2Integer(msg, 11);
                            actions = llList2Integer(msg, 12);
                            lifeTime = llList2Float(msg, 13);
                            paths = llList2Integer(msg, 14);
                            flatland = llList2Integer(msg, 15);
                            chirp = llList2Float(msg, 16);
                            volume = llList2Float(msg, 17);
                            targetFactor = llList2Float(msg, 18);
                        }
                        //  Compute margin of cage where birds turn
                        vector edgy = < edgeMargin, edgeMargin, edgeMargin >;
                        cageEdgeLow = cageCornerLow + edgy;
                        cageEdgeHigh = cageCornerHigh - edgy;

                        llSetTimerEvent(timerUpdate);   // Reset periodic update timer

                        /* IF TRACE */
                        if (trace && b1) {
                            tawk("Bird " + (string) bird_number + " received settings." +
                                "\n  timerUpdate " + eff(timerUpdate) +
                                "\n  visualRange " + eff(visualRange) +
                                "\n  edgeMargin " + eff(edgeMargin) +
                                "\n  turnFactor " + eff(turnFactor) +
                                "\n  centeringFactor " + eff(centeringFactor) +
                                "\n  minDistance " + eff(minDistance) +
                                "\n  avoidFactor " + eff(avoidFactor) +
                                "\n  matchingFactor " + eff(matchingFactor) +
                                "\n  speedLimit " + eff(speedLimit) +
                                "\n  targetFactor " + eff(targetFactor)

                                + "\n    trace " + (string) trace +
                                "\n    chirp " + eff(llRound(chirp * RAD_TO_DEG)) +
                                "\n    volume " + eff(volume) +
                                "\n    actions " + (string) actions +
                                "\n    lifeTime " + eff(lifeTime)

                                + "\n    cageEdgeLow " + efv(cageEdgeLow) +
                                "\n    cageEdgeHigh " + efv(cageEdgeHigh)
                            );
                        }
                        /* END TRACE */
                        if (initState == 2) {
                            initState = 3;                  // INIT and SETTINGS received, now flying
                            updateVelocity(initialVelDir * initialVelMag);
                            startTime = llGetTime();        // Remember when we started
                        }

                        //  Set or clear particle trail depending upon paths
                        if (paths) {
                            llParticleSystem(
                                [ PSYS_PART_FLAGS, PSYS_PART_EMISSIVE_MASK | PSYS_PART_INTERP_COLOR_MASK |
                                    PSYS_PART_RIBBON_MASK,
                                  PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_DROP,
                                  PSYS_PART_START_COLOR, pathColour,
                                  PSYS_PART_END_COLOR, pathColour,
                                  PSYS_PART_START_SCALE, <0.25, 0.25, 0.25>,
                                  PSYS_PART_END_SCALE, <0.25, 0.25, 0.25>,
                                  PSYS_SRC_MAX_AGE, 0,
                                  PSYS_PART_MAX_AGE, 3.0,
                                  PSYS_SRC_BURST_RATE, 0.0,
                                  PSYS_SRC_BURST_PART_COUNT, 20
                                ]);
                        } else {
                            llParticleSystem([ ]);
                        }
                    }
                } else {
                    //  Messages from other birds
                    if (ccmd == "EJECT") {
                        /*  EJECT message: un-sit seated avatar.  Note that we currently
                            accept EJECT messages from birds hatched by a different
                            deployer.  If you want to restrict this to only birds from
                            our own deployer, just add a test for:
                                llList2Key(msg, 5) == deployer
                            and ignore the EJECT if not TRUE.  */
                        key ekey = llList2Key(msg, 3);

                        if (ekey == llAvatarOnSitTarget()) {
                            llUnSit(ekey);
                        }
                    }
                }
            }
        }

        //  Process messages from other scripts

        link_message(integer sender, integer num, string str, key id) {
//llOwnerSay("Bird message sender " + (string) sender + "  num " + (string) num + "  str " + str + "  id " + (string) id);

            //  LM_BI_TARGET (11): Set target

            if (num == LM_BI_TARGET) {
                list m = llJson2List(str);
                currTarget = (vector) llList2String(m, 2);
                /* IF TRACE */
                if (trace && b1) {
                    tawk("Bird " + (string) bird_number + " target " +
                        llList2String(m, 1) + " at " +
                        efv(currTarget));
                }
                /* END TRACE */

            //  LM_BI_VELREQ (13): Request velocity and turn notifications

            } else if (num == LM_BI_VELREQ) {
                list m = llJson2List(str);
                notifyVel = llList2Integer(m, 0);
            }
        }

        //  Sensor scan results

        sensor(integer ndet) {
            integer i;

            birds = [ ];

            /* IF TRACE */
            if (trace && b1) {
                if (ndet == 0) {
                    tawk("No birds detected.");
                    return;
                }

                if (ndet >= 16) {
                    tawk("Warning: 16 birds were detected.  If more than 16\n" +
                         "   are within range, some will not have been found.");
                }
            }
            /* END TRACE */

            //  Scan the sensor finds and build a list of nearby birds

            birdPos = llGetPos();

            for (i = 0; i < ndet; i++) {
                key k = llDetectedKey(i);
                list det = llGetObjectDetails(k,
                    [   OBJECT_DESC,
                        OBJECT_POS,
                        OBJECT_VELOCITY ]);
                string desc = llList2String(det, 0);
                vector pos = llList2Vector(det, 1);
                vector vel = llList2Vector(det, 2);
                /* IF TRACE */
                if (trace && b1) {
                    tawk("Bird " + (string) bird_number + " sees " + desc + " at " +
                        efv(pos) + " velocity " + efv(vel));
                }
                /* END TRACE */
                integer bn = (integer) llGetSubString(desc, llSubStringIndex(desc, " ") + 1, -1);
                birds += [ llVecDist(pos, birdPos), bn, pos, vel ];
            }

            birds = llListSort(birds, 4, TRUE);

            birdVel = llGetVel();

            velChanged = FALSE;
            flyCentreMass();            // Turn toward centre of mass of nearby birds
            avoidCollisions();          // Avoid collisions with nearby birds
            matchVelocities();          // Match velocities with nearby birds

            //  If a change was commanded, apply it

            if (velChanged) {
                //  Repeat edge and speed constraint tests after sensor results
                avoidEdges();           // Turn if we're close to an edge
                maxSpeed();             // Enforce maximum speed
                /* IF TRACE */
                if (trace && b1) {
                    tawk("Bird " + (string) bird_number +
                        " sensor changed velocity to " + efv(birdVel) +
                        " speed " + eff(llVecMag(birdVel)));
                }
                /* END TRACE */
                updateVelocity(birdVel);
            }
        }

        timer() {

            //  Check for reaching end of lifeTime
            if (lifeTime > 0) {
                if ((llGetTime() - startTime) >= lifeTime) {
                    llDie();
                }
            }

            //  Hidden arguments/results to the functions below
            birdPos = llGetPos();
            birdVel = llGetVel();

            /* IF CAGE_CHECK
            //  Check whether bird has violated cage constraints
            if (birdPos.x < cageCornerLow.x) {
                tawk("Bird " + (string) bird_number + " X- cage violation by " +
                    efv(cageCornerLow - birdPos));
            }
            if (birdPos.x > cageCornerHigh.x) {
                tawk("Bird " + (string) bird_number + " X+ cage violation by " +
                    efv(birdPos - cageCornerHigh));
            }
            if (birdPos.y < cageCornerLow.y) {
                tawk("Bird " + (string) bird_number + " Y- cage violation by " +
                    efv(cageCornerLow - birdPos));
            }
            if (birdPos.y > cageCornerHigh.y) {
                tawk("Bird " + (string) bird_number + " Y+ cage violation by " +
                    efv(birdPos - cageCornerHigh));
            }
            /* END CAGE_CHECK */

            /*  Perform the adjustments which do not depend upon
                other birds.  We do them unconditionally here because
                if the sensor probe does not detect any other birds
                within visualRange, we don't get the sensor()
                call-back.  We could handle this from a no_sensor()
                return, but this is more responsive and simpler.  */
            velChanged = FALSE;
            avoidEdges();               // Turn if we're close to an edge
            maxSpeed();                 // Enforce maximum speed
            flyTarget();                // Fly toward designated target

            if (velChanged) {
                /* IF TRACE */
                if (trace && b1) {
                    tawk("Bird " + (string) bird_number +
                        " timer changed velocity to " + efv(birdVel) +
                        " speed " + eff(llVecMag(birdVel)));
                }
                /* END TRACE */
                updateVelocity(birdVel);
            }

            //  Now start the sensor probe to look for other birds

            llSensor(ourName, NULL_KEY, ACTIVE, visualRange, PI);
        }
    }
