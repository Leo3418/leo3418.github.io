---
title: "MC Forge Mod 开发记录：加入配置界面"
lang: zh
toc: true
---
{% include img-path.liquid %}

## 前言

最近我萌生了一个想法，写一些记录我开发 Minecraft Forge 模组（mod）的过程、和我维护时长两年半的个人 mod 项目 [Hypixel 起床战争助手](https://github.com/Leo3418/HBWHelper)（HBW Helper）之间的故事的文章。这么做的目的主要有两个：首先是对我个人而言，可以有一个记录下我如何作出 mod 开发过程中的一些关键决定、遇到 mod 开发问题时的解决思路以及解决方案的地方，可供日后温习；其次是为屏幕前的您和其他的读者朋友，在遇到与我类似的情况时，提供一个参考内容。

我之所以没有用“教程”这个名字而是使用了“记录”，是因为我想记录下来的主要是我如何解决我个人遇到的具体问题，而不是一个宽泛的问题的通用解决方案。当然，我还是会尝试尽可能对具体的解决方案进行概括。尽管如此，在运用此系列文章中提及的知识、执行列出的步骤的时候，仍然需要您拥有举一反三、灵活变通的能力；无脑的复制粘贴在某些情况下可能无助于问题的解决。正因如此，我并没有使用“教程”这一要求更加严格的称谓，而是使用了显得比较随意的“记录”一词。

Hypixel 起床战争助手是专为在 Hypixel 上玩起床战争的玩家设计的一款 mod。它可以将您在游戏中购买的升级、下一次钻石和绿宝石的刷新时间、以及其它一些关键的游戏信息直接显示在屏幕上，一目了然。两年半前，我为了解决自己想方便查看一局起床中哪些升级已经购买的需求开发了这个 mod；现在虽然我已经不玩起床了，但依然会每年对这个 mod 进行数次维护。

![Hypixel 起床战争助手的用户界面]({{ img_path }}/hud.png)

首篇 mod 开发记录便是关于我在最新版本的 Minecraft 和 Minecraft Forge 之上研究和开发 mod 选项界面的心得，也正好是伴随着我的 mod 近期 1.2.0 更新中新加入的配置界面的推出。

## 动机

Minecraft Forge 允许每个 mod 拥有自己的配置，以允许向玩家提供自定义 mod 选项的功能。例如，Hypixel 起床战争助手在游戏画面上显示游戏信息的位置就支持自定义。

![移动游戏信息的显示位置]({{ img_path }}/custom.png)

为了允许玩家自定义游戏信息的显示位置，我提供了几个相关的配置选项。在此基础上，还需要给玩家提供一种调整设置的机制。我在 2018 年上旬开始开发这个 mod 时，Minecraft 最新版本还是 1.12.2，当时的 Forge 里有一个配置界面框架，mod 开发者可以用它来制作一个允许玩家调整 mod 设置的界面。研究了一下之后，我感觉还行，就在这个框架的基础上做了我的 mod 的配置界面。

![Forge 自己的配置界面]({{ img_path_l10n }}/forge-config-gui.png)

![我的 mod 的配置界面]({{ img_path_l10n }}/mod-config-gui-forge.png)

几个月后，Minecraft 1.13 横空出世。Mojang 在 1.13 内部调整了许多东西，导致 Minecraft Forge 开发组的跟进进度异常迟缓，直到 1.14 出了都未能完善，以至于 1.13.x 到最后没有 Forge 的稳定版。

直到 1.14.4 的时候，Forge 开发组终于推出了新的稳定版本。自 Minecraft 本身在 1.13 的大重构之后，Minecraft Forge 也经历了很大的变化：许多类被重命名，接口被更改，然而最显著的变化可能就是 mod 配置界面框架没有了。也许是因为 Minecraft 本身被大规模重构，Forge 的许多现有框架也需要随之重写，但是开发者把旧的代码移除了之后，一直没有重写新的代码。连 Forge 自己的配置界面都被迫随之删除了，在 mod 列表里看 Forge 的“配置”按钮是灰色的。

![自 1.14.4 起，Minecraft Forge 自己的配置界面都没有了]({{ img_path_l10n }}/forge-no-config.png)

我在 2019 年 8 月[把我的 mod 移植到 Minecraft 1.14.4](https://github.com/Leo3418/HBWHelper/commit/c082844786a1a1dff9cca29f2ffe2f1219537966) 时发觉到了这个问题。我选择的解决方案是提供一个可以修改 mod 配置的命令。当时想着这个框架只是因为 Forge 开发者为了清理过时代码而删除的，因为需要先重写其它更加关键的组件，分身乏术，一时还没有时间和精力重新加回来，以后肯定会逐渐完善，所以就先弄了命令这么一个短期的解决方案。命令行使用起来不如图形界面易用，但是心想着等 Forge 开发组重写了框架就能回到原来的配置界面，所以就无所谓了。

![配置命令]({{ img_path_l10n }}/config-command.png)

这一等就是一年，Forge 都发布三个稳定版了，新的配置界面框架却还没完成，目前仅有的进度还是一个[外部开发者提交的尚未完工的 pull request](https://github.com/MinecraftForge/MinecraftForge/pull/6467)。当时我写的只准备用来熬到框架完成的 mod 配置命令，已经不能指望着用来糊弄了，而且继续等下去也是个无底洞，所以我放弃了无止境的等待，研究如何不用 Forge 的框架来做配置界面。我估计，如果不是这名外部开发者做了一些东西提交了个 pull request，Forge 的核心开发者可能已经忘了他们有东西删了后没加回来，甚至可能都不准备重写了，让 Forge 就这么一个个地失去本来有的功能，继续发布功能残缺的稳定版，逐渐退化下去。

## 计划

新的配置界面不一定必须复刻之前 Forge 风格的配置界面，“撤销更改”和“重置为默认值”这些功能一来不好弄，二来可能没必要；一个配置界面只要允许玩家轻松修改设置就基本可以了，比如 Minecraft 自己的设置界面。

![Minecraft 设置界面]({{ img_path_l10n }}/mc-video-settings.png)

在配置 Minecraft Forge 开发环境的时候，会自动安装 Mod Coder Pack (MCP)。MCP 可以反编译 Minecraft，然后以一个程序库的形式提供反编译后的代码，这样一来 Forge mod 就可以直接使用 Minecraft 的 API，与之进行交互。也正是因为如此，我们可以仿照 Minecraft 设置界面的风格，利用 Minecraft 的 API 来做一个 mod 的配置界面。

在上面 Minecraft 设置界面的截图中，我们可以找到三种类型的控件：

- 滑块，用来调整数值选项，例如最高帧率
- 开关按钮，用来调整布尔值选项
- 在多个选项设定值中滚动切换的按钮，比如界面尺寸（自动、小、中、大）和攻击指示器样式（关、十字准星、快捷栏）

恰好，Hypixel 起床战争助手的所有选项都在这三种类型的选项当中，意味着我可以直接用 Minecraft 中和设置界面相关的工具来创建 mod 配置界面，不需要自己再造任何额外的轮子。

## 步骤

在 Minecraft 1.14.4 和更高版本上为一个 Minecraft Forge mod 做配置界面的步骤大致分为：为配置界面创建一个类、注册配置界面工厂、添加配置界面上要显示的元素、以及将配置界面前端和 mod 配置后端连接起来。

### 为配置界面创建类

Minecraft 当中有一个 `net.minecraft.client.gui.screen.Screen` 类被设计为所有游戏内屏幕界面的父类，因此我的 mod 的配置界面也将成为它的子类。

`Screen` 类中有如下重要成员，子类可能往往会覆写或调用：

- `protected Screen(ITextComponent title)`：唯一的构造器
- `protected void init()`：执行屏幕界面初始化任务
- `public void render(int mouseX, int mouseY, float partialTicks)`：渲染屏幕界面
- `public void onClose()`：关闭屏幕界面，并执行清理任务

于是，我首先写了一个简单的 `ConfigScreen` 类：

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
    public void render(int mouseX, int mouseY, float partialTicks) {
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

配置界面类创建好了，但现在还需要一个能创建它的实例的入口，用户才能打开这个界面来修改设置。下面要做的就是向 Minecraft Forge 注册可以创建新的配置界面实例的工厂。注册了工厂，mod 列表中的“配置”按钮就会亮起，用户点击它就可以进入配置界面了。

配置界面工厂的注册操作应在 mod 主类（也就是有 `@Mod` 标注的类）的公有构造器中完成：

```java
import net.minecraftforge.fml.ExtensionPoint;
import net.minecraftforge.fml.ModLoadingContext;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.fml.event.lifecycle.FMLClientSetupEvent;
import net.minecraftforge.fml.javafmlmod.FMLJavaModLoadingContext;

@Mod(HbwHelper.MOD_ID)
public final class HbwHelper {
    public static final String NAME = "HBW Helper";
    public static final String MOD_ID = "hbwhelper";

    public HbwHelper() {
        FMLJavaModLoadingContext.get().getModEventBus()
                .addListener(this::clientSetup);
        // 注册配置界面工厂
        ModLoadingContext.get().registerExtensionPoint(
                ExtensionPoint.CONFIGGUIFACTORY,
                () -> (mc, screen) -> new ConfigScreen()
        );
    }

    private void clientSetup(FMLClientSetupEvent event) {
        ...
    }
}
```

这个用来注册工厂的 [`registerExtensionPoint` 方法](https://github.com/MinecraftForge/MinecraftForge/blob/d5cb0935e9758e1ae62dadf4535a12a5fda8e9f1/src/main/java/net/minecraftforge/fml/ModLoadingContext.java#L57)调用有些复杂，我们来仔细看一下。这个方法的签名如下：

```java
public <T> void registerExtensionPoint(ExtensionPoint<T> point,
                                       Supplier<T> extension)
```

这个方法的第一个参数要求一个 `ExtensionPoint<T>` 类型的对象。看过这个类的[源代码](https://github.com/MinecraftForge/MinecraftForge/blob/31.2/src/main/java/net/minecraftforge/fml/ExtensionPoint.java)后，您会发现它里面有三个这个类的实例，各自存在一个常量中，然后还有一个私有构造器，防止更多的实例被创建。这样的设计模式和一个有三个常量的枚举类很相似，然而因为枚举类不可以是泛型类，设计这个 `ExtensionPoint` 类时就不得不用这种方式来曲线救国，来模拟一个泛型枚举类。

`ExtensionPoint` 的 `CONFIGGUIFACTORY` 常量，顾名思义就是用来注册配置界面工厂的：

```java
public static final
ExtensionPoint<BiFunction<Minecraft, Screen, Screen>> CONFIGGUIFACTORY
        = new ExtensionPoint<>();
```

在这个常量的声明中，`ExtensionPoint` 的类型参数 `<T>` 是 `BiFunction<Minecraft, Screen, Screen>`。[`BiFunction`](https://docs.oracle.com/javase/8/docs/api/java/util/function/BiFunction.html) 是 Java API 中的一个类，作为 lambda 表达式支持的一部分，在 Java 8 里新加入的。此接口用来代表一个接受两个输入值，然后输出一个结果的函数。

`BiFunction<Minecraft, Screen, Screen>` 在这里的实际用途是配置界面工厂的类型。在需要创建一个配置界面实例的时候，Minecraft Forge 会给工厂一个 `Minecraft` 实例和启动配置界面的屏幕的对象，然后从工厂获得创建的配置界面实例。工厂既可以选择不理会 Forge 提供的参数，直接返回一个普通的配置界面实例，也可以依据参数的具体情况来创建一个特殊的配置界面。我这里使用的工厂 `(mc, screen) -> new
ConfigScreen()` 就是一个不理会参数的工厂。这里顺带用到了 *lambda 表达式*；如果不熟悉的话，可以在网上查阅相关资料。

而同样的类型也成为了 `registerExtensionPoint` 方法的类型参数 `<T>`，意味着这个方法的第二个参数——`extension`——被要求的类型是 `Supplier<BiFunction<Minecraft, Screen, Screen>`，也就是配置界面工厂的提供者。此处用到的 [`Supplier`](https://docs.oracle.com/javase/8/docs/api/java/util/function/Supplier.html) 接口用来代表一个不接受任何输入、直接返回结果的函数。只需要再写一个直接返回我刚才提到的工厂的 lambda 表达式 `() -> (mc, screen) -> new ConfigScreen()`，这个参数就解决了。


### 添加基本 UI 元素

成功注册配置界面的工厂，并且工厂可以正常地创建配置界面的实例后，我们就可以在 mod 列表点击“配置”按钮进入配置界面了。不过，因为目前只添加并渲染了屏幕标题，进去后会发现配置界面除了标题外空空如也，而且除非按 Esc 键，否则也没办法退出。

![空白的配置界面]({{ img_path_l10n }}/blank-config-screen.png)

要想模仿一个 Minecraft 原生风格的配置界面，我们需要创建一个在屏幕中间包含配置所有选项用的控件的容器、以及屏幕底部的“完成”按钮。控件容器的背后是一个 `net.minecraft.client.gui.widget.list.OptionsRowList` 对象。从 `OptionsRowList` 这个名字里可以看出，它就是用来存储 Minecraft 设置界面里一行一行选项的列表。至于“完成”按钮，Minecraft 中有一个 `net.minecraft.client.gui.widget.button.Button` 类，可以用来创建各种按钮。

```java
import net.minecraft.client.gui.widget.button.Button;
import net.minecraft.client.gui.widget.list.OptionsRowList;
import net.minecraft.client.resources.I18n;

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
                I18n.format("gui.done"),
                // 按钮被点击时执行的操作
                button -> this.onClose()
        ));
    }

    @Override
    public void render(int mouseX, int mouseY, float partialTicks) {
        this.renderBackground();
        // 为避免显示错乱，需要在这个时机渲染选项列表
        this.optionsRowList.render(mouseX, mouseY, partialTicks);
        this.drawCenteredString(this.font, this.title.getFormattedText(),
                this.width / 2, TITLE_HEIGHT, 0xFFFFFF);
        super.render(mouseX, mouseY, partialTicks);
    }
}
```

我在上面代码里加的注释应该可以解释这些类的用法和注意事项，不过还是有必要再额外说一下 `Button` 构造器的最后一个参数。这个参数的类型是 `Button.IPressable`，是一个接口，定义如下：

```java
public interface IPressable {
    void onPress(Button button);
}
```

这个接口代表了按钮被按下时的回调函数。实现这个接口，在它唯一的 `onPress` 方法的实现中插入按钮被按下时要执行的代码，然后在用户点击按钮时，`onPress` 方法就会被调用，`button` 参数的值也就是该按钮对应的 `Button` 对象。

作为一个“完成”按钮，我们希望在用户按下它时将配置界面关闭，所以我在回调函数中调用了 `Screen.onClose` 方法来关闭界面。此外，作为只有一个抽象方法的接口，`IPressable` 也是一个*函数式接口*，因此可以直接用 lambda 表达式 `button -> this.onClose()` 来实现它。

现在配置界面最基础的结构就完成了，可以开始添加用来操纵选项的控件了。

![基本配置界面]({{ img_path_l10n }}/basic-config-screen.png)

### 添加操纵选项的控件

我的 mod 的选项的值都是布尔值、数值或者枚举常量。对于每种数据类型，Minecraft 的 `net.minecraft.client.settings` 程序包中都有对应的控件：

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

此处定义的 getter 和 setter 都用到了泛型，并且包含类型参数 `net.minecraft.client.GameSettings`——这是 Minecraft 用来代表游戏设置的类。Getter 是一个 [`Predicate`](https://docs.oracle.com/javase/8/docs/api/java/util/function/Predicate.html)，接受一个某种类型的数值然后返回一个 `boolean` 值；setter 是一个 [`BiConsumer`](https://docs.oracle.com/javase/8/docs/api/java/util/function/BiConsumer.html)，接受两个值，然后可能使用它们进行一些操作，但不返回任何值。

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

        this.optionsRowList.addOption(new BooleanOption(
                "hbwhelper.configGui.showArmorInfo.title",
                // GameSettings 参数被忽略
                unused -> ModSettings.getShowArmorInfo(),
                (unused, newValue) -> ModSettings.setShowArmorInfo(newValue)
        ));

        this.children.add(this.optionsRowList);

        ...
    }
```

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

最有意思的参数当属 `getDisplayString`，一个返回此选项的字符串表示的 `BiFunction`。这个 `BiFunction` 返回的字符串将会被显示在配置界面上。`BooleanOption` 的构造器是没有这个参数的，因为那个类它自己定义了默认的字符串表示方式，也就是 `<选项名>: [开|关]`。然而，`SliderPercentageOption` 没有类似的默认定义，需要程序员来指定怎么以字符串来表示一个选项。我这里用的返回格式相似的字符串表示的 `BiFunction` 是 `(gs,
option) -> option.getDisplayString() + option.get(gs)`。

在下面的示例中，假设 `ModSettings.getHudX` 返回 `int`，并且 `ModSettings.setHudX` 需要一个 `int` 参数。

```java
        // 添加整数值选项
        // 如果需要小数值选项的话，需要移除类型转换，并按需调整步进值
        this.optionsRowList.addOption(new SliderPercentageOption(
                "hbwhelper.configGui.hudX.title",
                // 范围：0 到当前窗口宽度
                0.0, this.width,
                // 由于是整数值，使用整数步进
                1.0F,
                // Getter 和 setter 指定方法与 BooleanOption 类似
                unused -> (double) ModSettings.getHudX(),
                (unused, newValue) -> ModSettings.setHudX(newValue.intValue()),
                // 返回 "<选项名>: <设定值>" 格式的字符串的 BiFunction
                (gs, option) -> option.getDisplayString() + (int) option.get(gs)
        ));
```

#### `IteratableOption`

`IteratableOption` 的构造器和 `BooleanOption` 的很像，不过请注意一点，那就是 getter 和 setter 的位置被调换了。

```java
public IteratableOption(String translationKey,
                        BiConsumer<GameSettings, Integer> setter,
                        BiFunction<GameSettings, IteratableOption, String> getter)
```

`IteratableOption` 类并不关心这个选项允许的值的类型；它只关心被选定的选项在允许的设定值序列中的下标。这也是为什么它的 setter 接受的是一个整数，而不是一个泛型对象。因此，如果要使用 `IteratableOption` 的话，需要明确定义每个允许的设定值的下标。如果允许的设定值都被存在一个数组或者列表里的话，直接用数组或列表的下标就可以了；如果是枚举类常量，可以将 [`Enum.ordinal()`](https://docs.oracle.com/javase/8/docs/api/java/lang/Enum.html#ordinal--) 方法返回的序数用作下标。

当选项被更改时，setter 会被传入一个整数值。把这个值和当前设定在允许的设定值序列中的下标相加，在一般情况下就会得到新设定值的下标。这个计算操作是需要由 setter 负责的；特别需要注意的是，如果越过了序列的结尾，回到了序列的开头，必须小心处理下标的计算，及时将下标归零，避免越界。

至于 getter 方面，它是一个返回字符串而非整数的 `BiFunction`，数据类型和 setter 出现了偏差。`IteratableOption` 的 getter 的作用和上文中 `SliderPercentageOption` 构造器的 `getDisplayString` 是一样的，都是返回直接显示在配置界面上的文字，而非代表当前设定值的对象，甚至不是下标。

这样的设计可能让 API 难以理解和使用，不过倒是允许 `IteratableOption` 忽略所有与一个选项允许的设定值相关的信息。像总共有多少个设定值被允许、以及每个设定值的字符串表示这些信息，`IteratableOption` 都不需要知道。

下面的示例演示了如何添加一个允许的设定值来自枚举类常量的选项。用到的枚举类是我的 mod 的 `DreamMode` 类，可以在[此处](https://github.com/Leo3418/HBWHelper/blob/v1.2.0/src/main/java/io/github/leo3418/hbwhelper/game/DreamMode.java)找到它的源代码。

```java
        // 添加允许的设定值来自枚举类常量的选项
        this.optionsRowList.addOption(new IteratableOption(
                "hbwhelper.configGui.dreamMode.title",
                (unused, newValue) ->
                        // 每个枚举类都有一个编译器生成的 'values()' 静态方法，
                        // 返回存有该枚举类所有常量的数组
                        ModSettings.setDreamMode(DreamMode.values()[
                                (ModSettings.getDreamMode().ordinal() + newValue)
                                    // 处理从序列结尾回到开头的特殊情况
                                        % DreamMode.values().length
                        ]),
                (unused, option) -> option.getDisplayString() +
                        I18n.format(ModSettings.getDreamMode().getTranslateKey())
        ));
```

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

![完整的配置界面]({{ img_path_l10n }}/complete-config-screen.png)

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
        this.minecraft.displayGuiScreen(parentScreen);
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

## 总结

Minecraft Forge 原有的允许 mod 创建自己的配置界面的框架在 Minecraft 1.13 推出后被移除，之后一直没有被加回来。这篇文章中所记载的就是如何在没有该框架的情况下，直接用 Minecraft 的 API 来写一个类似的 mod 配置界面。

如果是 Minecraft 1.12.2 或者之前的版本的话，就可以直接使用 Forge 的配置界面框架，无需依照本篇文章的描述用 Minecraft 的 API 来替代。

## 更多资源

如果您想找个用此文章记载的方法创建的配置界面的完整例子，可以在[这里](https://github.com/Leo3418/HBWHelper/blob/f13354adeeca6618f8047477fe20f121043f61c8/src/main/java/io/github/leo3418/hbwhelper/gui/ConfigScreen.java)找到我的 mod 的配置界面类。

您还可以在 IDE 中打开下面列出的类，阅读它们的源代码，学习更多此文章中提及的 API 的用法示例。这些源代码都是在配置 mod 开发环境时反编译 Minecraft 得到的。

- `net.minecraft.client.gui.screen.VideoSettingsScreen`
- `net.minecraft.client.settings.AbstractOption`
