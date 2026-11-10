import WidgetKit
import SwiftUI

@main
struct DoorWidgetsBundle: WidgetBundle {
    var body: some Widget {
        OpenDoorWidget()
        OpenDoorControl()
        DoorCallLiveActivity()
    }
}
