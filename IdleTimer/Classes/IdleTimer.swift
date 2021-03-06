//
//  IdleTimer.swift
//  Pods
//
//  Created by Jordan Zucker on 1/25/17.
//
//

import UIKit

fileprivate let IsAwakeKey = "IsAwakeKey"
fileprivate let ScreenStateKey = "ScreenStateKey"

public protocol IdleTimerListener {
    func idleTimer(timer: IdleTimer, didUpdateState: Bool)
}

@objc
public enum ScreenState: Int {
    case awake
    case sleepy
    
    static var allStates: [ScreenState] {
        return [.awake, .sleepy]
    }
    
    public var title: String {
        switch self {
        case .awake:
            return "Awake"
        case .sleepy:
            return "Off"
        }
    }
    
    static func screenState(for string: String) -> ScreenState? {
        return allStates.first(where: { (state) -> Bool in
            return state.title == string
        })
    }
    
    public func setIdleTimer() {
        let idleTimerState = isIdleTimerDisabled
        UIApplication.shared.isIdleTimerDisabled = idleTimerState
        print("UIApplication.shared.isIdleTimerDisabled = \(UIApplication.shared.isIdleTimerDisabled)")
    }
    
    var isIdleTimerDisabled: Bool {
        switch self {
        case .awake:
            return true
        case .sleepy:
            return false
        }
    }
}

public extension Notification.Name {
    static let IdleTimerDidChange: Notification.Name = Notification.Name("IdleTimerDidChange")
}

@objc
public class IdleTimer: NSObject {
    
    
    private let defaultScreenState = ScreenState.sleepy
    
    static let IdleTimerNotificationAwakeCurrentStateKey = "UpdatedIdleTimerStateKey"
    static let IdleTimerNotificationAwakeOldStateKey = "OldIdleTimerStateKey"
    
    public static let sharedInstance = IdleTimer()
    
    private var listeners: [IdleTimerListener] = [IdleTimerListener]()
    
    override init() {
        if let existingState = UserDefaults.standard.object(forKey: ScreenStateKey) {
            guard let intState = existingState as? Int, let actualState = ScreenState(rawValue: intState) else {
                fatalError("What happened, existingState: \(existingState)")
            }
            self.screenState = actualState
        } else {
            self.screenState = defaultScreenState
            UserDefaults.standard.set(defaultScreenState.rawValue, forKey: ScreenStateKey)
        }
        super.init()
        screenState.setIdleTimer()
    }
    
    public dynamic var screenState: ScreenState {
        didSet {
            screenState.setIdleTimer()
            UserDefaults.standard.set(screenState.rawValue, forKey: ScreenStateKey)
        }
    }

}

public extension UIAlertController {
    
    public static func idleTimerDurationAlertController(idleTimer: IdleTimer) -> UIAlertController {
        let alertController = UIAlertController(title: "Awake duration", message: "Choose a duration to keep the screen awake", preferredStyle: .actionSheet)
        
        let alertActionHandler: (UIAlertAction) -> Void = { (alertAction) in
            guard let title = alertAction.title, let newState = ScreenState.screenState(for: title) else {
                fatalError("How did we not find an expected value?")
            }
            idleTimer.screenState = newState
        }
        func alertAction(for state: ScreenState) -> UIAlertAction {
            return UIAlertAction(title: state.title, style: .default, handler: alertActionHandler)
        }
        
        ScreenState.allStates.forEach { (state) in
            let action = alertAction(for: state)
            alertController.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        return alertController
    }
}
