//
//  CloseTransitionNode.swift
//  LightRoute
//
//  Created by Vladislav Prusakov on 29/10/2017.
//  Copyright © 2017 Vladislav Prusakov. All rights reserved.
//

/// Responds style how controller will be close.
public enum CloseTransitionStyle {
    /// Make default dismiss controller action.
    case `default`
    
    /// Make custom navigation controller close action.
    case navigationController(style: CloseTransitionNavigationStyle)
}

/// Responds transition case how navigation controller will be close.
public enum CloseTransitionNavigationStyle {
    
    /// Make pop to view controller for you controller.
    case pop(to: UIViewController)
    
    /// Make default pop on one controller back.
    case simplePop
    
    /// Make pop to root action.
    case toRoot
    
    /// Return you to finded controller in navigation stack.
    /// - Note: Fot this style, you should be complete method `find(pop:)`
    case findedPop
}

public final class CloseTransitionNode {
    
    // Main transition data.
    internal unowned var root: UIViewController
    
    /// Shows animated this transition or not.
    public var isAnimated: Bool {
        return animated
    }
    
    // MARK: Private
    /// Set and get current transition animate state.
    internal var animated: Bool = true
    
    /// Wait transition post action.
    internal var postLinkAction: TransitionPostLinkAction?
    
    internal var findPopController: UIViewController?
    // MARK: -
    // MARK: Initialize
    
    
    ///
    /// Initialize transition node for current transition.
    ///
    /// - Parameters:
    ///   - root: The root view controller.
    ///   - destination: The view controller at which the jump occurs.
    ///   - type: The argument which checks the specified type and controller type for compatibility, and returns this type in case of success.
    ///
    init(root: UIViewController) {
        self.root = root
    }
    
    ///
    /// This method find controller in navigation stack, for popToViewController method.
    ///
    /// - Note: You should be call CloseTransitionNavigationStyle.findedPop for complete this action.
    ///
    /// - Parameter completionHandler:
    /// - Returns: Return current transition context.
    /// - Throws: Throw error, if parent view controller not navigation controller.
    ///
    public func find(pop completionHandler: (UIViewController) -> Bool) throws -> CloseTransitionNode {
        guard let parent = root.parent, let navigationController = parent as? UINavigationController
            else { throw LightRouteError.viewControllerWasNil("Navigation") }
        self.findPopController = navigationController.childViewControllers.first(where: completionHandler)
        return self
    }
    
    ///
    /// This method select preffered transition close style.
    ///
    /// - Parameter style: Set preffered style to close.
    /// - Returns: Return current transition node
    /// - Throws: Throw error, if root or navigation controllers was nil.
    ///
    public func preferred(style: CloseTransitionStyle) throws -> CloseTransitionNode {
        // Remove old link action
        self.postLinkAction = nil
        
        self.postLinkAction { [weak self] in
            
            guard let root = self?.root, let animated = self?.isAnimated else {
                throw LightRouteError.viewControllerWasNil("Root")
            }
            
            switch style {
            case .navigationController(style: let navStyle):
                
                guard let parent = root.parent, let navigationController = parent as? UINavigationController
                    else { throw LightRouteError.viewControllerWasNil("Navigation") }
                
                switch navStyle {
                case .pop(to: let controller):
                    navigationController.popToViewController(controller, animated: animated)
                case .simplePop:
                    if navigationController.childViewControllers.count > 1 {
                        guard let controller = navigationController.childViewControllers.dropLast().last else { return }
                        navigationController.popToViewController(controller, animated: animated)
                    } else {
                        throw LightRouteError.customError("Can't do popToViewController(:animated), because childViewControllers < 1")
                    }
                case .toRoot:
                    navigationController.popToRootViewController(animated: animated)
                case .findedPop:
                    guard let findedController = self?.findPopController else {
                        throw LightRouteError.customError("Finded controller can't be nil!")
                    }
                    navigationController.popToViewController(findedController, animated: animated)
                }
            case .default:
                root.dismiss(animated: animated, completion: nil)
            }
        }
        
        return self
    }
    
    ///
    /// This method perform close module.
    /// - Throws: Throw error, if something went wrong.
    ///
    public func perform() throws {
        try self.postLinkAction?()
    }
    
    // MARK: -
    // MARK: Private methods
    
    ///
    /// This method waits to be able to fire.
    /// - parameter completion: Whait push action from `TransitionPromise` class.
    ///
    func postLinkAction( _ completion: @escaping TransitionPostLinkAction) {
        self.postLinkAction = completion
    }
}