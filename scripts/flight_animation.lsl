     /*
                       Flight Animation

                        by John Walker

        This script handles the animesh animation of a flying bird.
        The animation, "Bird flapping and looking", consists of a
        period of wing flapping followed by gliding while the
        head looks around.  We use this in the following manner.
        Whenever we receive notification from the Bird script that
        the bird has turned sharply, we restart the animation so
        the flapping resumes.  This will automatically transition to
        gliding.  If we still haven't turned by the end of the clip,
        we stop the animation with wings level waiting for the next
        turn to resume flapping.

    */

    string anim =  "Bird flapping and looking";
    float animL = 6;                // Animation length, seconds
    float flap = 1.0472;  // (60 deg)  Flap on turn sharper than this (radians)
    integer animStopped = FALSE;    // Is animation stopped ?
    integer velrcv = FALSE;         // Have we received a velocity notification ?
    integer hatched = FALSE;        // Were we hatched by the deployer ?
    vector lastvel = ZERO_VECTOR;   // Last velocity

    //  Link messages

    integer LM_BI_VELOCITY = 12;        // Notification of change in velocity
    integer LM_BI_VELREQ = 13;          // Request velocity notification

    //  stopAnimations  --  Stop any running animations

    stopAnimations() {
            list animn = llGetObjectAnimationNames();
//llOwnerSay("Running animations: " + llList2CSV(animn));
            integer i;

            for (i = 0; i < llGetListLength(animn); i++) {
                llStopObjectAnimation(llList2String(animn, i));
//llOwnerSay("Stopping " + llList2String(animn, i));
            }
    }

    default {
        on_rez(integer start_param) {
//llOwnerSay("Anim on_rez " + (string) start_param);
            stopAnimations();
            hatched = start_param > 0;
            if (hatched) {
                //  Only start animation if hatched by the deployer
                llStartObjectAnimation(anim);
                llSetTimerEvent(animL);
                animStopped = FALSE;
//llOwnerSay("Starting animation at rez.");
                //  Request velocity change notifications from Bird script
                llMessageLinked(LINK_THIS, LM_BI_VELREQ,
                    llList2Json(JSON_ARRAY, [ TRUE ]), NULL_KEY);
            }
        }

        //  Process messages from other scripts

        link_message(integer sender, integer num, string str, key id) {
//llOwnerSay("Bird message sender " + (string) sender + "  num " + (string) num + "  str " + str + "  id " + (string) id);

            //  LM_BI_VELOCITY (12): Change in velocity

            if (num == LM_BI_VELOCITY) {
                list m = llJson2List(str);
                vector vel = (vector) llList2String(m, 0);  // Velocity
                float turnang = llList2Float(m, 1);         // Turn angle
                velrcv = TRUE;                  // We've received a notification
                integer flappy = FALSE;

                if (turnang > flap) {
                    //  Flap on sharp turn
                    flappy = TRUE;
                } else if ((lastvel.z < 0) && (vel.z > 0)) {
                    //  Flap on start of climb
                    flappy = TRUE;
                }

                if (flappy) {
                    if (!animStopped) {
                        llStopObjectAnimation(anim);
                    }
                    llStartObjectAnimation(anim);
                    llSetTimerEvent(animL);
                    animStopped = FALSE;
//llOwnerSay("Re-starting animation.");
                }
                lastvel = vel;
            }
        }

        /*  The timer is used to stop the animation at the end
            of the glide phase, leaving the bird with wings spread
            until receipt of a velocity message indicates we should
            restart it in the flapping phase.  */

        timer() {
            if (!velrcv) {
                /*  Due to start-up race conditions, we can't be guaranteed
                    the Bird script will receive the LM_BI_VELREQ we send
                    in state_entry.  Until we receive a LM_BI_VELOCITY,
                    keep re-sending the LM_BI_VELREQ.  */
                llMessageLinked(LINK_THIS, LM_BI_VELREQ,
                    llList2Json(JSON_ARRAY, [ TRUE ]), NULL_KEY);
//llOwnerSay("Repeating velocity request.");
                llSetTimerEvent(0.25);
            } else {
                llSetTimerEvent(0);
//llOwnerSay("Stop animation at timer.");
                llStopObjectAnimation(anim);
                animStopped = TRUE;
            }
        }
    }
