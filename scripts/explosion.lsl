    /*
                        Explosion

                       by John Walker

        This object and script exists solely to produce the
        explosion when the laser bolt strikes a target.  It is
        rezzed by the Laser Cannon script at the location the
        llCastRay() struck the target.  After launching its
        particle system and playing the explosion sound, it
        deletes itself after a timed delay.

    */

    float lifeTime = 2;                 // How long we live

    //  Create particle system for impact effect

    splodey() {
        llParticleSystem([
            PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,

            PSYS_SRC_BURST_RADIUS, 0.1,

            PSYS_PART_START_COLOR, <1, 1, 1>,
            PSYS_PART_END_COLOR, <1, 1, 1>,

            PSYS_PART_START_ALPHA, 0.9,
            PSYS_PART_END_ALPHA, 0.0,

            PSYS_PART_START_SCALE, <0.3, 0.3, 0>,
            PSYS_PART_END_SCALE, <0.1, 0.1, 0>,

            PSYS_PART_START_GLOW, 1,
            PSYS_PART_END_GLOW, 0,

            PSYS_SRC_MAX_AGE, 0.1,
            PSYS_PART_MAX_AGE, 0.5,

            PSYS_SRC_BURST_RATE, 20,
            PSYS_SRC_BURST_PART_COUNT, 1000,

            PSYS_SRC_ACCEL, <0, 0, 0>,

            PSYS_SRC_BURST_SPEED_MIN, 2,
            PSYS_SRC_BURST_SPEED_MAX, 2,

            PSYS_PART_FLAGS, 0
                | PSYS_PART_EMISSIVE_MASK
                | PSYS_PART_INTERP_COLOR_MASK
                | PSYS_PART_INTERP_SCALE_MASK
                | PSYS_PART_FOLLOW_VELOCITY_MASK
        ]);
    }

    default {
        on_rez(integer start_param) {
            //  If start_param is zero, this is a simple manual rez
            if (start_param != 0) {
                llSetAlpha(0, ALL_SIDES);   // Hide
                llSetStatus(STATUS_PHANTOM | STATUS_BLOCK_GRAB, TRUE);  // Make sure we're phantom
                //  Make us temporary just in case timer doesn't fire
                llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_TEMP_ON_REZ, TRUE ]);
                llSetTimerEvent(lifeTime);  // Start self-destruct timer
                splodey();                  // Start the explosion particle system
                llPlaySound("Bang", 1);     // Sound off
            }
        }

        timer() {
            llDie();                        // We're out of here
        }

        /* IF TOUCH_EXPLOSION
        touch_start(integer i) {
            //  Trigger explosion effects by touch for debugging and fine-tuning
            splodey();                      // Start the explosion particle system
            llPlaySound("Bang", 1);         // Sound off
            llSleep(0.5);
            llParticleSystem([ ]);          // Cancel particle system so it doesn't linger
        }
        /* END TOUCH_EXPLOSION */
    }
