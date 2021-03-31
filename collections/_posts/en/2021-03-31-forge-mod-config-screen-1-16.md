---
title: "MC Forge Mod Dev Blog: Adding a Configuration GUI - 1.16 Version"
lang: en
tags:
  - Minecraft Forge
  - Java
categories:
  - Blog
toc: true
---

The [very first blog post for this series][config-screen] covered how I created
a configuration GUI screen for a Minecraft Forge mod targeting Minecraft 1.14.4
and above, despite the fact that the related framework and library classes have
been removed from Forge, and the core developers have decided that [it should
never be added back][lexmanos-denial].  I am extremely disappointed to see
LexManos, the leader of Forge, harshly rejecting more than one year of hard
work of [**@Cadiboo**][cadiboo], the developer who started that linked pull
request, with a willy-nilly closure of the pull request.  This not only means
another dissatisfaction of mine with the Minecraft Forge project but also my
obligation to maintain an up-to-date method for creating a mod configuration
screen.  From my private communication with [**@yuesha-yc**][yuesha-yc], a
Minecraft mod developer who followed me on GitHub after reading my blogs and a
current student of the high school I graduated from, I learned that my blog
posts about a platform with extremely incomplete documentation can be very
useful to developers of that platform.  Thus, I will endeavor to share my
knowledge about Minecraft Forge mod as before to the greatest possible extent.

