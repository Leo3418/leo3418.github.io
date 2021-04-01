---
title: "MC Forge Mod 开发记录：升级到 Minecraft 1.16"
lang: zh
tags:
  - Minecraft Forge
  - Java
categories:
  - 博客
toc: true
last_modified_at: 2021-03-31
---

Minecraft Forge 支持 Minecraft 1.16 已经有相当长一段时间了。1.16.x 系列的第一个稳定版本 34.1.0 早在 2020 年 9 月，也就是我[这个系列上一篇关于我的 mod 的更新的文章][config-screen]发布不久后，就已经出了。其实在我准备更新 mod 期间，Forge 的 1.16 支持就已经比较成熟了，所以我当时就在考虑要不要在更新时顺带把 mod 移植到 1.16 上。但是，经过艰苦的尝试，我发现当时 Forge 附带的 MCP 反编译出的 Minecraft 代码中依然有许多没完全*反混淆*的方法名称，遂感觉 Forge 对 1.16 的支持仍然不够完善，于是决定暂不把 mod 移植到 1.16。

后来，我看到 Forge 出了第一个 1.16 的稳定版后，就将其下载了下来，看了看之前没反混淆的那些方法的名字有没有给改过来。结果是令人十分失望的：所有原来没反混淆的名字，一个都没有变。这样一个在我看来完全算不上是一个稳定版本，Forge 就这么草草发布，贴上了“推荐”的标签，顺带还[停止了 1.14.x 的支持][1.14-eol]。停止支持意味着什么呢？意味着如果您在 Forge 官方论坛发帖求助，并且您用的是一个停止支持的版本，[就][eol-thread-msg-1][会][eol-thread-msg-2][有][eol-thread-msg-3]论坛管理给您扔下一句冷冰冰的“你用的版本已停止支持，请升级以继续获得支持”，然后无情地关闭您的帖子，顺手阻止了其他非管理员的论坛成员提供帮助。好家伙，发布一个未成品，还把一个稳定版本的支持结束了，就是强行让追求稳定的开发者选择 1.15.x 呗？我当时差点就要在这里写一篇檄文，点评 Forge 开发者对“稳定版”的重新定义、以及论坛管理对于有关停止支持的版本的提问的冷淡的处理态度。

于是乎，我决定继续等，等到我认为真正能称得上是稳定版的 Forge 出了再说。但是因为后来就忙了，这一等就是相当长的时间。2020 年 10 月底的时候，反混淆算是[基本完成][mappings-update]了，我的 mod 的绝大多数代码也相应地被成功迁移到了 Minecraft 1.16 上。唯一没有解决的问题，是 1.16 中对和游戏内文本相关的 API 的重新设计导致我的 mod 中一些模块不兼容。我的 mod 需要通过阅读游戏内聊天信息的方式来检测起床战争游戏开没开始和记录团队升级，并且依赖聊天信息里的[格式代码][formatting-codes]来正常工作，但是读取带格式代码的聊天信息的方法在 1.16 里被删除了，所以我就只能自己解析聊天信息对象、自己重建带格式代码的聊天信息。虽然最后写出的解决方案并不复杂，但当时感觉这是个大工程的我决定以后再解决，而这一拖就拖到了最近。

<div class="notice--success">

{{ "**什么是反混淆？**" | markdownify }}

{{ "回答这个问题前，我们先看什么是*混淆*。[混淆](https://zh.wikipedia.org/zh-cn/%E4%BB%A3%E7%A0%81%E6%B7%B7%E6%B7%86)是那些急于阻止自己的程序件被逆向工程的软件开发者，为了防止其他人仅从程序的函数名/方法名中获得一点点有关程序内部实现原理的蛛丝马迹，所采取的一种手段。混淆的具体作用，是将函数名/方法名变为毫无意义的名字，这样别人就无法通过函数名/方法名来猜测一个函数/方法是用来干什么的了。" | markdownify }}

{{ "Mojang 基本是一直在对 Minecraft 的代码进行混淆，这无疑给想对游戏机制进行修改的 mod 开发者竖起了壁垒。而 [Mod Coder Pack](https://docs.spongepowered.org/stable/zh-CN/plugin/internals/mcp.html)（MCP）可以在反编译 Minecraft 的基础上，将反编译出的代码中的混淆后的方法名称，全部一一转换为能表达方法目的且更加友好的名称。这个过程就叫做**反混淆**。" | markdownify }}

