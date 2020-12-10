//
//  TaskTableViewController.swift
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
import BridgeApp
import BridgeSDK
import BridgeAppUI
import Research
import ResearchUI

class TaskTableViewController: UITableViewController {

    let scheduleManager = SBAScheduleManager()
    var sortedScheduleActivities : [SBBScheduledActivity] = []
	
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var appNameLabel: UILabel!
    @IBOutlet weak var appVersionLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Use automatic hieght dimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .singleLine
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DefaultCell")

        NotificationCenter.default.addObserver(forName: .SBAUpdatedScheduledActivities,
                                           object: nil,
                                           queue: OperationQueue.main) {(_) in
                                            self.loadUpdatedActivities()
        }
        NotificationCenter.default.addObserver(forName: .SBAFinishedUpdatingScheduleCache,
                                           object: nil,
                                           queue: OperationQueue.main) {(_) in
                                            self.scheduleManager.reloadData()
        }
        self.scheduleManager.reloadData()

        self.appNameLabel.text = Bundle.main.appName()
        self.appVersionLabel.text = "Version \(Bundle.main.appVersion())"
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Dynamic sizing for the header view
        if let headerView = tableView.tableHeaderView {
            let height = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            var headerFrame = headerView.frame

            // If we don't have this check, viewDidLayoutSubviews() will get
            // repeatedly called, causing the app to hang.
            if height != headerFrame.size.height {
                headerFrame.size.height = height
                headerView.frame = headerFrame
                tableView.tableHeaderView = headerView
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        //Reset app orientation to default orientation
        SBAAppDelegate.shared?.orientationLock = SBAAppDelegate.shared?.defaultOrientationLock

        self.sortedScheduleActivities = self.sortedActivities(activities: self.scheduleManager.scheduledActivities)
		
        //Show activity indicator if there are no activities yet
        if self.sortedScheduleActivities.count == 0 {
            self.activityIndicatorView.isHidden = false
            self.activityIndicatorView.startAnimating()
        }
    }

    func sortedActivities(activities : [SBBScheduledActivity]) -> [SBBScheduledActivity] {
        activities.sorted(by:{$0.activity.label < $1.activity.label})
    }
	
	//Activity list has been updated
    func loadUpdatedActivities() {
        self.sortedScheduleActivities = self.sortedActivities(activities: self.scheduleManager.scheduledActivities)
        self.loadActivities()
    }
	
	//Update activity list or run the task if it's the only one
    func loadActivities() {
        self.activityIndicatorView.stopAnimating()
        //Should always update the table with the latest information
        self.tableView.reloadData()
	}
    
    func loadTask(at indexPathRow:Int) {
        guard indexPathRow < self.sortedScheduleActivities.count else { return }
        let schedule = self.sortedScheduleActivities[indexPathRow]
        let taskVM = self.scheduleManager.instantiateTaskViewModel(for: schedule)
        let viewController = RSDTaskViewController(taskViewModel: taskVM)
        viewController.delegate = self
        self.present(viewController, animated: true) {
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //When not waiting for Bridge, return 1 for the message
        if (self.sortedScheduleActivities.count == 0 && self.activityIndicatorView.isHidden) {
            return 1
        } else {
            return self.sortedScheduleActivities.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        scheduleSectionCell(tableView, cellForRowAt: indexPath)
    }
    
    func scheduleSectionCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DefaultCell", for: indexPath)
		cell.textLabel?.numberOfLines = 0
        
		//Put up message if there are no activities
		if self.sortedScheduleActivities.count > 0 {
            let schedule = self.sortedScheduleActivities[indexPath.row]
            cell.textLabel?.text = schedule.activity.label
            cell.selectionStyle = .default
        }
        else {
            cell.textLabel?.text = NSLocalizedString("No activities are scheduled.",
                                                     comment: "Message to user when there are no activities scheduled.")
            cell.selectionStyle = .none
        }
        return cell
    }

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < self.sortedScheduleActivities.count {
            self.loadTask(at: indexPath.row)
        }
	}
}

extension TaskTableViewController: RSDTaskViewControllerDelegate {
    
    func taskController(_ taskController: RSDTaskController, didFinishWith reason: RSDTaskFinishReason, error: Error?) {
        self.scheduleManager.taskController(taskController, didFinishWith: reason, error: error)
        (taskController as? UIViewController)?.dismiss(animated: true, completion: {
            if let err = error {
                self.presentAlertWithOk(title: "Task failed", message: "\(err)", actionHandler: nil)
            }
        })
    }

    func taskController(_ taskController: RSDTaskController, readyToSave taskViewModel: RSDTaskViewModel) {
        self.scheduleManager.taskController(taskController, readyToSave: taskViewModel)
    }
}
