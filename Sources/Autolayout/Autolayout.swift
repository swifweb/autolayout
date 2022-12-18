//
//  Autolayout.swift
//
//
//  Created by Mihael Isaev on 08.12.2022.
//

import Web
import ResizeObserverAPI

let _autolayout = Autolayout()

extension Id {
    public static var autolayoutStyles: Id { "autolayout_styles" }
}

public class Autolayout {
    let stylesheet = Stylesheet().id(.autolayoutStyles)
    var ruleIndexCache: [String: Int] = [:]
    
    fileprivate init () {
        #if WEBPREVIEW
        WebApp.shared.stylesheets.append(stylesheet)
        #endif
        WebApp.shared.document.head.appendChild(stylesheet)
    }
    
    // MARK: Constraints
    
    enum ConstraintAttribute: String {
        case left
        case right
        case top
        case bottom
        case width
        case height
        case centerX
        case centerY
    }
    
    // MARK: Constraint sides

    public enum ConstraintCXSide {
        case left, right, center
        var side: ConstraintAttribute {
            switch self {
            case .left: return .left
            case .right: return .right
            case .center: return .centerX
            }
        }
    }

    public enum ConstraintCYSide {
        case top, bottom, center
        var side: ConstraintAttribute {
            switch self {
            case .top: return .top
            case .bottom: return .bottom
            case .center: return .centerY
            }
        }
    }
    
    public enum ConstraintDSide {
        case width, height
        var side: ConstraintAttribute {
            switch self {
            case .width: return .width
            case .height: return .height
            }
        }
    }

    public enum ConstraintXSide {
        case left, right, center
        var side: ConstraintAttribute {
            switch self {
            case .left: return .left
            case .right: return .right
            case .center: return .centerX
            }
        }
    }

    public enum ConstraintYSide {
        case top, bottom, center
        var side: ConstraintAttribute {
            switch self {
            case .top: return .top
            case .bottom: return .bottom
            case .center: return .centerY
            }
        }
    }
}

extension MediaRule.MediaType {
    /// Extra small `<576px`
    public static var extraSmall: MediaRule.MediaType { .init(.all.maxWidth(575.px), label: "xs") }
    
    /// Small `≥576px` and `<768px`
    public static var small: MediaRule.MediaType { .init(.all.minWidth(576.px).maxWidth(767.px), label: "s") }
    
    /// Medium `≥768px` and `<992px`
    public static var medium: MediaRule.MediaType { .init(.all.minWidth(768.px).maxWidth(991.px), label: "m") }
    
    /// Large `≥992px` and `<1200px`
    public static var large: MediaRule.MediaType { .init(.all.minWidth(992.px).maxWidth(1199.px), label: "l") }
    
    /// Large `≥1200px` and `<1400px`
    public static var extraLarge: MediaRule.MediaType { .init(.all.minWidth(1200.px).maxWidth(1399.px), label: "xl") }
    
    /// Large `≥1400px`
    public static var extraExtraLarge: MediaRule.MediaType { .init(.all.minWidth(1400.px), label: "xxl") }
}

extension BaseElement {
    private func _getClassName(_ methodName: String, breakpoints: [MediaRule.MediaType]) -> String {
        let media = breakpoints.map {
            String($0.description.map { [" ", ",", "(", ")", "-", ":", "."].contains($0) ? "_" : $0 })
        }.joined(separator: "_")
        return properties._id + "_" + methodName + (media.isEmpty ? "" : "_" + media)
    }
    
    private func _setRule(
        _ className: String,
        breakpoints: [MediaRule.MediaType],
        _ rulesHandler: @escaping (CSSRule) -> CSSRule
    ) {
        if let indexToDelete = _autolayout.ruleIndexCache[className] {
            _autolayout.stylesheet.deleteRule(indexToDelete)
        }
        let index: Int
        if breakpoints.count == 0 {
            let rule = rulesHandler(CSSRule(Class(stringLiteral: className).pointer))
            index = _autolayout.stylesheet.addRule(rule)
        } else {
            let cssRule = CSSRule(Class(stringLiteral: className).pointer)
            let mediaRule = MediaRule(breakpoints) { cssRule }
            let _ = rulesHandler(cssRule)
            index = _autolayout.stylesheet.addMediaRule(mediaRule)
        }
        if index >= 0 {
            _autolayout.ruleIndexCache[className] = index
        }
    }
    
    // MARK: - Edges
    
    /// Convenience setter for all sides: top, right, bottom, left
    @discardableResult
    public func edges<U: UnitValuable>(
        _ value: U = 0.px,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        top(value)
        .left(value)
        .right(UnitValue(value.value.doubleValue * (-1), value.unit))
        .bottom(UnitValue(value.value.doubleValue * (-1), value.unit))
    }
    
    /// Convenience setter for all sides: top, right, bottom, left
    @discardableResult
    public func edges<U: UnitValuable>(
        _ value: U = 0.px,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        edges(value, breakpoints: breakpoints)
    }
    
    /// Convenience setter for all sides: top, right, bottom, left
    public func edges<U: UnitValuable>(
        _ value: State<U>,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        top(value)
        .left(value)
        .right(value.map { UnitValue($0.value.doubleValue * (-1), $0.unit) })
        .bottom(value.map { UnitValue($0.value.doubleValue * (-1), $0.unit) })
    }
    
