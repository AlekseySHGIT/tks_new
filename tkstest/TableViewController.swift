//
//  ViewController.swift
//  tkstest
//
//  Created by Admin on 26.04.2018.
//  Copyright © 2018 Alex. All rights reserved.
//

import UIKit
import CoreData

struct Balance {
    var income_balance:Float = 0.00
    var outgoing_balance = -110562.11
    var income_balance_date = "17.03.2013"
    var income_ammount = 15000.00
    var credit_limit:Float = 120000.00
    
}

class TableViewController: UITableViewController {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var TransactionsArray = [Transaction]()
    var ProcentArray = [Procents]()
    var foundProcentDataArray = [Procents]()
    var balancefirstmonth = Balance()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        balancefirstmonth = Balance(income_balance: 0.00, outgoing_balance: -110562.11, income_balance_date: "17.03.2013", income_ammount: 15000.00, credit_limit: 120000.00)
        print(balancefirstmonth.credit_limit)
        
        //readCSV
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
        //readDataFromCSVFile()
        loadItemsFromCoreData()
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TransactionsArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Item",for:indexPath)
        let item = TransactionsArray[indexPath.row]
        
        let date = NSDate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from:item.time_attr as! Date)
        //print(dateString)
        
        print(item.type_attr)
        var str = ""
        if (item.type_attr == "Пополнение") {
            str = " +"
            
        } else {str = " -"}
        
        cell.textLabel?.text = dateString + str + String(item.amount_attr) + " " + item.type_attr!
        //cell.textLabel?.text = "-"+String(item.amount_attr)
        return cell
        
    }
    
    
    
    
    func loadItemsFromCoreData(){
        
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        
        let sort = NSSortDescriptor(key: #keyPath(Transaction.time_attr), ascending: true)
        request.sortDescriptors = [sort]
        
        
        
        do {
            TransactionsArray = try context.fetch(request)
            calculateProcent()
            
        } catch {
            print("error getting data")
        }
        
        
        
        
    }
    
    func calculateProcent(){
        
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Procents")
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        do{
            try context.execute(request)
        }catch{
            print("Error Clearing Procent Table")
        }
        
        
        
        
        
        
        var currentBalance = balancefirstmonth.income_balance
        
        /*
         for t in 1..<count  {
         if(AllTrati[t].mydate.compare(AllTrati[t-1].mydate) ==   .orderedSame){
         AllTrati[t].price +=  AllTrati[t-1].price
         AllTrati[t-1].price = 0
         
         }
         */
        
         for transaction_item in TransactionsArray{
        let requestSearch: NSFetchRequest <Procents> = Procents.fetchRequest()
          //  let predicate = NSPredicate(format: "timeattr CONTAINS[cd] %@", transaction_item.time_attr as! CVarArg)
            let predicate = NSPredicate(format: "time_attr == %@", transaction_item.time_attr as! NSDate)
            
            requestSearch.predicate = predicate
            
            do {
            foundProcentDataArray =  try context.fetch(requestSearch)
                print(foundProcentDataArray)
            } catch {
                print("ERROR FETCHING DATA")
            }
       
            if ( foundProcentDataArray.count != 0){
                print("Found same date in procent table")
             //   foundProcentDataArray[0].time_attr
                
            } else {
                 let procentItem = Procents(context: context)
                procentItem.time_attr = transaction_item.time_attr
                 procentItem.total_debt_in = currentBalance - transaction_item.amount_attr
                currentBalance = procentItem.total_debt_in
                print("Put date to Procent Array")
            }
        
       
        }
      
    /*
     for transaction_item in TransactionsArray{
     //  transaction_item.total_debt_in = currentBalance -  transaction_item.amount_attr
     
     
     let procentItem = Procents(context: context)
     procentItem.time_attr = transaction_item.time_attr
     // procentItem.total_debt_in = 1
     procentItem.time_attr = transaction_item.time_attr
     procentItem.total_debt_out = currentBalance - transaction_item.amount_attr
     
     */
    
    do{
    try context.save()
    }catch{
    print("Error Saving context")
    }
    
    
    
    




}






func saveItemsToCoreData(str:[String]) ->Bool{
    //print(str[0])
    //print(str[1])
    //print(str[2])
    
    
    let newItem = Transaction(context: context)
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .short
    dateFormatter.timeStyle = .none
    dateFormatter.dateFormat = "dd-MM-yy"
    
    
    guard let date = dateFormatter.date(from: str[0]) else {
        fatalError("ERROR: Date conversion failed due to mismatched format.")
    }
    
    
    newItem.time_attr = date
    newItem.amount_attr=Float(str[1])!
    newItem.type_attr=str[2]
    
    
    
    // Transaction
    do{
        try context.save()
    }catch{
        print("Error Saving context")
    }
    
    
    
    return true
}


func readDataFromCSVFile(){
    let fileName = "FirstCSVTinkoff"
    // let DocumentDirURL = try! FileManager.default.url(for: ., in: .userDomainMask, appropriateFor: nil, create: true)
    if let filepath = Bundle.main.path(forResource: "FirstCSVTinkoff", ofType: "txt"){
        
        do{
            let contents = try String(contentsOfFile: filepath)
            print("CONTENT:")
            //print(contents)
            
            let parsedCSV: [[String]] = contents.components(separatedBy: "\n").map{ $0.components(separatedBy: " ") }.filter{!$0.isEmpty}
            
            
            // print(parsedCSV)
            
            for line in parsedCSV {
                
                
                print(line)
                // if line.isEmpty {print("EMPTY LINE")}
                if line[0] == "" {print("EMPTY STRING")
                    return
                    
                }
                saveItemsToCoreData(str:line)
            }
            
        }
        catch{
            print("Contents could not be loaded.")
        }
        
    }
    else{
        print("FILENOTFOUND")
    }
    
    
}


override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
}


}


