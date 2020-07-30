
                                Universal Flying Object User Guide
                                                by John Walker

The Universal Flying Object (UFO) allows you to turn other Second Life
objects into objects which can be made to fly and flock with Fourmilab
Flocking Birds.  Here's how it's done.

First of all, rez the Universal Flying Object and change its name to
whatever you wish for your flying object.  If you want the flying
object to make a special sound when it turns sharply, replace the sound
in the object with your sound clip.  The name of the sound clip should
be followed by its length in seconds, for example:
    Pig snort, time 0.75
If you include multiple sound clips in the inventory, each object
hatched will choose one at random.  Sound clips whose names include an
exclamation point, for example “Kaboom!”, will not be used as the
turning sound.  This allows you to supply sound clips for other scripts
placed in the model.

Next, rez the object you want to make fly.  This can be anything at
all: a simple prim, a linked object with multiple prims, or a simple
(non-animated) mesh object.  What's important is that you rotate it so
that the direction of travel is in its positive Z axis (up) and the
positive X axis points down toward the ground.  Scale the object
appropriately for the size of Flocking Birds.

Now is where the magic happens.  Move the UFO so it coincides with the
centre of your object.  Do a multiple selection, choosing the UFO last,
and click Link to make a composite object with the UFO as the root
prim.  Rename the composite object as you wish, for example "My Flying
Pig".

Now you should be able to take a copy of the composite object into your
inventory and drag it to the inventory of the deployer.  At this point
it should be available in the "Set model" command of the deployer.
Test it and confirm it behaves as intended.

Don't worry about the image of a bird on the UFO: it's just there to
remind you how you you should orient your model with respect to it; the
black side is the top and the white side the bottom.  When the deployer
hatches your model, the alignment guide image will be automatically
hidden.

Animesh Models

You cannot use the Universal Flying Object with Animesh (animated mesh)
models because an Animesh object cannot be the child prim of another
object.  To make an animesh model into one usable with Flocking Birds,
you must install a copy of the Bird script (which you can find in the
inventory of the UFO) and, optionally, sound clip(s) for sharp turns,
into the inventory of the Animesh object.  If the object already
contains its own sound clips, you'll have to rename them to include an
exclamation point and modify the scripts that use them accordingly.

If the animesh object was designed to move along its local Z (up) axis
with the positive X axis directed toward the ground (down), you're good
to go.  Otherwise, you'll have to include a “principal axis
declaration” in the object's description which specifies, as a vector,
the axis along which the model was designed to move.  If, for example,
the model is intended to fly along its local +X axis, you might
specify, for example, a description of:
    My animesh flying model, ax=<1,0,0>
The “ax=” specification must be given in lower case with no embedded
spaces.