{{ "全面反混淆 Minecraft 中的方法名称的结果是 *MCP 映射*，可为 Minecraft 中的方法提供易于理解的命名（*MCP 命名*），比如 `getMainWindow`。但这些命名的产生绝不是无中生有，而是要得益于与 Minecraft mod 相关的开发者们的付出。如果 Minecraft 中的某个方法还没有开发者提供 MCP 命名，那么它就会被分配一个 *Searge 映射*中的 *Searge 命名*，例如 `func_228018_at_`。在我看来，Searge 映射只能算是*不完全*的反混淆：虽然一个方法的 Searge 名称跟它在编译后的 Minecraft 二进制文件中的名称是不同的，也就意味着还是实现了初步的反混淆，但是 Searge 名称依然不能告诉我们一个方法的具体用途，所以仍然不能算是最终极的反混淆。" | markdownify }}

{{ "如果某个 Minecraft Forge 版本附带的 MCP 中仍然包含许多无意义的 Searge 命名的话，那基于这个 Forge 版本开发 mod 可能就会很艰难。我的 mod 的代码库中的[这次提交](https://github.com/Leo3418/HBWHelper/commit/ddd6cecfec3c3168aba025a11ccff16583bc9b25)就是展示这一点的一个很好的例子：这次提交将 Forge 升级到了一个 MCP 映射更完整的版本，带来的直接好处就是我可以把我 mod 中用到 Searge 命名的地方都相应地替换为 MCP 名称了。试问有没有人会倾向于使用 Searge 命名而非清晰易懂的 MCP 命名编程的？这就是我对 Forge 将一个仍有许多尚未完全反混淆的方法名的版本称为稳定版的行为如此不满的原因。如果换做是我的话，我在 MCP 映射都做完之前是绝不会发布 1.16 的 Forge 稳定版的，因为指望着 mod 开发者自己去猜每个方法的用途是一种不负责任的行为。" | markdownify }}

{{ "*P.S. 但愿各位不会以将程序内部实现原理保密为目的而混淆代码，无论是因为上司要求还是完全出于自愿。混淆代码有悖于自由软件精神，损害了他人基本的研究软件的工作原理和根据自己的意愿修改软件的自由。*" | markdownify }}

</div>

吐槽就到此为止了，接下来我将开始介绍我为了把自己的 mod 更新到 1.16 都做了哪些改动。

[config-screen]: /2020/09/09/forge-mod-config-screen.html
[1.14-eol]: https://forums.minecraftforge.net/topic/91710-forge-341-minecraft-1163/
[eol-thread-msg-1]: https://forums.minecraftforge.net/topic/97284-forge-1144-sever-help/?do=findComment&comment=442057
[eol-thread-msg-2]: https://forums.minecraftforge.net/topic/97309-help-please/?do=findComment&comment=442112
[eol-thread-msg-3]: https://forums.minecraftforge.net/topic/97311-how-can-i-remove-knockback/?do=findComment&comment=442119
[mappings-update]: https://github.com/MinecraftForge/MinecraftForge/commit/53eedb0f102bb1d8cf9432fae891730481206bce
[formatting-codes]: https://minecraft-zh.gamepedia.com/%E6%A0%BC%E5%BC%8F%E5%8C%96%E4%BB%A3%E7%A0%81

## 用于图形渲染的各种方法要求额外的 `matrixStack` 参数

Minecraft 1.16.x 中许多和图形渲染相关的方法现在都要求一个额外的 `com.mojang.blaze3d.matrix.MatrixStack` 类型的参数。如果您在调用图形渲染方法的时候，当前的命名空间（比如当前的类的字段，或者当前方法的参数和本地变量）里已经有了一个 `matrixStack` 变量，那么您可以直接将该变量的值用于此参数。如果没有的话，您也可以直接使用 `MatrixStack` 类的默认构造器 `new MatrixStack()` 创建一个新对象用于此参数。

我们来看下面这段代码，它是一个负责屏幕界面渲染的方法，其中调用了一些其它的渲染界面元素的方法，例如 `renderBackground` 绘制界面的背景、`drawCenteredString` 绘制文本：

```java
@Override
public void render(int mouseX, int mouseY, float partialTicks) {
    // 渲染界面背景
    this.renderBackground();
    // 渲染标题
    this.drawCenteredString(this.font, title, width, height, color);
    // 调用父类对应方法，完成渲染
    super.render(mouseX, mouseY, partialTicks);
}
```

到了 Minecraft 1.16.x，这样一个方法就需要改为如下所示的样子了。请注意该方法自己的签名以及它调用的其它图形渲染方法都多了一个 `matrixStack` 参数：

