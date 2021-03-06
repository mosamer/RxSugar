import UIKit
import RxSwift

extension Sugar where HostType: UIButton {
	/**
	Observable<Void> that sends event for every .TouchUpInside control event
	*/
	public var tap: Observable<Void> { return controlEvents(.TouchUpInside) }
}