    /// Convenience setter for all sides: top, right, bottom, left
    public func edges<U: UnitValuable>(
        _ value: State<U>,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        edges(value, breakpoints: breakpoints)
    }
    
    /// Convenience setter for horizontal sides: left and right
    @discardableResult
    public func edges<U: UnitValuable>(
        h: U,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        left(h)
        .right(UnitValue(h.value.doubleValue * (-1), h.unit))
    }
    
    /// Convenience setter for horizontal sides: left and right
    @discardableResult
    public func edges<U: UnitValuable>(
        h: U,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        edges(h: h, breakpoints: breakpoints)
    }
    
    /// Convenience setter for horizontal sides: left and right
    @discardableResult
    public func edges<U: UnitValuable>(
        h: State<U>,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        left(h)
        .right(h.map { UnitValue($0.value.doubleValue * (-1), $0.unit) })
    }
    
    /// Convenience setter for horizontal sides: left and right
    @discardableResult
    public func edges<U: UnitValuable>(
        h: State<U>,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        edges(h: h, breakpoints: breakpoints)
    }
    
    /// Convenience setter for vertical sides: top and bottom
    @discardableResult
    public func edges<U: UnitValuable>(
        v: U,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        top(v)
        .bottom(UnitValue(v.value.doubleValue * (-1), v.unit))
    }
    
    /// Convenience setter for vertical sides: top and bottom
    @discardableResult
    public func edges<U: UnitValuable>(
        v: U,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        edges(v: v, breakpoints: breakpoints)
    }
    
    /// Convenience setter for vertical sides: top and bottom
    @discardableResult
    public func edges<U: UnitValuable>(
        v: State<U>,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        top(v)
        .bottom(v.map { UnitValue($0.value.doubleValue * (-1), $0.unit) })
    }
    
    /// Convenience setter for vertical sides: top and bottom
    @discardableResult
    public func edges<U: UnitValuable>(
        v: State<U>,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        edges(v: v, breakpoints: breakpoints)
    }
    
    /// Convenience setter for horizontal sides: left and right, and vertical sides: top and bottom
    @discardableResult
    public func edges<H: UnitValuable, V: UnitValuable>(
        h: H,
        v: V,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        top(v)
        .left(h)
        .right(UnitValue(h.value.doubleValue * (-1), h.unit))
        .bottom(UnitValue(v.value.doubleValue * (-1), v.unit))
    }
    
    /// Convenience setter for horizontal sides: left and right, and vertical sides: top and bottom
    @discardableResult
    public func edges<H: UnitValuable, V: UnitValuable>(
        h: H,
        v: V,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        edges(h: h, v: v, breakpoints: breakpoints)
    }
    
    /// Convenience setter for horizontal sides: left and right, and vertical sides: top and bottom
    @discardableResult
    public func edges<H: UnitValuable, V: UnitValuable>(
        h: State<H>,
        v: State<V>,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        top(v)
        .left(h)
        .right(h.map { UnitValue($0.value.doubleValue * (-1), $0.unit) })
        .bottom(v.map { UnitValue($0.value.doubleValue * (-1), $0.unit) })
    }
    
    /// Convenience setter for horizontal sides: left and right, and vertical sides: top and bottom
    @discardableResult
    public func edges<H: UnitValuable, V: UnitValuable>(
        h: State<H>,
        v: State<V>,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        edges(h: h, v: v, breakpoints: breakpoints)
    }
    
    // MARK: - Top
    
    /// Specifies the top position to the first parent element with relative position
    @discardableResult
    public func top<U: UnitValuable>(
        _ state: State<U>,
        to side: State<Autolayout.ConstraintYSide> = .init(wrappedValue: .top),
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        let important = breakpoints.count > 0 ? "!important" : ""
        let className = _getClassName("top", breakpoints: breakpoints)
        self.class(.init(stringLiteral: className))
        let perform: (U, Autolayout.ConstraintYSide, Double) -> Void = { [weak self] value, side, multiplier in
            self?._setRule(className, breakpoints: breakpoints) { rule in
                let percentage: Int
                switch side {
                case .top: percentage = 0
                case .center: percentage = 50
                case .bottom: percentage = 100
                }
                if value.value.doubleValue > 0 {
                    if multiplier == 1 {
                        if percentage == 0 {
                            return rule.custom("top", value.description + important)
                        } else {
                            return rule.custom("top", "calc(\(percentage)% + \(value.description))" + important)
                        }
                    } else {
                        if percentage == 0 {
                            return rule.custom("top", "calc(\(value.description) * \(multiplier))" + important)
                        } else {
                            return rule.custom("top", "calc((\(percentage)% + \(value.description)) * \(multiplier))" + important)
                        }
                    }
                } else if value.value.doubleValue < 0 {
                    if multiplier == 1 {
                        if percentage == 0 {
                            return rule.custom("top", value.description + important)
                        } else {
                            return rule.custom("top", "calc(\(percentage)% - \(UnitValue(-value.value.doubleValue, value.unit).description))" + important)
                        }
                    } else {
                        if percentage == 0 {
                            return rule.custom("top", "calc(\(value.description) * \(multiplier))" + important)
                        } else {
                            return rule.custom("top", "calc((\(percentage)% - \(UnitValue(-value.value.doubleValue, value.unit).description)) * \(multiplier))" + important)
                        }
                    }
                } else {
                    return rule.custom("top", "0px" + important)
                }
            }
        }
        perform(state.wrappedValue, side.wrappedValue, multiplier.wrappedValue)
        state.listen {
            perform($0, side.wrappedValue, multiplier.wrappedValue)
        }
        side.listen {
            perform(state.wrappedValue, $0, multiplier.wrappedValue)
        }
        multiplier.listen {
            perform(state.wrappedValue, side.wrappedValue, $0)
        }
        return self
    }
    
