import UIKit
import XCTest




class Bug {
    
    // MARK : enumrations
    enum State : String{
        case open = "open"
        case closed = "closed"
    }
    
    enum JSONParsingError: String, Error {
        case EncodingFailed
        case DeSerializationFailed
        case MappingJSONError
    }
    
    // MARK : typealias
    
    typealias JSONDictionary = [String: Any]
    
    let state: State
    let timestamp: Date
    let comment: String
    
    init(state: State, timestamp: Date, comment: String) {
        self.state = state
        self.timestamp = timestamp
        self.comment = comment
        
    }
    
    init(jsonString: String) throws {
        
        guard let  desirlizedJsonData =  jsonString.data(using: String.Encoding.utf8)else{
            throw JSONParsingError.EncodingFailed
        }
        guard let  bugDictionary = try JSONSerialization.jsonObject(with:desirlizedJsonData) as? JSONDictionary else {
            throw JSONParsingError.DeSerializationFailed
        }
        guard let  stateRawValue = bugDictionary["state"] as? String, let timestamp = bugDictionary["timestamp"] as? Int, let comment = bugDictionary["comment"] as? String ,let state =  State(rawValue: stateRawValue) else {
            throw JSONParsingError.MappingJSONError
        }
        
        
        
        self.state = state
        self.timestamp = Date(timeIntervalSince1970: TimeInterval(timestamp))
        self.comment = comment
        
    }
}






enum TimeRange {
    case pastDay
    case pastWeek
    case pastMonth
    case other
}


class FilteredBugs {
    private var openBugsSincePastDay = [Bug]()
    private var openBugsSincePastWeek = [Bug]()
    private var openBugsSincePastMonth = [Bug]()
    private var openBugsSinceOther = [Bug]()
    
    private var closeBugsSincePastDay = [Bug]()
    private var closeBugsSincePastWeek = [Bug]()
    private var closeBugsSincePastMonth = [Bug]()
    private var closeBugsSinceOther = [Bug]()
    
    init(bugs:[Bug]) {
        
        for bug in bugs {
            
            if bug.timestamp.timeIntervalSinceNow/(-24 * 60 * 60) <=  1 {
                if bug.state == .open{
                    openBugsSincePastDay.append(bug)
                }else{
                    closeBugsSincePastDay.append(bug)
                }
            }else if bug.timestamp.timeIntervalSinceNow/(-24 * 60 * 60 * 7) <=  1 {
                if bug.state == .open{
                    openBugsSincePastWeek.append(bug)
                }else{
                    closeBugsSincePastWeek.append(bug)
                }
                
            }else if bug.timestamp.timeIntervalSinceNow/(-24 * 60 * 60 * 7 * 30 ) <=  1 {
                if bug.state == .open{
                    openBugsSincePastMonth.append(bug)
                }else{
                    closeBugsSincePastMonth.append(bug)
                }
                
            }else{
                if bug.state == .open{
                    openBugsSinceOther.append(bug)
                }else{
                    closeBugsSinceOther.append(bug)
                }
            }
        }
        
    }
    
    func getBugsWith(timeRange:TimeRange,state:Bug.State?) ->  [Bug] {
        switch timeRange {
        case .pastDay:
            
            return choseToGetWith(state: state,openBugs: openBugsSincePastDay,closeBugs: closeBugsSincePastDay)
        case .pastWeek:
            return choseToGetWith(state: state,openBugs: openBugsSincePastWeek,closeBugs: closeBugsSincePastWeek)
        case .pastMonth:
            return choseToGetWith(state: state,openBugs: openBugsSincePastMonth,closeBugs: closeBugsSincePastMonth)
        case .other:
            return choseToGetWith(state: state,openBugs: openBugsSinceOther,closeBugs: closeBugsSinceOther)
        }
        
    }
    
    private func choseToGetWith(state:Bug.State?,openBugs:[Bug],closeBugs:[Bug] )-> [Bug]{
        
        if let state = state{
            if state == .open{
                return openBugs
            }else{
                return closeBugs
            }
        }
        return closeBugs + openBugs
    }
    
    
}


class Application {
    var bugs: [Bug]
    
    
    init(bugs: [Bug]) {
        self.bugs = bugs
    }
    
    
    
    func findBugs(state: Bug.State?, timeRange: TimeRange) -> [Bug] {
        
        let bugs = FilteredBugs(bugs: self.bugs)
        
        return bugs.getBugsWith(timeRange: timeRange, state: state)
        
    }
}









class UnitTests : XCTestCase {
    lazy var bugs: [Bug] = {
        var date26HoursAgo = Date()
        date26HoursAgo.addTimeInterval(-1 * (26 * 60 * 60))
        
        var date2WeeksAgo = Date()
        date2WeeksAgo.addTimeInterval(-1 * (14 * 24 * 60 * 60))
        
        let bug1 = Bug(state: .open, timestamp: Date(), comment: "Bug 1")
        let bug2 = Bug(state: .open, timestamp: date26HoursAgo, comment: "Bug 2")
        let bug3 = Bug(state: .closed, timestamp: date2WeeksAgo, comment: "Bug 2")
        
        return [bug1, bug2, bug3]
    }()
    
    lazy var application: Application = {
        let application = Application(bugs: self.bugs)
        return application
    }()
    
    
    
    
    func testFindOpenBugsInThePastDay() {
        
        
        let bugs = application.findBugs(state: .open, timeRange: .pastDay)
        XCTAssertTrue(bugs.count == 1, "Invalid number of bugs")
        XCTAssertEqual(bugs[0].comment, "Bug 1", "Invalid bug order")
    }
    
    func testFindClosedBugsInThePastMonth() {
        
        
        let bugs = application.findBugs(state: .closed, timeRange: .pastMonth)
        
        XCTAssertTrue(bugs.count == 1, "Invalid number of bugs")
    }
    
    func testFindClosedBugsInThePastWeek() {
        
        let bugs = application.findBugs(state: .closed, timeRange: .pastWeek)
        
        XCTAssertTrue(bugs.count == 0, "Invalid number of bugs")
    }
    
    func testInitializeBugWithJSON() {
        do {
            let json = "{\"state\": \"open\",\"timestamp\": 1493393946,\"comment\": \"Bug via JSON\"}"
            
            let bug = try Bug(jsonString: json)
            
            XCTAssertEqual(bug.comment, "Bug via JSON")
            XCTAssertEqual(bug.state, .open)
            XCTAssertEqual(bug.timestamp, Date(timeIntervalSince1970: 1493393946))
        } catch {
            print(error)
        }
    }
}

class PlaygroundTestObserver : NSObject, XCTestObservation {
    @objc func testCase(_ testCase: XCTestCase, didFailWithDescription description: String, inFile filePath: String?, atLine lineNumber: UInt) {
        print("Test failed on line \(lineNumber): \(String(describing: testCase.name)), \(description)")
    }
}

let observer = PlaygroundTestObserver()
let center = XCTestObservationCenter.shared()
center.addTestObserver(observer)

TestRunner().runTests(testClass: UnitTests.self)
