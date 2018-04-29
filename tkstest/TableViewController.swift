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
    var income_balance_date = DateComponents(timeZone: .current, year: 2013, month: 07, day: 17)
    var income_ammount = 15000.00
    var credit_limit:Float = 120000.00
    var service_charge:Float = 590
}

class TableViewController: UITableViewController {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var TransactionsArray = [Transaction]()
    var ProcentArray = [Procents]()
    var foundProcentDataArray = [Procents]()
    var BalanceForPeriod = Balance()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        BalanceForPeriod = Balance(income_balance: 0.00, outgoing_balance: -110562.11, income_balance_date: DateComponents(timeZone: TimeZone.init(abbreviation: "UTC") ,year: 2013, month: 07, day: 17), income_ammount: 15000.00, credit_limit: 120000.00,service_charge:590)
        
       
        // print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
       
        readDataFromCSVFile()
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
      
        var str = ""
        if (item.type_attr == "Пополнение") {
            str = " +"
            
        } else {str = " -"}
        
        cell.textLabel?.text = dateString + str + String(item.amount_attr) + " " + item.type_attr!
       
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
    
    
    func GetDaysInMonth(balancedate: DateComponents) -> Int{
        
        let calendar = Calendar.current
        let date = calendar.date(from: balancedate)!
        let range = calendar.range(of: .day, in: .month, for: date)!
        let numDays = range.count
        return (numDays - balancedate.day!)
    }
    
    
    func GetNextDate(currentDate : Date) -> Date  {
        
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to:currentDate)
        return tomorrow!
    }
    
    
    func clearTransactionTable(){
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Transaction")
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        do{
            try context.execute(request)
        }catch{
            print("Error Clearing Transaction Table")
        }
    }
    
    
    func clearProcentTable(){
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Procents")
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        do{
            try context.execute(request)
        }catch{
            print("Error Clearing Procent Table")
        }
    }
    
    
  
      var firstPopolnenie = false
    func CheckPayment(currentDate: Date,currentBalance:Float,currentNonPurchase_without_Grace_Balance:Float,currentGraceBalance:Float)
        -> (currentLocalBalance:Float,currentLocalNonPurchase_without_Grace_Balance:Float,currentLocalGraceBalance:Float){
        
            
            
            var currentLocalNonPurchase_without_Grace_Balance = currentNonPurchase_without_Grace_Balance
        var currentLocalBalance = currentBalance
       
           var  currentLocalGraceBalance = currentGraceBalance
            
            
            
            let procentItem = Procents(context: context)
        procentItem.time_attr = currentDate
        
        let requestSearch: NSFetchRequest <Transaction> = Transaction.fetchRequest()
        let predicate = NSPredicate(format: "time_attr == %@", currentDate as! NSDate)
        
        requestSearch.predicate = predicate
        var transactionsFoundForThisDate = [Transaction]()
        do {
            transactionsFoundForThisDate =  try context.fetch(requestSearch)
        } catch {
            print("ERROR FETCHING DATA")
        }
        
        if ( transactionsFoundForThisDate.count != 0){
            print("\(transactionsFoundForThisDate.count) transactions for this date: \(currentDate) IN transactionArray: \(transactionsFoundForThisDate[0].time_attr) + \(transactionsFoundForThisDate[0].amount_attr)")
            for transactionItem in transactionsFoundForThisDate {
                print("Transaction:: \(transactionItem.amount_attr)   \(transactionItem.type_attr)")
            
                switch transactionItem.type_attr {
                case "Плата\r":
                     print("FOUND PLATA")
                  procentItem.total_debt_out = currentLocalBalance - transactionItem.amount_attr
                currentLocalBalance = procentItem.total_debt_out
                case "Выдача\r":
                print("FOUND nalichnie vidashs")
                     procentItem.total_debt_out = currentLocalBalance - transactionItem.amount_attr
                     currentLocalBalance = procentItem.total_debt_out
                    
             
                    currentLocalNonPurchase_without_Grace_Balance = currentLocalNonPurchase_without_Grace_Balance + transactionItem.amount_attr
                         procentItem.nonpurchase_without_Grace = currentLocalNonPurchase_without_Grace_Balance
                    
                case "Комиссия\r":
                    print("FOUND komissia")
                    procentItem.total_debt_out = currentLocalBalance - transactionItem.amount_attr
                    currentLocalBalance = procentItem.total_debt_out
                 
                    currentLocalNonPurchase_without_Grace_Balance = currentLocalNonPurchase_without_Grace_Balance + transactionItem.amount_attr
                    procentItem.nonpurchase_without_Grace = currentLocalNonPurchase_without_Grace_Balance
                    
                case "Оплата\r":
                    print("FOUND Oplata")
                 procentItem.total_debt_out = currentLocalBalance - transactionItem.amount_attr
                     currentLocalBalance = procentItem.total_debt_out
                    
                    currentLocalGraceBalance = currentLocalGraceBalance +  transactionItem.amount_attr
                     procentItem.purchases_current_Grace = currentLocalGraceBalance
                    
                    
                    
                case "Пополнение":
                   
                    
                    if(!firstPopolnenie){
                       print("FIRST")
                        firstPopolnenie = true
                        currentLocalGraceBalance = currentLocalGraceBalance +  BalanceForPeriod.service_charge
                        procentItem.purchases_current_Grace = currentLocalGraceBalance
                      
                    }
                    
                    print("FOUND Popolnenie")
                    print(currentLocalBalance)
                    procentItem.total_debt_out = currentLocalBalance + transactionItem.amount_attr
                    currentLocalBalance = procentItem.total_debt_out
                    print("AFTER")
                    print(currentLocalBalance)
                    
                    currentLocalGraceBalance = currentLocalGraceBalance -  transactionItem.amount_attr
                    procentItem.purchases_current_Grace = currentLocalGraceBalance
                    
                    
                    
                case "Пополнение\r":
                    if(!firstPopolnenie){
                      print("FIRST")
                        firstPopolnenie = true
                       
                        currentLocalGraceBalance = currentLocalGraceBalance +  BalanceForPeriod.service_charge
                        procentItem.purchases_current_Grace = currentLocalGraceBalance
                        
                        
                    }
                    
                    print("FOUND Popolnenie")
                    print(currentLocalBalance)
                    procentItem.total_debt_out = currentLocalBalance + transactionItem.amount_attr
                    currentLocalBalance = procentItem.total_debt_out
                    print("AFTER")
                    print(currentLocalBalance)
                default:
                    print("No category found")
                }
              
            
            
            }
          
            
        }
        else {
            print("No transaction for date: \(currentDate)")
             procentItem.total_debt_out = currentLocalBalance
           
        }
        print("BALANCE: ")
        print(currentLocalBalance)
        print("nonpurchase_without_Grace \(currentLocalNonPurchase_without_Grace_Balance)")
           print("Current Grace \(currentLocalGraceBalance)")
            procentItem.nonpurchase_without_Grace = currentLocalNonPurchase_without_Grace_Balance
            procentItem.purchases_current_Grace = currentLocalGraceBalance
        return (currentLocalBalance,currentLocalNonPurchase_without_Grace_Balance,currentLocalGraceBalance)
    }
    
    
    func calculateProcent(){
        
        clearProcentTable()
        
        var currentBalance = BalanceForPeriod.income_balance
        var currentNonPurchase_without_Grace_Balance:Float = 0
        var currentGraceBalance:Float = 0
        var current_period = GetDaysInMonth(balancedate:BalanceForPeriod.income_balance_date)
        var currentDate = Calendar.current.date(from: BalanceForPeriod.income_balance_date)
        
        
        //pochemu 17 chislo pishet a ne 18 srashu? UTC nado delat
        for _ in 0..<current_period+20 {
            
            print("Proshet v etu datu: \(currentDate)")
            
            //check if payment was for this day
            let current = CheckPayment(currentDate: currentDate!,currentBalance:  currentBalance, currentNonPurchase_without_Grace_Balance: currentNonPurchase_without_Grace_Balance,currentGraceBalance: currentGraceBalance)
            
            currentBalance = current.currentLocalBalance
            currentNonPurchase_without_Grace_Balance = current.currentLocalNonPurchase_without_Grace_Balance
         currentGraceBalance = current.currentLocalGraceBalance
            currentDate = GetNextDate(currentDate: currentDate!)
            
        }
        
       
        do{
            try context.save()
        }catch{
            print("Error Saving context")
        }
        
        
    }
    let dateFormatter = DateFormatter()
    
    func saveItemsToCoreData(str:[String]) ->Bool{
        //print(str[0])
     
        let newItem = Transaction(context: context)
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        dateFormatter.dateFormat = "dd-MM-yy"
        dateFormatter.locale = Locale(identifier: "ru_RU")
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
       
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
        
        clearTransactionTable()
        
        let fileName = "FirstCSVTinkoff"
        // let DocumentDirURL = try! FileManager.default.url(for: ., in: .userDomainMask, appropriateFor: nil, create: true)
        if let filepath = Bundle.main.path(forResource: "FirstCSVTinkoff", ofType: "txt"){
            
            do{
                let contents = try String(contentsOfFile: filepath)
                let parsedCSV: [[String]] = contents.components(separatedBy: "\n").map{ $0.components(separatedBy: " ") }.filter{!$0.isEmpty}
                for line in parsedCSV {

                    if line[0] != "" {
                        //print("EMPTY STRING")
                       
                         saveItemsToCoreData(str:line)
                    }
                  
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


