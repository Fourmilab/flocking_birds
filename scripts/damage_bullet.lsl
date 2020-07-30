    /*
                       Damage Bullet

                       by John Walker

        If we're inflicting damage on avatars we hit, this prim is
        rezzed in the immediate vicinity of the avatar, turns on physics,
        sets itself to the specified damage level, then promptly
        arranges to collide with the avatar, resulting in its own
        destruction and damage to the avatar.  We have to do it
        this way because a collision that inflicts damage destroys
        the prim which collided.

        If for some reason we miss the avatar, a self-destruct timer
        keeps the prim from cluttering things up and, in addition,
        we mark ourselves temporary and set to die should we pass
        off the edge of the world.

    */

    float lifeTime = 2;                 // How long we live

    default {
        on_rez(integer start_param) {
            //  If start_param is zero, this is a simple manual rez
            if (start_param != 0) {
                llSetBuoyancy(1);       // Set buoyancy of object: 0 = fall, 1 = float
                llSetStatus(STATUS_PHYSICS | STATUS_DIE_AT_EDGE, TRUE);
                llSleep(0.1);
                /*  Nonzero start_param indicates we were created as
                    a result of a hit.  If the start_param is -1, we
                    are to cause no damage.  If it's positive, then the
                    damage to inflict is that integer divided by 1000.0.  */
                if (start_param > 0) {
                    llSetDamage(start_param / 1000.0);
                }
                llSetAlpha(0, ALL_SIDES);   // Hide
                //  Make us temporary just in case timer doesn't fire
                llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_TEMP_ON_REZ, TRUE ]);
                llSetTimerEvent(lifeTime);  // Start self-destruct timer
                llMoveToTarget(llGetPos() - <0.1, 0.1, 0>, 0.05);   // Move to hit location
            }
        }

        timer() {
            llDie();                        // We're out of here
        }
    }
