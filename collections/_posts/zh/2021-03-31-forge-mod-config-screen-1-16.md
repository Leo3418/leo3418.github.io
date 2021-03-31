---
title: "MC Forge Mod 开发记录：加入配置界面（1.16 版）"
lang: zh
tags:
  - Minecraft Forge
  - Java
categories:
  - 博客
toc: true
---

在[本系列博客的第一篇文章][config-screen]中，我介绍了如何在 Minecraft 1.14.4 及以上版本之上给 Minecraft Forge mod 做一个配置界面，即使是在 Forge 里原有的配置界面框架被删除、并且核心开发成员[已经决定再也不会把它加回来][lexmanos-denial]的情况下。Forge 项目领导者 LexManos 如此冷酷无情地否定 [**@Cadiboo**][cadiboo] 耗费多于一年的心血才做出的劳动成果，仅凭几句话就随意地关闭前面链接里的 pull request，让我感到非常失望和心寒。除了对 Minecraft Forge 项目的主要成员又多了一份不满以外，这件事也让我明确了一项新的责任和使命，那就是继续维护这种开发 mod 配置界面的方法，确保它在最新的 Minecraft Forge 版本上仍然可用。在与一名 mod 开发者、本系列博客的一名读者、同时也是我所毕业的高中的一名学生 [**@yuesha-yc**][yuesha-yc] 交流后，我意识到了对于 Minecraft Forge 这样一个官方文档聊胜于无的平台来说，我这些关于 Forge mod 开发的文章对于 mod 开发者们来说就如同雪中送炭，所以我也会竭尽全力，继续分享我关于 Forge mod 开发的经验和知识，为广大开发者提供帮助。

原来的那篇关于配置界面的文章中介绍的方法在 Minecraft 1.14.4 和 1.15.x 上可以正常使用，而在 Minecraft 1.16.x 上就需要一些小改动。因为这些改动用三言两语就可以概括，所以我并没有为了 1.16 重写一篇文章，而只是在原文章里加了像“如果是在 1.16 上开发，请参阅此链接中的内容”这样的特别说明。然而，到了 Minecraft 1.16.5，仅仅几句特别说明就不够了，因为这次是 Minecraft Forge 有了一个重要的变化。在[本系列博客的上一篇文章][migrate-to-1.16]中，我在讨论反混淆时简单介绍了*映射表*的概念。如果想了解关于映射表的更多知识，可以参阅 [Sponge 文档上的内容][mappings-sponge]。从 Minecraft 1.16.5 起，Minecraft Forge 开始默认使用微软提供的[官方映射表][official-mappings]了（映射表文件顶部写的是微软而非 Mojang 的名字），也导致了在反编译的 Minecraft 源代码中许多字段和方法的名称发生了变化。这相继造成了我需要大量修改文章中的代码示例，所以我决定把原来那篇文章中的方法针对 Minecraft 1.16.x 完整地重写一遍。

[config-screen]: /2020/09/09/forge-mod-config-screen.html
[lexmanos-denial]: https://github.com/MinecraftForge/MinecraftForge/pull/7395#issuecomment-779515483
[cadiboo]: https://github.com/Cadiboo
[yuesha-yc]: https://github.com/yuesha-yc
[migrate-to-1.16]: /2021/02/06/forge-mod-migrate-to-1-16.html
[mappings-sponge]: https://docs.spongepowered.org/stable/zh-CN/plugin/internals/mcp.html#mappings
[official-mappings]: https://launcher.mojang.com/v1/objects/374c6b789574afbdc901371207155661e0509e17/client.txt

## 要求

如果要根据此文章中的步骤创建如下图所示的配置界面，那么需要使用 Minecraft Forge 36.1.0 或更高版本。虽然这个版本的 Forge 对应的是 Minecraft 1.16.5，但是基于它构建的 mod 也应该可以与其它一些 1.16.x 版本兼容。比如，我自己的 mod，Hypixel 起床战争助手，使用 Forge 36.1.0 构建的 JAR 文件在 Minecraft 1.16.2-1.16.4 上也都可以正常使用。与此同时，Forge 36.1.0 是第一个默认使用官方映射表的 Forge 稳定版本，而本篇文章也将使用官方映射表中的方法名称。

![跟随此帖中的步骤后将会创建的配置界面](/assets/img/posts/2020-09-09-forge-mod-config-screen/zh/complete-config-screen.png)

## 步骤

