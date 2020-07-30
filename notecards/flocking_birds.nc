                    Fourmilab Flocking Birds

                              User Guide

Fourmilab Flocking Birds is an artificial life simulation based upon
the “Boids” algorithm developed by Craig Reynolds in 1986:
    https://en.wikipedia.org/wiki/Boids
The product provides an egg-shaped deployer which is controlled by
commands in local chat.  It will hatch (either confined to the
two-dimensional X-Y plane or in three-dimensional space) a flock of
individual birds with random positions and velocities that
independently fly, sense the positions and motions of nearby birds, and
obey five simple, identical, rules:

    1.  Turn away from the edges of the “cage” in which they
        are confined.
    2.  Obey a limit on their maximum speed.
    3.  Fly toward the centre of mass of nearby birds.
    4.  Avoid collisions with nearby birds.
    5.  Try to match the average velocity of nearby birds.

All of the parameters which govern these rules, such as the visual
range within which birds can sense one another and the strengths of the
various behaviours, can be set by commands in local chat, either before
the birds are hatched or while the simulation is running.  Each of the
rules can be independently enabled or disabled to observe how it
affects behaviour.  Other than distributing settings to all birds,
there is no central control: each bird is entirely autonomous and
controlled by its own script and what it senses within its visual
range.

Despite this simplicity, a flock of these birds exhibits complex
emergent behaviour that evokes that of real birds.  It demonstrates how
complexity and order spontaneously emerge from simple rules without
top-down control.  Other than the initial random assignment of bird
position and velocity, the simulation is completely deterministic:
there is no randomness in the behaviour of the birds, yet the flock
appears to be acting with free will and patterns never repeat.  A
demonstration video is available on YouTube at:
    https://www.youtube.com/watch?v=SZkUB-TeT-U

Land Impact and Permissions

In order to run the Flocking Birds simulation, you must have land on
which you can create objects and run scripts (this can be your own
land, that of another who grants you object creation permission, or a
public sandbox which allows scripted objects), and sufficient space so
the birds you create do not fly off the property.  The deployer and
each bird it creates have a land impact of 1: the property where you
run the simulation must have sufficient object capacity remaining to
accommodate the number of birds you create.  By default, birds delete
themselves after ten minutes to avoid clutter: you can change this time
or make them immortal via settings in local chat.  A “Remove” command
will immediately delete all birds created by a deployer.  (A variety of
alternative models are supplied in addition to the default bird
silhouette.  Some of these have land impact greater than one.  The land
impact of models is listed under the “Set model” command below.)

Details

Birds are physical objects, but are marked as “Phantom” so they do not
interact with other objects.  Hence, they can fly through walls and
other obstacles, which allows you to run the simulation in crowded
spaces if you wish.

Chat Commands

