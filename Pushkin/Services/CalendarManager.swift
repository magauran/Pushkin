//
//  CalendarManager.swift
//  Pushkin
//
//  Created by Alexey Salangin on 9/28/19.
//  Copyright © 2019 Alexey Salangin. All rights reserved.
//

import EventKit
import EventKitUI

final class CalendarManager: NSObject {
    private let eventStore = EKEventStore()
    private var dismissingHandler: ((EKEventEditViewController) -> Void)?

    func openEventCreator(
        date: Date,
        showingHandler: @escaping (EKEventEditViewController) -> Void,
        dismissingHandler: @escaping (EKEventEditViewController) -> Void
    ) {
        func open(date: Date, showingHandler: @escaping (EKEventEditViewController) -> Void) {
            DispatchQueue.main.async {
                let addController = EKEventEditViewController()
                let event = EKEvent(eventStore: self.eventStore)
                event.startDate = date
                event.endDate = date.addingTimeInterval(2 * 60 * 60)
                event.title = "Посетить Пушкинский музей"
                addController.event = event
                addController.eventStore = self.eventStore
                addController.editViewDelegate = self
                showingHandler(addController)
            }
        }

        self.dismissingHandler = dismissingHandler

        if self.checkEventStoreAccessForCalendar() {
            open(date: date, showingHandler: showingHandler)
        } else {
            self.eventStore.requestAccess(to: .event) { (granted, error) in
                open(date: date, showingHandler: showingHandler)
            }
        }
    }

    private func checkEventStoreAccessForCalendar() -> Bool {
        let status = EKEventStore.authorizationStatus(for: EKEntityType.event)
        return status == .authorized
    }
}

extension CalendarManager: EKEventEditViewDelegate {
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        self.dismissingHandler?(controller)
    }
}
