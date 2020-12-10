//
//  ExternalIDRegistrationViewController.swift
//  SageResearchCatalog
//
//  Copyright © 2020 Sage Bionetworks. All rights reserved.
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
import ResearchUI
import Research
import BridgeSDK
import BridgeApp

enum RegistrationError: Error {
	case emptyExternalID
}

class ExternalIDRegistrationStep : SimpleQuestion, QuestionStep, RSDStepViewControllerVendor, RSDTableStep {
    
    init() {
    }

    let identifier = "externalID"
    
    let stepType: RSDStepType = "externalID"
    
    let skipCheckbox: SkipCheckboxInputItem? = nil
    
    let isOptional: Bool = false
    
    let title: String? = nil
    
    let subtitle: String? = NSLocalizedString("Thank you for participating in this study.", comment: "Default text for an external ID registration step.")
    
    let detail: String? = NSLocalizedString("Enter the External ID you were given to get started.", comment: "Default text for an external ID registration step.")
    
    let footnote: String? = nil
    
    var inputItem: InputItemBuilder = {
        let input = StringTextInputItemObject()
        input.placeholder = NSLocalizedString("external ID", comment: "Localized string for the external ID prompt")
        return input
    }()
    
    func instantiateStepResult() -> RSDResult {
        AnswerResultObject(identifier: self.identifier, answerType: AnswerTypeString())
    }
    
    func validate() throws {
    }
    
    func action(for actionType: RSDUIActionType, on step: RSDStep) -> RSDUIAction? {
        nil
    }
    
    func shouldHideAction(for actionType: RSDUIActionType, on step: RSDStep) -> Bool? {
        nil
    }
    
    // MARK: RSDStepViewControllerVendor
    
    func instantiateViewController(with parent: RSDPathComponent?) -> (UIViewController & RSDStepController)? {
        return ExternalIDRegistrationViewController(step: self, parent: parent)
    }
    
    // MARK: RSDTableStep
    
    func instantiateDataSource(with parent: RSDPathComponent?, for supportedHints: Set<RSDFormUIHint>) -> RSDTableDataSource? {
        QuestionStepDataSource(step: self, parent: parent, supportedHints: supportedHints)
    }
}

class ExternalIDRegistrationViewController: RSDTableStepViewController {
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.navigationHeader?.cancelButton?.isHidden = true
	}
    
	//No longer sign up, just sign in
	func signIn(completion: @escaping SBBNetworkManagerCompletionBlock) throws {
		
        print("self.stepViewModel.taskResult=\(self.stepViewModel.taskResult)")
        
        let stepResult = self.stepViewModel.findStepResult()
        guard let answerResult = stepResult as? AnswerResult,
              let value = answerResult.value,
              let externalId = value as? String
			else {
				throw RegistrationError.emptyExternalID
		}
		
		BridgeSDK.authManager.signIn(withExternalId: externalId, password: externalId, completion: { (task, result, error) in
			//Save off external id, don't check for error since one error code goes through
			completion(task, result, error)
		})

	}
    
    override func goForward() {
        guard validateAndSave()
            else {
                return
        }
		
		do {
			//Don't sign up anyone, only sign in
			try self.signIn { (task, result, error) in
				if error == nil || (error! as NSError).code == SBBErrorCode.serverPreconditionNotMet.rawValue {
					DispatchQueue.main.async {
						super.goForward()
					}
				} else {
					let title = "Error on sign in"
					var message: String
					let errorCode = (error! as NSError).code
					//Create friendlier messages for some known cases
					switch errorCode {
					case 400, 404:
						message = "External ID not recognized."
					case 412:
						message = "This External ID will not work for this study."
					default:
						message = "Network connection problem, please try again in a few minutes."
					}
					self.displayError(title: title, message: message)
					debugPrint("Error attempting to sign up and sign in:\n\(String(describing: error))\n\nResult:\n\(String(describing: result))")
				}
			}
		} catch RegistrationError.emptyExternalID {
			self.displayError(title: "Error at sign in", message: "Please enter your External ID.")
		} catch {
			self.displayError(title: "Error at sign in", message: error.localizedDescription)
		}
	}
	
	//Make sure this is done in the main queue
	func displayError(title: String, message: String) {
		DispatchQueue.main.async {
			self.presentAlertWithOk(title: title, message: message, actionHandler: nil)
		}
	}
	
}