The original method for adding a configuration GUI works on Minecraft 1.14.4
and 1.15.x, but on Minecraft 1.16.x, some changes are necessary.  The required
changes could be summarized in a few succinct sentences, so instead of starting
a new standalone article for 1.16, I just added some notes like "if you are
developing a mod on 1.16, make sure to check out this link".  However, starting
from Minecraft 1.16.5, a significant change in Minecraft Forge has made those
side notes insufficient.  In the [previous blog post for this
series][migrate-to-1.16], I briefly mentioned the concept of *mappings* in the
discussion pertaining to deobfuscation.  More details about mappings can be
found [here in Sponge documentation][mappings-sponge].  Since Minecraft 1.16.5,
Minecraft Forge has migrated to the [official mappings][official-mappings]
provided by Microsoft (as stated in the linked file's header) by default, which
caused many fields and methods in the decompiled Minecraft source code to have
different names.  As a result, the code examples need major modifications.
Therefore, this is a good time for me to produce a new version of that blog
specifically for Minecraft 1.16.x.

[config-screen]: /2020/09/09/forge-mod-config-screen.html
[lexmanos-denial]: https://github.com/MinecraftForge/MinecraftForge/pull/7395#issuecomment-779515483
[cadiboo]: https://github.com/Cadiboo
[yuesha-yc]: https://github.com/yuesha-yc
[migrate-to-1.16]: /2021/02/06/forge-mod-migrate-to-1-16.html
[mappings-sponge]: https://docs.spongepowered.org/stable/en/plugin/internals/mcp.html#mappings
[official-mappings]: https://launcher.mojang.com/v1/objects/374c6b789574afbdc901371207155661e0509e17/client.txt

## Requirements

To follow this post to create a configuration GUI like the one presented below,
Minecraft Forge 36.1.0 or later is needed.  This version of Forge is for
Minecraft 1.16.5, but mods built with it should be compatible with some of the
other 1.16.x versions as well.  For example, the artifact of my mod, HBW
Helper, built with Forge 36.1.0 can work on Minecraft 1.16.2-1.16.4 too.  Forge
36.1.0 is also the first recommended build that uses the official mappings by
default, which is the mappings this post focuses on.

![The screen that would be created after following this
post](/assets/img/posts/2020-09-09-forge-mod-config-screen/en/complete-config-screen.png)

## Steps

The steps to create a configuration GUI for a Forge mod for Minecraft 1.16.x
are creating a class for the GUI, registering a factory of the GUI, adding
elements to be shown on the GUI, and connecting the GUI with the mod’s
configuration back-end.  The general procedure is identical with those for
Minecraft 1.14.4 and 1.15.x but differs in details.

### Create a Class for the Configuration GUI

There is an abstract class `net.minecraft.client.gui.screen.Screen` designated
as the base class for every screen in Minecraft, so the mod configuration GUI
would be a subclass of it.

The `Screen` class contains the following important members that its subclasses
might want to call or override:

- `protected Screen(ITextComponent title)`: the only constructor
- `protected void init()`: performs initialization tasks of the screen
- `public void render(MatrixStack matrixStack, int mouseX, int mouseY, float
  partialTicks)`: renders the screen
- `public void onClose()`: closes the screen and performs teardown tasks

The class for the configuration GUI, `ConfigScreen`, can thus be created as
follows:

```java
import net.minecraft.client.gui.screen.Screen;
import net.minecraft.util.text.TranslationTextComponent;

public final class ConfigScreen extends Screen {
    /** Distance from top of the screen to this GUI's title */
    private static final int TITLE_HEIGHT = 8;

    public ConfigScreen() {
        // Use the super class' constructor to set the screen's title
        super(new TranslationTextComponent("hbwhelper.configGui.title",
                HbwHelper.NAME));
    }

    @Override
    public void render(MatrixStack matrixStack,
                       int mouseX, int mouseY, float partialTicks) {
        // First draw the background of the screen
        this.renderBackground(matrixStack);
        // Draw the title
        drawCenteredString(matrixStack, this.font, this.title.getString(),
                this.width / 2, TITLE_HEIGHT, 0xFFFFFF);
        // Call the super class' method to complete rendering
        super.render(matrixStack, mouseX, mouseY, partialTicks);
    }
}
```

### Register a Configuration GUI Factory

This step on Minecraft 1.16.x is the same as on Minecraft 1.14.4 and 1.15.x.
Please refer to [this section in the original article][og-register-factory] for
details.

[og-register-factory]: /2020/09/09/forge-mod-config-screen.html#register-a-configuration-gui-factory

### Add Basic UI Elements

Once the configuration GUI factory is registered with Minecraft Forge, and the
factory can create instances of the class for the GUI, it can be opened by
clicking the "Config" button in the mods list.

Because nothing except the configuration screen's title has been added, the
screen is not functional at all, and it cannot be closed without pressing Esc.

![The blank configuration
screen](/assets/img/posts/2020-09-09-forge-mod-config-screen/en/blank-config-screen.png)

To complete a Minecraft-style settings screen, a container of the widgets in
the center and a "Done" button on the bottom should be added.

The widget container is created from an instance of
`net.minecraft.client.gui.widget.list.OptionsRowList`.  The name of
`OptionsRowList` is self-explanatory - it is a list of rows of options users
see in a settings screen. A row in the list may have one or two options.

For the "Done" button, Minecraft has a
`net.minecraft.client.gui.widget.button.Button` class, which can be used to
create it.

```java
import net.minecraft.client.gui.widget.button.Button;
import net.minecraft.client.gui.widget.list.OptionsRowList;
import net.minecraft.util.text.TranslationTextComponent;

import ...;

public final class ConfigScreen extends Screen {
    /** Distance from top of the screen to the options row list's top */
    private static final int OPTIONS_LIST_TOP_HEIGHT = 24;
    /** Distance from bottom of the screen to the options row list's bottom */
    private static final int OPTIONS_LIST_BOTTOM_OFFSET = 32;
    /** Height of each item in the options row list */
    private static final int OPTIONS_LIST_ITEM_HEIGHT = 25;

    /** Width of a button */
    private static final int BUTTON_WIDTH = 200;
    /** Height of a button */
    private static final int BUTTON_HEIGHT = 20;
    /** Distance from bottom of the screen to the "Done" button's top */
    private static final int DONE_BUTTON_TOP_OFFSET = 26;

    /** List of options rows shown on the screen */
    // Not a final field because this cannot be initialized in the constructor,
    // as explained below
    private OptionsRowList optionsRowList;

    ...

    @Override
    protected void init() {
        // Create the options row list
        // It must be created in this method instead of in the constructor,
        // or it will not be displayed properly
        this.optionsRowList = new OptionsRowList(
                this.minecraft, this.width, this.height,
                OPTIONS_LIST_TOP_HEIGHT,
                this.height - OPTIONS_LIST_BOTTOM_OFFSET,
                OPTIONS_LIST_ITEM_HEIGHT
        );

        // Add the options row list as this screen's child
        // If this is not done, users cannot click on items in the list
        this.children.add(this.optionsRowList);

        // Add the "Done" button
        this.addButton(new Button(
                (this.width - BUTTON_WIDTH) / 2,
                this.height - DONE_BUTTON_TOP_OFFSET,
                BUTTON_WIDTH, BUTTON_HEIGHT,
                // Text shown on the button
                new TranslationTextComponent("gui.done"),
                // Action performed when the button is pressed
                button -> this.onClose()
        ));
    }

    @Override
    public void render(MatrixStack matrixStack,
                       int mouseX, int mouseY, float partialTicks) {
        this.renderBackground(matrixStack);
        // Options row list must be rendered here,
        // otherwise the GUI will be broken
        this.optionsRowList.render(matrixStack, mouseX, mouseY, partialTicks);
        drawCenteredString(matrixStack, this.font, this.title.getString(),
                this.width / 2, TITLE_HEIGHT, 0xFFFFFF);
        super.render(matrixStack, mouseX, mouseY, partialTicks);
    }
}
```

The comments added to this code snippet should explain the usage of those
classes and some caveats.  However, it is worth giving a special remark on the
last argument for the constructor of `Button`.  It requires an object of type
`Button.IPressable`, which is an interface defined as follows:

```java
public interface IPressable {
    void onPress(Button button);
}
```

This interface is used to define the callback function when a button is
pressed.  Put whatever code to be executed in an implementation of this
interface, then pass it to `Button`'s constructor.  When the button is pressed,
the `onPress` method of the `Button` object will be called, with the `button`
argument being that `Button` object itself.

For the "Done" button, when it is pressed, the settings screen should be
closed, so a call to the `Screen.onClose` method is put in the button's
callback function's body.  In addition, `IPressable` is effectively a
*functional interface* because it has only one abstract method, so I can
implement it easily with a lambda expression `button -> this.onClose()`.

The configuration GUI screen now has a complete skeleton, so it is time to add
the widgets for options.

![Basic configuration
screen](/assets/img/posts/2020-09-09-forge-mod-config-screen/en/basic-config-screen.png)

### Add Widgets for Controlling Configuration Values

Minecraft provides the following specialized widget classes for different types
of options in the `net.minecraft.client.settings` package:

- `BooleanOption` for options whose possible values are just "on" and "off".

- `SliderPercentageOption` for options with numeric values. Although its name
  says "percentage", it still works for options with arbitrary range and unit.

- `IteratableOption` for options with a limited set of allowed values, like an
  array of strings, or all constants of an enum class.

#### `BooleanOption`

Let us start from `BooleanOption`, which is the easiest one to use. The
signature of the class' only constructor is:

```java
public BooleanOption(String translationKey,
                     Predicate<GameSetting> getter,
                     BiConsumer<GameSettings, Boolean> setter)
```

Defining a `BooleanOption` is as easy as specifying the translation key of the
option's name, a getter of the option's current value, and a setter for
changing the value.  But the types of the getter and the setter can be
confusing, so they will be inspected in depth.

Both of them are objects of generic types with one type parameter being
`net.minecraft.client.GameSettings`.  That is a class Minecraft uses to
represent its own game settings.  The getter is a [`Predicate`][predicate],
which accepts a value and returns a `boolean`.  The setter is a
[`BiConsumer`][biconsumer], which takes in two values, does something about
them, but returns nothing.

The `BooleanOption` class was designed to interact with the game settings of
Minecraft itself: the getter takes in a `GameSettings` object, finds the
current value of a setting from that object, and returns it; the setter accepts
the `GameSettings` object to update and the new value of an option to change.
However, because the `GameSettings` class is specialized for Minecraft's
options, it cannot be used for a mod's settings. What can be done for a mod's
settings, though, is to ignore any `GameSettings` arguments and connect the
getter and the setter directly to the object that represents the mod's
settings.

For the example below, assume the mod has a `ModSettings` class that contains
static methods for retrieving and changing values of the mod's options.

```java
    @Override
    protected void init() {
        this.optionsRowList = new OptionsRowList(
                this.minecraft, this.width, this.height,
                OPTIONS_LIST_TOP_HEIGHT,
                this.height - OPTIONS_LIST_BOTTOM_OFFSET,
                OPTIONS_LIST_ITEM_HEIGHT
        );

        // Add options after the options row list is created

        this.optionsRowList.addBig(new BooleanOption(
                "hbwhelper.configGui.showArmorInfo.title",
                // GameSettings argument unused for both getter and setter
                unused -> ModSettings.getShowArmorInfo(),
                (unused, newValue) -> ModSettings.setShowArmorInfo(newValue)
        ));

        this.children.add(this.optionsRowList);

        ...
    }
```

[predicate]: https://docs.oracle.com/javase/8/docs/api/java/util/function/Predicate.html
[biconsumer]: https://docs.oracle.com/javase/8/docs/api/java/util/function/BiConsumer.html

#### `SliderPercentageOption`

The `SliderPercentageOption` class is a little bit more complicated.  Increased
number of parameters in its constructor and their types probably have suggested
this:

```java
public SliderPercentageOption(String translationKey,
                              double minValue,
                              double maxValue,
                              float stepSize,
                              Function<GameSettings, Double> getter,
                              BiConsumer<GameSettings, Double> setter,
                              BiFunction<GameSettings, SliderPercentageOption, String> getDisplayString)
```

The ideas behind the getter and setter for this class are similar to those for
`BooleanOption` except that `Predicate<GameSettings>` becomes
[`Function<GameSettings, Double>`][function].  By viewing
`Predicate<GameSettings>` as `Function<GameSettings, Boolean>`, this should
create no surprise at all.  So, let us look at the other additional parameters
for this class.

The `minValue` and `maxValue` parameters can be used to set the range of
accepted values for this option.  Their type is `double` so decimal numbers can
be used for the value, but integers may be used as well.  The `stepSize`
controls the minimal change in the option's value when the user drags the
slider.  If the option's value must be an integer, then passing `1.0F` through
this parameter will impose the limit.  Otherwise, choose whatever value that is
appropriate.

The most interesting parameter here is `getDisplayString`, a `BiFunction` that
returns the string representation shown for this option.  `BooleanOption` does
not ask for this because it has a default string representation in the format
of `<name>: [ON|OFF]`.  `SliderPercentageOption` does not have such a default
representation and relies on the programmer to determine one.

For the example below, assume `ModSettings.getHudX` returns an `int`, and
`ModSettings.setHudX` requires an `int` argument.

```java
        // Add an integer option
        // For a decimal number option, remember to remove casts,
        // and change the step's value if necessary
        this.optionsRowList.addBig(new SliderPercentageOption(
                "hbwhelper.configGui.hudX.title",
                // Range: 0 to width of game window
                0.0, this.width,
                // This is an integer option, so allow whole steps only
                1.0F,
                // Getter and setter are similar to those in BooleanOption
                unused -> (double) ModSettings.getHudX(),
                (unused, newValue) -> ModSettings.setHudX(newValue.intValue()),
                // BiFunction that returns a string text component
                // in format "<name>: <value>"
                (gs, option) -> new StringTextComponent(
                        // Use I18n.get(String) to get a translation key's value
                        I18n.get("hbwhelper.configGui.hudX.title")
                        + ": "
                        + (int) option.get(gs)
                )
        ));
```

[function]: https://docs.oracle.com/javase/8/docs/api/java/util/function/Function.html

#### `IteratableOption`

The constructor of `IteratableOption` is similar to the one of `BooleanOption`.
Note that the order of `getter` and `setter` parameters is swapped here.

```java
public IteratableOption(String translationKey,
                        BiConsumer<GameSettings, Integer> setter,
                        BiFunction<GameSettings, IteratableOption, String> getter)
```

The `IteratableOption` class does not care about the type of allowed values for
an option; it only tracks the index of the selected value in the iteration
sequence.  This is why the setter is expected to take in an integer instead of
an object of a generic type.  Therefore, to use it, a method to index the set
of allowed values for such an option is needed.  For arrays and lists, their
indices can be used for this purpose directly.  For enum constants, the indices
can be defined with [`Enum.ordinal()`][enum-ordinal].

When the option is changed, the setter receives an integer which, when added to
the option's current value's index, becomes the index of the option's new value
in the general case.  The setter is responsible for calculating the new value's
index and reflecting the change in the underlying configuration.  In
particular, careful handling of edge cases when the iteration is started over
is required.  The programmer should avoid out-of-bound indices and reset the
index to 0 when needed.

The getter, on the other hand, is a `BiFunction` that returns a string instead
of an integer.  It was intended to directly return the string representation of
the option and its value to be displayed to the user, not the index of the
current value, or even the object that represents the value.  Its purpose is
the same as the `getDisplayString` argument in the constructor of
`SliderPercentageOption`.

Although this kind of design makes the API harder to understand and use, at
least it allows the `IteratableOption` to care nothing about the set of allowed
values for an option, including information like how many values are in the
set, and what each value's string representation is.

The following example works with an option whose allowed values are constants
from an enum class called `DreamMode` in my mod.  The source code of that class
can be found [here][dream-mode].

```java
        // Add an option whose allowed values are an enum class' constants
        this.optionsRowList.addBig(new IteratableOption(
                "hbwhelper.configGui.dreamMode.title",
                (unused, newValue) ->
                        // Every enum class has an implicit static method
                        // 'values()', which returns an array containing
                        // every constant of the enum type
                        ModSettings.setDreamMode(DreamMode.values()[
                                (ModSettings.getDreamMode().ordinal() + newValue)
                                    // Handle the edge case of starting over
                                        % DreamMode.values().length
                        ]),
                (unused, option) -> new StringTextComponent(
                        I18n.get("hbwhelper.configGui.dreamMode.title")
                        + ": "
                        + I18n.get(ModSettings.getDreamMode().getTranslateKey())
                )
        ));
```

[enum-ordinal]: https://docs.oracle.com/javase/8/docs/api/java/lang/Enum.html#ordinal--
[dream-mode]: https://github.com/Leo3418/HBWHelper/blob/v1.2.2/src/main/java/io/github/leo3418/hbwhelper/game/DreamMode.java

#### Saving the Options

If the mod's configuration needs to be saved manually by calling a method, then
override the `Screen.onClose` method and insert the method call into it:

```java
import ...;

public final class ConfigScreen extends Screen {
    ...

    @Override
    public void onClose() {
        // Save mod configuration
        ModSettings.save();
        super.onClose();
    }
}
```

### Correctly Exit to the Parent Screen

Now that the option widgets have been added, the mod configuration GUI looks
very complete.

![Complete configuration
screen](/assets/img/posts/2020-09-09-forge-mod-config-screen/en/complete-config-screen.png)

There is only one small imperfection with this GUI: when the user clicks on the
"Done" button, the game does not go back to the mods list screen from which the
GUI was opened, but the main menu of the game instead.  If this is not the
desired behavior, then tracking the parent screen when the GUI is being created
and returning back to it when the GUI is closed will fix it.

To track the parent screen, add a parameter for it in the configuration GUI's
constructor, and save it in a field.  When the GUI is being closed, display the
parent screen.

```java
import ...;

public final class ConfigScreen extends Screen {
    ...

    /** The parent screen of this screen */
    private final Screen parentScreen;

    public ConfigScreen(Screen parentScreen) {
        super(new TranslationTextComponent("hbwhelper.configGui.title",
                HbwHelper.NAME));
        this.parentScreen = parentScreen;
    }

    ...

    @Override
    public void onClose() {
        ModSettings.save();
        // Display the parent screen
        this.minecraft.setScreen(parentScreen);
    }
}
```

After this change is made, do not forget to change the configuration GUI
factory as well, because the constructor's signature has been altered:

```diff
          ModLoadingContext.get().registerExtensionPoint(
                  ExtensionPoint.CONFIGGUIFACTORY,
-                 () -> (mc, screen) -> new ConfigScreen()
+                 () -> (mc, screen) -> new ConfigScreen(screen)
          );
```

## More Resources

If you want to look at a full example of a configuration GUI class created with
this method, please visit the source code of my mod's configuration screen
[here][mod-src].

You can also find and read the source code of the following classes in your
IDE, they contain more sample code that uses the APIs mentioned in this post.
The source code was generated during the decompilation process of Minecraft
when you set up your mod's workspace.

- `net.minecraft.client.gui.screen.VideoSettingsScreen`
- `net.minecraft.client.settings.AbstractOption`

[mod-src]: https://github.com/Leo3418/HBWHelper/blob/v1.2.2/src/main/java/io/github/leo3418/hbwhelper/gui/ConfigScreen.java
