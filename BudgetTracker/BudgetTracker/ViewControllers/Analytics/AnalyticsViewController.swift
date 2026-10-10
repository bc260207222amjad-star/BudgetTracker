//
//  AnalyticsViewController.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import UIKit
import SwiftUI

public class AnalyticsViewController: UIViewController {
    
    private var hostingController: UIHostingController<AnalyticsChartsView>?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupHosting()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = ThemeManager.shared.colors.background
    }
    
    private func setupNavigation() {
        title = "Analytics"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let reportBtn = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(exportReportTapped))
        navigationItem.rightBarButtonItem = reportBtn
    }
    
    private func setupHosting() {
        let chartsView = AnalyticsChartsView()
        let host = UIHostingController(rootView: chartsView)
        host.view.backgroundColor = .clear
        
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        host.didMove(toParent: self)
        self.hostingController = host
    }
    
    @objc private func exportReportTapped() {
        let sheet = UIAlertController(title: "Export Report", message: "Choose format for this month's financial report:", preferredStyle: .actionSheet)
        
        sheet.addAction(UIAlertAction(title: "Export PDF Summary Report", style: .default, handler: { [weak self] _ in
            if let pdfURL = ExportManager.shared.generatePDFReport() {
                let activity = UIActivityViewController(activityItems: [pdfURL], applicationActivities: nil)
                self?.present(activity, animated: true)
            }
        }))
        
        sheet.addAction(UIAlertAction(title: "Export Raw CSV Data", style: .default, handler: { [weak self] _ in
            let all = TransactionManager.shared.fetchTransactions()
            if let csvURL = ExportManager.shared.generateCSV(transactions: all) {
                let activity = UIActivityViewController(activityItems: [csvURL], applicationActivities: nil)
                self?.present(activity, animated: true)
            }
        }))
        
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }
}
