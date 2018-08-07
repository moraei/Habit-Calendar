//
//  AppDelegate.swift
//  Active
//
//  Created by Tiago Maia Lopes on 27/05/18.
//  Copyright © 2018 Tiago Maia Lopes. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: Properties

    /// The app's main window.
    var window: UIWindow?

    /// Convenient access to the app's delegate instance.
    static var current: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    /// The app's seed manager.
    /// - Note: The seed takes place between each app launches.
    private lazy var seedManager: SeedManager = SeedManager(
        container: persistentContainer
    )

    /// The app's UserMO storage.
    private(set) lazy var userStorage = UserStorage()

    /// The app's UserMO main entity.
    private(set) lazy var mainUser = userStorage.getUser(
        using: persistentContainer.viewContext
    )!

    /// The app's DayMO storage.
    private(set) lazy var dayStorage = DayStorage()

    /// The app's HabitDayMO storage.
    private(set) lazy var habitDayStorage = HabitDayStorage(
        calendarDayStorage: dayStorage
    )

    /// The app's DaysSequenceStorage.
    private (set) lazy var daysSequenceStorage = DaysSequenceStorage(
        habitDayStorage: habitDayStorage
    )

    /// The app's UserNotificationManager in charge of all local
    /// user notifications.
    private(set) lazy var notificationManager = UserNotificationManager(
        notificationCenter: UNUserNotificationCenter.current()
    )

    private lazy var notificationScheduler = NotificationScheduler(
        notificationManager: notificationManager
    )

    /// The app's NotificationMO storage.
    private(set) lazy var notificationStorage = NotificationStorage()

    /// The app's Habit storage that's going to be used by the controllers.
    private(set) lazy var habitStorage: HabitStorage = HabitStorage(
        daysSequenceStorage: daysSequenceStorage,
        notificationStorage: notificationStorage,
        notificationScheduler: notificationScheduler,
        fireTimeStorage: FireTimeStorage()
    )

    // MARK: Delegate methods

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        /// Flag indicating if the tests are being executed or not.
        let isTesting = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

        if !isTesting {
            // TODO: Move this authorization request to the appropriate controller.
            // Request the user's authorization to schedule local notifications.
            notificationManager.requestAuthorization { authorized in
                print("User \(authorized ? "authorized" : "denied").")
            }

            // Only run the seed in the debug mode and when the process's
            // environment isn't the test one.
            #if DEBUG
            // Remove the previously seeded entities.
            seedManager.erase()

            // Begin again by seeding the app's database with new dummy entities.
            seedManager.seed()
            #endif
        }

        // Inject the main dependencies into the initial HabitTableViewController:
        if let habitsListingController = window?.rootViewController?.contents as? HabitsTableViewController {
            // Inject its container.
            habitsListingController.container = persistentContainer
            // Inject its habit storage.
            habitsListingController.habitStorage = habitStorage
        }

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

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Save the view context.
        self.saveContext()
    }

    // MARK: - Core Data stack

    /// The container used by the app.
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "Active")
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    /// Convenient access to the app's persistent container.
    static var persistentContainer: NSPersistentContainer {
        return AppDelegate.current.persistentContainer
    }

    /// Convenient access to the app's used view context.
    static var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // MARK: - Core Data Saving support

    /// Saves the app's view context.
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}
