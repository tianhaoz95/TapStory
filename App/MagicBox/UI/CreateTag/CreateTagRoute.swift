import Foundation

enum CreateTagRoute: Hashable {
    case chooseSource(type: String)
    case bundledPicker(type: String)
    case recordVocab
    case recordMusic
    case recordStory
    case writeTag(record: ContentRecord, title: String)
}
