import UIKit

protocol OptionsControllerDelegate: class {
    func optionsController(optionsController: OptionsController, didSelectOption option: String)
}

class OptionsController: UITableViewController {
    static let CellIdentifier = "CellIdentifier"
    static let PopoverSize = CGFloat(179)
    weak var delegate: OptionsControllerDelegate?
    static let RowHeight = CGFloat(60.0)
    fileprivate var options = ["First option", "Second option", "Third option"]

    init(sourceView: UIView, sourceRect: CGRect) {
        super.init(nibName: nil, bundle: nil)

        #if os(iOS)
            self.modalPresentationStyle = .popover
            self.popoverPresentationController?.delegate = self
        #endif
        self.preferredContentSize = CGSize(width: OptionsController.PopoverSize, height: OptionsController.PopoverSize)
        self.popoverPresentationController?.backgroundColor = .white
        self.popoverPresentationController?.permittedArrowDirections = [.any]
        self.popoverPresentationController?.sourceView = sourceView
        self.popoverPresentationController?.sourceRect = sourceRect
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.rowHeight = OptionsController.RowHeight
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: OptionsController.CellIdentifier)
    }
}

#if os(iOS)
    extension OptionsController: UIPopoverPresentationControllerDelegate {

        func adaptivePresentationStyleForPresentationController(controller _: UIPresentationController) -> UIModalPresentationStyle {
            return .none
        }
    }
#endif

extension OptionsController {

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return self.options.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: OptionsController.CellIdentifier, for: indexPath)

        let option = self.options[indexPath.row]
        cell.textLabel?.text = option

        return cell
    }

    public override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let option = self.options[indexPath.row]
        self.delegate?.optionsController(optionsController: self, didSelectOption: option)
    }
}