The Bird Deployer accepts commands sent via local chat, listening by
default on channel 1785 (the year of birth of John James Audubon).
Commands can be sent by the owner, or by others permitted by the
“Access” command.  All commands and parameters may be abbreviated to
two characters and are case-insensitive: hence “Set paths on” may be
entered as “se PA oN”.

    Access public/group/owner
        Specifies who can send commands to the deployer and birds.  You
        can restrict it to the owner only, members of the owner's
        group, or open to the general public.  Default access is by
        owner.

    Auxiliary script_name arg...
        Passes the specified arguments to auxiliary script script_name
        placed in the root prim of a bird model.  The valid arguments
        and their actions depend upon their interpretation by the
        auxiliary script.  For example, to set the range at which
        avatars are detected by the Laser Cannon script included in the
        supplied Attack Drone model to three metres, you would use
        “Auxiliary cannon range 3”.

    Boot
        Restarts the deployer script, restoring all of its initial
        defaults.  Note that this will also reset the Access and
        Channel settings to their defaults.

    Channel n
        Sets the channel on which the deployer listens for commands in
        local chat.  The default is 1785.  Note that the channel number
        will be reset to the default if you reset the script with the
        edit menu or Boot command.

    Clear
        Send vertical white space to local chat to separate output when
        debugging.

    Hatch n_birds radius(5) height(5) maxvel(2) dist(uniform)
        Hatch n_birds at random locations within radius metres of the
        location of the deployer, up to height metres above the
        deployer.  If “Set flatland on” is set (see below), all birds
        will be placed in the X-Y plane 1 metre above the deployer.
        The birds will start flying in random directions with initial
        velocity maxvel.  Birds can be distributed either uniformly
        within the radius and height, in a Gaussian (bell curve)
        distribution, or an inverse Gaussian distribution according to
        the dist setting (uniform, gauss, or igauss).  All parameters
        other than n_birds may be omitted, and take on the defaults
        given in parentheses above.  A parameter of “-” will take the
        default value, allowing subsequent parameters to be specified.
        Entering Hatch with no parameters displays a single-line
        reminder of the parameters.

        After the Hatch command is entered, the deployer will move to
        the randomly chosen location for each bird and release it into
        flight, then returning to its original position before
        deploying the next bird.  Birds are coloured based upon their
        bird number and the resistor colour code:
            (https://en.wikipedia.org/wiki/Electronic_color_code)
        with the top (toward the sky) colour indicating the units digit
        and the bottom (toward the ground) the tens.  If there are more
        than 100 birds, some colours will be duplicated.

        The number of birds you can hatch, whether by a single or in
        multiple Hatch commands, is limited only by the prim capacity
        of the land in which you're hatching them and the land impact
        of each bird (which is just 1 for the standard bird model).

    Help
        Give this notecard to the requester.

    Hide on/off/hatch
        Hide the deployer.  Whilst hidden, it continues to accept chat
        commands.  If “Hide hatch” is set, the deployer is hidden while
        hatching birds but reappears when it's done.

    Initialise
        Restores all birds to their initial location and velocity.
        This restarts the simulation from its initial conditions.  This
        is handy when experimenting with settings to observe their
        effect upon behaviour of the birds.

    List [ bird bird... ]
        Lists the colours, positions, velocities, and speeds of birds
        hatched by the deployer.  Since individual birds list their own
        information, the birds will be listed in random order.  You can
        list specific birds by number or all birds by omitting the bird
        number(s).

    Remove
        Delete all birds hatched by this deployer.

    Set
        The Set command sets a variety of parameters.

        Set actions
            Controls which of the behaviours the birds will exhibit.
            The actions are specified as the sum of the following
            numbers, representing binary bits.  The default is all
            actions, or 63.
                1   Avoid edges of cage
                2   Enforce maximum speed
                4   Fly toward centre of mass nearby birds
                8   Avoid collisions
               16   Match velocities with nearby birds
               32   Fly toward targets (if set by an auxiliary script)

        Set avoidFactor n
            Specifies the strength with which birds avoid other birds
            within minDistance (see below).  A vector is computed to
            avoid them, and the bird moves in that direction with
            strength avoidFactor (default 0.2).

        Set centringFactor n
            Sets the strength with which birds fly toward the centre of
            mass of nearby birds within visualDistance.  The default
            value is 1.

        Set chirp n
            Birds will chirp when making a turn sharper than n degrees
            (default 60).  You can suppress chirping by setting chirp
            to 0 or setting volume (see below) to 0.  If no sound clip
            is present in the bird's inventory, it will be silent.

        Set edges n
            Sets the boundaries, in metres, which define the edges of
            the area in which the birds fly.  When a bird approaches
            within n metres of an edge, it begins to turn away from the
            edge.  Birds are not strictly confined within the
            boundaries, and may fly outside based upon other rules.
            The default setting is 0.2 metres.

        Set flatland on/off
            If flatland is on, birds will be hatched in the X-Y plane
            one metre above the deployer and their flight will be
            confined to that plane.  The same behaviour rules and
            settings work in a two dimensional plane and three
            dimensional space.  Flatland is off by default.

        Set lifetime n
            Birds will have a lifetime of n seconds (default 600: 10
            minutes).  If you set lifetime to 0, the birds will be
            immortal and continue to fly until deleted by the Remove
            command (see above) or manually.  Setting lifetime only
            affects subsequently-hatched birds: existing birds retain
            their lifetime when hatched.

        Set matching n
            Sets the strength with which birds adjust their velocity to
            match that of nearby birds within visualRange.  The mean
            velocity of nearby birds is computed and the bird's
            velocity is adjusted by the factor specified by n (default
            0.1).

        Set minDistance n
            Specifies the distance at which birds try to avoid other
            birds to prevent collisions (default 0.5 metres).

        Set model name
            Sets the name of the model object in the deployer's
            inventory which will be used for subsequently hatched
            birds.  Model names may be upper and lower case and contain
            embedded spaces.  Omitting the name lists available models.
            In building models, the +Z axis is the direction of flight
            and the +X axis points toward the ground.  The following
            alternative models are included in the standard deployer
            egg.
                1.  Fourmilab Bird — The standard bird silhouette
                2.  Big Bird — A larger version of the bird silhouette
                3.  Curious bird — Bird that is attracted to nearby avatars
                4.  Flying Hawk — A textured mesh model of a hawk (land
                    impact 2)
                5.  Flying Corgi — Textured mesh model of a Welsh Corgi dog
                6.  Flying Anvil — An ACME anvil, makes a clang when turning
                7.  Flying Tie Fighter — Star Wars imperial tie fighter
                8.  Attack Drone — Tie Fighter that seeks and zaps avatars
                    (land impact 2)
                9.  Defender Drone — Tie Fighter that hunts and kills
                    Attack Drones (land impact 2)
            The custom models are demonstrated in the YouTube video:
                https://www.youtube.com/watch?v=KcmZssizMwo

        Set paths on/off
            If set on, birds will leave a temporary path behind them as
            they fly, showing where they've been in the last three
            seconds.  This is done using Second Life's “particle
            system” mechanism and may behave oddly if there are lags in
            the simulation and/or communication between the simulator
            and viewer.  Paths are off by default.

        Set speedLimit n
            Birds will be limited to a maximum speed of n metres per
            second (default 2).

        Set targetFactor n
            For models which include an auxiliary script that
            identifies targets which attract the birds (such as the
            Laser Cannon script of the included Attack Drone model),
            sets how strongly the birds are attracted to the target
            (default 0.2).

        Set timerUpdate n
            Birds will update their velocity every n seconds (default
            0.1).

        Set trace on/off
            If set on, the first bird hatched by the deployer will
            report detailed (and voluminous) information about its
            behaviour to its creator in local chat.  This information
            is generally useful only to developers modifying the birds'
            script.

        Set turning n
            Specifies how strongly birds turn away when approaching
            the boundaries defined by Set edges.  The default is 1.5
            metres per second.

        Set visualRange n
            Sets the distance, in metres, to which birds will respond
            to others in the vicinity to move toward their centre of
            mass and match their mean velocity.  The default is 1.5
            metres.

        set volume n
            Sets the volume, between 0 and 1, at which the birds chirp
            (default 1).  If set to 0, the birds will be silent.

    Status
        Display the current settings of parameters which can be
        modified by the Set command.


Adding Custom Flying Objects

Fourmilab Flocking Birds is supplied with a simple silhouette model of
a bird which has a land impact of just a single prim.  The script which
animates birds can be used to make any model, regardless of complexity,
fly and behave like the standard bird.  Included with the product is an
object called the “Universal Flying Object” (UFO).  This is a bird
silhouette in the standard orientation (direction of flight up [+Z],
ground direction +X), with the top coloured black and the bottom white
like many real birds.  Rez a copy of the UFO, then take the model you
want to fly, which can be a simple prim, a linked prim set, or a
complex mesh model, and orient it in the same way as the texture of the
UFO.  Next, move the UFO so its centre coincides with that of your
model.  The two objects will appear to overlap, but don't worry about
that.  Now, in the editor, select the model first and then, holding
down the shift key for a multiple selection, select the UFO: it is
essential you select the UFO last so that it becomes the “root prim” of
the linked object.  Press the “Link” button to link the prims.

You can now edit the linked prim and change its name to whatever you
wish to call it.  Do not change the description from “Universal Flying
Object”: this is required for the custom object to work.  Click the
Content tab on the editor.  You'll see the sound which is played when
the model makes a sharp turn.  By default this is Homer Simpson saying
“Doooh!”  You should delete this and replace it with whatever clip you
prefer or no clip at all, in which case the object will be silent.  If
the object contains more than one sound clip, one will be chosen at
random by each individual bird.  Each sound clip should have a name
followed by its length in seconds, for example “Flying Pig, time
0.752”.

Your custom model is now complete.  Take a copy into your inventory,
then edit the deployer egg and drag your model into its Contents.  The
model should now appear when you list models with the “Set model”
command and be selectable by entering the name you gave it on that
command.

If you have multiple models flying at the same time, individual models
only “see” those of the same kind (name), and thus do not interact with
other species.  Birds of a feather flock together.

Several ready-to-use alternative models are included in the standard
deployer egg, all using the UFO as their root prim, and included in the
Development Kit.  You can use these as examples when building your own
custom models.

Here are some models available on the Second Life Marketplace which are
sold with full permissions and are suitable (appropriately scaled and
oriented) for use with Fourmilab Flocking Birds:
    Dove - Full Perm
        https://marketplace.secondlife.com/p/Dove-Full-Perm/5443285
    Flying Eagle - Mesh - Full Perm
        https://marketplace.secondlife.com/p/Flying-Eagle-Mesh-Full-Perm/5689301
    Pig - Mesh - Full Perm
        https://marketplace.secondlife.com/p/Pig-Mesh-Full-Perm/5671568
The Sounds folder in the Development Kit (see below) includes sound
clips suitable for these models.

Auxiliary Scripts and Targeting

The classic flocking birds simulation uses only the five rules listed
at the start of this document.  An extension adds a sixth rule:
    6.  Fly toward targets.
which is enabled by the 32 bit in “Set actions” command.  Targets are
designated by an auxiliary script placed in the root prim of the model
along with the main Bird script.  For example, if you want the birds to
be attracted by nearby avatars, the script could poll, based upon a
timer event, for avatars within, say, five metres using the llSensor()
facility, choose the closest of the avatars detected, and then
designate the target by sending a link message to the Bird script with
a call like:
    llMessageLinked(LINK_THIS, LM_BI_TARGET,
        llList2Json(JSON_ARRAY, target_dist, target_desc, target_pos),
        target_key);
where LM_BI_TARGET is a constant defined as the integer 11.  To revoke
a previously specified target, send a message of:
    llMessageLinked(LINK_THIS, LM_BI_TARGET,
        llList2Json(JSON_ARRAY, [ 0, "", <-1, -1, -1> ]), NULL_KEY);

If the user enters an “Auxiliary” command, the full text of the command
and its parsed arguments will be sent in a region message consisting of
a JSON-encoded string to all birds containing a list with the following
values:
    "AUX"
    n           Bird number or 0 for all birds
    key         Key of avatar who submitted the command
    command     Full text of the command, upper and lower case
    argn        Number of parsed arguments
    arg...      Arguments, converted to lower case
The meaning of the arguments and their actions is up to the auxiliary
script.  By convention, the first argument is the name of the auxiliary
script to which the command is directed, allowing independent control
of multiple auxiliary scripts in bird models.

Curious Bird

The Curious Bird model demonstrates a simple application of an
auxiliary script.  It uses the same bird silhouette model as the
standard bird and an unmodified Bird script, but adds an auxiliary
script named “Curiosity”.  This script causes birds to, in addition to
their standard flocking behaviour, be attracted to nearby avatars and
swarm around them.  Birds, being bird-brained, have limited attention
spans, and after a while will become bored with their current object of
fascination and fly off seeking another.  You can control their
behaviour with the following auxiliary commands:
    Auxiliary curiosity boredom timeF [timeR]
        Birds will become bored with swarming around an avatar
        after timeF seconds plus a random interval between zero
        and timeR seconds.  After a similar interval, they will
        cease being bored and resume being interested in that
        avatar.  The default timeF is 15 seconds and timeR is 5
        seconds.
    Auxiliary curiosity NPCs on/off
        Controls whether birds are attracted to non-player characters
        (NPCs) in addition to avatars.  In order to attract birds,
        non-player character objects must have an object name of
        “[NPC]”.
    Auxiliary curiosity ownerIgnore on/off
        If set on, birds will ignore their owner.  This allows
        you to use birds to greet those who visit your land without
        bothering you.
    Auxiliary curiosity sensor n
        Birds will see and fly toward avatars within n metres.  Set
        this based upon the size of your parcel and how far you
        wish the birds to seek visitors.  The default is 7 metres.
    Auxiliary curiosity trace on/off
        Enable or disable voluminous output about the behaviour of
        birds which is mostly of interest to developers.

Attack and Defender Drones

The included Attack Drone model uses an auxiliary script called “Laser
Cannon” which can serve as a model and point of departure for your own
builds.  It performs timed sensor scans for avatars in the vicinity,
reports the location of the closest as a target if any is detected, and
casts a ray in the direction of the cannon's beam.  If the ray cast
hits an avatar, the beam is shown, a “Pew!” sound is played, and an
explosion materialised at the point of impact.  Defender Drones are
similar, but instead of avatars they seek out and shoot down Attack
Drones.  Attack Drones defend themselves by shooting at Defender
Drones, although they'll first take a shot at an avatar if it's
available.  The Attack and Defender Drone models respond to the
following commands:
    Auxiliary cannon boredom timeF [timeR]
        Attack Drones will become bored with swarming around an avatar
        after timeF seconds plus a random interval between zero and
        timeR seconds.  After a similar interval, they will cease being
        bored and resume being interested in that avatar.  The default
        timeF is 15 seconds and timeR is 5 seconds.
    Auxiliary cannon damage n
        Inflict damage (where permitted) of n (0 is none, 100 an
        immediate kill) on avatars hit by the drone, default 0.
    Auxiliary cannon explode on/off
        Enable/disable explosion when hit by an adversary drone.
    Auxiliary curiosity NPCs on/off
        Controls whether drones are attracted to non-player characters
        (NPCs) in addition to avatars.  In order to attract drones,
        non-player character objects must have an object name of
        “[NPC]”.
    Auxiliary cannon ownerProtect on/off
        If on, don't shoot at the object's owner.
    Auxiliary cannon push n
        If nonzero, push avatars (where permitted) when hit with
        impulse n (default 2000).
    Auxiliary cannon range n
        Sets range of cannon beam to n metres, default 2.5.
    Auxiliary cannon sensor n
        Sets range at which avatar targets are detected, default 7 metres.
    Auxiliary cannon trace on/off
        Enables voluminous output for debugging.
    Auxiliary cannon volume n
        Sets volume of cannon firing between 0 (off) and 1.
If you want to restrict a command to affect only attack or defender
drones, specify the word “attack” or “defender” after “Auxiliary
cannon” and before the main command.  For example:
    Auxiliary cannon defender explode off
will prevent defenders from exploding when hit by attackers' lasers.
Note that auxiliary commands are sent to already-hatched and flying
objects; they do not affect those hatched subsequently to the command's
being entered.  As with all commands, you can abbreviate commands and
arguments to as few as two letters: “Auxiliary” is often entered as
“Aux”.

Permissions and the Development Kit

Fourmilab Flocking Birds are delivered with “full permissions”.  Every
part of the object, including the scripts, may be copied, modified, and
transferred without any restrictions whatsoever. If you find a bug and
fix it, or add a feature, let me know so I can include it for others to
use.  The distribution includes a “Development Kit” directory, which
includes the textures and sound clips used in the models.

The Development Kit directory contains a Logs subdirectory which
contains the development log for the project.  If you wonder, “Why does
it work that way?” the answer may be there.

Source code for this project is maintained on and available from the
GitHub repository:
    https://github.com/Fourmilab/flocking_birds

Acknowledgements

    The mesh model for the Flying Tie Fighter and the Attack and
    Defender Drones is based upon the Blender “Low Poly TIE fighter”
    model:
        https://www.blendswap.com/blend/18585
    developed by Blend Swap user lengyel109:
        https://www.blendswap.com/profile/616479
    and released under the Creative Commons Attribution 3.0 Unported
    license:
        https://creativecommons.org/licenses/by/3.0/

    The mesh model used for the Flying Hawk is based upon the Blender
    “Hawk” model:
        https://www.blendswap.com/blend/9761
    developed by Blend Swap user kaladin:
        https://www.blendswap.com/profile/131313
    and released under the Creative Commons Attribution 3.0 Unported
    license:
        https://creativecommons.org/licenses/by/3.0/

    The mesh model used for the Flying Anvil is based upon the “Blender
    model of an anvil”:
        https://www.blendswap.com/blend/20662
    developed by Blend Swap user Alan Shukan:
        https://www.blendswap.com/profile/278192
    and released under the Creative Commons Attribution 3.0 Unported
    license:
        https://creativecommons.org/licenses/by/3.0/

    The mesh model used for the Flying Corgi is based upon the Blender
    “Low Poly Corgi” model:
        https://www.blendswap.com/blend/15391
    developed by Blend Swap user ishigoemon:
        https://www.blendswap.com/profile/156218
    and released under the Creative Commons Attribution 3.0 Unported
    license:
        https://creativecommons.org/licenses/by/3.0/

    The following sound effects are free clips available from:
        https://www.soundeffectsplus.com/
    The “chirp” sound when an bird turns sharply is derived from "Birds
    Chirping 01" (SFX 41497961):
        https://www.soundeffectsplus.com/product/birds-chirping-01/
    The barking sounds made by the Flying Corgi model is derived from
    “Dog Barking 04” (SFX 43562143):
        https://www.soundeffectsplus.com/product/dog-barking-04/
    The “Pew!” sound when the Attack Drone laser cannon fires is derived
    from “Laser Ray Gun Shot 03” (SFX 39725679):
        https://www.soundeffectsplus.com/product/laser-ray-gun-shot-03/
    The sound when the laser cannon hits an avatar is derived from
    "Balloon Explode" (SFX 43561988):
        https://www.soundeffectsplus.com/product/balloon-explode-01/
    The sound when a drone shoots down another with its laser cannon is
    extracted from "Cartoon Bomb Explosion 01" (SFX 43132584):
        https://www.soundeffectsplus.com/product/cartoon-bomb-explosion-01/
    These sound effects are © Copyright Finnolia Productions Inc. and
    distributed under the Standard License:
        https://www.soundeffectsplus.com/content/license/

    The clang sound when the Flying Anvil turns sharply is derived from
    “Sound Ideas, HIT, METAL - ANVIL FALL ON HEAD, CARTOON 01”:
        https://soundeffects.fandom.com/wiki/Sound_Ideas,_HIT,_METAL_-_ANVIL_FALL_ON_HEAD,_CARTOON_01
    The cry made by the Flying Hawk when it turns sharply is derived
    from “Hollywoodedge, Bird Hawk Single Scre PE020801”:
        https://soundeffects.fandom.com/wiki/Hollywoodedge,_Bird_Hawk_Single_Scre_PE020801
    Both are licensed under the Creative Commons Attribution-Share
    Alike License:
        https://creativecommons.org/licenses/by-sa/3.0/

    The two fly-by sounds made by the Flying Tie Fighter and Attack and
    Defender drones are based upon the “Tie fighter flyby 1” sound:
        https://www.soundboard.com/sb/sound/963768
    and:
        http://soundfxcenter.com/movies/star-wars/8d82b5_Tie_Fighter_Flyby_Sound_Effect.mp3
    both of which are free downloads without any license specified.

    The sound clips were prepared for use in these objects with the
    Audacity sound editor on Linux.

License

This product (software, documents, images, and models) is licensed
under a Creative Commons Attribution-ShareAlike 4.0 International
License.
    http://creativecommons.org/licenses/by-sa/4.0/
    https://creativecommons.org/licenses/by-sa/4.0/legalcode
You are free to copy and redistribute this material in any medium or
format, and to remix, transform, and build upon the material for any
purpose, including commercially.  You must give credit, provide a link
to the license, and indicate if changes were made.  If you remix,
transform, or build upon this material, you must distribute your
contributions under the same license as the original.

The sound effects and mesh models are licensed as described above in
the Acknowledgements section.