```java
@Override
public void render(MatrixStack matrixStack, int mouseX, int mouseY, float partialTicks) {
    this.renderBackground(matrixStack);
    drawCenteredString(matrixStack, this.font, title, width, height, color);
    super.render(matrixStack, mouseX, mouseY, partialTicks);
}
```

## 用于获取设置选项的名称的方法被删除

如果您参考[本系列博客的上一篇文章][config-screen]中介绍的方法创建了一个配置界面的话，那么您需要对每个使用 `SliderPercentageOption` 和 `IteratableOption` 的地方进行修改。在该文章中，我使用了 `net.minecraft.client.settings.AbstractOption.getDisplayString()` 方法来获取设置选项的显示名称，但在 1.16 中，这个方法变成了另一个 `protected` 方法 `getBaseMessageTranslation()`，因此现在 `AbstractOption` 类中就没有公开的返回选项名称的方法了。如果您还想像在以前版本中那样显示选项名称的话，您需要自行生成名称字符串。具体的方法是将选项名称的翻译键传给 `I18n.format(String)` 以获得翻译后的选项名称，然后将其与一个冒号串接起来。

```java
import net.minecraft.client.settings.SliderPercentageOption;
import net.minecraft.client.settings.IteratableOption;
import net.minecraft.util.text.StringTextComponent;
import net.minecraft.client.resources.I18n;

// SliderPercentageOption
this.optionsRowList.addOption(new SliderPercentageOption(
        "hbwhelper.configGui.hudX.title",
        min, max, step,
        unused -> (double) ModSettings.getHudX(),
        (unused, newValue) -> ModSettings.setHudX(newValue.intValue()),
        // 返回 "<选项名>: <设定值>" 格式的字符串的 BiFunction
        (gs, option) -> new StringTextComponent(
                // 使用 I18n.format(String) 查询一个翻译键对应的译文
                I18n.format("hbwhelper.configGui.hudX.title")
                + ": "
                + (int) option.get(gs)
        )
));

// IteratableOption
this.optionsRowList.addOption(new IteratableOption(
        "hbwhelper.configGui.dreamMode.title",
        (unused, newValue) ->
                ModSettings.setDreamMode(DreamMode.values()[
                        (ModSettings.getDreamMode().ordinal() + newValue)
                                % DreamMode.values().length
                ]),
        (unused, option) -> new StringTextComponent(
                I18n.format("hbwhelper.configGui.dreamMode.title")
                + ": "
                + I18n.format(ModSettings.getDreamMode().getTranslateKey())
        )
));
```

这样的改动不可避免地导致了源代码中翻译键的重复，但这是我能想到的最直接的解决方法。毕竟我们选择了使用 Minecraft 内部没有任何文档的 API，也得做好 API 出现各种不兼容的改动的心理准备。

还有一种解决方法，就是继承 `SliderPercentageOption` 和 `IteratableOption` 这两个类，就可以使用 `getBaseMessageTranslation()` 这个 `protected` 方法了。但这也意味着需要为此在 mod 中创建两个新类。

## 用于读取带格式代码的文本的方法被移除

许多 Minecraft 玩家都应该熟悉[格式代码][formatting-codes]，就是以分节符号 `§` 开头的代码。格式代码可以用来给文字添加颜色，还可以用来控制粗体、斜体等文字样式。我暂且称这种带格式代码的文本为*格式化文本*。

Minecraft 中有一个 `net.minecraft.util.text.ITextComponent` 接口，是文本要素（text component）对象的统一接口。您在 Minecraft 中看到的几乎所有文字的背后都有一个对应的文本要素对象。本来在 `ITextComponent` 接口中是有一个可用于获得一个文本要素所对应的格式化文本的 `getFormattedText()` 方法的，但是这个方法在 1.16 中被移除了，导致目前没有方式可以用来方便地从一个文本要素提取格式化文本了。

如果不能提取带格式代码的文本，那我的 mod 的功能就废了一半。我的 mod 通过检查聊天信息里有没有收到 Hypixel 在一局起床战争游戏开始时发送的介绍性文字来[检测游戏是否开始][game-detector]，并且通过[持续检测聊天里的提示][team-upgrades]判断玩家的队伍有没有购买团队升级。当然了，在 1.16 中仍然可以直接获取不带颜色代码的聊天文本，但这会允许了解我的 mod 的工作原理的人对使用我的 mod 的用户进行干扰。比如说，他们在聊天里发一条像“Leo3418 购买了治愈池”这种和 Hypixel 系统提示一样的信息，就能让我的 mod 误以为有人买了治愈池，尽管实际根本没有人买。我的 mod 现在防范这种攻击的措施是检查收到的信息里的格式代码，因为玩家发不了带格式的聊天信息，所有有格式代码的信息都肯定是 Hypixel 的系统提示。

