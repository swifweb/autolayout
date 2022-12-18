[![SwifWeb](https://user-images.githubusercontent.com/1272610/208304595-5f487e1b-e416-4b23-b14f-3503a22da6d3.png)](http://swifweb.com)

<p align="center">
    <a href="LICENSE">
        <img src="https://img.shields.io/badge/license-MIT-brightgreen.svg" alt="MIT License">
    </a>
    <a href="https://swift.org">
        <img src="https://img.shields.io/badge/swift-5.7-brightgreen.svg" alt="Swift 5.7">
    </a>
    <a href="https://discord.gg/q5wCPYv">
        <img src="https://img.shields.io/discord/612561840765141005" alt="Swift.Stream">
    </a>
</p>

This library gives you the powerful autolayout which works on pure CSS3  ❤️

It will help you to easily build your awesome reactive web app in beloved Swift ❤️

# Installation

Add package to your SwifWeb app's `Package.swift`

In dependencies section
```swift
 dependencies: [
    .package(url: "https://github.com/swifweb/autolayout", from: "1.0.3")
]
```
In target section
```swift
targets: [
    .executableTarget(name: "App", dependencies: [
        .product(name: "Web", package: "web"),
        .product(name: "Autolayout", package: "autolayout")
    ]
]
```

# Usage

Instead of building complex `@media` rules in stylesheets you now can do same inline declaratively.
Under the hood autolayout takes care about solving complex overriding priority issues.

```swift
import Autolayout

// amazingly laconic and powerful
Div()
    .position(.relative)
    .position(.absolute) // it will override relative with absolute for extra-small and small screens
    .height(100.px)
    .top()
    .backgroundColor(.brown)
    .widthToParent() // which is width: 100%
    .width(100.px, breakpoints: .xs, .s) // it will override 100% to 100px for extra-small and small screens
    .edges(h: 0.px) // which is left: 0px, right: 0px
    .centerX(breakpoints: .xs, .s) // it will disable right, and will set left: 50%, translate-x: -50% for extra-small and small screens
    .opacity(0.8, breakpoints: .xs, .s) // it will set opacity: 0.8 for extra-small and small screens
```

Start using it at any view by simply declaring methods listed below. But first read about breakpoints.

## Breakpoints

Normally we have to declare `@media` rules in a stylesheet, and it takes a lot of time.

With autolayout you could declare breakpoints (aka `@media` rules) once and use it as an alias.

There are predefined breakpoints for you:

```swift
.xs or .extraSmall        // <576px
.s or .small              // ≥576px and <768px
.m or .medium             // ≥768px and <992px
.l or .large              // ≥992px and <1200px
.xl or .extraLarge        // ≥1200px and <1400px
.xxl or .extraExtraLarge  // ≥1400px
```

or you can declare your own (just notice how long they are):
 
```swift
extension MediaRule.MediaType {
    static var extraSmall: MediaRule.MediaType { .init(.all.maxWidth(575.px), label: "xs") }
    static var small: MediaRule.MediaType { .init(.all.minWidth(576.px).maxWidth(767.px), label: "s") }
    static var medium: MediaRule.MediaType { .init(.all.minWidth(768.px).maxWidth(991.px), label: "m") }
}
```

> use `label: "xs"` to prettify your breakpoint in the source code, cause otherwise it will use just the whole rule text

Breakpoints can be added in the end of any autolayout-method. It uses full power of CSS3 `@media` rule under the hood.

```swift
.top(100.px, breakpoints: .extraSmall, .small, .medium)
```

Or you can use breakpoints within the classic stylesheet

```swift
@DOM override var body: DOM.Content {
    Stylesheet {
        Rule(Body.pointer)
            .margin(all: 0.px)
            .padding(all: 0.px)
        MediaRule(.xs, .s) { // will be applied only for extra-small and small screens
            Rule(Body.pointer)
                .backgroundColor(0x9bc4e2)
        }
        MediaRule(.m, .l, .xl) { // will be applied only for medium, large, and extra-large screens
            Rule(Body.pointer)
                .backgroundColor(0xffd700)
        }
    }
    // ...other elements...
}
```

## Methods

### Overriding

You can declare different values for the same property but with different breakpoints

```swift
// will be applied in any case
.width(600.px)

// will override any other values when screen width is extra-small or small
.width(200.px, breakpoints: .xs, .s)

// will override any other values when screen width is medium or large
.width(400.px, breakpoints: .m, .l)
```

The library will take care of overriding priority.

### Positioning

`top, right, bottom, left, center, width, height` methods relate to `position` property of the element and of its parent 

#### Setting global position

if you want to set these properties globally (to the window boundaries) then use
```swift
.position(.absolute) // or .fixed, .sticky
```

#### Setting relative position

if you want to set these properties relative to its parent then use 
```swift
.position(.relative)
```
and don't forget that that's parent also should have
```swift
.position(.relative)
```
or the parent of its parent and so on

#### Potential confusion

Please don't forget that with
```swift
.position(.static) // or if position haven't been set at all
```
only `width` and `height` property works, other properties just can't work in this case

> Each method also can be used with `@State` value

### Top

Specifies `top` position to the first parent element with relative position

#### Top to top

```swift
// will set top to 0px
.top()

// will set top to 100px
.top(100.px)

// will set top to 50px
.top(100.px, multiplier: 0.5)

// will set top to 0px only for extra-small, small and medium screens
.top(breakpoints: .xs, .s, .m)

// will set top to 50px only for extra-small, small and medium screens
.top(50.px, breakpoints: .xs, .s, .m)

// will set top to 25px only for extra-small, small and medium screens
.top(50.px, multiplier: 0.5, breakpoints: .xs, .s, .m)
```

#### Top to center

Simply add `side: .center` as a second argument and `top` side will stick to `center` of the first parent with relative position

```swift
// will set top to 0px from the center
.top(side: .center)

// will set top to 100px from the center
.top(100.px, side: .center)

// will set top to 50px from the center
.top(100.px, side: .center, multiplier: 0.5)

// will set top to 0px from the center only for extra-small, small and medium screens
.top(side: .center, breakpoints: .xs, .s, .m)

// will set top to 50px from the center only for extra-small, small and medium screens
.top(50.px, side: .center, breakpoints: .xs, .s, .m)

// will set top to 25px from the center only for extra-small, small and medium screens
.top(50.px, side: .center, multiplier: 0.5, breakpoints: .xs, .s, .m)
```

#### Top to bottom

Simply add `side: .bottom` as a second argument and `top` side will stick to `bottom` of the first parent with relative position

```swift
// will set top to 0px from the bottom
.top(side: .bottom)

// will set top to 100px from the bottom
.top(100.px, side: .bottom)

// will set top to 50px from the bottom
.top(100.px, side: .bottom, multiplier: 0.5)

// will set top to 0px from the bottom only for extra-small, small and medium screens
.top(side: .bottom, breakpoints: .xs, .s, .m)

// will set top to 50px from the bottom only for extra-small, small and medium screens
.top(50.px, side: .bottom, breakpoints: .xs, .s, .m)

// will set top to 25px from the bottom only for extra-small, small and medium screens
.top(50.px, side: .bottom, multiplier: 0.5, breakpoints: .xs, .s, .m)
```

### Bottom

Specifies `bottom` position to the first parent element with relative position

#### Bottom to bottom

```swift
// will set bottom to 0px
.bottom()

// will set bottom to 100px
.bottom(100.px)

// will set bottom to 50px
.bottom(100.px, multiplier: 0.5)

// will set bottom to 0px only for extra-small, small and medium screens
.bottom(breakpoints: .xs, .s, .m)

// will set bottom to 50px only for extra-small, small and medium screens
.bottom(50.px, breakpoints: .xs, .s, .m)

// will set bottom to 25px only for extra-small, small and medium screens
.bottom(50.px, multiplier: 0.5, breakpoints: .xs, .s, .m)
```

#### Bottom to center

Simply add `side: .center` as a second argument and `bottom` side will stick to `center` of the first parent with relative position

```swift
// will set bottom to 0px from the center
.bottom(side: .center)

// will set bottom to 100px from the center
.bottom(100.px, side: .center)

// will set bottom to 50px from the center
.bottom(100.px, side: .center, multiplier: 0.5)

// will set bottom to 0px from the center only for extra-small, small and medium screens
.bottom(side: .center, breakpoints: .xs, .s, .m)

// will set bottom to 50px from the center only for extra-small, small and medium screens
.bottom(50.px, side: .center, breakpoints: .xs, .s, .m)

// will set bottom to 25px from the center only for extra-small, small and medium screens
.bottom(50.px, side: .center, multiplier: 0.5, breakpoints: .xs, .s, .m)
```

#### Bottom to top

Simply add `side: .top` as a second argument and `bottom` side will stick to `top` of the first parent with relative position

```swift
// will set bottom to 0px from the top
.bottom(side: .top)

// will set bottom to 100px from the top
.bottom(100.px, side: .top)

// will set bottom to 50px from the top
.bottom(100.px, side: .top, multiplier: 0.5)

// will set bottom to 0px from the top only for extra-small, small and medium screens
.bottom(side: .top, breakpoints: .xs, .s, .m)

// will set bottom to 50px from the top only for extra-small, small and medium screens
.bottom(50.px, side: .top, breakpoints: .xs, .s, .m)

// will set bottom to 25px from the top only for extra-small, small and medium screens
.bottom(50.px, side: .top, multiplier: 0.5, breakpoints: .xs, .s, .m)
```

### Left

Specifies `left` position to the first parent element with relative position

#### Left to left

```swift
// will set left to 0px
.left()

// will set left to 100px
.left(100.px)

// will set left to 50px
.left(100.px, multiplier: 0.5)

// will set left to 0px only for extra-small, small and medium screens
.left(breakpoints: .xs, .s, .m)

// will set left to 50px only for extra-small, small and medium screens
.left(50.px, breakpoints: .xs, .s, .m)

// will set left to 25px only for extra-small, small and medium screens
.left(50.px, multiplier: 0.5, breakpoints: .xs, .s, .m)
```

#### Left to center

Simply add `side: .center` as a second argument and `left` side will stick to `center` of the first parent with relative position

```swift
// will set left to 0px from the center
.left(side: .center)

// will set left to 100px from the center
.left(100.px, side: .center)

// will set left to 50px from the center
.left(100.px, side: .center, multiplier: 0.5)

// will set left to 0px from the center only for extra-small, small and medium screens
.left(side: .center, breakpoints: .xs, .s, .m)

// will set left to 50px from the center only for extra-small, small and medium screens
.left(50.px, side: .center, breakpoints: .xs, .s, .m)

// will set left to 25px from the center only for extra-small, small and medium screens
.left(50.px, side: .center, multiplier: 0.5, breakpoints: .xs, .s, .m)
```

#### Left to right

Simply add `side: .right` as a second argument and `left` side will stick to `right` of the first parent with relative position

```swift
// will set left to 0px from the right
.left(side: .right)

// will set left to 100px from the right
.left(100.px, side: .right)

// will set left to 50px from the right
.left(100.px, side: .right, multiplier: 0.5)

// will set left to 0px from the right only for extra-small, small and medium screens
.left(side: .right, breakpoints: .xs, .s, .m)

// will set left to 50px from the right only for extra-small, small and medium screens
.left(50.px, side: .right, breakpoints: .xs, .s, .m)

// will set left to 25px from the right only for extra-small, small and medium screens
.left(50.px, side: .right, multiplier: 0.5, breakpoints: .xs, .s, .m)
```

### Right

Specifies `right` position to the first parent element with relative position

#### Right to right

```swift
// will set right to 0px
.right()

// will set right to 100px
.right(100.px)

// will set right to 50px
.right(100.px, multiplier: 0.5)

// will set right to 0px only for extra-small, small and medium screens
.right(breakpoints: .xs, .s, .m)

// will set right to 50px only for extra-small, small and medium screens
.right(50.px, breakpoints: .xs, .s, .m)

// will set right to 25px only for extra-small, small and medium screens
.right(50.px, multiplier: 0.5, breakpoints: .xs, .s, .m)
```

#### Right to center

Simply add `side: .center` as a second argument and `right` side will stick to `center` of the first parent with relative position

```swift
// will set right to 0px from the center
.right(side: .center)

// will set right to 100px from the center
.right(100.px, side: .center)

// will set right to 50px from the center
.right(100.px, side: .center, multiplier: 0.5)

// will set right to 0px from the center only for extra-small, small and medium screens
.right(side: .center, breakpoints: .xs, .s, .m)

// will set right to 50px from the center only for extra-small, small and medium screens
.right(50.px, side: .center, breakpoints: .xs, .s, .m)

// will set right to 25px from the center only for extra-small, small and medium screens
.right(50.px, side: .center, multiplier: 0.5, breakpoints: .xs, .s, .m)
```

#### Right to left

Simply add `side: .left` as a second argument and `right` side will stick to `left` of the first parent with relative position

```swift
// will set right to 0px from the left
.right(side: .left)

// will set right to 100px from the left
.right(100.px, side: .left)

// will set right to 50px from the left
.right(100.px, side: .left, multiplier: 0.5)

// will set right to 0px from the left only for extra-small, small and medium screens
.right(side: .left, breakpoints: .xs, .s, .m)

// will set right to 50px from the left only for extra-small, small and medium screens
.right(50.px, side: .left, breakpoints: .xs, .s, .m)

// will set right to 25px from the left only for extra-small, small and medium screens
.right(50.px, side: .left, multiplier: 0.5, breakpoints: .xs, .s, .m)
```

### Edges

Convenience setter for all sides: top, right, bottom, left

#### All edges

```swift
// Will set top, right, bottom, and left to 0px
.edges()

// Will set top, right, bottom, and left to 10px
.edges(10.px)

// Will set top, right, bottom, and left to 5px only for extra-small, small and medium screens
.edges(5.px, breakpoints: .xs, .s, .m)
```

#### Horizontal edges

```swift
// Will set left and right to 0px
.edges(h: 0.px)

// Will set left and right to 10px
.edges(h: 10.px)

// Will set left and right to 5px only for extra-small, small and medium screens
.edges(h: 5.px, breakpoints: .xs, .s, .m)
```

#### Vertical edges

```swift
// Will set top and bottom to 0px
.edges(v: 0.px)

// Will set top and bottom to 10px
.edges(v: 10.px)

// Will set top and bottom to 5px only for extra-small, small and medium screens
.edges(v: 5.px, breakpoints: .xs, .s, .m)
```

#### Horizontal and vertical edges

```swift
// Will set left and right to 0px, and top and bottom to 0px
.edges(h: 0.px, v: 0.px)

// Will set left and right to 0px, and top and bottom to 10px
.edges(h: 0.px, v: 10.px)

// Will set left and right to 2px, and top and bottom to 4px only for extra-small, small and medium screens
.edges(h: 2.px, v: 4.px, breakpoints: .xs, .s, .m)
```

### Center X

Specifies the horizontal center position to the first parent element with relative position

#### Center to center

```swift
// will set centerX to 0px
.centerX()

// will set centerX to 100px
.centerX(100.px)

// will set centerX to 50px
.centerX(100.px, multiplier: 0.5)

// will set centerX to 0px only for extra-small, small and medium screens
.centerX(breakpoints: .xs, .s, .m)

// will set centerX to 50px only for extra-small, small and medium screens
.centerX(50.px, breakpoints: .xs, .s, .m)

// will set centerX to 25px only for extra-small, small and medium screens
.centerX(50.px, multiplier: 0.5, breakpoints: .xs, .s, .m)
```

#### Center to left

Simply add `side: .left` as a second argument and `centerX` side will stick to `left` of the first parent with relative position

```swift
// will set centerX to 0px of the left
.centerX(side: .left)

// will set centerX to 100px of the left
.centerX(100.px, side: .left)

// will set centerX to 50px of the left
.centerX(100.px, side: .left, multiplier: 0.5)

// will set centerX to 0px of the left only for extra-small, small and medium screens
.centerX(side: .left, breakpoints: .xs, .s, .m)

// will set centerX to 50px of the left only for extra-small, small and medium screens
.centerX(50.px, side: .left, breakpoints: .xs, .s, .m)

// will set centerX to 25px of the left only for extra-small, small and medium screens
.centerX(50.px, side: .left, multiplier: 0.5, breakpoints: .xs, .s, .m)
```

#### Center to right

Simply add `side: .right` as a second argument and `centerX ` side will stick to `right` of the first parent with relative position

```swift
// will set centerX to 0px of the right
.centerX(side: .right)

// will set centerX to 100px of the right
.centerX(100.px, side: .right)

// will set centerX to 50px of the right
.centerX(100.px, side: .right, multiplier: 0.5)

// will set centerX to 0px of the right only for extra-small, small and medium screens
.centerX(side: .right, breakpoints: .xs, .s, .m)

// will set centerX to 50px of the right only for extra-small, small and medium screens
.centerX(50.px, side: .right, breakpoints: .xs, .s, .m)

// will set centerX to 25px of the right only for extra-small, small and medium screens
.centerX(50.px, side: .right, multiplier: 0.5, breakpoints: .xs, .s, .m)
```

### Center Y

Specifies the vertical center position to the first parent element with relative position

#### Center to center

```swift
// will set centerY to 0px
.centerY()

// will set centerY to 100px
.centerY(100.px)

// will set centerY to 50px
.centerY(100.px, multiplier: 0.5)

// will set centerY to 0px only for extra-small, small and medium screens
.centerY(breakpoints: .xs, .s, .m)

// will set centerY to 50px only for extra-small, small and medium screens
.centerY(50.px, breakpoints: .xs, .s, .m)

// will set centerY to 25px only for extra-small, small and medium screens
.centerY(50.px, multiplier: 0.5, breakpoints: .xs, .s, .m)
```

#### Center to top

Simply add `side: .top` as a second argument and `centerY` side will stick to `top` of the first parent with relative position

```swift
// will set centerY to 0px of the top
.centerY(side: .top)

// will set centerY to 100px of the top
.centerY(100.px, side: .top)

// will set centerY to 50px of the top
.centerY(100.px, side: .top, multiplier: 0.5)

// will set centerY to 0px of the top only for extra-small, small and medium screens
.centerY(side: .top, breakpoints: .xs, .s, .m)

// will set centerY to 50px of the top only for extra-small, small and medium screens
.centerY(50.px, side: .top, breakpoints: .xs, .s, .m)

// will set centerY to 25px of the top only for extra-small, small and medium screens
.centerY(50.px, side: .top, multiplier: 0.5, breakpoints: .xs, .s, .m)
```

#### Center to bottom

Simply add `side: .bottom` as a second argument and `centerY ` side will stick to `bottom` of the first parent with relative position

```swift
// will set centerY to 0px of the bottom
.centerY(side: .bottom)

// will set centerY to 100px of the bottom
.centerY(100.px, side: .bottom)

// will set centerY to 50px of the bottom
.centerY(100.px, side: .bottom, multiplier: 0.5)

// will set centerY to 0px of the bottom only for extra-small, small and medium screens
.centerY(side: .bottom, breakpoints: .xs, .s, .m)

// will set centerY to 50px of the bottom only for extra-small, small and medium screens
.centerY(50.px, side: .bottom, breakpoints: .xs, .s, .m)

// will set centerY to 25px of the bottom only for extra-small, small and medium screens
.centerY(50.px, side: .bottom, multiplier: 0.5, breakpoints: .xs, .s, .m)
```

### Center X+Y

Specifies both vertical and horizontal center position to the first parent element with relative position

```swift
// will set centerX and centerY to 0px
.center()

// will set centerX and centerY to 100px
.center(100.px)

// will set centerX and centerY to 50px
.center(100.px, multiplier: 0.5)

// will set centerX and centerY to 0px only for extra-small, small and medium screens
.center(breakpoints: .xs, .s, .m)

// will set centerX and centerY to 50px only for extra-small, small and medium screens
.center(50.px, breakpoints: .xs, .s, .m)

// will set centerX and centerY to 25px only for extra-small, small and medium screens
.center(50.px, multiplier: 0.5, breakpoints: .xs, .s, .m)
```

### Width

Sets width of an element

```swift
// will set width to 0px
.width()

// will set width to 100px
.width(100.px)

// will set width to 100%
.width(100.percent)

// will set width to 50px
.width(100.px, multiplier: 0.5)

// will set width to 0px only for extra-small, small and medium screens
.width(breakpoints: .xs, .s, .m)

// will set width to 50px only for extra-small, small and medium screens
.width(50.px, breakpoints: .xs, .s, .m)

// will set width to 25px only for extra-small, small and medium screens
.width(50.px, multiplier: 0.5, breakpoints: .xs, .s, .m)
```

### Width to parent

Sets width of an element to fit first parent element with relative position

```swift
// will set width to 100% of first parent element with relative position
.widthToParent()

// will set width to 100% of first parent element with relative position only for extra-small, small and medium screens
.widthToParent(breakpoints: .xs, .s, .m)

// will set width to 100% + 100px of first parent element with relative position
.widthToParent(extra: 100.px)

// will set width to 100% + 100px of first parent element with relative position
// only for extra-small, small and medium screens
.widthToParent(extra: 100.px, breakpoints: .xs, .s, .m)

// will set width to (100% + 100px) * 0.5 of first parent element with relative position
.widthToParent(extra: 100.px, multiplier: 0.5)

// will set width to (100% + 100px) * 0.5 of first parent element with relative position
// only for extra-small, small and medium screens
.widthToParent(extra: 100.px, multiplier: 0.5, breakpoints: .xs, .s, .m)

// will set width to 50% of first parent element with relative position
.widthToParent(multiplier: 0.5)

// will set width to 50% of first parent element with relative position
// only for extra-small, small and medium screens
.widthToParent(multiplier: 0.5, breakpoints: .xs, .s, .m)
```

### Height

Sets height of an element

```swift
// will set height to 0px
.height()

// will set height to 100px
.height(100.px)

// will set height to 100%
.height(100.percent)

// will set height to 50px
.height(100.px, multiplier: 0.5)

// will set height to 0px only for extra-small, small and medium screens
.height(breakpoints: .xs, .s, .m)

// will set height to 50px only for extra-small, small and medium screens
.height(50.px, breakpoints: .xs, .s, .m)

// will set height to 25px only for extra-small, small and medium screens
.height(50.px, multiplier: 0.5, breakpoints: .xs, .s, .m)
```

### Height to parent

Sets height of an element to fit first parent element with relative position

```swift
// will set height to 100% of first parent element with relative position
.heightToParent()

// will set height to 100% of first parent element with relative position only for extra-small, small and medium screens
.heightToParent(breakpoints: .xs, .s, .m)

// will set height to 100% + 100px of first parent element with relative position
.heightToParent(extra: 100.px)

// will set height to 100% + 100px of first parent element with relative position
// only for extra-small, small and medium screens
.heightToParent(extra: 100.px, breakpoints: .xs, .s, .m)

// will set height to (100% + 100px) * 0.5 of first parent element with relative position
.heightToParent(extra: 100.px, multiplier: 0.5)

// will set height to (100% + 100px) * 0.5 of first parent element with relative position
// only for extra-small, small and medium screens
.heightToParent(extra: 100.px, multiplier: 0.5, breakpoints: .xs, .s, .m)

// will set height to 50% of first parent element with relative position
.heightToParent(multiplier: 0.5)

// will set height to 50% of first parent element with relative position
// only for extra-small, small and medium screens
.heightToParent(multiplier: 0.5, breakpoints: .xs, .s, .m)
```

### Position

Specifies the type of positioning method used for an element `static, relative, absolute or fixed`

```swift
// will set position to absolute
.position(.absolute)

// will set position to absolute only for extra-small, small and medium screens
.position(.absolute, breakpoints: .xs, .s, .m)
```

### Display

Specifies how a certain HTML element should be displayed

```swift
// will set display to block
.display(.block)

// will set display to block only for extra-small, small and medium screens
.display(.block, breakpoints: .xs, .s, .m)
```

### Visibility

Specifies whether or not an element is visible

```swift
// will set visibility to visible
.visibility(.visible)

// will set visibility to hidden only for extra-small, small and medium screens
.visibility(.hidden, breakpoints: .xs, .s, .m)
```

### Opacity

Sets the opacity level for an element

```swift
// will set opacity to 0.8
.opacity(0.8)

// will set opacity to 0.5 only for extra-small, small and medium screens
.opacity(0.5, breakpoints: .xs, .s, .m)
```

# Live preview

To make it work with live preview you need to specify either all styles or exact autolayout's one

#### With all app styles included
```swift
class Welcome_Preview: WebPreview {
    override class var title: String { "Initial page" } // optional
    override class var width: UInt { 440 } // optional
    override class var height: UInt { 480 } // optional

    @Preview override class var content: Preview.Content {
        // add styles if needed
        AppStyles.all
        // add here as many elements as needed
        WelcomeViewController()
    }
}
```

#### With exact app styles including autoalyout's one
```swift
class Welcome_Preview: WebPreview {
    override class var title: String { "Initial page" } // optional
    override class var width: UInt { 440 } // optional
    override class var height: UInt { 480 } // optional

    @Preview override class var content: Preview.Content {
        // add styles if needed
        AppStyles.id(.mainStyle)
        AppStyles.id(.autolayoutStyles)
        // add here as many elements as needed
        WelcomeViewController()
    }
}
```
