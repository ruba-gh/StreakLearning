📚 LearnByStreak (StreakLearning)
A SwiftUI iOS app to help you build a daily learning habit.
Pick a topic, set a duration (Week, Month, Year), and track your streak.
Mark days as Learned or Freezed, and see your progress grow.
Completed goals are auto-archived — start new or repeat anytime.

🚀 Features
Set a goal (topic + duration)
Track streaks & freeze days
Weekly progress view
Month/Year picker for history
Auto-archive finished goals
Local storage (UserDefaults)
Light/Dark mode
Custom design with gradients & glass effects

🖥 Screens
EditView – Create or edit your goal
MainView – Log learned or freeze days, view progress
CalendarView – See all logged days
RootRouterView – Routes between onboarding & main

⚙️ Structure
Models: LearningGoal (topic, duration, streak info)
Persistence: GoalManager (save/load/archive via UserDefaults)
ViewModels: CalendarViewModel (collects logged data)
Views: MainView, EditView, CalendarView, etc.
Theme: Colors, gradients, and button styles

💾 Data Storage
Stored in UserDefaults:
Current & finished goals (JSON)
Learned/freezed dates
Counters for streaks & freezes

🧩 Streak Logic
Week = 7 days, Month = 30, Year = 365
Log Learned or Freezed each day
When done → auto-archive
Updating goal restarts streak

🧠 Requirements
Xcode 15+
Swift 5.9+
iOS 17+

🛠 Run
Open in Xcode
Choose device/simulator
Press Cmd + R
No setup or dependencies needed.

🌟 Roadmap
Notifications
iCloud sync
Widgets
Data export/import
