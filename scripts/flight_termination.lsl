    /*
                      Flight Termination

                        by John Walker

        This script handles the explosion effect when the drone is hit
        by the laser cannon of a hostile drone.

    */

    integer bird_number;                // Our bird number
    string ourName;                     // Our object name
    integer defender;                   // Are we a defender ?

    integer birdChannel = -982449722;   // Channel for communicating with birds
    float lifeTime = 2;                 // How long we live
    integer volume = 10;                // Kaboom volume
    string kaboom = "Kaboom!";          // Kaboom sound clip

    integer flash = TRUE;               // Show explosion effect ?
    integer bang = TRUE;                // Play kaboom clip ?

    vector colStart = <1, 0.647, 0>;    // Explosion start colour
    vector colEnd = <0.7, 0.25, 0.25>;  // Explosion end colour

    //  Generate sound and light show for an impact

    integer exploding = FALSE;      // Explosion particle effect running ?

    splodey() {
        if (flash) {
            integer particle_count = 200;
            float particle_scale = 0.2;
            float particle_speed = 1;
            float particle_lifetime = 1;

            llParticleSystem([
                PSYS_PART_FLAGS,            PSYS_PART_INTERP_COLOR_MASK | PSYS_PART_INTERP_SCALE_MASK |
                    PSYS_PART_EMISSIVE_MASK,
                PSYS_SRC_PATTERN,           PSYS_SRC_PATTERN_EXPLODE,
                PSYS_PART_START_COLOR,      colStart,
                PSYS_PART_END_COLOR,        colEnd,
                PSYS_PART_START_ALPHA,      0.5,
                PSYS_PART_END_ALPHA,        0,
                PSYS_PART_START_SCALE,      <particle_scale, particle_scale, 0>,
                PSYS_PART_END_SCALE,        <particle_scale * 2 + particle_lifetime,
                                             particle_scale * 2 + particle_lifetime, 0>,
                PSYS_PART_MAX_AGE,          particle_lifetime,
                PSYS_SRC_ACCEL,             <0, 0, 0>,
                PSYS_SRC_BURST_RATE,        20,
                PSYS_SRC_BURST_PART_COUNT,  particle_count / 2,
                PSYS_SRC_BURST_RADIUS,      0,
                PSYS_SRC_BURST_SPEED_MIN,   particle_speed / 3,
                PSYS_SRC_BURST_SPEED_MAX,   particle_speed * (2.0 / 3),
                PSYS_SRC_MAX_AGE,           particle_lifetime / 4,
                PSYS_SRC_OMEGA,             <0, 0, 0>
            ]);
        }

        if (bang && (volume > 0)) {
            llPlaySound(kaboom, volume);
            exploding = TRUE;
            llSetTimerEvent(lifeTime);      // Start timer to cancel particle system
        }
    }

    default {
        on_rez(integer start_param) {
            llParticleSystem([ ]);
            if (start_param > 0) {
                bird_number = start_param;
                ourName = llGetObjectName();
                defender = ourName == "Defender Drone";
                if (defender) {
                    colStart = <0.5, 1, 0>;
                    colEnd = <0.25, 0.5, 0.25>;
                }
                llListen(birdChannel, "", NULL_KEY, ""); // Listen for messages from other birds
            }
        }

        state_entry() {
            llPreloadSound(kaboom);
            llParticleSystem([ ]);
        }

        //  The listen event handles HIT commands from hostile drones

        listen(integer channel, string name, key id, string message) {
//llOwnerSay("FT: listen channel " + (string) channel + " name " + name + " id " + (string) id + " message " + message);
            if (channel == birdChannel) {
                list msg = llJson2List(message);
                string ccmd = llList2String(msg, 0);

                //  [ "HIT", bird_number, sender_number, sender_key ]

                if (ccmd == "HIT") {
                    integer bnhit = llList2Integer(msg, 1);
                    if ((bnhit == 0) || (bnhit == bird_number)) {
//llOwnerSay("Hit by bird " + (string) llList2Integer(msg, 2));
                        llSetLinkPrimitiveParamsFast(LINK_SET,      // Disappear bird immediately
                            [ PRIM_COLOR, ALL_SIDES, <0, 0, 0>, 0 ]);
                        splodey();
                    }
                }
            }
        }

        timer() {
            llDie();                        // We're out of here
        }

        /* IF TOUCH_EXPLOSION
        touch_start(integer i) {
            //  Trigger explosion effects by touch for debugging and fine-tuning
            flash = bang = TRUE;
            splodey();                      // Start the explosion effects
            llSetTimerEvent(0);             // Cancel self-destruct timer
            llSleep(lifeTime + 0.25);       // Allow the explosion to play out
            llParticleSystem([ ]);          // Cancel the particle system
        }
        /* END TOUCH_EXPLOSION */
    }