在 Minecraft 1.16.x 上为一个 Minecraft Forge mod 做配置界面的步骤大致分为：为配置界面创建一个类、注册配置界面工厂、添加配置界面上要显示的元素、以及将配置界面前端和 mod 配置后端连接起来。其实整体的步骤和 Minecraft 1.14.4 与 1.15.x 是一样的，只是在细节之处有一些差异。

### 为配置界面创建类

Minecraft 当中有一个 `net.minecraft.client.gui.screen.Screen` 抽象类被设计为所有游戏内屏幕界面的父类，因此 mod 的配置界面也将成为它的子类。

`Screen` 类中有如下重要成员，子类可能往往会覆写或调用：

- `protected Screen(ITextComponent title)`：唯一的构造器
- `protected void init()`：执行屏幕界面初始化任务
- `public void render(MatrixStack matrixStack, int mouseX, int mouseY, float partialTicks)`：渲染屏幕界面
- `public void onClose()`：关闭屏幕界面，并执行清理任务

可以先按照下面的例子所示，写一个简单的 `ConfigScreen` 类：

```java
import net.minecraft.client.gui.screen.Screen;
import net.minecraft.util.text.TranslationTextComponent;

public final class ConfigScreen extends Screen {
    /** 从屏幕顶部到此界面标题的距离 */
    private static final int TITLE_HEIGHT = 8;

    public ConfigScreen() {
        // 通过父类构造器指定此界面的标题
        super(new TranslationTextComponent("hbwhelper.configGui.title",
                HbwHelper.NAME));
    }

    @Override
    public void render(MatrixStack matrixStack,
                       int mouseX, int mouseY, float partialTicks) {
        // 首先渲染界面背景
        this.renderBackground();
        // 渲染标题
        this.drawCenteredString(this.font, this.title.getFormattedText(),
                this.width / 2, TITLE_HEIGHT, 0xFFFFFF);
        // 调用父类对应方法，完成渲染
        super.render(mouseX, mouseY, partialTicks);
    }
}
```

### 注册配置界面工厂

这一步在 Minecraft 1.16.x 上和在 1.14.4 与 1.15.x 上是一样的，因此请移步[原文章中的对应章节][og-register-factory]了解更多信息。

[og-register-factory]: /2020/09/09/forge-mod-config-screen.html#注册配置界面工厂

### 添加基本 UI 元素

成功注册配置界面的工厂，并且工厂可以正常地创建配置界面的实例后，就可以在 mod 列表点击“配置”按钮进入配置界面了。不过，因为目前只添加并渲染了屏幕标题，进去后会发现配置界面除了标题外空空如也，而且除非按 Esc 键，否则也没办法退出。

![空白的配置界面](/assets/img/posts/2020-09-09-forge-mod-config-screen/zh/blank-config-screen.png)

若要模仿一个 Minecraft 原生风格的配置界面，就需要创建一个在屏幕中间包含配置所有选项用的控件的容器、以及屏幕底部的“完成”按钮。控件容器的背后是一个 `net.minecraft.client.gui.widget.list.OptionsRowList` 对象。从 `OptionsRowList` 这个名字里可以看出，它就是用来存储 Minecraft 设置界面里一行一行选项的列表。至于“完成”按钮，Minecraft 中有一个 `net.minecraft.client.gui.widget.button.Button` 类，可以用来创建各种按钮。