为了解决这个问题，我专门写了一个[工具方法][text-components]，将 `ITextComponent` 转换为格式化文本，然后将 mod 代码中使用 `getFormattedText()` 的地方全部替换为使用我的工具方法即可。Minecraft 1.16 的 API 中仍然提供了足以允许我手动提取 `ITextComponent` 中的格式信息并自行生成格式化文本的方法，只不过步骤有些繁琐，所以我将相关的逻辑封装进了一个方法，以促进代码复用。

```diff
- String formattedMsg = event.getMessage().getFormattedText();
+ String formattedMsg = TextComponents.toFormattedText(event.getMessage());
```

如果您也与到了相同问题的话，您可以直接把我的 mod 中包含我那个工具方法的文件复制到您自己的 mod 中使用，毕竟我的 mod 是基于带附加权限的 GNU GPLv3+ 授权的自由软件，只要您遵守相关的[协议条款][mod-license]即可。

[game-detector]: https://github.com/Leo3418/HBWHelper/blob/v1.2.1/src/main/java/io/github/leo3418/hbwhelper/util/GameDetector.java#L202
[team-upgrades]: https://github.com/Leo3418/HBWHelper/blob/v1.2.1/src/main/java/io/github/leo3418/hbwhelper/game/GameManager.java#L323
[text-components]: https://github.com/Leo3418/HBWHelper/blob/v1.2.1/src/main/java/io/github/leo3418/hbwhelper/util/TextComponents.java#L68
[mod-license]: https://github.com/Leo3418/HBWHelper/tree/v1.2.1#license

## 用于发送聊天信息的方法要求额外参数

`net.minecraft.entity.Entity` 中的`sendMessage` 方法可以用来给玩家发送聊天信息：

```java
import net.minecraft.client.Minecraft;
import net.minecraft.util.text.StringTextComponent;

// 1.16 以前给玩家发送聊天信息的方法
Minecraft.getInstance().player.sendMessage(new StringTextComponent("hello, world"));
```

在 Minecraft 1.16 中，这个方法需要一个额外的 `java.util.UUID` 参数，代表的是发送聊天信息的玩家的 UUID。只有在多人联机时给其他玩家发送聊天信息时才会用到这个 UUID。如果您只是给当前客户端的玩家（也就是一个 `net.minecraft.client.entity.player.ClientPlayerEntity` 对象）发送提示信息的话，这个参数实际不会被用到，所以您可以随便指定它的值，连 `null` 都可以。但是如果您不喜欢在编程中大量使用 `null` 的话，您可以使用 Minecraft 提供的 `NIL_UUID`（这也是 Minecraft 自己调用这个方法时使用的参数）：

```java
import net.minecraft.client.Minecraft;
import net.minecraft.util.Util;
import net.minecraft.util.text.StringTextComponent;

Minecraft.getInstance().player.sendMessage(
        new StringTextComponent("hello, world"),
        Util.NIL_UUID
);
```

## `mods.toml` 中需声明 Mod 协议

从 Minecraft Forge 34.1 开始，您的 mod 的 `mods.toml` 中必须声明 `license` 字段，其对应的值就是您的 mod 的许可协议的名称。您可以参考[我自己的 mod 的 `mods.toml` 中的改动][mods-toml]。

[mods-toml]: https://github.com/Leo3418/HBWHelper/commit/71cc524438ec25fbeba8310fe14064465aeabf28

## 用于关闭屏幕界面的方法有改动

{: .notice--warning}
**注意：**此部分内容仅适用于 Minecraft Forge 35.1.x 及以前版本（对应 Minecraft 1.16.4 及以前版本）。如果您是在 Minecraft Forge 36.1.x（对应 Minecraft 1.16.5）及更高版本上开发的话，请忽略此部分内容。

在不是 Mojang 员工的情况下，我们能接触到的 Minecraft 的源代码就只有 MCP 反编译出的不带任何文档的源代码，所以我们要想了解 Minecraft API 的话，就只能通过直接阅读和研究源码、以及写一些调用 Minecraft API 的代码来实验和试错等方式了。根据我在开发 mod 的过程中与 Minecraft API 打交道的经验，在以前版本中关闭一个基于 `net.minecraft.client.gui.screen.Screen` 类的屏幕界面的原理是这样的：

- `Screen` 类中的 `onClose()` 方法里，应该包括当前屏幕将要被关闭时执行清理和收尾工作的代码，然后必须在该方法返回前调用 `net.minecraft.client.Minecraft.displayGuiScreen(Screen)` 以切到另一个屏幕界面。

