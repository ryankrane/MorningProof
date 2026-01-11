import WidgetKit
import SwiftUI

@main
struct MorningProofWidgetBundle: WidgetBundle {
    var body: some Widget {
        StreakWidget()
        HabitsWidget()
        if #available(iOS 16.1, *) {
            MorningRoutineLiveActivity()
        }
    }
}