```java
import net.minecraft.client.gui.widget.button.Button;
import net.minecraft.client.gui.widget.list.OptionsRowList;
import net.minecraft.util.text.TranslationTextComponent;

import ...;

public final class ConfigScreen extends Screen {
    /** 从屏幕顶部到选项列表顶端的距离 */
    private static final int OPTIONS_LIST_TOP_HEIGHT = 24;
    /** 从屏幕底部到选项列表底端的距离 */
    private static final int OPTIONS_LIST_BOTTOM_OFFSET = 32;
    /** 选项列表里每个选项的高度 */
    private static final int OPTIONS_LIST_ITEM_HEIGHT = 25;

    /** 按钮宽度 */
    private static final int BUTTON_WIDTH = 200;
    /** 按钮高度 */
    private static final int BUTTON_HEIGHT = 20;
    /** 从屏幕底部到“完成”按钮顶端的距离 */
    private static final int DONE_BUTTON_TOP_OFFSET = 26;

    /** 选项列表 */
    // 如下所述，此字段无法在对象构造时初始化，故无法使用 'final' 关键字
    private OptionsRowList optionsRowList;

    ...

    @Override
    protected void init() {
        // 创建选项列表
        // 如果不在这里创建，而在构造器里创建的话，会造成选项列表渲染错误
        this.optionsRowList = new OptionsRowList(
                this.minecraft, this.width, this.height,
                OPTIONS_LIST_TOP_HEIGHT,
                this.height - OPTIONS_LIST_BOTTOM_OFFSET,
                OPTIONS_LIST_ITEM_HEIGHT
        );

        // 将选项列表加入到此界面的子元素中
        // 如果不加，用户就无法点击列表中的元素
        this.children.add(this.optionsRowList);

        // 添加“完成”按钮
        this.addButton(new Button(
                (this.width - BUTTON_WIDTH) / 2,
                this.height - DONE_BUTTON_TOP_OFFSET,
                BUTTON_WIDTH, BUTTON_HEIGHT,
                // 按钮上显示的文字
                new TranslationTextComponent("gui.done"),
                // 按钮被点击时执行的操作
                button -> this.onClose()
        ));
    }

    @Override
    public void render(MatrixStack matrixStack,
                       int mouseX, int mouseY, float partialTicks) {
        this.renderBackground(matrixStack);
        // 为避免显示错乱，需要在这个时机渲染选项列表
        this.optionsRowList.render(matrixStack, mouseX, mouseY, partialTicks);
        drawCenteredString(matrixStack, this.font, this.title.getString(),
                this.width / 2, TITLE_HEIGHT, 0xFFFFFF);
        super.render(matrixStack, mouseX, mouseY, partialTicks);
    }
}
```

上面代码里的注释应该可以解释这些类的用法和注意事项，不过还是有必要再额外说一下 `Button` 构造器的最后一个参数。这个参数的类型是 `Button.IPressable`，是一个接口，定义如下：

```java
public interface IPressable {
    void onPress(Button button);
}
```

这个接口代表了按钮被按下时的回调函数。实现这个接口，在它唯一的 `onPress` 方法的实现中插入按钮被按下时要执行的代码，然后在用户点击按钮时，`onPress` 方法就会被调用，`button` 参数的值也就是该按钮对应的 `Button` 对象。

作为一个“完成”按钮，当它被用户按下时应该将配置界面关闭，所以回调函数中调用了 `Screen.onClose` 方法来关闭界面。此外，作为只有一个抽象方法的接口，`IPressable` 也是一个*函数式接口*，因此可以直接用 lambda 表达式 `button -> this.onClose()` 来实现它。

现在配置界面最基础的结构就完成了，可以开始添加用来操纵选项的控件了。

![基本配置界面](/assets/img/posts/2020-09-09-forge-mod-config-screen/zh/basic-config-screen.png)

### 添加操纵选项的控件

Minecraft 的 `net.minecraft.client.settings` 程序包中提供了多种控件，用于不同类型的选项：

- `BooleanOption` 用于布尔值选项，也就是只有“开”和“关”两种状态的选项。

- `SliderPercentageOption` 用于数值选项。虽然它的名字叫“percentage”，也就是百分比，但它的用途并不局限于百分比，可以用来调整任意范围的数值。

- `IteratableOption` 用于多选一的选项，也就是允许的所有设定值都在一个序列中的选项，例如从一个存有多个字符串的数组中选择一项、或者从一个枚举类的常量中选择一个的选项。

#### `BooleanOption`

我们从最简单的 `BooleanOption` 入手。`BooleanOption` 类唯一构造器的签名如下：

```java
public BooleanOption(String translationKey,
                     Predicate<GameSetting> getter,
                     BiConsumer<GameSettings, Boolean> setter)
```

想要创建一个 `BooleanOption` 很简单，只需指定该选项名称的翻译键、获取该选项当前值的方法（“getter”）、以及为该选项设定新的值的方法（“setter”）即可。然而，这里的 getter 和 setter 要求的数据类型比较特殊，我们来仔细看一下。

此处定义的 getter 和 setter 都用到了泛型，并且包含类型参数 `net.minecraft.client.GameSettings`——这是 Minecraft 用来代表游戏设置的类。Getter 是一个 [`Predicate`][predicate]，接受一个某种类型的数值然后返回一个 `boolean` 值；setter 是一个 [`BiConsumer`][biconsumer]，接受两个值，然后可能使用它们进行一些操作，但不返回任何值。