- 默认情况下，如果用户按下了 Esc 键，当前屏幕的 `onClose()` 方法就会被调用，所以 `onClose()` 就是用来关闭屏幕界面的方法。

但是到了 Minecraft 1.16，`onClose()` 的作用就发生了变化：

- 用户按下 Esc 键时调用的方法被改为 `closeScreen()`——这是 `Screen` 类中的一个新方法。`closeScreen()` 的默认实现中只有一个 `Minecraft.displayGuiScreen(Screen)` 的调用。

- `onClose()` 里现在**不应该**再包含 `Minecraft.displayGuiScreen(Screen)` 的调用了，否则会导致游戏崩溃。现在 `onClose()` 当中只应该包含执行清理和收尾工作的代码。

- 因此，在 1.16 中就不能通过调用 `onClose()` 来关闭屏幕界面了，而是应该直接调用 `Minecraft.displayGuiScreen(Screen)`，或者用更佳的 `closeScreen()` 方法。这两个方法都会间接调用 `onClose()` 方法。

我们来看看这些修改对 mod 代码产生的实际影响，以下面的代码为例：

```java
/*
 * 在 1.14.4 和 1.15.x 上可正常运行，但与 1.16.x 不兼容
 */

import net.minecraft.client.gui.screen.Screen;
import net.minecraft.client.gui.widget.button.Button;
import net.minecraft.client.resources.I18n;

public final class ConfigScreen extends Screen {
    /** 当前界面的上级界面 */
    private final Screen parentScreen;

    public ConfigScreen(Screen parentScreen) {
        // 指定此界面的标题
        super(new TranslationTextComponent("hbwhelper.configGui.title",
                HbwHelper.NAME));
        this.parentScreen = parentScreen;
    }

    @Override
    protected void init() {
        ...
        // 添加一个用于退出此界面的“完成”按钮
        this.addButton(new Button(
                horizontalPosition, verticalPosition, width, height,
                I18n.format("gui.done"),
                // 按钮被点击时执行的操作
                button -> this.onClose()
        ));
    }

    /** 执行关闭界面前需要运行的任务，然后关闭此界面 */
    @Override
    public void onClose() {
        // 保存 mod 配置
        ModSettings.save();
        // 显示上级界面，以关闭当前的界面
        this.minecraft.displayGuiScreen(parentScreen);
    }
}
```

下面是将这个类移植到 Minecraft 1.16.x 后的代码：

```java
/*
 * 在 1.16.x 上可正常运行，但与 1.14.4、1.15.x 不兼容
 */

import net.minecraft.client.gui.screen.Screen;
import net.minecraft.client.gui.widget.button.Button;
import net.minecraft.client.resources.I18n;

public final class ConfigScreen extends Screen {
    private final Screen parentScreen;

    public ConfigScreen(Screen parentScreen) {
        super(new TranslationTextComponent("hbwhelper.configGui.title",
                HbwHelper.NAME));
        this.parentScreen = parentScreen;
    }

    @Override
    protected void init() {
        ...
        this.addButton(new Button(
                horizontalPosition, verticalPosition, width, height,
                // 此处按钮文字参数的类型也发生了变化，从 String 变为 ITextComponent
                new TranslationTextComponent("gui.done"),
                // 注意这里用于关闭屏幕的方法的改动
                button -> this.closeScreen()
        ));
    }

    /** 仅执行关闭界面前需要运行的任务 */
    @Override
    public void onClose() {
        ModSettings.save();
        // 此处不可调用 Minecraft.displayGuiScreen(Screen)！
    }

    /** 关闭此界面 (1.16 中的新方法) */
    @Override
    public void closeScreen() {
        // 显示上级界面的调用被移到了此处
        this.minecraft.displayGuiScreen(parentScreen);
    }
}
```

## 更多变动

除了上面提到的改动之外，Minecraft 1.16.x 和 Minecraft Forge 中肯定还有很多别的需要 mod 开发者更新 mod 代码的改动。这篇文章显然不能涵盖所有的改动；它的主要目的是分享我在解决迁移到 1.16 的问题时的经历和经验、以及我找到的解决办法，在您遇到相同问题时可以作为您的参考资料。希望这篇文章对您有所帮助！如果您需要更多相关资源的话，可以参阅[我的 mod 的 1.2.1 版本在 Minecraft 1.16.x 分支下的源代码][mod-src]，将其当作一个真实的例子进行参考。

[mod-src]: https://github.com/Leo3418/HBWHelper/tree/v1.2.1
