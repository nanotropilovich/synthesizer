

import Foundation
import CoreData
import UIKit


class PDFListViewController: UITableViewController, UIDocumentPickerDelegate, NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.reloadData()
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let document = fetchedResultsController.object(at: indexPath)
        if let filePath = document.filePath {
            let fileURL = URL(fileURLWithPath: filePath)
            showPDFViewer(with: fileURL)
        }
    }
    
    
    func showPDFViewer(with fileURL: URL) {
        let pdfViewer = PDFViewerViewController(fileURL: fileURL)
        self.navigationController?.pushViewController(pdfViewer, animated: true)
    }
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController.sections else {
            fatalError("No sections in fetchedResultsController")
        }
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PDFCell", for: indexPath)
        let document = fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = document.fileName
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let document = fetchedResultsController.object(at: indexPath)
            context.delete(document)
            do {
                try context.save()
            } catch {
                print("Failed to delete item: \(error.localizedDescription)")
            }
        }
    }
    
    let context: NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var fetchedResultsController: NSFetchedResultsController<PDF>!
    var selectedFileURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PDFCell")
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addPDF))
        navigationItem.rightBarButtonItem = addButton
        print("aaa")
        let request: NSFetchRequest<PDF> = PDF.fetchRequest() as! NSFetchRequest<PDF>
        let sortDescriptor = NSSortDescriptor(key: "filePath", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Failed to fetch items!")
        }
    }
    
    @objc func addPDF() {
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["com.adobe.pdf"], in: .import)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .formSheet
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let sourceURL = urls.first {
            selectedFileURL = sourceURL
            
            showFileNameInputAlert()
        }
    }
    func showFileNameInputAlert() {
        let alertController = UIAlertController(title: "Enter File Name", message: nil, preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.placeholder = "File Name"
        }
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] (_) in
            guard let textField = alertController.textFields?.first,
                  let fileName = textField.text,
                  !fileName.isEmpty,
                  let selectedURL = self?.selectedFileURL else {
                return
            }
         
            self?.savePDF(with: selectedURL, fileName: fileName)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(addAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    func savePDF(with sourceURL: URL, fileName: String) {
        do {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = documentsURL.appendingPathComponent(fileName)
            
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            
            // Теперь вы можете сохранить путь к файлу в CoreData
            let newDocument = PDF(context: self.context)
            newDocument.filePath = destinationURL.path
            newDocument.fileName = fileName
            try self.context.save()
            
        } catch {
            print("Failed to copy file: \(error.localizedDescription)")
        }
    }
    
    
    
    
}
