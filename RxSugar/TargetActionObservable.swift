import UIKit
import RxSwift

public final class TargetActionObservable<Element>: NSObject, ObservableType {
    public typealias E = Element
	public let actionSelector: Selector = "action"
	
	private let _unsubscribe: (NSObjectProtocol, Selector) -> ()
    private let subject = PublishSubject<Element>()
    private let valueGenerator: () throws -> Element
    private let complete: Observable<Void>
	
    public init(valueGenerator generator: () throws -> Element, subscribe subscribeAction: (NSObjectProtocol, Selector) -> (), unsubscribe: (NSObjectProtocol, Selector) -> (), complete completeEvents: Observable<Void>) {
		valueGenerator = generator
		_unsubscribe = unsubscribe
        complete = completeEvents
		super.init()
		subscribeAction(self, actionSelector)
	}
	
	public convenience init (control: UIControl, forEvents controlEvents: UIControlEvents, valueGenerator generator: () throws -> Element) {
		self.init(
			valueGenerator: generator,
			subscribe: { (target, action) in
				control.addTarget(target, action: action, forControlEvents: controlEvents)
			},
			unsubscribe: { (target, action) in
				control.removeTarget(target, action: action, forControlEvents: controlEvents)
			},
            complete: control.rxs.onDeinit
		)
	}
	
    public convenience init<ObservedType: RXSObject>(notificationName: String, onObject: ObservedType, valueGenerator: (ObservedType) throws -> Element) {
		self.init(
            valueGenerator: { [unowned onObject] in try valueGenerator(onObject) },
			subscribe: { (target, action) in
				NSNotificationCenter.defaultCenter().addObserver(target, selector: action, name: notificationName, object: onObject)
			},
			unsubscribe: { (target, _) in
				NSNotificationCenter.defaultCenter().removeObserver(target, name: notificationName, object: onObject)
            },
            complete: onObject.rxs.onDeinit
		)
	}
    
    public func subscribe<O: ObserverType where O.E == Element>(observer: O) -> Disposable {
        let subjectDisposable = subject.takeUntil(complete).subscribe(observer)
        let triggerDisposable = AnonymousDisposable { _ = self }
        return CompositeDisposable() ++ subjectDisposable ++ triggerDisposable
    }
	
    func action() {
        guard let value = try? valueGenerator() else { subject.onError(RxsError()); return }
		subject.onNext(value)
	}
	
	deinit {
		subject.onCompleted()
		_unsubscribe(self, actionSelector)
	}
}