两个参数的类型参数里都有 Minecraft 的 `GameSettings` 类，这个 `BooleanOption` 类的主要设计意图显然是对 Minecraft 自己的游戏设置进行操作。Getter 会接受一个 `GameSettings` 对象，从中读取一项 Minecraft 游戏设定的当前值然后返回；setter 把新的设定值写入接受的 `GameSettings` 对象，达到更改游戏设置的效果。`GameSettings` 类中有许多和 Minecraft 游戏设置相关的字段，故无法被用来表示一个 mod 的设定；但是我们可以忽略所有和 `GameSettings` 有关的参数，让 getter 和 setter 直接访问 mod 自己的配置。

在下面的示例中，假设 mod 有一个包含读取和修改 mod 配置的静态方法的 `ModSettings` 类。

```java
    @Override
    protected void init() {
        this.optionsRowList = new OptionsRowList(
                this.minecraft, this.width, this.height,
                OPTIONS_LIST_TOP_HEIGHT,
                this.height - OPTIONS_LIST_BOTTOM_OFFSET,
                OPTIONS_LIST_ITEM_HEIGHT
        );

        // 创建完选项列表后，添加选项控件

        this.optionsRowList.addBig(new BooleanOption(
                "hbwhelper.configGui.showArmorInfo.title",
                // GameSettings 参数被忽略
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

`SliderPercentageOption` 类就有点复杂了，从它的构造器的参数数量和类型上就可以看出来：

```java
public SliderPercentageOption(String translationKey,
                              double minValue,
                              double maxValue,
                              float stepSize,
                              Function<GameSettings, Double> getter,
                              BiConsumer<GameSettings, Double> setter,
                              BiFunction<GameSettings, SliderPercentageOption, String> getDisplayString)
```

对 `SliderPercentageOption` 而言，getter 和 setter 的思路和 `BooleanOption` 是相似的。不过，`Predicate<GameSettings>` 到这里变成了 [`Function<GameSettings,
Double>`](https://docs.oracle.com/javase/8/docs/api/java/util/function/Function.html)。其实，`Predicate<GameSettings>` 基本上就是个 `Function<GameSettings, Boolean>`，如果这么看的话，这一处不同就可以很容易地解释和理解了。

至于其它的不同点，`minValue` 和 `maxValue` 指定选项数值允许的范围。它们的数据类型都是 `double`，因此这个类可同时用于整数值和小数值的选项。`stepSize` 参数决定用户在配置界面上拖动滑块时，设定值最小可以变更的量是多大。如果某个选项的值必须是整数的话，在这里指定 `1.0F` 就可以达到限制的效果。

最有意思的参数当属 `getDisplayString`，一个返回此选项的字符串表示的 `BiFunction`。这个 `BiFunction` 返回的字符串将会被显示在配置界面上。`BooleanOption` 的构造器是没有这个参数的，因为那个类它自己定义了默认的字符串表示方式，也就是 `<选项名>: [开|关]`。然而，`SliderPercentageOption` 没有类似的默认定义，需要程序员来指定怎么以字符串来表示一个选项。

在下面的示例中，假设 `ModSettings.getHudX` 返回 `int`，并且 `ModSettings.setHudX` 需要一个 `int` 参数。

```java
        // 添加整数值选项
        // 如果需要小数值选项的话，需要移除类型转换，并按需调整步进值
        this.optionsRowList.addBig(new SliderPercentageOption(
                "hbwhelper.configGui.hudX.title",
                // 范围：0 到当前窗口宽度
                0.0, this.width,
                // 由于是整数值，使用整数步进
                1.0F,
                // Getter 和 setter 指定方法与 BooleanOption 类似
                unused -> (double) ModSettings.getHudX(),
                (unused, newValue) -> ModSettings.setHudX(newValue.intValue()),
                // 返回 "<选项名>: <设定值>" 格式的字符串的 BiFunction
                (gs, option) -> new StringTextComponent(
                        // 使用 I18n.get(String) 查询一个翻译键对应的译文
                        I18n.get("hbwhelper.configGui.hudX.title")
                        + ": "
                        + (int) option.get(gs)
                )
        ));
```

#### `IteratableOption`

`IteratableOption` 的构造器和 `BooleanOption` 的很像，不过请注意一点，那就是 getter 和 setter 的位置被调换了。

```java
public IteratableOption(String translationKey,
                        BiConsumer<GameSettings, Integer> setter,
                        BiFunction<GameSettings, IteratableOption, String> getter)
