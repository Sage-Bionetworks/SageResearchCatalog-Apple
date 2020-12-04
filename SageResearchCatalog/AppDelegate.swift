//
//  AppDelegate.swift
//  SageResearchCatalog
//
//  Copyright © 2020 Sage Bionetworks. All rights reserved.
//
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import UIKit
import BridgeApp
import BridgeAppUI
import BridgeSDK
import Research
import ResearchUI

@UIApplicationMain
class AppDelegate: SBAAppDelegate, RSDTaskViewControllerDelegate {

    override func instantiateColorPalette() -> RSDColorPalette? {
        .beach
    }
    
    func openStoryboard(_ name: String) -> UIStoryboard? {
        UIStoryboard(name: name, bundle: nil)
    }

    func showAppropriateViewController(animated: Bool) {
        if BridgeSDK.authManager.isAuthenticated() {
            showMainViewController(animated: animated)
        } else {
            showSignInViewController(animated: animated)
        }
    }

    func showMainViewController(animated: Bool) {
        guard self.rootViewController?.state != .main else { return }
        guard let storyboard = openStoryboard("Main"),
            let vc = storyboard.instantiateInitialViewController()
            else {
                fatalError("Failed to instantiate initial view controller in the main storyboard.")
        }
        self.transition(to: vc, state: .main, animated: true)
    }

    func showSignInViewController(animated: Bool) {
        guard self.rootViewController?.state != .onboarding else { return }

        let externalIDStep = ExternalIDRegistrationStep()
        let task = AssessmentTaskObject(identifier: "signin", steps: [externalIDStep], usesTrackedData: false, progressMarkers: [])
        let vc = RSDTaskViewController(task: task)
        vc.delegate = self
        self.transition(to: vc, state: .onboarding, animated: true)
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
                
        // Override point for customization after application launch.
        RSDStudyConfiguration.shared.shouldShowRemindMe = true
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    override func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
         super.applicationDidBecomeActive(application)
         self.showAppropriateViewController(animated: true)
    }

    // MARK: RSDTaskViewControllerDelegate
    
    func taskController(_ taskController: RSDTaskController, didFinishWith reason: RSDTaskFinishReason, error: Error?) {
        guard BridgeSDK.authManager.isAuthenticated() else { return }
        showAppropriateViewController(animated: true)
    }
    
    func taskController(_ taskController: RSDTaskController, readyToSave taskViewModel: RSDTaskViewModel) {
    }
}

