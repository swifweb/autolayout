//
//  Autolayout.swift
//
//
//  Created by Mihael Isaev on 08.12.2022.
//

import Web
import ResizeObserverAPI

public class Autolayout {
    // MARK: Storage keys
    
    struct ResizeObserverStorageKey: StorageKey {
        typealias Value = ResizeObserver
    }

    struct StoredConstraintStorageKey: StorageKey {
        typealias Value = Set<StoredConstraint>
    }
    
    class StoredConstraint: Equatable, Hashable, CustomStringConvertible {
        typealias Handler = () -> Void
        
        let destinationView: BaseElement
        let constraint: Constraint
        var handlers: [Handler]
        
        init (destinationView: BaseElement, constraint: Constraint, handlers: [Handler]) {
            self.destinationView = destinationView
            self.constraint = constraint
            self.handlers = handlers
        }
        
        // Equatable
        
        static func == (lhs: Autolayout.StoredConstraint, rhs: Autolayout.StoredConstraint) -> Bool {
            lhs.destinationView == rhs.destinationView && lhs.constraint == rhs.constraint
        }
        
        // Hashable
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(destinationView)
            hasher.combine(constraint)
        }
        
        public var description: String {
            "#\(destinationView.properties._id)/\(constraint.rawValue)"
        }
    }
    
    // MARK: Constraints
    
    enum Constraint: String {
        case widthToWidthOfView
        case widthToHeightOfView
        case heightToHeightOfView
        case heightToWidthOfView
        case leftToLeftOfView
        case leftToRightOfView
        case leftToCenterOfView
        case rightToRightOfView
        case rightToLeftOfView
        case rightToCenterOfView
        case topToTopOfView
        case topToBottomOfView
        case topToCenterOfView
        case bottomToBottomOfView
        case bottomToTopOfView
        case bottomToCenterOfView
        case widthToSuperview
        case heightToSuperview
        case topToSuperview
        case bottomToSuperview
        case leadingToSuperview
        case trailingToSuperview
        case leftToSuperview
        case rightToSuperview
        case centerXInSuperview
        case centerXToLeftOfView
        case centerXToRightOfView
        case centerXToCenterXOfView
        case centerYInSuperview
        case centerYToTopOfView
        case centerYToBottomOfView
        case centerYToCenterYOfView
    }
    
    enum ConstraintAttribute: String {
        case left
        case right
        case top
        case bottom
        case leading
        case trailing
        case width
        case height
        case centerX
        case centerY
    }
    
    // MARK: Constraint sides

    public enum ConstraintCXSide {
        case x
        case leading, left
        case trailing, right
        case centerX
        var side: ConstraintAttribute {
            switch self {
            case .x: return .centerX
            case .leading: return .leading
            case .left: return .left
            case .trailing: return .trailing
            case .right: return .right
            case .centerX: return .centerX
            }
        }
    }

    public enum ConstraintCYSide {
        case y
        case top, bottom
        case centerY
        var side: ConstraintAttribute {
            switch self {
            case .y: return .centerY
            case .top: return .top
            case .bottom: return .bottom
            case .centerY: return .centerY
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
        case leading, left, trailing, right, centerX
        var side: ConstraintAttribute {
            switch self {
            case .leading: return .leading
            case .left: return .left
            case .trailing: return .trailing
            case .right: return .right
            case .centerX: return .centerX
            }
        }
    }

    public enum ConstraintYSide {
        case top, bottom, centerY
        var side: ConstraintAttribute {
            switch self {
            case .top: return .top
            case .bottom: return .bottom
            case .centerY: return .centerY
            }
        }
    }
}

extension BaseElement {
    var resizeObserver: ResizeObserver? {
        get { self.storage.get(Autolayout.ResizeObserverStorageKey.self) }
        set { self.storage.set(Autolayout.ResizeObserverStorageKey.self, to: newValue) }
    }
    var storedConstraints: Set<Autolayout.StoredConstraint> {
        get { self.storage.get(Autolayout.StoredConstraintStorageKey.self) ?? .init() }
        set { self.storage.set(Autolayout.StoredConstraintStorageKey.self, to: newValue) }
    }
    
    // MARK: Relative
    
    private func setupConstraint(_ constraint: Autolayout.Constraint, for view: BaseElement, _ handler: @escaping () -> Void) {
        let resizeObserver = view.resizeObserver ?? ResizeObserver().observe(view)
        
        if let member = view.storedConstraints.first(where: { $0.destinationView == view && $0.constraint == constraint }) {
//            print("❗️storedConstraints already contains member #\(view.properties._id) set handlersForView #\(self.properties._id)")
            member.handlers.append(handler)
        } else {
            let member = Autolayout.StoredConstraint(destinationView: view, constraint: constraint, handlers: [handler])
            view.storedConstraints.insert(member)
        }
        
//        print("#\(view.properties._id) set handlersForView #\(self.properties._id)")
        
        resizeObserver.setObserver(for: self) { [weak self] entries, observer in
//            print("#\(self?.properties._id ?? "nnn") #\(view.properties._id).resizeObserver fired, storedConstraints.count: \(view.storedConstraints.count), values: \(view.storedConstraints.map { $0.description })")
            view.storedConstraints.forEach {
//                print("#\(self?.properties._id ?? "nnn") calling #\($0.destinationView.properties._id) handler for \($0.constraint)")
                $0.handlers.forEach { $0() }
            }
        }
        view.resizeObserver = resizeObserver
        if isInDOM {
            handler()
        } else {
            onDidAddToDOM(handler)
        }
        view.onDidAddToDOM(handler)
    }
    
    // MARK: - Relative
    
    private func _createRelative<U: UnitValuable>(
        value: State<U>,
        multiplier: Double,
        attribute1: Autolayout.ConstraintAttribute,
        attribute2: Autolayout.ConstraintAttribute,
        destinationView: BaseElement
    ) -> Self {
        var printedWarning: [Autolayout.Constraint: Bool] = [:]
        func _setupSides(
            currentAbsolute: @escaping () -> Double?,
            currentOffset: @escaping () -> Double?,
            destinationAbsolute: @escaping () -> Double?,
            constraint: Autolayout.Constraint,
            trackSelf: Bool = false,
            newValueHandler: @escaping (UnitValue) -> Void
        ) {
            func _setup(_ value: UnitValue) {
//                print("_setupSides #\(self.properties._id) -> #\(destinationView.properties._id) \(constraint)")
                let updateHandler: () -> Void = { [weak self] in
                    guard let self = self else { return }
                    let _position = Window.shared.getComputedStyle(self, for: CSS.PropertyType.position.rawValue)
                    guard let p = _position, p != "", p != "static" else {
                        if printedWarning[constraint] != true {
                            printedWarning[constraint] = true
                            #if DEBUG
                            Console.warning("⚠️🎨 \(attribute1.rawValue.capitalized) to \(attribute2.rawValue) constraint doesn't work with static position (#\(self.properties._id).\(attribute1.rawValue) to #\(destinationView.properties._id).\(attribute2.rawValue))")
                            #endif
                        }
                        return
                    }
//                    if (p != "absolute" || p != "fixed"), [
//                        .topToSuperview, .topToTopOfView, .topToBottomOfView, .topToCenterOfView,
//                        .bottomToSuperview, .bottomToTopOfView, .bottomToBottomOfView, .bottomToCenterOfView,
//                        .leftToSuperview, .leftToLeftOfView, .leftToRightOfView, .leftToCenterOfView,
//                        .rightToSuperview, .rightToLeftOfView, .rightToRightOfView, .rightToCenterOfView,
//                        .leadingToSuperview,
//                        .trailingToSuperview
//                    ].contains(constraint) {
//                        self.position(.absolute)
//                        #if DEBUG
//                        Console.warning("⚠️🎨 \(attribute1.rawValue.capitalized) to \(attribute2.rawValue) automatically fixed position to absolute (#\(self.properties._id).\(attribute1.rawValue) to #\(destinationView.properties._id).\(attribute2.rawValue))")
//                        #endif
//                    }
                    let currentAbsolute = currentAbsolute() ?? 0
                    let currentOffset = currentOffset() ?? 0
                    let destinationAbsolute = destinationAbsolute() ?? 0
                    printedWarning[constraint] = false
                    var diff: Double = 0
                    let newValue: Double
                    if currentAbsolute > destinationAbsolute {
                        diff = currentAbsolute - destinationAbsolute
                        newValue = currentOffset - diff
                    } else if currentAbsolute < destinationAbsolute {
                        diff = destinationAbsolute - currentAbsolute
                        newValue = currentOffset + diff
                    } else {
                        newValue = currentOffset
                    }
//                    print("#\(self.properties._id) -> #\(destinationView.properties._id) cAbsolute: \(currentAbsolute) cOffset: \(currentOffset) dAbsolute: \(destinationAbsolute)")
                    newValueHandler(.init(newValue * multiplier + value.value, .px))
                }
                setupConstraint(constraint, for: destinationView, updateHandler)
                if trackSelf {
                    setupConstraint(constraint, for: self, updateHandler)
                }
            }
            value.listen {
                _setup(.init($0.value.doubleValue, $0.unit))
            }
            _setup(.init(value.wrappedValue.value.doubleValue, value.wrappedValue.unit))
        }
        switch attribute1 {
        case .left, .leading:
            switch attribute2 {
            case .left, .leading:
                _setupSides(
                    currentAbsolute: { [weak self] in self?.absoluteLeft },
                    currentOffset: { [weak self] in self?.offsetLeft },
                    destinationAbsolute: { [weak destinationView] in destinationView?.absoluteLeft },
                    constraint: .leftToLeftOfView
                ) { [weak self] in
//                    print("left to left called")
                    self?.left($0)
                }
            case .right, .trailing:
                _setupSides(
                    currentAbsolute: { [weak self] in self?.absoluteLeft },
                    currentOffset: { [weak self] in self?.offsetLeft },
                    destinationAbsolute: { [weak destinationView] in destinationView?.absoluteRight },
                    constraint: .leftToRightOfView
                ) { [weak self] in
//                    print("left to right called")
                    self?.left($0)
                }
//            case .leading: // TODO
//                break
//            case .trailing: // TODO
//                break
            case .centerX:
                _setupSides(
                    currentAbsolute: { [weak self] in self?.absoluteLeft },
                    currentOffset: { [weak self] in self?.offsetLeft },
                    destinationAbsolute: { [weak destinationView] in destinationView?.absoluteLeft },
                    constraint: .leftToCenterOfView
                ) { [weak self] in
//                    print("left to centerX called")
                    guard let self = self else { return }
                    self.left(($0.value + (destinationView.clientWidth / 2)).px)
                }
            default:
                break
            }
        case .right, .trailing:
            switch attribute2 {
            case .left, .leading:
                _setupSides(
                    currentAbsolute: { [weak self] in self?.absoluteLeft },
                    currentOffset: { [weak self] in self?.offsetLeft },
                    destinationAbsolute: { [weak destinationView] in destinationView?.absoluteLeft },
                    constraint: .rightToLeftOfView,
                    trackSelf: true
                ) { [weak self] in
//                    print("right to left called")
                    guard let self = self else { return }
                    self.left(($0.value - self.clientWidth).px)
                }
            case .right, .trailing:
                _setupSides(
                    currentAbsolute: { [weak self] in self?.absoluteLeft },
                    currentOffset: { [weak self] in self?.offsetLeft },
                    destinationAbsolute: { [weak destinationView] in destinationView?.absoluteLeft },
                    constraint: .rightToRightOfView,
                    trackSelf: true
                ) { [weak self] in
//                    print("right to right called")
                    guard let self = self else { return }
                    if destinationView.clientWidth > self.clientWidth {
                        self.left(($0.value + (destinationView.clientWidth - self.clientWidth)).px)
                    } else if self.clientWidth > destinationView.clientWidth {
                        self.left(($0.value + (self.clientWidth - destinationView.clientWidth)).px)
                    } else {
                        self.left($0)
                    }
                }
//            case .leading: // TODO
//                break
//            case .trailing: // TODO
//                break
            case .centerX:
                _setupSides(
                    currentAbsolute: { [weak self] in self?.absoluteLeft },
                    currentOffset: { [weak self] in self?.offsetLeft },
                    destinationAbsolute: { [weak destinationView] in destinationView?.absoluteLeft },
                    constraint: .rightToCenterOfView,
                    trackSelf: true
                ) { [weak self] in
//                    print("right to centerX called")
                    guard let self = self else { return }
                    let destinationCenterPoint = ($0.value + (destinationView.clientWidth / 2))
                    let currentRightPoint = $0.value + self.clientWidth
                    let diff = currentRightPoint - destinationCenterPoint
                    if destinationCenterPoint > currentRightPoint {
                        self.left(($0.value + (destinationCenterPoint - currentRightPoint)).px)
                    } else if destinationCenterPoint < currentRightPoint {
                        self.left(($0.value - (currentRightPoint - destinationCenterPoint)).px)
                    } else {
                        self.left($0)
                    }
                }
            default:
                break
            }
        case .top:
            switch attribute2 {
            case .top:
                _setupSides(
                    currentAbsolute: { [weak self] in self?.absoluteTop },
                    currentOffset: { [weak self] in self?.offsetTop },
                    destinationAbsolute: { [weak destinationView] in destinationView?.absoluteTop },
                    constraint: .topToTopOfView
                ) { [weak self] in
//                    print("top to top called")
                    self?.top($0)
                }
            case .bottom:
                _setupSides(
                    currentAbsolute: { [weak self] in self?.absoluteTop },
                    currentOffset: { [weak self] in self?.offsetTop },
                    destinationAbsolute: { [weak destinationView] in destinationView?.absoluteBottom },
                    constraint: .topToBottomOfView
                ) { [weak self] in
//                    print("top to bottom called")
                    self?.top($0)
                }
            case .centerY:
                _setupSides(
                    currentAbsolute: { [weak self] in self?.absoluteTop },
                    currentOffset: { [weak self] in self?.offsetTop },
                    destinationAbsolute: { [weak destinationView] in destinationView?.absoluteTop },
                    constraint: .topToCenterOfView
                ) { [weak self] in
//                    print("top to centerY called")
                    guard let self = self else { return }
                    self.top(($0.value + (destinationView.clientHeight / 2)).px)
                }
            default:
                break
            }
        case .bottom:
            switch attribute2 {
            case .top:
                _setupSides(
                    currentAbsolute: { [weak self] in self?.absoluteTop },
                    currentOffset: { [weak self] in self?.offsetTop },
                    destinationAbsolute: { [weak destinationView] in destinationView?.absoluteTop },
                    constraint: .bottomToTopOfView,
                    trackSelf: true
                ) { [weak self] in
//                    print("bottom to top called")
                    guard let self = self else { return }
                    self.top(($0.value - self.clientHeight).px)
                }
            case .bottom:
                _setupSides(
                    currentAbsolute: { [weak self] in self?.absoluteTop },
                    currentOffset: { [weak self] in self?.offsetTop },
                    destinationAbsolute: { [weak destinationView] in destinationView?.absoluteTop },
                    constraint: .bottomToBottomOfView,
                    trackSelf: true
                ) { [weak self] in
//                    print("bottom to bottom called")
                    guard let self = self else { return }
                    if destinationView.clientHeight > self.clientHeight {
                        self.top(($0.value + (destinationView.clientHeight - self.clientHeight)).px)
                    } else if self.clientHeight > destinationView.clientHeight {
                        self.top(($0.value + (self.clientHeight - destinationView.clientHeight)).px)
                    } else {
                        self.top($0)
                    }
                }
            case .centerY:
                _setupSides(
                    currentAbsolute: { [weak self] in self?.absoluteTop },
                    currentOffset: { [weak self] in self?.offsetTop },
                    destinationAbsolute: { [weak destinationView] in destinationView?.absoluteTop },
                    constraint: .bottomToCenterOfView,
                    trackSelf: true
                ) { [weak self] in
//                    print("bottom to centerY called")
                    guard let self = self else { return }
                    let destinationCenterPoint = ($0.value + (destinationView.clientHeight / 2))
                    let currentRightPoint = $0.value + self.clientHeight
                    let diff = currentRightPoint - destinationCenterPoint
                    if destinationCenterPoint > currentRightPoint {
                        self.top(($0.value + (destinationCenterPoint - currentRightPoint)).px)
                    } else if destinationCenterPoint < currentRightPoint {
                        self.top(($0.value - (currentRightPoint - destinationCenterPoint)).px)
                    } else {
                        self.top($0)
                    }
                }
            default:
                break
            }
//        case .leading: // TODO
//            switch attribute2 {
//            case .left:
//                break
//            case .right:
//                break
//            case .leading:
//                break
//            case .trailing:
//                break
//            case .centerX:
//                break
//            default:
//                break
//            }
//        case .trailing: // TODO
//            switch attribute2 {
//            case .left:
//                break
//            case .right:
//                break
//            case .leading:
//                break
//            case .trailing:
//                break
//            case .centerX:
//                break
//            default:
//                break
//            }
        case .width:
            switch attribute2 {
            case .width:
                func setup(_ value: UnitValue) {
                    let updateHandler: () -> Void = { [weak self] in
//                        print("height to width called")
                        self?.width(UnitValue(destinationView.clientWidth * multiplier + value.value, .px))
                    }
                    setupConstraint(.widthToWidthOfView, for: destinationView, updateHandler)
                }
                value.listen {
                    setup(.init($0.value.doubleValue, $0.unit))
                }
                setup(.init(value.wrappedValue.value.doubleValue, value.wrappedValue.unit))
            case .height:
                func setup(_ value: UnitValue) {
                    let updateHandler: () -> Void = { [weak self] in
//                        print("width to height called")
                        self?.width(UnitValue(destinationView.clientHeight * multiplier + value.value, .px))
                    }
                    setupConstraint(.widthToHeightOfView, for: destinationView, updateHandler)
                }
                value.listen {
                    setup(.init($0.value.doubleValue, $0.unit))
                }
                setup(.init(value.wrappedValue.value.doubleValue, value.wrappedValue.unit))
            default:
                break
            }
        case .height:
            switch attribute2 {
            case .width:
                func setup(_ value: UnitValue) {
                    let updateHandler: () -> Void = { [weak self] in
//                        print("height to width called")
                        self?.height(UnitValue(destinationView.clientWidth * multiplier + value.value, .px))
                    }
                    setupConstraint(.heightToWidthOfView, for: destinationView, updateHandler)
                }
                value.listen {
                    setup(.init($0.value.doubleValue, $0.unit))
                }
                setup(.init(value.wrappedValue.value.doubleValue, value.wrappedValue.unit))
            case .height:
                func setup(_ value: UnitValue) {
                    let updateHandler: () -> Void = { [weak self] in
//                        print("height to height called")
                        self?.height(UnitValue(destinationView.clientHeight * multiplier + value.value, .px))
                    }
                    setupConstraint(.heightToHeightOfView, for: destinationView, updateHandler)
                }
                value.listen {
                    setup(.init($0.value.doubleValue, $0.unit))
                }
                setup(.init(value.wrappedValue.value.doubleValue, value.wrappedValue.unit))
            default:
                break
            }
        case .centerX:
//            print("create centerX 1")
            switch attribute2 {
            case .left, .leading:
                _setupSides(
                    currentAbsolute: { [weak self] in self?.absoluteLeft },
                    currentOffset: { [weak self] in self?.offsetLeft },
                    destinationAbsolute: { [weak destinationView] in destinationView?.absoluteLeft },
                    constraint: .centerXToLeftOfView,
                    trackSelf: true
                ) { [weak self] in
//                    print("centerX to left called")
                    guard let self = self else { return }
                    self.left(($0.value - (self.clientWidth / 2)).px)
                }
            case .right, .trailing:
                _setupSides(
                    currentAbsolute: { [weak self] in self?.absoluteLeft },
                    currentOffset: { [weak self] in self?.offsetLeft },
                    destinationAbsolute: { [weak destinationView] in destinationView?.absoluteRight },
                    constraint: .centerXToRightOfView,
                    trackSelf: true
                ) { [weak self] in
//                    print("centerX to right called")
                    guard let self = self else { return }
                    self.left(($0.value - (self.clientWidth / 2)).px)
                }
//            case .leading: // TODO
//                break
//            case .trailing: // TODO
//                break
            case .centerX:
//                print("centerX(#\(self.properties._id)) to centerX(#\(destinationView.properties._id)) case 1")
                _setupSides(
                    currentAbsolute: { [weak self] in self?.absoluteLeft },
                    currentOffset: { [weak self] in self?.offsetLeft },
                    destinationAbsolute: { [weak destinationView] in destinationView?.absoluteLeft },
                    constraint: .centerXToCenterXOfView,
                    trackSelf: true
                ) { [weak self] in
//                    print("centerX to centerX called")
//                    print("centerX(#\(self?.properties._id ?? "nnn")) to centerX(#\(destinationView.properties._id)) case 2")
                    guard let self = self else { return }
//                    print("centerX(#\(self.properties._id)) to centerX(#\(destinationView.properties._id)) case 3")
                    let currentCenter = (self.clientWidth / 2)
                    let destinationCenter = (destinationView.clientWidth / 2)
                    if currentCenter > destinationCenter {
//                        print("centerX(#\(self.properties._id)) to centerX(#\(destinationView.properties._id)) case 4.1")
                        self.left(($0.value + destinationCenter - currentCenter).px)
                    } else if destinationCenter > currentCenter {
//                        print("centerX(#\(self.properties._id)) to centerX(#\(destinationView.properties._id)) case 4.2")
                        self.left(($0.value + destinationCenter - currentCenter).px)
                    } else {
//                        print("centerX(#\(self.properties._id)) to centerX(#\(destinationView.properties._id)) case 4.3")
                        self.left($0)
                    }
                }
            default:
                break
            }
        case .centerY:
            switch attribute2 {
            case .top:
                _setupSides(
                    currentAbsolute: { [weak self] in self?.absoluteTop },
                    currentOffset: { [weak self] in self?.offsetTop },
                    destinationAbsolute: { [weak destinationView] in destinationView?.absoluteTop },
                    constraint: .centerYToTopOfView,
                    trackSelf: true
                ) { [weak self] in
//                    print("centerY to top called")
                    guard let self = self else { return }
                    self.top(($0.value - (self.clientHeight / 2)).px)
                }
            case .bottom:
                _setupSides(
                    currentAbsolute: { [weak self] in self?.absoluteTop },
                    currentOffset: { [weak self] in self?.offsetTop },
                    destinationAbsolute: { [weak destinationView] in destinationView?.absoluteBottom },
                    constraint: .centerYToBottomOfView,
                    trackSelf: true
                ) { [weak self] in
//                    print("centerY to bottom called")
                    guard let self = self else { return }
                    self.top(($0.value - (self.clientHeight / 2)).px)
                }
            case .centerY:
                _setupSides(
                    currentAbsolute: { [weak self] in self?.absoluteTop },
                    currentOffset: { [weak self] in self?.offsetTop },
                    destinationAbsolute: { [weak destinationView] in destinationView?.absoluteTop },
                    constraint: .centerYToCenterYOfView,
                    trackSelf: true
                ) { [weak self] in
                    print("centerY to centerY called: destinationView.clientHeight: \(destinationView.clientHeight)")
                    guard let self = self else { return }
                    let currentCenter = (self.clientHeight / 2)
                    let destinationCenter = (destinationView.clientHeight / 2)
                    if currentCenter > destinationCenter {
                        print("centerY to centerY case 1")
                        self.top(($0.value + destinationCenter - currentCenter).px)
                    } else if destinationCenter > currentCenter {
                        print("centerY to centerY case 2")
                        self.top(($0.value + destinationCenter - currentCenter).px)
                    } else {
                        print("centerY to centerY case 3")
                        self.top($0)
                    }
                }
            default:
                break
            }
        }
        return self
    }
    
    // MARK: - top
    
    /// Has no effect with **position: static**
    @discardableResult
    public func top<U: UnitValuable>(
        to side: Autolayout.ConstraintYSide,
        of view: BaseElement,
        _ state: State<U>,
        multiplier: Double = 1
    ) -> Self {
        _createRelative(value: state,
                        multiplier: multiplier,
                        attribute1: .top,
                        attribute2: side.side,
                        destinationView: view)
    }
    
    /// By default to `bottom` of destination view
    ///
    /// Has no effect with **position: static**
    @discardableResult
    public func top<U: UnitValuable>(
        to view: BaseElement,
        _ state: State<U>,
        multiplier: Double = 1
    ) -> Self {
        top(to: .bottom, of: view, state, multiplier: multiplier)
    }
    
    /// Has no effect with **position: static**
    @discardableResult
    public func top<U: UnitValuable>(
        to side: Autolayout.ConstraintYSide,
        of view: BaseElement,
        _ value: U = 0.px
    ) -> Self {
        top(to: side,
              of: view,
              .init(wrappedValue: value),
              multiplier: 1)
    }
    
    /// By default to `bottom` of destination view
    ///
    /// Has no effect with **position: static**
    @discardableResult
    public func top<U: UnitValuable>(
        to view: BaseElement,
        _ value: U = 0.px
    ) -> Self {
        top(to: .bottom, of: view, value)
    }
    
    // MARK: - leading
    
    /// Has no effect with **position: static**
    @discardableResult
    public func leading<U: UnitValuable>(
        to side: Autolayout.ConstraintXSide,
        of view: BaseElement,
        _ state: State<U>,
        multiplier: Double = 1
    ) -> Self {
        _createRelative(value: state,
                                multiplier: multiplier,
                                attribute1: .leading,
                                attribute2: side.side,
                                destinationView: view)
    }
    
    /// By default to `trailing` of destination view
    ///
    /// Has no effect with **position: static**
    @discardableResult
    public func leading<U: UnitValuable>(
        to view: BaseElement,
        _ state: State<U>,
        multiplier: Double = 1
    ) -> Self {
        leading(to: .trailing, of: view, state, multiplier: multiplier)
    }
    
    /// Has no effect with **position: static**
    @discardableResult
    public func leading<U: UnitValuable>(
        to side: Autolayout.ConstraintXSide,
        of view: BaseElement,
        _ value: U = 0.px
    ) -> Self {
        leading(to: side,
                   of: view,
                   .init(wrappedValue: value),
                   multiplier: 1)
    }
    
    /// By default to `trailing` of destination view
    ///
    /// Has no effect with **position: static**
    @discardableResult
    public func leading<U: UnitValuable>(
        to view: BaseElement,
        _ value: U = 0.px
    ) -> Self {
        leading(to: .trailing, of: view, value)
    }
    
    // MARK: - left
    
    /// Has no effect with **position: static**
    @discardableResult
    public func left<U: UnitValuable>(
        to side: Autolayout.ConstraintXSide,
        of view: BaseElement,
        _ state: State<U>,
        multiplier: Double = 1
    ) -> Self {
        _createRelative(value: state,
                                multiplier: multiplier,
                                attribute1: .left,
                                attribute2: side.side,
                                destinationView: view)
    }
    
    /// By default to `right` of destination view
    ///
    /// Has no effect with **position: static**
    @discardableResult
    public func left<U: UnitValuable>(
        to view: BaseElement,
        _ state: State<U>,
        multiplier: Double = 1
    ) -> Self {
        left(to: .right, of: view, state, multiplier: multiplier)
    }
    
    /// Has no effect with **position: static**
    @discardableResult
    public func left<U: UnitValuable>(
        to side: Autolayout.ConstraintXSide,
        of view: BaseElement,
        _ value: U = 0.px
    ) -> Self {
        left(to: side,
              of: view,
              .init(wrappedValue: value),
              multiplier: 1)
    }
    
    /// By default to `right` of destination view
    ///
    /// Has no effect with **position: static**
    @discardableResult
    public func left<U: UnitValuable>(
        to view: BaseElement,
        _ value: U = 0.px
    ) -> Self {
        left(to: .right, of: view, value)
    }
    
    // MARK: - trailing
    
    /// Has no effect with **position: static**
    @discardableResult
    public func trailing<U: UnitValuable>(
        to side: Autolayout.ConstraintXSide,
        of view: BaseElement,
        _ state: State<U>,
        multiplier: Double = 1
    ) -> Self {
        _createRelative(value: state,
                                multiplier: multiplier,
                                attribute1: .trailing,
                                attribute2: side.side,
                                destinationView: view)
    }
    
    /// By default to `leading` of destination view
    ///
    /// Has no effect with **position: static**
    @discardableResult
    public func trailing<U: UnitValuable>(
        to view: BaseElement,
        _ state: State<U>,
        multiplier: Double = 1
    ) -> Self {
        trailing(to: .leading, of: view, state, multiplier: multiplier)
    }
    
    /// Has no effect with **position: static**
    @discardableResult
    public func trailing<U: UnitValuable>(
        to side: Autolayout.ConstraintXSide,
        of view: BaseElement,
        _ value: U = 0.px
    ) -> Self {
        trailing(to: side,
                   of: view,
                   .init(wrappedValue: value),
                   multiplier: 1)
    }
    
    /// By default to `leading` of destination view
    ///
    /// Has no effect with **position: static**
    @discardableResult
    public func trailing<U: UnitValuable>(
        to view: BaseElement,
        _ value: U = 0.px
    ) -> Self {
        trailing(to: .leading, of: view, value)
    }
    
    // MARK: - right
    
    /// Has no effect with **position: static**
    @discardableResult
    public func right<U: UnitValuable>(
        to side: Autolayout.ConstraintXSide,
        of view: BaseElement,
        _ state: State<U>,
        multiplier: Double = 1
    ) -> Self {
        _createRelative(value: state,
                                multiplier: multiplier,
                                attribute1: .right,
                                attribute2: side.side,
                                destinationView: view)
    }
    
    /// By default to `left` of destination view
    ///
    /// Has no effect with **position: static**
    @discardableResult
    public func right<U: UnitValuable>(
        to view: BaseElement,
        _ state: State<U>,
        multiplier: Double = 1
    ) -> Self {
        right(to: .left, of: view, state, multiplier: multiplier)
    }
    
    /// Has no effect with **position: static**
    @discardableResult
    public func right<U: UnitValuable>(
        to side: Autolayout.ConstraintXSide,
        of view: BaseElement,
        _ value: U = 0.px
    ) -> Self {
        right(to: side,
                of: view,
                .init(wrappedValue: value),
                multiplier: 1)
    }
    
    /// By default to `left` of destination view
    ///
    /// Has no effect with **position: static**
    @discardableResult
    public func right<U: UnitValuable>(
        to view: BaseElement,
        _ value: U = 0.px
    ) -> Self {
        right(to: .left, of: view, value)
    }
    
    // MARK: - bottom
    
    /// Has no effect with **position: static**
    @discardableResult
    public func bottom<U: UnitValuable>(
        to side: Autolayout.ConstraintYSide,
        of view: BaseElement,
        _ state: State<U>,
        multiplier: Double = 1
    ) -> Self {
        _createRelative(value: state,
                                multiplier: multiplier,
                                attribute1: .bottom,
                                attribute2: side.side,
                                destinationView: view)
    }
    
    /// By default to `top` of destination view
    ///
    /// Has no effect with **position: static**
    @discardableResult
    public func bottom<U: UnitValuable>(
        to view: BaseElement,
        _ state: State<U>,
        multiplier: Double = 1
    ) -> Self {
        bottom(to: .top, of: view, state, multiplier: multiplier)
    }
    
    /// Has no effect with **position: static**
    @discardableResult
    public func bottom<U: UnitValuable>(
        to side: Autolayout.ConstraintYSide,
        of view: BaseElement,
        _ value: U = 0.px
    ) -> Self {
        bottom(to: side,
                   of: view,
                   .init(wrappedValue: value),
                   multiplier: 1)
    }
    
    /// By default to `top` of destination view
    ///
    /// Has no effect with **position: static**
    @discardableResult
    public func bottom<U: UnitValuable>(
        to view: BaseElement,
        _ value: U = 0.px
    ) -> Self {
        bottom(to: .top, of: view, value)
    }
    
    // MARK: - center x
    
    /// Has no effect with **position: static**
    @discardableResult
    public func centerX<U: UnitValuable>(
        to side: Autolayout.ConstraintCXSide,
        of view: BaseElement,
        _ state: State<U>,
        multiplier: Double = 1
    ) -> Self {
        _createRelative(value: state,
                                multiplier: multiplier,
                                attribute1: .centerX,
                                attribute2: side.side,
                                destinationView: view)
    }
    
    /// By default to `centerX` of destination view
    ///
    /// Has no effect with **position: static**
    @discardableResult
    public func centerX<U: UnitValuable>(
        to view: BaseElement,
        _ state: State<U>,
        multiplier: Double = 1
    ) -> Self {
        centerX(to: .x, of: view, state, multiplier: multiplier)
    }
    
    /// Has no effect with **position: static**
    @discardableResult
    public func centerX<U: UnitValuable>(
        to side: Autolayout.ConstraintCXSide,
        of view: BaseElement,
        _ value: U = 0.px,
        multiplier: Double = 1
    ) -> Self {
        centerX(to: side,
                    of: view,
                    .init(wrappedValue: value),
                    multiplier: multiplier)
    }
    
    /// By default to `centerX` of destination view
    ///
    /// Has no effect with **position: static**
    @discardableResult
    public func centerX<U: UnitValuable>(
        to view: BaseElement,
        _ value: U = 0.px,
        multiplier: Double = 1
    ) -> Self {
        centerX(to: .x, of: view, value, multiplier: multiplier)
    }
    
    // MARK: - center y
    
    /// Has no effect with **position: static**
    @discardableResult
    public func centerY<U: UnitValuable>(
        to side: Autolayout.ConstraintCYSide,
        of view: BaseElement,
        _ state: State<U>,
        multiplier: Double = 1
    ) -> Self {
        _createRelative(value: state,
                                multiplier: multiplier,
                                attribute1: .centerY,
                                attribute2: side.side,
                                destinationView: view)
    }
    
    /// By default to `centerY` of destination view
    ///
    /// Has no effect with **position: static**
    @discardableResult
    public func centerY<U: UnitValuable>(
        to view: BaseElement,
        _ state: State<U>,
        multiplier: Double = 1
    ) -> Self {
        centerY(to: .y, of: view, state, multiplier: multiplier)
    }
    
    /// Has no effect with **position: static**
    @discardableResult
    public func centerY<U: UnitValuable>(
        to side: Autolayout.ConstraintCYSide,
        of view: BaseElement,
        _ value: U = 0.px,
        multiplier: Double = 1
    ) -> Self {
        centerY(to: side,
                    of: view,
                    .init(wrappedValue: value),
                    multiplier: multiplier)
    }
    
    /// By default to `centerY` of destination view
    ///
    /// Has no effect with **position: static**
    @discardableResult
    public func centerY<U: UnitValuable>(
        to view: BaseElement,
        _ value: U = 0.px,
        multiplier: Double = 1
    ) -> Self {
        centerY(to: .y, of: view, value, multiplier: multiplier)
    }
    
    // MARK: - center both
    
    /// Has no effect with **position: static**
    @discardableResult
    public func center<U: UnitValuable>(
        to view: BaseElement,
        _ value: State<U>,
        multiplier: Double = 1
    ) -> Self {
        centerX(to: view, value, multiplier: multiplier)
        .centerY(to: view, value, multiplier: multiplier)
    }
    
    /// Has no effect with **position: static**
    @discardableResult
    public func center<U: UnitValuable>(
        to view: BaseElement,
        _ value: U
    ) -> Self {
        centerX(to: view, value).centerY(to: view, value)
    }
    
    /// Has no effect with **position: static**
    @discardableResult
    public func center<X: UnitValuable, Y: UnitValuable>(
        to view: BaseElement,
        x: State<X>,
        y: State<Y>,
        multiplier: Double = 1
    ) -> Self {
        centerX(to: view, x, multiplier: multiplier)
        .centerY(to: view, y, multiplier: multiplier)
    }
    
    /// Has no effect with **position: static**
    @discardableResult
    public func center<X: UnitValuable, Y: UnitValuable>(
        to view: BaseElement,
        x: State<X>,
        y: Y,
        multiplier: Double = 1
    ) -> Self {
        centerX(to: view, x, multiplier: multiplier)
        .centerY(to: view, y, multiplier: multiplier)
    }
    
    /// Has no effect with **position: static**
    @discardableResult
    public func center<X: UnitValuable, Y: UnitValuable>(
        to view: BaseElement,
        x: X,
        y: State<Y>,
        multiplier: Double = 1
    ) -> Self {
        centerX(to: view, x, multiplier: multiplier)
        .centerY(to: view, y, multiplier: multiplier)
    }
    
    /// Has no effect with **position: static**
    @discardableResult
    public func center<X: UnitValuable, Y: UnitValuable>(
        to view: BaseElement,
        x: X = 0.px,
        y: Y = 0.px
    ) -> Self {
        centerX(to: view, x).centerY(to: view, y)
    }
    
    // MARK: - width
    
    @discardableResult
    public func width<U: UnitValuable>(
        to side: Autolayout.ConstraintDSide,
        of view: BaseElement,
        _ state: State<U>,
        multiplier: Double = 1
    ) -> Self {
        _createRelative(value: state,
                                multiplier: multiplier,
                                attribute1: .width,
                                attribute2: side.side,
                                destinationView: view)
    }
    
    /// By default to `width` of destination view
    @discardableResult
    public func width<U: UnitValuable>(
        to view: BaseElement,
        _ state: State<U>,
        multiplier: Double = 1
    ) -> Self {
        width(to: .width, of: view, state, multiplier: multiplier)
    }
    
    @discardableResult
    public func width<U: UnitValuable>(
        to side: Autolayout.ConstraintDSide,
        of view: BaseElement,
        _ value: U = 0.px
    ) -> Self {
        width(to: side,
                 of: view,
                 .init(wrappedValue: value),
                 multiplier: 1)
    }
    
    /// By default to `width` of destination view
    @discardableResult
    public func width<U: UnitValuable>(
        to view: BaseElement,
        _ value: U = 0.px
    ) -> Self {
        width(to: .width, of: view, value)
    }
    
    // MARK: - height
    
    @discardableResult
    public func height<U: UnitValuable>(
        to side: Autolayout.ConstraintDSide,
        of view: BaseElement,
        _ state: State<U>,
        multiplier: Double = 1
    ) -> Self {
        _createRelative(value: state,
                                multiplier: multiplier,
                                attribute1: .height,
                                attribute2: side.side,
                                destinationView: view)
    }
    
    /// By default to `height` of destination view
    @discardableResult
    public func height<U: UnitValuable>(
        to view: BaseElement,
        _ state: State<U>,
        multiplier: Double = 1
    ) -> Self {
        height(to: .height, of: view, state, multiplier: multiplier)
    }
    
    @discardableResult
    public func height<U: UnitValuable>(
        to side: Autolayout.ConstraintDSide,
        of view: BaseElement,
        _ value: U = 0.px
    ) -> Self {
        height(to: side,
                  of: view,
                  .init(wrappedValue: value),
                  multiplier: 1)
    }
    
    /// By default to `height` of destination view
    @discardableResult
    public func height<U: UnitValuable>(
        to view: BaseElement,
        _ value: U = 0.px
    ) -> Self {
        width(to: .width, of: view, value)
    }
    
    // MARK: - equal
    
    @discardableResult
    public func equalSize<U: UnitValuable>(
        to: BaseElement,
        _ value: U = 0.px
    ) -> Self {
        width(to: to, value)
        .height(to: to, value)
    }
    
    @discardableResult
    public func equalSize<U: UnitValuable>(
        to: BaseElement,
        _ state: State<U>,
        multiplier: Double = 1
    ) -> Self {
        width(to: to, state, multiplier: multiplier)
        .height(to: to, state, multiplier: multiplier)
    }
    
    // MARK: - Super
    
    @discardableResult
    public func edgesToSuperview<U: UnitValuable>(_ value: U = 0.px) -> Self {
        topToSuperview(value)
        .leadingToSuperview(value)
        .trailingToSuperview(UnitValue(value.value.doubleValue * (-1), .px))
        .bottomToSuperview(UnitValue(value.value.doubleValue * (-1), .px))
    }
    
    @discardableResult
    public func edgesToSuperview<U: UnitValuable>(h: U) -> Self {
        leadingToSuperview(h)
        .trailingToSuperview(UnitValue(h.value.doubleValue * (-1), .px))
    }
    
    @discardableResult
    public func edgesToSuperview<U: UnitValuable>(v: U) -> Self {
        topToSuperview(v)
        .bottomToSuperview(UnitValue(v.value.doubleValue * (-1), .px))
    }
    
    @discardableResult
    public func edgesToSuperview<H: UnitValuable, V: UnitValuable>(h: H, v: V) -> Self {
        topToSuperview(v)
        .leadingToSuperview(h)
        .trailingToSuperview(UnitValue(h.value.doubleValue * (-1), .px))
        .bottomToSuperview(UnitValue(v.value.doubleValue * (-1), .px))
    }
    
    public func edgesToSuperview<U: UnitValuable>(_ value: State<U>) -> Self {
        topToSuperview(value)
        .leadingToSuperview(value)
        .trailingToSuperview(value.map { UnitValue($0.value.doubleValue * (-1), .px) })
        .bottomToSuperview(value.map { UnitValue($0.value.doubleValue * (-1), .px) })
    }
    
    @discardableResult
    public func edgesToSuperview<U: UnitValuable>(h: State<U>) -> Self {
        leadingToSuperview(h)
        .trailingToSuperview(h.map { UnitValue($0.value.doubleValue * (-1), .px) })
    }
    
    @discardableResult
    public func edgesToSuperview<U: UnitValuable>(v: State<U>) -> Self {
        topToSuperview(v)
        .bottomToSuperview(v.map { UnitValue($0.value.doubleValue * (-1), .px) })
    }
    
    @discardableResult
    public func edgesToSuperview<H: UnitValuable, V: UnitValuable>(h: State<H>, v: State<V>) -> Self {
        topToSuperview(v)
        .leadingToSuperview(h)
        .trailingToSuperview(h.map { UnitValue($0.value.doubleValue * (-1), .px) })
        .bottomToSuperview(v.map { UnitValue($0.value.doubleValue * (-1), .px) })
    }
        
    @discardableResult
    public func edgesToSuperview<U: UnitValuable>(top: U? = nil, leading: U? = nil, trailing: U? = nil, bottom: U? = nil) -> Self {
        if let top = top {
            topToSuperview(top)
        }
        if let leading = leading {
            leadingToSuperview(leading)
        }
        if let trailing = trailing {
            trailingToSuperview(trailing)
        }
        if let bottom = bottom {
            bottomToSuperview(bottom)
        }
        return self
    }
        
    @discardableResult
    public func edgesToSuperview<U: UnitValuable>(top: State<U>? = nil, leading: State<U>? = nil, trailing: State<U>? = nil, bottom: State<U>? = nil) -> Self {
        if let top = top {
            topToSuperview(top)
        }
        if let leading = leading {
            leadingToSuperview(leading)
        }
        if let trailing = trailing {
            trailingToSuperview(trailing)
        }
        if let bottom = bottom {
            bottomToSuperview(bottom)
        }
        return self
    }
    
    // MARK: - top
    
    @discardableResult
    public func topToSuperview<U: UnitValuable>(
        _ state: State<U>,
        multiplier: Double = 1
    ) -> Self {
        let setup = { [weak self] in
            guard let self = self else { return }
            guard let superview = self.superview else { return }
            self.top(to: .top, of: superview, state, multiplier: multiplier)
        }
        setup()
        onDidAddToDOM(setup)
        return self
    }
    
    @discardableResult
    public func topToSuperview<U: UnitValuable>(_ value: U = 0.px, multiplier: Double = 1) -> Self {
        topToSuperview(
            .init(wrappedValue: value),
            multiplier: multiplier
        )
    }
    
    // MARK: - left
    
    @discardableResult
    public func leftToSuperview<U: UnitValuable>(
        _ state: State<U>,
        multiplier: Double = 1
    ) -> Self {
        let setup = { [weak self] in
            guard let self = self else { return }
            guard let superview = self.superview else { return }
            self.left(to: .left, of: superview, state, multiplier: multiplier)
        }
        setup()
        onDidAddToDOM(setup)
        return self
    }
        
    @discardableResult
    public func leftToSuperview<U: UnitValuable>(
        _ value: U = 0.px,
        multiplier: Double = 1
    ) -> Self {
        leftToSuperview(.init(wrappedValue: value), multiplier: multiplier)
    }
    
    // MARK: - leading
    
    @discardableResult
    public func leadingToSuperview<U: UnitValuable>(
        _ state: State<U>,
        multiplier: Double = 1
    ) -> Self {
        let setup = { [weak self] in
            guard let self = self else { return }
            guard let superview = self.superview else { return }
            self.leading(to: .leading, of: superview, state, multiplier: multiplier)
        }
        setup()
        onDidAddToDOM(setup)
        return self
    }
        
    @discardableResult
    public func leadingToSuperview<U: UnitValuable>(
        _ value: U = 0.px,
        multiplier: Double = 1
    ) -> Self {
        leadingToSuperview(.init(wrappedValue: value), multiplier: multiplier)
    }
    
    // MARK: - right
    
    @discardableResult
    public func rightToSuperview<U: UnitValuable>(
        _ state: State<U>,
        multiplier: Double = 1
    ) -> Self {
        let setup = { [weak self] in
            guard let self = self else { return }
            guard let superview = self.superview else { return }
            self.right(to: .right, of: superview, state, multiplier: multiplier)
        }
        setup()
        onDidAddToDOM(setup)
        return self
    }
    
    @discardableResult
    public func rightToSuperview<U: UnitValuable>(
        _ value: U = 0.px,
        multiplier: Double = 1
    ) -> Self {
        rightToSuperview(.init(wrappedValue: value), multiplier: multiplier)
    }
    
    // MARK: - trailing
    
    @discardableResult
    public func trailingToSuperview<U: UnitValuable>(
        _ state: State<U>,
        multiplier: Double = 1
    ) -> Self {
        let setup = { [weak self] in
            guard let self = self else { return }
            guard let superview = self.superview else { return }
            self.trailing(to: .trailing, of: superview, state, multiplier: multiplier)
        }
        setup()
        onDidAddToDOM(setup)
        return self
    }
    
    @discardableResult
    public func trailingToSuperview<U: UnitValuable>(
        _ value: U = 0.px,
        multiplier: Double = 1
    ) -> Self {
        trailingToSuperview(.init(wrappedValue: value), multiplier: multiplier)
    }
    
    // MARK: - bottom
    
    @discardableResult
    public func bottomToSuperview<U: UnitValuable>(
        _ state: State<U>,
        multiplier: Double = 1
    ) -> Self {
        let setup = { [weak self] in
            guard let self = self else { return }
            guard let superview = self.superview else { return }
            self.bottom(to: .bottom, of: superview, state, multiplier: multiplier)
        }
        setup()
        onDidAddToDOM(setup)
        return self
    }
    
    @discardableResult
    public func bottomToSuperview<U: UnitValuable>(
        _ value: U = 0.px,
        multiplier: Double = 1
    ) -> Self {
        bottomToSuperview(.init(wrappedValue: value), multiplier: multiplier)
    }
    
    // MARK: - center x
    
    @discardableResult
    public func centerXInSuperview<U: UnitValuable>(
        _ state: State<U>,
        side: Autolayout.ConstraintCXSide = .centerX,
        multiplier: Double = 1
    ) -> Self {
//        print("centerXInSuperview 1")
        let setup = { [weak self] in
//            print("centerXInSuperview 2")
            guard let self = self else { return }
//            print("centerXInSuperview 3")
            guard let superview = self.superview else { return }
//            print("centerXInSuperview 4")
            self.centerX(to: side, of: superview, state, multiplier: multiplier)
        }
        setup()
        onDidAddToDOM(setup)
        return self
    }
    
    @discardableResult
    public func centerXInSuperview<U: UnitValuable>(
        _ value: U = 0.px,
        side: Autolayout.ConstraintCXSide = .centerX,
        multiplier: Double = 1
    ) -> Self {
        centerXInSuperview(.init(wrappedValue: value), side: side, multiplier: multiplier)
    }
    
    // MARK: - center y
    
    @discardableResult
    public func centerYInSuperview<U: UnitValuable>(
        _ state: State<U>,
        side: Autolayout.ConstraintCYSide = .centerY,
        multiplier: Double = 1
    ) -> Self {
        let setup = { [weak self] in
            guard let self = self else { return }
            guard let superview = self.superview else { return }
            self.centerY(to: side, of: superview, state, multiplier: multiplier)
        }
        setup()
        onDidAddToDOM(setup)
        return self
    }
    
    @discardableResult
    public func centerYInSuperview<U: UnitValuable>(
        _ value: U = 0.px,
        side: Autolayout.ConstraintCYSide = .centerY,
        multiplier: Double = 1
    ) -> Self {
        centerYInSuperview(.init(wrappedValue: value), side: side, multiplier: multiplier)
    }
    
    // MARK: center both
    
    @discardableResult
    public func centerInSuperview<U: UnitValuable>(
        _ state: State<U>,
        multiplier: Double = 1
    ) -> Self {
        centerXInSuperview(state, multiplier: multiplier)
        .centerYInSuperview(state, multiplier: multiplier)
    }
    
    @discardableResult
    public func centerInSuperview<U: UnitValuable>(_ value: U = 0.px) -> Self {
        centerXInSuperview(value)
        .centerYInSuperview(value)
    }
    
    @discardableResult
    public func centerInSuperview<X: UnitValuable, Y: UnitValuable>(x: X, y: Y) -> Self {
        centerXInSuperview(x)
        .centerYInSuperview(y)
    }
    
    @discardableResult
    public func centerInSuperview<X: UnitValuable, Y: UnitValuable>(
        x: State<X>,
        y: State<Y>,
        multiplier: Double = 1
    ) -> Self {
        centerXInSuperview(x, multiplier: multiplier)
        .centerYInSuperview(y, multiplier: multiplier)
    }
    
    // MARK: - width
    
    @discardableResult
    public func widthToSuperview<U: UnitValuable>(
        _ state: State<U>,
        dimension: Autolayout.ConstraintDSide = .width,
        multiplier: Double = 1
    ) -> Self {
        let setup = { [weak self] in
            guard let self = self else { return }
            guard let superview = self.superview else { return }
            self.width(to: dimension, of: superview, state, multiplier: multiplier)
        }
        setup()
        onDidAddToDOM(setup)
        return self
    }
    
    @discardableResult
    public func widthToSuperview<U: UnitValuable>(
        _ value: U = 0.px,
        dimension: Autolayout.ConstraintDSide = .width,
        multiplier: Double = 1
    ) -> Self {
        widthToSuperview(
            .init(wrappedValue: value),
            dimension: dimension,
            multiplier: multiplier
        )
    }
    
    // MARK: - height
    
    @discardableResult
    public func heightToSuperview<U: UnitValuable>(
        _ state: State<U>,
        dimension: Autolayout.ConstraintDSide = .height,
        multiplier: Double = 1
    ) -> Self {
        let setup = { [weak self] in
            guard let self = self else { return }
            guard let superview = self.superview else { return }
            self.height(to: dimension, of: superview, state, multiplier: multiplier)
        }
        setup()
        onDidAddToDOM(setup)
        return self
    }
    
    @discardableResult
    public func heightToSuperview<U: UnitValuable>(
        _ value: U = 0.px,
        dimension: Autolayout.ConstraintDSide = .height,
        multiplier: Double = 1
    ) -> Self {
        heightToSuperview(
            .init(wrappedValue: value),
            dimension: dimension,
            multiplier: multiplier
        )
    }
}
