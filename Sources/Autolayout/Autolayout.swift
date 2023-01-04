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
    /// Extra small `<576px`
    public static var xs: MediaRule.MediaType { .extraSmall }
    
    /// Small `≥576px` and `<768px`
    public static var small: MediaRule.MediaType { .init(.all.minWidth(576.px).maxWidth(767.px), label: "s") }
    /// Small `≥576px` and `<768px`
    public static var s: MediaRule.MediaType { .small }
    
    /// Medium `≥768px` and `<992px`
    public static var medium: MediaRule.MediaType { .init(.all.minWidth(768.px).maxWidth(991.px), label: "m") }
    /// Medium `≥768px` and `<992px`
    public static var m: MediaRule.MediaType { .medium }
    
    /// Large `≥992px` and `<1200px`
    public static var large: MediaRule.MediaType { .init(.all.minWidth(992.px).maxWidth(1199.px), label: "l") }
    /// Large `≥992px` and `<1200px`
    public static var l: MediaRule.MediaType { .large }
    
    /// Large `≥1200px` and `<1400px`
    public static var extraLarge: MediaRule.MediaType { .init(.all.minWidth(1200.px).maxWidth(1399.px), label: "xl") }
    /// Large `≥1200px` and `<1400px`
    public static var xl: MediaRule.MediaType { .extraLarge }
    
    /// Large `≥1400px`
    public static var extraExtraLarge: MediaRule.MediaType { .init(.all.minWidth(1400.px), label: "xxl") }
    /// Large `≥1400px`
    public static var xxl: MediaRule.MediaType { .extraExtraLarge }
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
        if let _ = _autolayout.ruleIndexCache[className] {
            _autolayout.ruleIndexCache.removeValue(forKey: className)
            if let ruleIndex = _autolayout.stylesheet.findRuleIndex(by: "." + className) {
                _autolayout.stylesheet.deleteRule(ruleIndex)
            }
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
                            rule.custom("--top", value.description + important)
                        } else {
                            rule.custom("--top", "calc(\(percentage)% + \(value.description))" + important)
                        }
                    } else {
                        if percentage == 0 {
                            rule.custom("--top", "calc(\(value.description) * \(multiplier))" + important)
                        } else {
                            rule.custom("--top", "calc((\(percentage)% + \(value.description)) * \(multiplier))" + important)
                        }
                    }
                } else if value.value.doubleValue < 0 {
                    if multiplier == 1 {
                        if percentage == 0 {
                            rule.custom("--top", value.description + important)
                        } else {
                            rule.custom("--top", "calc(\(percentage)% - \(UnitValue(-value.value.doubleValue, value.unit).description))" + important)
                        }
                    } else {
                        if percentage == 0 {
                            rule.custom("--top", "calc(\(value.description) * \(multiplier))" + important)
                        } else {
                            rule.custom("--top", "calc((\(percentage)% - \(UnitValue(-value.value.doubleValue, value.unit).description)) * \(multiplier))" + important)
                        }
                    }
                } else {
                    rule.custom("--top", "0px" + important)
                }
                return rule.custom("top", "var(--top, auto)" + important)
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
                            rule.custom("--left", value.description + important)
                        } else {
                            rule.custom("--left", "calc(\(percentage)% + \(value.description))" + important)
                        }
                    } else {
                        if percentage == 0 {
                            rule.custom("--left", "calc(\(value.description) * \(multiplier))" + important)
                        } else {
                            rule.custom("--left", "calc((\(percentage)% + \(value.description)) * \(multiplier))" + important)
                        }
                    }
                } else if value.value.doubleValue < 0 {
                    if multiplier == 1 {
                        if percentage == 0 {
                            rule.custom("--left", value.description + important)
                        } else {
                            rule.custom("--left", "calc(\(percentage)% - \(UnitValue(-value.value.doubleValue, value.unit).description))" + important)
                        }
                    } else {
                        if percentage == 0 {
                            rule.custom("--left", "calc(\(value.description) * \(multiplier))" + important)
                        } else {
                            rule.custom("--left", "calc((\(percentage)% - \(UnitValue(-value.value.doubleValue, value.unit).description)) * \(multiplier))" + important)
                        }
                    }
                } else {
                    rule.custom("--left", "0px" + important)
                }
                return rule.custom("left", "var(--left, auto)" + important)
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
                            rule.custom("--right", value.description + important)
                        } else {
                            rule.custom("--right", "calc(\(percentage)% + \(value.description))" + important)
                        }
                    } else {
                        if percentage == 0 {
                            rule.custom("--right", "calc(\(value.description) * \(multiplier))" + important)
                        } else {
                            rule.custom("--right", "calc((\(percentage)% + \(value.description)) * \(multiplier))" + important)
                        }
                    }
                } else if value.value.doubleValue < 0 {
                    if multiplier == 1 {
                        if percentage == 0 {
                            rule.custom("--right", value.description + important)
                        } else {
                            rule.custom("--right", "calc(\(percentage)% - \(UnitValue(-value.value.doubleValue, value.unit).description))" + important)
                        }
                    } else {
                        if percentage == 0 {
                            rule.custom("--right", "calc(\(value.description) * \(multiplier))" + important)
                        } else {
                            rule.custom("--right", "calc((\(percentage)% - \(UnitValue(-value.value.doubleValue, value.unit).description)) * \(multiplier))" + important)
                        }
                    }
                } else {
                    rule.custom("--right", "0px" + important)
                }
                return rule.custom("right", "var(--right, auto)" + important)
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
                            rule.custom("--bottom", value.description + important)
                        } else {
                            rule.custom("--bottom", "calc(\(percentage)% + \(value.description))" + important)
                        }
                    } else {
                        if percentage == 0 {
                            rule.custom("--bottom", "calc(\(value.description) * \(multiplier))" + important)
                        } else {
                            rule.custom("--bottom", "calc((\(percentage)% + \(value.description)) * \(multiplier))" + important)
                        }
                    }
                } else if value.value.doubleValue < 0 {
                    if multiplier == 1 {
                        if percentage == 0 {
                            rule.custom("--bottom", value.description + important)
                        } else {
                            rule.custom("--bottom", "calc(\(percentage)% - \(UnitValue(-value.value.doubleValue, value.unit).description))" + important)
                        }
                    } else {
                        if percentage == 0 {
                            rule.custom("--bottom", "calc(\(value.description) * \(multiplier))" + important)
                        } else {
                            rule.custom("--bottom", "calc((\(percentage)% - \(UnitValue(-value.value.doubleValue, value.unit).description)) * \(multiplier))" + important)
                        }
                    }
                } else {
                    rule.custom("--bottom", "0px" + important)
                }
                return rule.custom("bottom", "var(--bottom, auto)" + important)
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
        let translationClassName = _getClassName("translate_x", breakpoints: breakpoints)
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
                    rule.custom("--left", "calc((\(percentage)% + \(value.description)) * \(multiplier))" + important)
                } else if value.value.doubleValue < 0 {
                    rule.custom("--left", "calc((\(percentage)% - \(UnitValue(-value.value.doubleValue, value.unit).description)) * \(multiplier))" + important)
                } else {
                    if multiplier == 1 {
                        rule.custom("--left", "\(percentage)%" + important)
                    } else {
                        rule.custom("--left", "calc(\(percentage)% * \(multiplier))" + important)
                    }
                }
                return rule.custom("left", "var(--left, auto)" + important).custom("--right", "auto" + important).custom("right", "var(--right, auto)" + important)
            }
        }
        let performTranslate: () -> Void = { [weak self] in
            self?._setRule(translationClassName, breakpoints: breakpoints) { rule in
                rule.custom("--translate-x", "-50%" + important).custom("translate", "var(--translate-x, 0) var(--translate-y, 0)" + important)
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
        let translationClassName = _getClassName("translate_y", breakpoints: breakpoints)
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
                    rule.custom("--top", "calc((\(percentage)% + \(value.description)) * \(multiplier))" + important)
                } else if value.value.doubleValue < 0 {
                    rule.custom("--top", "calc((\(percentage)% - \(UnitValue(-value.value.doubleValue, value.unit).description)) * \(multiplier))" + important)
                } else {
                    if multiplier == 1 {
                        rule.custom("--top", "\(percentage)%" + important)
                    } else {
                        rule.custom("--top", "calc(\(percentage)% * \(multiplier))" + important)
                    }
                }
                return rule.custom("top", "var(--top, auto)" + important).custom("--bottom", "auto" + important).custom("bottom", "var(--bottom, auto)" + important)
            }
        }
        let performTranslate: () -> Void = { [weak self] in
            self?._setRule(translationClassName, breakpoints: breakpoints) { rule in
                rule.custom("--translate-y", "-50%" + important).custom("translate", "var(--translate-x, 0) var(--translate-y, 0)" + important)
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
    
    // MARK: - MinWidth
    
    /// Sets the minimum width of an element
    @discardableResult
    public func minWidth<U: UnitValuable>(
        _ state: State<U>,
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        let important = breakpoints.count > 0 ? "!important" : ""
        let className = _getClassName("minwidth", breakpoints: breakpoints)
        self.class(.init(stringLiteral: className))
        let perform: (U, Double) -> Void = { [weak self] value, multiplier in
            self?._setRule(className, breakpoints: breakpoints) { rule in
                return rule.custom("--min-width", value.description + important).custom("min-width", "var(--min-width, 0)" + important)
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
    
    /// Sets the minimum width of an element
    @discardableResult
    public func minWidth<U: UnitValuable>(
        _ state: State<U>,
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        minWidth(state, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    /// Sets the minimum width of an element
    @discardableResult
    public func minWidth<U: UnitValuable>(
        _ value: U = 0.px,
        multiplier: Double = 1,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        minWidth(.init(wrappedValue: value), multiplier: .init(wrappedValue: multiplier), breakpoints: breakpoints)
    }
    
    /// Sets the minimum width of an element
    @discardableResult
    public func minWidth<U: UnitValuable>(
        _ value: U = 0.px,
        multiplier: Double = 1,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        minWidth(value, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    // MARK: - MaxWidth
    
    /// Sets the maximum width of an element
    @discardableResult
    public func maxWidth<U: UnitValuable>(
        _ state: State<U>,
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        let important = breakpoints.count > 0 ? "!important" : ""
        let className = _getClassName("maxwidth", breakpoints: breakpoints)
        self.class(.init(stringLiteral: className))
        let perform: (U, Double) -> Void = { [weak self] value, multiplier in
            self?._setRule(className, breakpoints: breakpoints) { rule in
                return rule.custom("--max-width", value.description + important).custom("max-width", "var(--max-width, 0)" + important)
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
    
    /// Sets the maximum width of an element
    @discardableResult
    public func maxWidth<U: UnitValuable>(
        _ state: State<U>,
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        maxWidth(state, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    /// Sets the maximum width of an element
    @discardableResult
    public func maxWidth<U: UnitValuable>(
        _ value: U = 0.px,
        multiplier: Double = 1,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        maxWidth(.init(wrappedValue: value), multiplier: .init(wrappedValue: multiplier), breakpoints: breakpoints)
    }
    
    /// Sets the maximum width of an element
    @discardableResult
    public func maxWidth<U: UnitValuable>(
        _ value: U = 0.px,
        multiplier: Double = 1,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        maxWidth(value, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    // MARK: - Width
    
    /// Sets the width of an element
    @discardableResult
    public func width<U: UnitValuable>(
        _ state: State<U>,
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        let important = breakpoints.count > 0 ? "!important" : ""
        let className = _getClassName("width", breakpoints: breakpoints)
        self.class(.init(stringLiteral: className))
        let perform: (U, Double) -> Void = { [weak self] value, multiplier in
            self?._setRule(className, breakpoints: breakpoints) { rule in
                return rule.custom("--width", value.description + important).custom("width", "var(--width, auto)" + important)
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
                    rule.custom("--width", "calc(\(100 * multiplier)% + \(extra.description))" + important)
                } else if extra.value.doubleValue < 0 {
                    rule.custom("--width", "calc(\(100 * multiplier)% - \(extra.description))" + important)
                } else {
                    rule.custom("--width", "\(100 * multiplier)%" + important)
                }
                return rule.custom("width", "var(--width, auto)" + important)
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
    
    // MARK: - MinHeight
    
    /// Sets the minimum height of an element
    @discardableResult
    public func minHeight<U: UnitValuable>(
        _ state: State<U>,
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        let important = breakpoints.count > 0 ? "!important" : ""
        let className = _getClassName("minheight", breakpoints: breakpoints)
        self.class(.init(stringLiteral: className))
        let perform: (U, Double) -> Void = { [weak self] value, multiplier in
            self?._setRule(className, breakpoints: breakpoints) { rule in
                return rule.custom("--min-height", value.description + important).custom("min-height", "var(--min-height, 0)" + important)
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
    
    /// Sets the minimum height of an element
    @discardableResult
    public func minHeight<U: UnitValuable>(
        _ state: State<U>,
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        minHeight(state, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    /// Sets the minimum height of an element
    @discardableResult
    public func minHeight<U: UnitValuable>(
        _ value: U = 0.px,
        multiplier: Double = 1,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        minHeight(.init(wrappedValue: value), multiplier: .init(wrappedValue: multiplier), breakpoints: breakpoints)
    }
    
    /// Sets the minimum height of an element
    @discardableResult
    public func minHeight<U: UnitValuable>(
        _ value: U = 0.px,
        multiplier: Double = 1,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        minHeight(value, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    // MARK: - MaxHeight
    
    /// Sets the maximum height of an element
    @discardableResult
    public func maxHeight<U: UnitValuable>(
        _ state: State<U>,
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        let important = breakpoints.count > 0 ? "!important" : ""
        let className = _getClassName("maxheight", breakpoints: breakpoints)
        self.class(.init(stringLiteral: className))
        let perform: (U, Double) -> Void = { [weak self] value, multiplier in
            self?._setRule(className, breakpoints: breakpoints) { rule in
                return rule.custom("--max-height", value.description + important).custom("max-height", "var(--max-height, 0)" + important)
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
    
    /// Sets the maximum height of an element
    @discardableResult
    public func maxHeight<U: UnitValuable>(
        _ state: State<U>,
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        maxHeight(state, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    /// Sets the maximum height of an element
    @discardableResult
    public func maxHeight<U: UnitValuable>(
        _ value: U = 0.px,
        multiplier: Double = 1,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        maxHeight(.init(wrappedValue: value), multiplier: .init(wrappedValue: multiplier), breakpoints: breakpoints)
    }
    
    /// Sets the maximum height of an element
    @discardableResult
    public func maxHeight<U: UnitValuable>(
        _ value: U = 0.px,
        multiplier: Double = 1,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        maxHeight(value, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    // MARK: - Height
    
    /// Sets the height of an element
    @discardableResult
    public func height<U: UnitValuable>(
        _ state: State<U>,
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        let important = breakpoints.count > 0 ? "!important" : ""
        let className = _getClassName("height", breakpoints: breakpoints)
        self.class(.init(stringLiteral: className))
        let perform: (U, Double) -> Void = { [weak self] value, multiplier in
            self?._setRule(className, breakpoints: breakpoints) { rule in
                return rule.custom("--height", value.description + important).custom("height", "var(--height, auto)" + important)
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
                    rule.custom("--height", "calc(\(100 * multiplier)% + \(extra.description))" + important)
                } else if extra.value.doubleValue < 0 {
                    rule.custom("--height", "calc(\(100 * multiplier)% - \(extra.description))" + important)
                } else {
                    rule.custom("--height", "\(100 * multiplier)%" + important)
                }
                return rule.custom("height", "var(--height, auto)" + important)
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
    
    // MARK: - Size
    
    /// Sets both width and height of an element
    @discardableResult
    public func size<U: UnitValuable>(
        _ state: State<U>,
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        width(state, multiplier: multiplier, breakpoints: breakpoints).height(state, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    /// Sets the height of an element
    @discardableResult
    public func size<U: UnitValuable>(
        _ state: State<U>,
        multiplier: State<Double> = .init(wrappedValue: 1),
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        size(state, multiplier: multiplier, breakpoints: breakpoints)
    }
    
    /// Sets the height of an element
    @discardableResult
    public func size<U: UnitValuable>(
        _ value: U = 0.px,
        multiplier: Double = 1,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        size(.init(wrappedValue: value), multiplier: .init(wrappedValue: multiplier), breakpoints: breakpoints)
    }
    
    /// Sets the height of an element
    @discardableResult
    public func size<U: UnitValuable>(
        _ value: U = 0.px,
        multiplier: Double = 1,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        size(value, multiplier: multiplier, breakpoints: breakpoints)
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
    
    // MARK: - Padding
    
    /// Sets padding for all sides
    @discardableResult
    public func padding<U: UnitValuable>(
        _ state: State<U>,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        paddingTop(state, breakpoints: breakpoints)
        paddingRight(state, breakpoints: breakpoints)
        paddingBottom(state, breakpoints: breakpoints)
        paddingLeft(state, breakpoints: breakpoints)
        return self
    }
    
    /// Sets padding for all sides
    @discardableResult
    public func padding<U: UnitValuable>(
        _ state: State<U>,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        padding(state, breakpoints: breakpoints)
    }
    
    /// Sets padding for all sides
    @discardableResult
    public func padding<U: UnitValuable>(
        _ value: U = 0.px,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        padding(.init(wrappedValue: value), breakpoints: breakpoints)
    }
    
    /// Sets padding for all sides
    @discardableResult
    public func padding<U: UnitValuable>(
        _ value: U = 0.px,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        padding(value, breakpoints: breakpoints)
    }
    
    // MARK: V & H
    
    /// Sets padding for horizontal and vertical sides separately
    @discardableResult
    public func padding<V: UnitValuable, H: UnitValuable>(
        v: State<V>,
        h: State<H>,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        paddingTop(v, breakpoints: breakpoints)
        paddingRight(h, breakpoints: breakpoints)
        paddingBottom(v, breakpoints: breakpoints)
        paddingLeft(h, breakpoints: breakpoints)
        return self
    }
    
    /// Sets padding for horizontal and vertical sides separately
    @discardableResult
    public func padding<V: UnitValuable, H: UnitValuable>(
        v: State<V>,
        h: State<H>,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        padding(v: v, h: h, breakpoints: breakpoints)
    }
    
    /// Sets padding for horizontal and vertical sides separately
    @discardableResult
    public func padding<V: UnitValuable, H: UnitValuable>(
        v: V,
        h: H,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        padding(v: .init(wrappedValue: v), h: .init(wrappedValue: h), breakpoints: breakpoints)
    }
    
    /// Sets padding for horizontal and vertical sides separately
    @discardableResult
    public func padding<V: UnitValuable, H: UnitValuable>(
        v: V,
        h: H,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        padding(v: v, h: h, breakpoints: breakpoints)
    }
    
    // MARK: V
    
    /// Sets padding for vertical sides
    @discardableResult
    public func padding<V: UnitValuable>(
        v: State<V>,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        paddingTop(v, breakpoints: breakpoints)
        paddingBottom(v, breakpoints: breakpoints)
        return self
    }
    
    /// Sets padding for vertical sides
    @discardableResult
    public func padding<V: UnitValuable>(
        v: State<V>,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        padding(v: v, breakpoints: breakpoints)
    }
    
    /// Sets padding for vertical sides
    @discardableResult
    public func padding<V: UnitValuable>(
        v: V,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        padding(v: .init(wrappedValue: v), breakpoints: breakpoints)
    }
    
    /// Sets padding for vertical sides
    @discardableResult
    public func padding<V: UnitValuable>(
        v: V,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        padding(v: v, breakpoints: breakpoints)
    }
    
    // MARK: H
    
    /// Sets padding for horizontal sides
    @discardableResult
    public func padding<H: UnitValuable>(
        h: State<H>,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        paddingRight(h, breakpoints: breakpoints)
        paddingLeft(h, breakpoints: breakpoints)
        return self
    }
    
    /// Sets padding for horizontal sides
    @discardableResult
    public func padding<H: UnitValuable>(
        h: State<H>,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        padding(h: h, breakpoints: breakpoints)
    }
    
    /// Sets padding for horizontal sides
    @discardableResult
    public func padding<H: UnitValuable>(
        h: H,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        padding(h: .init(wrappedValue: h), breakpoints: breakpoints)
    }
    
    /// Sets padding for horizontal sides
    @discardableResult
    public func padding<H: UnitValuable>(
        h: H,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        padding(h: h, breakpoints: breakpoints)
    }
    
    // MARK: Top
    
    /// Sets padding for top side
    @discardableResult
    public func paddingTop<U: UnitValuable>(
        _ state: State<U>,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        let important = breakpoints.count > 0 ? "!important" : ""
        let className = _getClassName("padding_top", breakpoints: breakpoints)
        self.class(.init(stringLiteral: className))
        let perform: (U) -> Void = { [weak self] value in
            self?._setRule(className, breakpoints: breakpoints) { rule in
                rule.custom("--padding-top", value.description + important)
                return rule.custom("padding", "var(--padding-top, 0) var(--padding-right, 0) var(--padding-bottom, 0) var(--padding-left, 0)" + important)
            }
        }
        perform(state.wrappedValue)
        state.listen {
            perform($0)
        }
        return self
    }
    
    /// Sets padding for top side
    @discardableResult
    public func paddingTop<U: UnitValuable>(
        _ state: State<U>,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        paddingTop(state, breakpoints: breakpoints)
    }
    
    /// Sets padding for top side
    @discardableResult
    public func paddingTop<U: UnitValuable>(
        _ value: U = 0.px,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        paddingTop(.init(wrappedValue: value), breakpoints: breakpoints)
    }
    
    /// Sets padding for top side
    @discardableResult
    public func paddingTop<U: UnitValuable>(
        _ value: U = 0.px,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        paddingTop(value, breakpoints: breakpoints)
    }
    
    // MARK: Right
    
    /// Sets padding for right side
    @discardableResult
    public func paddingRight<U: UnitValuable>(
        _ state: State<U>,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        let important = breakpoints.count > 0 ? "!important" : ""
        let className = _getClassName("padding_right", breakpoints: breakpoints)
        self.class(.init(stringLiteral: className))
        let perform: (U) -> Void = { [weak self] value in
            self?._setRule(className, breakpoints: breakpoints) { rule in
                rule.custom("--padding-right", value.description + important)
                return rule.custom("padding", "var(--padding-top, 0) var(--padding-right, 0) var(--padding-bottom, 0) var(--padding-left, 0)" + important)
            }
        }
        perform(state.wrappedValue)
        state.listen {
            perform($0)
        }
        return self
    }
    
    /// Sets padding for right side
    @discardableResult
    public func paddingRight<U: UnitValuable>(
        _ state: State<U>,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        paddingRight(state, breakpoints: breakpoints)
    }
    
    /// Sets padding for right side
    @discardableResult
    public func paddingRight<U: UnitValuable>(
        _ value: U = 0.px,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        paddingRight(.init(wrappedValue: value), breakpoints: breakpoints)
    }
    
    /// Sets padding for right side
    @discardableResult
    public func paddingRight<U: UnitValuable>(
        _ value: U = 0.px,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        paddingRight(value, breakpoints: breakpoints)
    }
    
    // MARK: Bottom
    
    /// Sets padding for bottom side
    @discardableResult
    public func paddingBottom<U: UnitValuable>(
        _ state: State<U>,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        let important = breakpoints.count > 0 ? "!important" : ""
        let className = _getClassName("padding_bottom", breakpoints: breakpoints)
        self.class(.init(stringLiteral: className))
        let perform: (U) -> Void = { [weak self] value in
            self?._setRule(className, breakpoints: breakpoints) { rule in
                rule.custom("--padding-bottom", value.description + important)
                return rule.custom("padding", "var(--padding-top, 0) var(--padding-right, 0) var(--padding-bottom, 0) var(--padding-left, 0)" + important)
            }
        }
        perform(state.wrappedValue)
        state.listen {
            perform($0)
        }
        return self
    }
    
    /// Sets padding for bottom side
    @discardableResult
    public func paddingBottom<U: UnitValuable>(
        _ state: State<U>,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        paddingBottom(state, breakpoints: breakpoints)
    }
    
    /// Sets padding for bottom side
    @discardableResult
    public func paddingBottom<U: UnitValuable>(
        _ value: U = 0.px,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        paddingBottom(.init(wrappedValue: value), breakpoints: breakpoints)
    }
    
    /// Sets padding for bottom side
    @discardableResult
    public func paddingBottom<U: UnitValuable>(
        _ value: U = 0.px,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        paddingBottom(value, breakpoints: breakpoints)
    }
    
    // MARK: Left
    
    /// Sets padding for left side
    @discardableResult
    public func paddingLeft<U: UnitValuable>(
        _ state: State<U>,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        let important = breakpoints.count > 0 ? "!important" : ""
        let className = _getClassName("padding_left", breakpoints: breakpoints)
        self.class(.init(stringLiteral: className))
        let perform: (U) -> Void = { [weak self] value in
            self?._setRule(className, breakpoints: breakpoints) { rule in
                rule.custom("--padding-left", value.description + important)
                return rule.custom("padding", "var(--padding-top, 0) var(--padding-right, 0) var(--padding-bottom, 0) var(--padding-left, 0)" + important)
            }
        }
        perform(state.wrappedValue)
        state.listen {
            perform($0)
        }
        return self
    }
    
    /// Sets padding for left side
    @discardableResult
    public func paddingLeft<U: UnitValuable>(
        _ state: State<U>,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        paddingLeft(state, breakpoints: breakpoints)
    }
    
    /// Sets padding for left side
    @discardableResult
    public func paddingLeft<U: UnitValuable>(
        _ value: U = 0.px,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        paddingLeft(.init(wrappedValue: value), breakpoints: breakpoints)
    }
    
    /// Sets padding for left side
    @discardableResult
    public func paddingLeft<U: UnitValuable>(
        _ value: U = 0.px,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        paddingLeft(value, breakpoints: breakpoints)
    }
    
    // MARK: - Margin
    
    /// Sets margin for all sides
    @discardableResult
    public func margin<U: UnitValuable>(
        _ state: State<U>,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        marginTop(state, breakpoints: breakpoints)
        marginRight(state, breakpoints: breakpoints)
        marginBottom(state, breakpoints: breakpoints)
        marginLeft(state, breakpoints: breakpoints)
        return self
    }
    
    /// Sets margin for all sides
    @discardableResult
    public func margin<U: UnitValuable>(
        _ state: State<U>,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        margin(state, breakpoints: breakpoints)
    }
    
    /// Sets margin for all sides
    @discardableResult
    public func margin<U: UnitValuable>(
        _ value: U = 0.px,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        margin(.init(wrappedValue: value), breakpoints: breakpoints)
    }
    
    /// Sets margin for all sides
    @discardableResult
    public func margin<U: UnitValuable>(
        _ value: U = 0.px,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        margin(value, breakpoints: breakpoints)
    }
    
    // MARK: V & H
    
    /// Sets margin for horizontal and vertical sides separately
    @discardableResult
    public func margin<V: UnitValuable, H: UnitValuable>(
        v: State<V>,
        h: State<H>,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        marginTop(v, breakpoints: breakpoints)
        marginRight(h, breakpoints: breakpoints)
        marginBottom(v, breakpoints: breakpoints)
        marginLeft(h, breakpoints: breakpoints)
        return self
    }
    
    /// Sets margin for horizontal and vertical sides separately
    @discardableResult
    public func margin<V: UnitValuable, H: UnitValuable>(
        v: State<V>,
        h: State<H>,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        margin(v: v, h: h, breakpoints: breakpoints)
    }
    
    /// Sets margin for horizontal and vertical sides separately
    @discardableResult
    public func margin<V: UnitValuable, H: UnitValuable>(
        v: V,
        h: H,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        margin(v: .init(wrappedValue: v), h: .init(wrappedValue: h), breakpoints: breakpoints)
    }
    
    /// Sets margin for horizontal and vertical sides separately
    @discardableResult
    public func margin<V: UnitValuable, H: UnitValuable>(
        v: V,
        h: H,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        margin(v: v, h: h, breakpoints: breakpoints)
    }
    
    // MARK: V
    
    /// Sets margin for vertical sides
    @discardableResult
    public func margin<V: UnitValuable>(
        v: State<V>,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        marginTop(v, breakpoints: breakpoints)
        marginBottom(v, breakpoints: breakpoints)
        return self
    }
    
    /// Sets margin for vertical sides
    @discardableResult
    public func margin<V: UnitValuable>(
        v: State<V>,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        margin(v: v, breakpoints: breakpoints)
    }
    
    /// Sets margin for vertical sides
    @discardableResult
    public func margin<V: UnitValuable>(
        v: V,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        margin(v: .init(wrappedValue: v), breakpoints: breakpoints)
    }
    
    /// Sets margin for vertical sides
    @discardableResult
    public func margin<V: UnitValuable>(
        v: V,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        margin(v: v, breakpoints: breakpoints)
    }
    
    // MARK: H
    
    /// Sets margin for horizontal sides
    @discardableResult
    public func margin<H: UnitValuable>(
        h: State<H>,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        marginRight(h, breakpoints: breakpoints)
        marginLeft(h, breakpoints: breakpoints)
        return self
    }
    
    /// Sets margin for horizontal sides
    @discardableResult
    public func margin<H: UnitValuable>(
        h: State<H>,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        margin(h: h, breakpoints: breakpoints)
    }
    
    /// Sets margin for horizontal sides
    @discardableResult
    public func margin<H: UnitValuable>(
        h: H,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        margin(h: .init(wrappedValue: h), breakpoints: breakpoints)
    }
    
    /// Sets margin for horizontal sides
    @discardableResult
    public func margin<H: UnitValuable>(
        h: H,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        margin(h: h, breakpoints: breakpoints)
    }
    
    // MARK: Top
    
    /// Sets margin for top side
    @discardableResult
    public func marginTop<U: UnitValuable>(
        _ state: State<U>,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        let important = breakpoints.count > 0 ? "!important" : ""
        let className = _getClassName("margin_top", breakpoints: breakpoints)
        self.class(.init(stringLiteral: className))
        let perform: (U) -> Void = { [weak self] value in
            self?._setRule(className, breakpoints: breakpoints) { rule in
                rule.custom("--margin-top", value.description + important)
                return rule.custom("margin", "var(--margin-top, 0) var(--margin-right, 0) var(--margin-bottom, 0) var(--margin-left, 0)" + important)
            }
        }
        perform(state.wrappedValue)
        state.listen {
            perform($0)
        }
        return self
    }
    
    /// Sets margin for top side
    @discardableResult
    public func marginTop<U: UnitValuable>(
        _ state: State<U>,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        marginTop(state, breakpoints: breakpoints)
    }
    
    /// Sets margin for top side
    @discardableResult
    public func marginTop<U: UnitValuable>(
        _ value: U = 0.px,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        marginTop(.init(wrappedValue: value), breakpoints: breakpoints)
    }
    
    /// Sets margin for top side
    @discardableResult
    public func marginTop<U: UnitValuable>(
        _ value: U = 0.px,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        marginTop(value, breakpoints: breakpoints)
    }
    
    // MARK: Right
    
    /// Sets margin for right side
    @discardableResult
    public func marginRight<U: UnitValuable>(
        _ state: State<U>,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        let important = breakpoints.count > 0 ? "!important" : ""
        let className = _getClassName("margin_right", breakpoints: breakpoints)
        self.class(.init(stringLiteral: className))
        let perform: (U) -> Void = { [weak self] value in
            self?._setRule(className, breakpoints: breakpoints) { rule in
                rule.custom("--margin-right", value.description + important)
                return rule.custom("margin", "var(--margin-top, 0) var(--margin-right, 0) var(--margin-bottom, 0) var(--margin-left, 0)" + important)
            }
        }
        perform(state.wrappedValue)
        state.listen {
            perform($0)
        }
        return self
    }
    
    /// Sets margin for right side
    @discardableResult
    public func marginRight<U: UnitValuable>(
        _ state: State<U>,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        marginRight(state, breakpoints: breakpoints)
    }
    
    /// Sets padding for right side
    @discardableResult
    public func marginRight<U: UnitValuable>(
        _ value: U = 0.px,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        marginRight(.init(wrappedValue: value), breakpoints: breakpoints)
    }
    
    /// Sets margin for right side
    @discardableResult
    public func marginRight<U: UnitValuable>(
        _ value: U = 0.px,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        marginRight(value, breakpoints: breakpoints)
    }
    
    // MARK: Bottom
    
    /// Sets margin for bottom side
    @discardableResult
    public func marginBottom<U: UnitValuable>(
        _ state: State<U>,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        let important = breakpoints.count > 0 ? "!important" : ""
        let className = _getClassName("margin_bottom", breakpoints: breakpoints)
        self.class(.init(stringLiteral: className))
        let perform: (U) -> Void = { [weak self] value in
            self?._setRule(className, breakpoints: breakpoints) { rule in
                rule.custom("--margin-bottom", value.description + important)
                return rule.custom("margin", "var(--margin-top, 0) var(--margin-right, 0) var(--margin-bottom, 0) var(--margin-left, 0)" + important)
            }
        }
        perform(state.wrappedValue)
        state.listen {
            perform($0)
        }
        return self
    }
    
    /// Sets margin for bottom side
    @discardableResult
    public func marginBottom<U: UnitValuable>(
        _ state: State<U>,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        marginBottom(state, breakpoints: breakpoints)
    }
    
    /// Sets margin for bottom side
    @discardableResult
    public func marginBottom<U: UnitValuable>(
        _ value: U = 0.px,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        marginBottom(.init(wrappedValue: value), breakpoints: breakpoints)
    }
    
    /// Sets margin for bottom side
    @discardableResult
    public func marginBottom<U: UnitValuable>(
        _ value: U = 0.px,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        marginBottom(value, breakpoints: breakpoints)
    }
    
    // MARK: Left
    
    /// Sets margin for left side
    @discardableResult
    public func marginLeft<U: UnitValuable>(
        _ state: State<U>,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        let important = breakpoints.count > 0 ? "!important" : ""
        let className = _getClassName("margin_left", breakpoints: breakpoints)
        self.class(.init(stringLiteral: className))
        let perform: (U) -> Void = { [weak self] value in
            self?._setRule(className, breakpoints: breakpoints) { rule in
                rule.custom("--margin-left", value.description + important)
                return rule.custom("margin", "var(--margin-top, 0) var(--margin-right, 0) var(--margin-bottom, 0) var(--margin-left, 0)" + important)
            }
        }
        perform(state.wrappedValue)
        state.listen {
            perform($0)
        }
        return self
    }
    
    /// Sets margin for left side
    @discardableResult
    public func marginLeft<U: UnitValuable>(
        _ state: State<U>,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        marginLeft(state, breakpoints: breakpoints)
    }
    
    /// Sets margin for left side
    @discardableResult
    public func marginLeft<U: UnitValuable>(
        _ value: U = 0.px,
        breakpoints: [MediaRule.MediaType]
    ) -> Self {
        marginLeft(.init(wrappedValue: value), breakpoints: breakpoints)
    }
    
    /// Sets margin for left side
    @discardableResult
    public func marginLeft<U: UnitValuable>(
        _ value: U = 0.px,
        breakpoints: MediaRule.MediaType...
    ) -> Self {
        marginLeft(value, breakpoints: breakpoints)
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
