# Squishybody
This describes in mostly good detail the tricks, trials, and tribulations I used and encountered during the softbody project.

## Force Integration
Integrating the forces that the springs created into the points themselves turned out to be far harder than one may expect.

Originally, they were simply added to the point's `linear_velocity` (Vector2), which worked mostly fine, however it was not technically
how the [Euler Integration](http://emweb.unl.edu/NEGAHBAN/EM373/note19/note19.htm) was supposed to work. After this, I tried creating an `F` (for Force) value on each point, and then
adding *that* to the `linear_velocity` each frame. This turned out to work even worse, and resulted in the body immediately exploding out to infinity. After further bugfixing and troubleshooting, I fixed the [Hooke's Law](https://en.wikipedia.org/wiki/Hooke%27s_law) code, adjusted the `dampingForce`, and it is finally mostly springy.

## **Parameters**
There are certain values of the parameters that work fine, and some that result in chaos and explosion.

### **Width / Height**
The amount of points across the shape will be. When w*h gets to more than about 150, the program starts to lag a *lot,* so be wary of this.

### **Px Between Points**
The amount of pixels in between the **center** of each point. This has no effect or relation to the point's radius, so if this value is exactly `2 * pointRadius`, there will be no gap between the points, and the "soft" body will be somewhat hard.

### **Point Radius**
Exactly what it sounds like; the radius of the hitbox (and of course visual shape) of each physics point in the softbody.

### **Stiffness**
The amount of force applied to the points each frame to get them back to the spring's `restLength`.

The higher the stiffness is, the more force will be applied to the points as they stray from the spring's `restLength`. If the spring was supposed to be a length of 10, and they are stretched to 20 pixels apart, a high stiffness will result in a lot of force being applied towards each other to correct this discrepancy, and a low stiffness will result in only a small amount of force being appplied. (This also applies for compression of course, and the force will be in the opposite direction.)

Keep in mind: <span style="color:red">**this is the most volatile parameter.**</span> The simulation will remain stable if `dampingFactor >= stiffness`, but if that isn't true, the body will immediately start to jiggle so hard it will send you flying into the next dimension, and then dissolve into infinity. <span style="color:pink">**Maintaing a stiffness below 50**</span> is highly advisable; even if you also keep the damping factor at 50 it will still vibrate weirdly.

### **Damping Factor** (No longer adjustable in editor)
The amount of dampening that is applied to the spring's force each frame.

This is essentially the Yin to stiffness' Yang. It decreases the force the spring applies each frame, based on how fast it is changing in length. For example, if the points are moving apart quickly, and the spring is applying force to move them back, a large amount of damping will be applied to prevent them from flying off too much.

### **Mass**
The mass of each physics point.

This affects how much the points are affected by the forces from the springs and gravity.

### **Hide Lines**
If this is disabled, the lines will show between the points, representing each spring.
If enabled, the lines will be invisible, and all that you can see will be the points themselves.