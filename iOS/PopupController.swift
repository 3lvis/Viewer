import UIKit

protocol OptionsControllerDelegate: class {
    func optionsController(optionsController: OptionsController, didSelectOption option: String)
}

class OptionsController: UITableViewController {
    static let CellIdentifier = "CellIdentifier"
    static let PopoverSize = CGFloat(179)
    weak var controllerDelegate: OptionsControllerDelegate?
    static let RowHeight = CGFloat(60.0)
    private var options = ["First option", "Second option", "Third option"]

    init(sourceView: UIView, sourceRect: CGRect) {
        super.init(nibName: nil, bundle: nil)

        self.modalPresentationStyle = .Popover
        self.preferredContentSize = CGSize(width: OptionsController.PopoverSize, height: OptionsController.PopoverSize)
        self.popoverPresentationController?.delegate = self
        self.popoverPresentationController?.backgroundColor = UIColor.whiteColor()
        self.popoverPresentationController?.permittedArrowDirections = [.Any]
        self.popoverPresentationController?.sourceView = sourceView
        self.popoverPresentationController?.sourceRect = sourceRect
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.rowHeight = OptionsController.RowHeight
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: OptionsController.CellIdentifier)
    }
}

extension OptionsController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }
}

extension OptionsController {
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.options.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(OptionsController.CellIdentifier, forIndexPath: indexPath)

        let option = self.options[indexPath.row]
        cell.textLabel?.text = option

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let option = self.options[indexPath.row]
        self.controllerDelegate?.optionsController(self, didSelectOption: option)
    }
}
