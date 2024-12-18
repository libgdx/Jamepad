# Jamepad Fork

#### A better way to use gamepads in Java.

*This is a fork of and based on the [original work by William Hartman](https://github.com/williamahartman/Jamepad/tree/ae170a95eb7c14d82b19328480b1ab5a45b77001)*.

Jamepad is a library for using gamepads in Java. It's based on SDL2 ([here](https://www.libsdl.org/)) and uses jnigen ([more info here](https://libgdx.com/wiki/utils/jnigen)). We also use [this](https://github.com/gabomdq/SDL_GameControllerDB) really nice database of gamepad mappings.

Jamepad has:
  - One library that supports all platforms (Windows, OSX, and Linux)
  - XInput support on Windows for full Xbox 360 controller support.
  - Support for plugging/unplugging controllers at runtime.
  - Support for rumble
  - Button/Axis mappings for popular controllers.
  - A permissive license (see below).

This fork improved the following points compared to last real [Jamepad version 1.3.2](https://github.com/williamahartman/Jamepad/tree/ae170a95eb7c14d82b19328480b1ab5a45b77001):
* This fork builts the native library on Github Actions. You can see all the magic happen there. Moreover, if you fork this repo and adjust settings, you are immediately ready to go with your own build! We are open for PRs though.
* New features added, newer SDL version used
* Natives are smaller in size
* Natives for arm architecture included

#### Stuff You Should Know About Jamepad

- On Windows (only 7 and up were tested), no special dependencies are needed.
- On Linux, runtime dependencies are: libevdev, libudev (normally included)
- On OS X, no special dependencies are needed

#### Current Limitations
- The order of gamepads on Windows is not necessarily the order they were plugged in. XInput controllers will always appear before DirectInput controllers, regardless of when they were plugged in. This means that the player numbers associated with each controller can change unexpectedly if XInput controllers are plugged in or disconnected while DirectInput controllers are present.
- If using getState() in ControllerManager, a new ControllerState is instantiated on each call. For some games, this could pose a problem.



## Using Jamepad

For usage within libgdx project, take a look at [gdx-controllers](https://github.com/libgdx/gdx-controllers).
The following information is only needed for non-gdx Java projects.

### Getting Jamepad

[![Sonatype Nexus (Releases)](https://img.shields.io/nexus/r/com.badlogicgames.jamepad/jamepad?nexusVersion=2&server=https%3A%2F%2Foss.sonatype.org&label=release)](https://search.maven.org/artifact/com.badlogicgames.jamepad/jamepad)
[![Sonatype Nexus (Snapshots)](https://img.shields.io/nexus/s/com.badlogicgames.jamepad/jamepad?server=https%3A%2F%2Foss.sonatype.org&label=snapshot)](https://oss.sonatype.org/#nexus-search;gav~com.badlogicgames.jamepad~jamepad)

##### gradle
If you use gradle, you can pull this package in from Maven Central.
Add this line to your dependencies section. Update the version number to whatever the latest release is.
````
dependencies {
  ...
  compile 'com.badlogicgames.jamepad:jamepad:2.0.14.0'
}
````
##### maven
If you use gradle, you can pull this package in from Maven Central.
Add this line to your dependencies section. Update the version number to whatever the latest release is.
````
<dependencies>
    ...
    <dependency>
        <groupId>com.badlogicgames.jamepad</groupId>
        <artifactId>jamepad</artifactId>
        <version>2.0.14.0</version>
    </dependency>
</dependencies>
````

#### Using Jamepad
There are two main ways to use Jamepad. Both rely on a ControllerManager Object.

```java
ControllerManager controllers = new ControllerManager();
controllers.initSDLGamepad();
```

For most applications, using the getState() method in ControllerManager is best. This method returns an immutable ControllerState object that describes the state of the controller at the instant the method is called. Using this method, you don't need to litter code with a bunch of exceoption handling or handle the possiblity of controller disconnections at weird times. 

If a controller is disconnected, the returned ControllerState object has the isConnected field set to false. All other fields are either false (for buttons) or 0 (for axes).

Here's a simple example:

```java
//Print a message when the "A" button is pressed. Exit if the "B" button is pressed 
//or the controller disconnects.
while(true) {
  ControllerState currState = controllers.getState(0);
  
  if(!currState.isConnected || currState.b) {
    break;
  }
  if(currState.a) {
    System.out.println("\"A\" on \"" + currState.controllerType + "\" is pressed");
  }
}
```

For a select few applications, getState() might not be the best decision. Since ControllerState is immutable, a new one is instantiated on each call to getState(). This should be fine for normal desktop JVMs; both Oracle's JVM and the OpenJDK one should absolutely be able to handle this. What problems do come up could probably be solved with some GC tuning.

If these allocations do end up being an actual problem, you can access the internal representation of the controllers. This is more complicated to use, and you might need to deal with some exceptions.

Here's a pretty barebones example:

```java
//Print a message when the "A" button is pressed. Exit if the "B" button is pressed 
//or the controller disconnects.
ControllerIndex currController = controllers.getControllerIndex(0);

while(true) {
  controllers.update(); //If using ControllerIndex, you should call update() to check if a new controller
                        //was plugged in or unplugged at this index.
  try {
    if(currController.isButtonPressed(ControllerButton.A)) {
      System.out.println("\"A\" on \"" + currController.getName() + "\" is pressed");
    }
    if(currController.isButtonPressed(ControllerButton.B)) {
      break;
    }
  } catch (ControllerUnpluggedException e) {   
    break;
  }
}
```

When you're finished with your gamepad stuff, you should call quitSDLGamepad() to free the native library.

```java
controllers.quitSDLGamepad();
```

## Building Jamepad

See [BUILDING](BUILDING.md)

## License

The original work by William Hartman is licensed under the permissive zLib license.
You can include this use this library in proprietary projects without sharing source, and you are allowed to alter the project.
The original license is kept [here](LICENSE_hartman.txt).

libSDL 2.0 is [zLib licensed](https://libsdl.org/license.php), too.

Every work done in this fork is licensed under Apache 2 License conditions, see LICENSE file.