    /// Specifies the top position to the first parent element with relative position
    @discardableResult
    public func top<U: UnitValuable>(
        _ state: State<U>,
        to side: State<Autolayout.ConstraintYSide> = .init(wrappedValue: .top),
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        top(state, to: side, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    /// Specifies the top position to the first parent element with relative position
    @discardableResult
    public func top<U: UnitValuable>(
        _ value: U = 0.px,
        to side: Autolayout.ConstraintYSide = .top,
        multiplier: Double = 1,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        top(.init(wrappedValue: value), to: .init(wrappedValue: side), multiplier: .init(wrappedValue: multiplier), breakpoints: breakpoints)
    }
    
    /// Specifies the top position to the first parent element with relative position
    @discardableResult
    public func top<U: UnitValuable>(
        _ value: U = 0.px,
        to side: Autolayout.ConstraintYSide = .top,
        multiplier: Double = 1,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        top(value, to: side, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    // MARK: - Left
    
    /// Specifies the left position to the first parent element with relative position
    @discardableResult
    public func left<U: UnitValuable>(
        _ state: State<U>,
        to side: State<Autolayout.ConstraintXSide> = .init(wrappedValue: .left),
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        let important = breakpoints.count > 0 ? "!important" : ""
        let className = _getClassName("left", breakpoints: breakpoints)
        self.class(.init(stringLiteral: className))
        let perform: (U, Autolayout.ConstraintXSide, Double) -> Void = { [weak self] value, side, multiplier in
            self?._setRule(className, breakpoints: breakpoints) { rule in
                let percentage: Int
                switch side {
                case .left: percentage = 0
                case .center: percentage = 50
                case .right: percentage = 100
                }
                if value.value.doubleValue > 0 {
                    if multiplier == 1 {
                        if percentage == 0 {
                            return rule.custom("left", value.description + important)
                        } else {
                            return rule.custom("left", "calc(\(percentage)% + \(value.description))" + important)
                        }
                    } else {
                        if percentage == 0 {
                            return rule.custom("left", "calc(\(value.description) * \(multiplier))" + important)
                        } else {
                            return rule.custom("left", "calc((\(percentage)% + \(value.description)) * \(multiplier))" + important)
                        }
                    }
                } else if value.value.doubleValue < 0 {
                    if multiplier == 1 {
                        if percentage == 0 {
                            return rule.custom("left", value.description + important)
                        } else {
                            return rule.custom("left", "calc(\(percentage)% - \(UnitValue(-value.value.doubleValue, value.unit).description))" + important)
                        }
                    } else {
                        if percentage == 0 {
                            return rule.custom("left", "calc(\(value.description) * \(multiplier))" + important)
                        } else {
                            return rule.custom("left", "calc((\(percentage)% - \(UnitValue(-value.value.doubleValue, value.unit).description)) * \(multiplier))" + important)
                        }
                    }
                } else {
                    return rule.custom("left", "0px" + important)
                }
            }
        }
        perform(state.wrappedValue, side.wrappedValue, multiplier.wrappedValue)
        state.listen {
            perform($0, side.wrappedValue, multiplier.wrappedValue)
        }
        side.listen {
            perform(state.wrappedValue, $0, multiplier.wrappedValue)
        }
        multiplier.listen {
            perform(state.wrappedValue, side.wrappedValue, $0)
        }
        return self
    }
    
    /// Specifies the left position to the first parent element with relative position
    @discardableResult
    public func left<U: UnitValuable>(
        _ state: State<U>,
        to side: State<Autolayout.ConstraintXSide> = .init(wrappedValue: .left),
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        left(state, to: side, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    /// Specifies the left position to the first parent element with relative position
    @discardableResult
    public func left<U: UnitValuable>(
        _ value: U = 0.px,
        to side: Autolayout.ConstraintXSide = .left,
        multiplier: Double = 1,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        left(.init(wrappedValue: value), to: .init(wrappedValue: side), multiplier: .init(wrappedValue: multiplier), breakpoints: breakpoints)
    }
    
    /// Specifies the left position to the first parent element with relative position
    @discardableResult
    public func left<U: UnitValuable>(
        _ value: U = 0.px,
        to side: Autolayout.ConstraintXSide = .left,
        multiplier: Double = 1,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        left(value, to: side, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    // MARK: - Right
    
    /// Specifies the right position to the first parent element with relative position
    @discardableResult
    public func right<U: UnitValuable>(
        _ state: State<U>,
        to side: State<Autolayout.ConstraintXSide> = .init(wrappedValue: .right),
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        let important = breakpoints.count > 0 ? "!important" : ""
        let className = _getClassName("right", breakpoints: breakpoints)
        self.class(.init(stringLiteral: className))
        let perform: (U, Autolayout.ConstraintXSide, Double) -> Void = { [weak self] value, side, multiplier in
            self?._setRule(className, breakpoints: breakpoints) { rule in
                let percentage: Int
                switch side {
                case .left: percentage = 100
                case .center: percentage = 50
                case .right: percentage = 0
                }
                if value.value.doubleValue > 0 {
                    if multiplier == 1 {
                        if percentage == 0 {
                            return rule.custom("right", value.description + important)
                        } else {
                            return rule.custom("right", "calc(\(percentage)% + \(value.description))" + important)
                        }
                    } else {
                        if percentage == 0 {
                            return rule.custom("right", "calc(\(value.description) * \(multiplier))" + important)
                        } else {
                            return rule.custom("right", "calc((\(percentage)% + \(value.description)) * \(multiplier))" + important)
                        }
                    }
                } else if value.value.doubleValue < 0 {
                    if multiplier == 1 {
                        if percentage == 0 {
                            return rule.custom("right", value.description + important)
                        } else {
                            return rule.custom("right", "calc(\(percentage)% - \(UnitValue(-value.value.doubleValue, value.unit).description))" + important)
                        }
                    } else {
                        if percentage == 0 {
                            return rule.custom("right", "calc(\(value.description) * \(multiplier))" + important)
                        } else {
                            return rule.custom("right", "calc((\(percentage)% - \(UnitValue(-value.value.doubleValue, value.unit).description)) * \(multiplier))" + important)
                        }
                    }
                } else {
                    return rule.custom("right", "0px" + important)
                }
            }
        }
        perform(state.wrappedValue, side.wrappedValue, multiplier.wrappedValue)
        state.listen {
            perform($0, side.wrappedValue, multiplier.wrappedValue)
        }
        side.listen {
            perform(state.wrappedValue, $0, multiplier.wrappedValue)
        }
        multiplier.listen {
            perform(state.wrappedValue, side.wrappedValue, $0)
        }
        return self
    }
    
    /// Specifies the right position to the first parent element with relative position
    @discardableResult
    public func right<U: UnitValuable>(
        _ state: State<U>,
        to side: State<Autolayout.ConstraintXSide> = .init(wrappedValue: .right),
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        right(state, to: side, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    /// Specifies the right position to the first parent element with relative position
    @discardableResult
    public func right<U: UnitValuable>(
        _ value: U = 0.px,
        to side: Autolayout.ConstraintXSide = .right,
        multiplier: Double = 1,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        right(.init(wrappedValue: value), to: .init(wrappedValue: side), multiplier: .init(wrappedValue: multiplier), breakpoints: breakpoints)
    }
    
    /// Specifies the right position to the first parent element with relative position
    @discardableResult
    public func right<U: UnitValuable>(
        _ value: U = 0.px,
        to side: Autolayout.ConstraintXSide = .right,
        multiplier: Double = 1,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        right(value, to: side, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    // MARK: - Bottom
    
    /// Specifies the bottom position to the first parent element with relative position
    @discardableResult
    public func bottom<U: UnitValuable>(
        _ state: State<U>,
        to side: State<Autolayout.ConstraintYSide> = .init(wrappedValue: .bottom),
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        let important = breakpoints.count > 0 ? "!important" : ""
        let className = _getClassName("bottom", breakpoints: breakpoints)
        self.class(.init(stringLiteral: className))
        let perform: (U, Autolayout.ConstraintYSide, Double) -> Void = { [weak self] value, side, multiplier in
            self?._setRule(className, breakpoints: breakpoints) { rule in
                let percentage: Int
                switch side {
                case .top: percentage = 100
                case .center: percentage = 50
                case .bottom: percentage = 0
                }
                if value.value.doubleValue > 0 {
                    if multiplier == 1 {
                        if percentage == 0 {
                            return rule.custom("bottom", value.description + important)
                        } else {
                            return rule.custom("bottom", "calc(\(percentage)% + \(value.description))" + important)
                        }
                    } else {
                        if percentage == 0 {
                            return rule.custom("bottom", "calc(\(value.description) * \(multiplier))" + important)
                        } else {
                            return rule.custom("bottom", "calc((\(percentage)% + \(value.description)) * \(multiplier))" + important)
                        }
                    }
                } else if value.value.doubleValue < 0 {
                    if multiplier == 1 {
                        if percentage == 0 {
                            return rule.custom("bottom", value.description + important)
                        } else {
                            return rule.custom("bottom", "calc(\(percentage)% - \(UnitValue(-value.value.doubleValue, value.unit).description))" + important)
                        }
                    } else {
                        if percentage == 0 {
                            return rule.custom("bottom", "calc(\(value.description) * \(multiplier))" + important)
                        } else {
                            return rule.custom("bottom", "calc((\(percentage)% - \(UnitValue(-value.value.doubleValue, value.unit).description)) * \(multiplier))" + important)
                        }
                    }
                } else {
                    return rule.custom("bottom", "0px" + important)
                }
            }
        }
        perform(state.wrappedValue, side.wrappedValue, multiplier.wrappedValue)
        state.listen {
            perform($0, side.wrappedValue, multiplier.wrappedValue)
        }
        side.listen {
            perform(state.wrappedValue, $0, multiplier.wrappedValue)
        }
        multiplier.listen {
            perform(state.wrappedValue, side.wrappedValue, $0)
        }
        return self
    }
    
    /// Specifies the bottom position to the first parent element with relative position
    @discardableResult
    public func bottom<U: UnitValuable>(
        _ state: State<U>,
        to side: State<Autolayout.ConstraintYSide> = .init(wrappedValue: .bottom),
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        bottom(state, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    /// Specifies the bottom position to the first parent element with relative position
    @discardableResult
    public func bottom<U: UnitValuable>(
        _ value: U = 0.px,
        to side: Autolayout.ConstraintYSide = .bottom,
        multiplier: Double = 1,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        bottom(.init(wrappedValue: value), to: .init(wrappedValue: side), multiplier: .init(wrappedValue: multiplier), breakpoints: breakpoints)
    }
    
    /// Specifies the bottom position to the first parent element with relative position
    @discardableResult
    public func bottom<U: UnitValuable>(
        _ value: U = 0.px,
        to side: Autolayout.ConstraintYSide = .bottom,
        multiplier: Double = 1,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        bottom(value, to: side, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    // MARK: - Center X
    
    /// Specifies the horizontal center position to the first parent element with relative position
    @discardableResult
    public func centerX<U: UnitValuable>(
        _ state: State<U>,
        to side: State<Autolayout.ConstraintCXSide> = .init(wrappedValue: .center),
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        let important = breakpoints.count > 0 ? "!important" : ""
        let className = _getClassName("left", breakpoints: breakpoints)
        let translationClassName = _getClassName("translate", breakpoints: breakpoints)
        self.class(.init(stringLiteral: className), .init(stringLiteral: translationClassName))
        let perform: (U, Autolayout.ConstraintCXSide, Double) -> Void = { [weak self] value, side, multiplier in
            self?._setRule(className, breakpoints: breakpoints) { rule in
                let percentage: Int
                switch side {
                case .left: percentage = 0
                case .center: percentage = 50
                case .right: percentage = 100
                }
                if value.value.doubleValue > 0 {
                    return rule.custom("left", "calc((\(percentage)% + \(value.description)) * \(multiplier))" + important)
                } else if value.value.doubleValue < 0 {
                    return rule.custom("left", "calc((\(percentage)% - \(UnitValue(-value.value.doubleValue, value.unit).description)) * \(multiplier))" + important)
                } else {
                    if multiplier == 1 {
                        return rule.custom("left", "\(percentage)%" + important)
                    } else {
                        return rule.custom("left", "calc(\(percentage)% * \(multiplier))" + important)
                    }
                }
            }
        }
        let performTranslate: () -> Void = { [weak self] in
            self?._setRule(translationClassName, breakpoints: breakpoints) { rule in
                rule.custom("--translate-x", "-50%").custom("translate", "var(--translate-x, 0) var(--translate-y, 0)" + important)
            }
        }
        perform(state.wrappedValue, side.wrappedValue, multiplier.wrappedValue)
        performTranslate()
        state.listen {
            perform($0, side.wrappedValue, multiplier.wrappedValue)
            performTranslate()
        }
        side.listen {
            perform(state.wrappedValue, $0, multiplier.wrappedValue)
            performTranslate()
        }
        multiplier.listen {
            perform(state.wrappedValue, side.wrappedValue, $0)
            performTranslate()
        }
        return self
    }
    
    /// Specifies the horizontal center position to the first parent element with relative position
    @discardableResult
    public func centerX<U: UnitValuable>(
        _ state: State<U>,
        to side: State<Autolayout.ConstraintCXSide> = .init(wrappedValue: .center),
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        centerX(state, to: side, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    /// Specifies the horizontal center position to the first parent element with relative position
    @discardableResult
    public func centerX<U: UnitValuable>(
        _ value: U = 0.px,
        to side: Autolayout.ConstraintCXSide = .center,
        multiplier: Double = 1,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        centerX(.init(wrappedValue: value), to: .init(wrappedValue: side), multiplier: .init(wrappedValue: multiplier), breakpoints: breakpoints)
    }
    
    /// Specifies the horizontal center position to the first parent element with relative position
    @discardableResult
    public func centerX<U: UnitValuable>(
        _ value: U = 0.px,
        to side: Autolayout.ConstraintCXSide = .center,
        multiplier: Double = 1,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        centerX(value, to: side, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    // MARK: - Center Y
    
    /// Specifies the vertical center position to the first parent element with relative position
    @discardableResult
    public func centerY<U: UnitValuable>(
        _ state: State<U>,
        to side: State<Autolayout.ConstraintCYSide> = .init(wrappedValue: .center),
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        let important = breakpoints.count > 0 ? "!important" : ""
        let className = _getClassName("top", breakpoints: breakpoints)
        let translationClassName = _getClassName("translate", breakpoints: breakpoints)
        self.class(.init(stringLiteral: className), .init(stringLiteral: translationClassName))
        let perform: (U, Autolayout.ConstraintCYSide, Double) -> Void = { [weak self] value, side, multiplier in
            self?._setRule(className, breakpoints: breakpoints) { rule in
                let percentage: Int
                switch side {
                case .top: percentage = 0
                case .center: percentage = 50
                case .bottom: percentage = 100
                }
                if value.value.doubleValue > 0 {
                    return rule.custom("top", "calc((\(percentage)% + \(value.description)) * \(multiplier))" + important)
                } else if value.value.doubleValue < 0 {
                    return rule.custom("top", "calc((\(percentage)% - \(UnitValue(-value.value.doubleValue, value.unit).description)) * \(multiplier))" + important)
                } else {
                    if multiplier == 1 {
                        return rule.custom("top", "\(percentage)%" + important)
                    } else {
                        return rule.custom("top", "calc(\(percentage)% * \(multiplier))" + important)
                    }
                }
            }
        }
        let performTranslate: () -> Void = { [weak self] in
            self?._setRule(translationClassName, breakpoints: breakpoints) { rule in
                rule.custom("--translate-y", "-50%").custom("translate", "var(--translate-x, 0) var(--translate-y, 0)" + important)
            }
        }
        perform(state.wrappedValue, side.wrappedValue, multiplier.wrappedValue)
        performTranslate()
        state.listen {
            perform($0, side.wrappedValue, multiplier.wrappedValue)
            performTranslate()
        }
        side.listen {
            perform(state.wrappedValue, $0, multiplier.wrappedValue)
            performTranslate()
        }
        multiplier.listen {
            perform(state.wrappedValue, side.wrappedValue, $0)
            performTranslate()
        }
        return self
    }
    
    /// Specifies the vertical center position to the first parent element with relative position
    @discardableResult
    public func centerY<U: UnitValuable>(
        _ state: State<U>,
        to side: State<Autolayout.ConstraintCYSide> = .init(wrappedValue: .center),
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        centerY(state, to: side, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    /// Specifies the vertical center position to the first parent element with relative position
    @discardableResult
    public func centerY<U: UnitValuable>(
        _ value: U = 0.px,
        to side: Autolayout.ConstraintCYSide = .center,
        multiplier: Double = 1,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        centerY(.init(wrappedValue: value), to: .init(wrappedValue: side), multiplier: .init(wrappedValue: multiplier), breakpoints: breakpoints)
    }
    
    /// Specifies the vertical center position to the first parent element with relative position
    @discardableResult
    public func centerY<U: UnitValuable>(
        _ value: U = 0.px,
        to side: Autolayout.ConstraintCYSide = .center,
        multiplier: Double = 1,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        centerY(value, to: side, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    // MARK: Center X+Y
    
    /// Specifies both vertical and horizontal center position to the first parent element with relative position
    @discardableResult
    public func center<U: UnitValuable>(
        _ state: State<U>,
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        centerX(state, multiplier: multiplier, breakpoints: breakpoints)
        .centerY(state, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    /// Specifies both vertical and horizontal center position to the first parent element with relative position
    @discardableResult
    public func center<U: UnitValuable>(
        _ state: State<U>,
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        center(state, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    /// Specifies both vertical and horizontal center position to the first parent element with relative position
    @discardableResult
    public func center<U: UnitValuable>(
        _ value: U = 0.px,
        multiplier: Double = 1,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        center(
            .init(wrappedValue: value),
            multiplier: .init(wrappedValue: multiplier),
            breakpoints: breakpoints
        )
    }
    
    /// Specifies both vertical and horizontal center position to the first parent element with relative position
    @discardableResult
    public func center<U: UnitValuable>(
        _ value: U = 0.px,
        multiplier: Double = 1,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        center(value, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    // MARK: - Width
    
    /// Sets the width of an element
    @discardableResult
    public func width<U: UnitValuable>(
        _ state: State<U>,
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        let className = _getClassName("width", breakpoints: breakpoints)
        self.class(.init(stringLiteral: className))
        let perform: (U, Double) -> Void = { [weak self] value, multiplier in
            self?._setRule(className, breakpoints: breakpoints) { rule in
                return rule.custom("width", UnitValue(value.value.doubleValue, value.unit, important: breakpoints.count > 0).description)
            }
        }
        perform(state.wrappedValue, multiplier.wrappedValue)
        state.listen {
            perform($0, multiplier.wrappedValue)
        }
        multiplier.listen {
            perform(state.wrappedValue, $0)
        }
        return self
    }
    
    /// Sets the width of an element
    @discardableResult
    public func width<U: UnitValuable>(
        _ state: State<U>,
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        width(state, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    /// Sets the width of an element
    @discardableResult
    public func width<U: UnitValuable>(
        _ value: U = 0.px,
        multiplier: Double = 1,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        width(.init(wrappedValue: value), multiplier: .init(wrappedValue: multiplier), breakpoints: breakpoints)
    }
    
    /// Sets the width of an element
    @discardableResult
    public func width<U: UnitValuable>(
        _ value: U = 0.px,
        multiplier: Double = 1,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        width(value, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    // MARK: - Width to parent
    
    /// Sets the width of an element to fit first parent element with relative position
    @discardableResult
    public func widthToParent<U: UnitValuable>(
        extra state: State<U>,
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        let important = breakpoints.count > 0 ? "!important" : ""
        let className = _getClassName("width", breakpoints: breakpoints)
        self.class(.init(stringLiteral: className))
        let perform: (U, Double) -> Void = { [weak self] extra, multiplier in
            self?._setRule(className, breakpoints: breakpoints) { rule in
                if extra.value.doubleValue > 0 {
                    return rule.custom("width", "calc(\(100 * multiplier)% + \(extra.description))" + important)
                } else if extra.value.doubleValue < 0 {
                    return rule.custom("width", "calc(\(100 * multiplier)% - \(extra.description))" + important)
                } else {
                    return rule.custom("width", "\(100 * multiplier)%" + important)
                }
            }
        }
        perform(state.wrappedValue, multiplier.wrappedValue)
        state.listen {
            perform($0, multiplier.wrappedValue)
        }
        multiplier.listen {
            perform(state.wrappedValue, $0)
        }
        return self
    }
    
    /// Sets the width of an element to fit first parent element with relative position
    @discardableResult
    public func widthToParent<U: UnitValuable>(
        extra state: State<U>,
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        widthToParent(extra: state, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    /// Sets the width of an element to fit first parent element with relative position
    @discardableResult
    public func widthToParent<U: UnitValuable>(
        extra value: U = 0.px,
        multiplier: Double = 1,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        widthToParent(extra: .init(wrappedValue: value), multiplier: .init(wrappedValue: multiplier), breakpoints: breakpoints)
    }
    
    /// Sets the width of an element to fit first parent element with relative position
    @discardableResult
    public func widthToParent<U: UnitValuable>(
        extra value: U = 0.px,
        multiplier: Double = 1,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        widthToParent(extra: value, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    // MARK: - Height
    
    /// Sets the height of an element
    @discardableResult
    public func height<U: UnitValuable>(
        _ state: State<U>,
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        let className = _getClassName("height", breakpoints: breakpoints)
        self.class(.init(stringLiteral: className))
        let perform: (U, Double) -> Void = { [weak self] value, multiplier in
            self?._setRule(className, breakpoints: breakpoints) { rule in
                return rule.custom("height", UnitValue(value.value.doubleValue, value.unit, important: breakpoints.count > 0).description)
            }
        }
        perform(state.wrappedValue, multiplier.wrappedValue)
        state.listen {
            perform($0, multiplier.wrappedValue)
        }
        multiplier.listen {
            perform(state.wrappedValue, $0)
        }
        return self
    }
    
    /// Sets the height of an element
    @discardableResult
    public func height<U: UnitValuable>(
        _ state: State<U>,
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        height(state, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    /// Sets the height of an element
    @discardableResult
    public func height<U: UnitValuable>(
        _ value: U = 0.px,
        multiplier: Double = 1,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        height(.init(wrappedValue: value), multiplier: .init(wrappedValue: multiplier), breakpoints: breakpoints)
    }
    
    /// Sets the height of an element
    @discardableResult
    public func height<U: UnitValuable>(
        _ value: U = 0.px,
        multiplier: Double = 1,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        height(value, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    // MARK: - Height to parent
    
    /// Sets the height of an element to fit first parent element with relative position
    @discardableResult
    public func heightToParent<U: UnitValuable>(
        extra state: State<U>,
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        let important = breakpoints.count > 0 ? "!important" : ""
        let className = _getClassName("height", breakpoints: breakpoints)
        self.class(.init(stringLiteral: className))
        let perform: (U, Double) -> Void = { [weak self] extra, multiplier in
            self?._setRule(className, breakpoints: breakpoints) { rule in
                if extra.value.doubleValue > 0 {
                    return rule.custom("height", "calc(\(100 * multiplier)% + \(extra.description))" + important)
                } else if extra.value.doubleValue < 0 {
                    return rule.custom("height", "calc(\(100 * multiplier)% - \(extra.description))" + important)
                } else {
                    return rule.custom("height", "\(100 * multiplier)%" + important)
                }
            }
        }
        perform(state.wrappedValue, multiplier.wrappedValue)
        state.listen {
            perform($0, multiplier.wrappedValue)
        }
        multiplier.listen {
            perform(state.wrappedValue, $0)
        }
        return self
    }
    
    /// Sets the height of an element to fit first parent element with relative position
    @discardableResult
    public func heightToParent<U: UnitValuable>(
        extra state: State<U>,
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        heightToParent(extra: state, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    /// Sets the height of an element to fit first parent element with relative position
    @discardableResult
    public func heightToParent<U: UnitValuable>(
        extra value: U = 0.px,
        multiplier: Double = 1,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        heightToParent(extra: .init(wrappedValue: value), multiplier: .init(wrappedValue: multiplier), breakpoints: breakpoints)
    }
    
    /// Sets the height of an element to fit first parent element with relative position
    @discardableResult
    public func heightToParent<U: UnitValuable>(
        extra value: U = 0.px,
        multiplier: Double = 1,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        heightToParent(extra: value, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    // MARK: - Position
    
    /// Specifies the type of positioning method used for an element (static, relative, absolute or fixed)
    @discardableResult
    public func position(
        _ state: State<PositionType>,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        let className = _getClassName("position", breakpoints: breakpoints)
        self.class(.init(stringLiteral: className))
        let perform: (PositionType) -> Void = { [weak self] value in
            self?._setRule(className, breakpoints: breakpoints) { rule in
                if breakpoints.count > 0 {
                    return rule.position(value.important)
                } else {
                    return rule.position(value)
                }
            }
        }
        perform(state.wrappedValue)
        state.listen {
            perform($0)
        }
        return self
    }
    
    /// Specifies the type of positioning method used for an element (static, relative, absolute or fixed)
    @discardableResult
    public func position(
        _ state: State<PositionType>,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        position(state, breakpoints: breakpoints)
    }
    
    /// Specifies the type of positioning method used for an element (static, relative, absolute or fixed)
    @discardableResult
    public func position(
        _ value: PositionType,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        position(.init(wrappedValue: value), breakpoints: breakpoints)
    }
    
    /// Specifies the type of positioning method used for an element (static, relative, absolute or fixed)
    @discardableResult
    public func position(
        _ value: PositionType,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        position(value, breakpoints: breakpoints)
    }
    
    // MARK: - Display
    
    /// Specifies how a certain HTML element should be displayed
    @discardableResult
    public func display(
        _ state: State<DisplayType>,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        let className = _getClassName("display", breakpoints: breakpoints)
        self.class(.init(stringLiteral: className))
        let perform: (DisplayType) -> Void = { [weak self] value in
            self?._setRule(className, breakpoints: breakpoints) { rule in
                if breakpoints.count > 0 {
                    return rule.display(value.important)
                } else {
                    return rule.display(value)
                }
            }
        }
        perform(state.wrappedValue)
        state.listen {
            perform($0)
        }
        return self
    }
    
    /// Specifies how a certain HTML element should be displayed
    @discardableResult
    public func display(
        _ state: State<DisplayType>,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        display(state, breakpoints: breakpoints)
    }
    
    /// Specifies how a certain HTML element should be displayed
    @discardableResult
    public func display(
        _ value: DisplayType,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        display(.init(wrappedValue: value), breakpoints: breakpoints)
    }
    
    /// Specifies how a certain HTML element should be displayed
    @discardableResult
    public func display(
        _ value: DisplayType,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        display(value, breakpoints: breakpoints)
    }
    
    // MARK: - Visibility
    
    /// Specifies whether or not an element is visible
    @discardableResult
    public func visibility(
        _ state: State<VisibilityType>,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        let className = _getClassName("visibility", breakpoints: breakpoints)
        self.class(.init(stringLiteral: className))
        let perform: (VisibilityType) -> Void = { [weak self] value in
            self?._setRule(className, breakpoints: breakpoints) { rule in
                if breakpoints.count > 0 {
                    return rule.visibility(value.important)
                } else {
                    return rule.visibility(value)
                }
            }
        }
        perform(state.wrappedValue)
        state.listen {
            perform($0)
        }
        return self
    }
    
    /// Specifies whether or not an element is visible
    @discardableResult
    public func visibility(
        _ state: State<VisibilityType>,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        visibility(state, breakpoints: breakpoints)
    }
    
    /// Specifies whether or not an element is visible
    @discardableResult
    public func visibility(
        _ value: VisibilityType,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        visibility(.init(wrappedValue: value), breakpoints: breakpoints)
    }
    
    /// Specifies whether or not an element is visible
    @discardableResult
    public func visibility(
        _ value: VisibilityType,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        visibility(value, breakpoints: breakpoints)
    }
    
    // MARK: - Opacity
    
    /// Sets the opacity level for an element
    @discardableResult
    public func opacity<N>(
        _ state: State<N>,
        breakpoints: [MediaRule.MediaType]
    ) -> Self where N: UniValue, N.UniValue: NumericValue {
        let className = _getClassName("opacity", breakpoints: breakpoints)
        self.class(.init(stringLiteral: className))
        let perform: (N) -> Void = { [weak self] value in
            self?._setRule(className, breakpoints: breakpoints) { rule in
                let container = NumericValueContainer(value, important: breakpoints.count > 0)
                return rule.custom("opacity", container.value)
            }
        }
        perform(state.wrappedValue)
        state.listen {
            perform($0)
        }
        return self
    }
    
    /// Sets the opacity level for an element
    @discardableResult
    public func opacity<N>(
        _ state: State<N>,
        breakpoints: MediaRule.MediaType...
    ) -> Self where N: UniValue, N.UniValue: NumericValue {
        opacity(state, breakpoints: breakpoints)
    }
    
    /// Sets the opacity level for an element
    @discardableResult
    public func opacity<N>(
        _ value: N,
        breakpoints: [MediaRule.MediaType]
    ) -> Self where N: UniValue, N.UniValue: NumericValue {
        opacity(.init(wrappedValue: value), breakpoints: breakpoints)
    }
    
    /// Sets the opacity level for an element
    @discardableResult
    public func opacity<N>(
        _ value: N,
        breakpoints: MediaRule.MediaType...
    ) -> Self where N: UniValue, N.UniValue: NumericValue {
        opacity(value, breakpoints: breakpoints)
    }
}