```

`IteratableOption` 类并不关心这个选项允许的值的类型；它只关心被选定的选项在允许的设定值序列中的下标。这也是为什么它的 setter 接受的是一个整数，而不是一个泛型对象。因此，如果要使用 `IteratableOption` 的话，需要明确定义每个允许的设定值的下标。如果允许的设定值都被存在一个数组或者列表里的话，直接用数组或列表的下标就可以了；如果是枚举类常量，可以将 [`Enum.ordinal()`][enum-ordinal] 方法返回的序数用作下标。

当选项被更改时，setter 会被传入一个整数值。把这个值和当前设定在允许的设定值序列中的下标相加，在一般情况下就会得到新设定值的下标。这个计算操作是需要由 setter 负责的；特别需要注意的是，如果越过了序列的结尾，回到了序列的开头，必须小心处理下标的计算，及时将下标归零，避免越界。

至于 getter 方面，它是一个返回字符串而非整数的 `BiFunction`，数据类型和 setter 出现了偏差。`IteratableOption` 的 getter 的作用和上文中 `SliderPercentageOption` 构造器的 `getDisplayString` 是一样的，都是返回直接显示在配置界面上的文字，而非代表当前设定值的对象，甚至不是下标。

这样的设计可能让 API 难以理解和使用，不过倒是允许 `IteratableOption` 忽略所有与合法设定值相关的信息。比如，像总共有多少个不同的合法设定值、以及每个设定值如何用字符串表示这些信息，`IteratableOption` 都不需要知道。

下面的示例演示了如何添加一个允许的设定值来自枚举类常量的选项。用到的枚举类是我的 mod 的 `DreamMode` 类，可以在[此处][dream-mode]找到它的源代码。

```java
        // 添加允许的设定值来自枚举类常量的选项
        this.optionsRowList.addBig(new IteratableOption(
                "hbwhelper.configGui.dreamMode.title",
                (unused, newValue) ->
                        // 每个枚举类都有一个编译器生成的 'values()' 静态方法，
                        // 返回存有该枚举类所有常量的数组
                        ModSettings.setDreamMode(DreamMode.values()[
                                (ModSettings.getDreamMode().ordinal() + newValue)
                                    // 处理从序列结尾回到开头的特殊情况
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

#### 保存配置

如果 mod 的配置需要通过调用某个方法来手动保存，那么应该覆写 `Screen.onClose` 方法，在其中调用保存配置文件的方法：

```java
import ...;

public final class ConfigScreen extends Screen {
    ...

    @Override
    public void onClose() {
        // 保存 mod 配置
        ModSettings.save();
        super.onClose();
    }
}
```

### 正确地返回到上级界面

添加完所有选项后，看一下 mod 配置界面，现在应该就有模有样了。

![完整的配置界面](/assets/img/posts/2020-09-09-forge-mod-config-screen/zh/complete-config-screen.png)

看完之后，觉得不错，点击“完成”按钮准备退出……等一下，明明是从 mod 列表进来的配置界面，怎么直接被送回到游戏主界面去了？

如果不适应这样的行为的话，可以在配置界面被构造时保存上级界面，然后在退出时重新显示上级界面，即可避免直接返回游戏主菜单。

保存上级界面的方法是在配置界面类的构造器中添加一个 `Screen` 类型的参数，然后将其保存到一个字段当中。当配置界面被关闭时，显示上级界面。

```java
import ...;

public final class ConfigScreen extends Screen {
    ...

    /** 当前界面的上级界面 */
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
        // 显示上级界面
        this.minecraft.setScreen(parentScreen);
    }
}
```

除此以外，因为构造器签名的变动，调用配置界面类构造器的地方也需要进行修改，比如配置界面工厂：

```diff
          ModLoadingContext.get().registerExtensionPoint(
                  ExtensionPoint.CONFIGGUIFACTORY,
-                 () -> (mc, screen) -> new ConfigScreen()
+                 () -> (mc, screen) -> new ConfigScreen(screen)
          );
```

## 更多资源

如果您想找个用此文章记载的方法创建的配置界面的完整例子，可以在[这里][mod-src]找到我的 mod 的配置界面类。

您还可以在 IDE 中打开下面列出的类，阅读它们的源代码，学习更多此文章中提及的 API 的用法示例。这些源代码都是在配置 mod 开发环境时反编译 Minecraft 得到的。

- `net.minecraft.client.gui.screen.VideoSettingsScreen`
- `net.minecraft.client.settings.AbstractOption`

[mod-src]: https://github.com/Leo3418/HBWHelper/blob/v1.2.2/src/main/java/io/github/leo3418/hbwhelper/gui/ConfigScreen.java
