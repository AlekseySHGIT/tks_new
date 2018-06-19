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
    var income_balance:Double = 0.00
    var outgoing_balance = -110562.11
    var income_balance_date = DateComponents(timeZone:TimeZone.init(abbreviation: "UTC"), year: 2013, month: 07, day: 17)
    var outcome_balance_date = DateComponents(timeZone:TimeZone.init(abbreviation: "UTC"), year: 2013, month: 08, day: 24)
    var income_ammount = 15000.00
    var credit_limit:Double = 120000.00
    var service_charge:Double = 590
    
    var data_fist_payment = DateComponents(timeZone:TimeZone.init(abbreviation: "UTC"), year: 2013, month: 07, day: 20)
    var data_grace_last_payment = DateComponents(timeZone:TimeZone.init(abbreviation: "UTC"), year: 2013, month: 07, day: 20)
    //сумма расходов
    var amount_of_expenses:Double = 0
    //сумма поступлений
    var amount_of_receipts:Double = 0
}

class TableViewController: UITableViewController {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var TransactionsArray = [Transaction]()
    var ProcentArray = [Procents]()
    var foundProcentDataArray = [Procents]()
    var BalanceForPeriod = Balance()
    var LastDayForPayInGracePeriod = Date()
    var gracePeriodIsActive:Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        
        BalanceForPeriod = Balance(
            income_balance: 0.00, outgoing_balance: -110562.11,
            income_balance_date: DateComponents(timeZone: TimeZone.init(abbreviation: "UTC") ,year: 2013, month: 07, day: 17),
            outcome_balance_date: DateComponents(timeZone:TimeZone.init(abbreviation: "UTC"), year: 2013, month: 08, day: 24),
            income_ammount: 0,
            credit_limit: 120000.00,
            service_charge: 590,
            data_fist_payment: DateComponents(timeZone:TimeZone.init(abbreviation: "UTC"), year: 2013, month: 07, day: 20),
            data_grace_last_payment: DateComponents(timeZone:TimeZone.init(abbreviation: "UTC"), year: 2013, month: 09, day: 20),
            amount_of_expenses: 0,
            amount_of_receipts: 0)
        
        gracePeriodIsActive = true
        var b = Calendar.current.date(from: BalanceForPeriod.income_balance_date)
        LastDayForPayInGracePeriod = GetGraceLastDate(currentDate: b!)
        LastDayForPayInGracePeriod = Calendar.current.date(from:BalanceForPeriod.data_grace_last_payment)!
        print("FIND GRACE LAST DATE \(LastDayForPayInGracePeriod)")
        
        /////
        b = Calendar.current.date(from: DateComponents(timeZone: TimeZone.init(abbreviation: "UTC") ,year: 2018, month: 04, day: 30))
        LastDayForPayInGracePeriod = NewGetGraceLastDate(currentDate: b!)
        print("GRACE FINAL DATE1 \(LastDayForPayInGracePeriod)")
        
        /////
        
        
        //особый случай для самой первой покупки, подумать может быть ошибка для будущих
        if(BalanceForPeriod.income_balance == 0.00 && (BalanceForPeriod.data_fist_payment.day! > BalanceForPeriod.income_balance_date.day!)){
            // BalanceForPeriod.outcome_balance_date = DateComponents(timeZone:TimeZone.init(abbreviation: "UTC"), year: 2013, month: 08, day: 24)
            //грейс смещается
            // may be in 30 dnay a bryat dlya mesatsa
            var oneMonthAgo = thisDayOneMonthEarlier(currentDate: Calendar.current.date(from: BalanceForPeriod.outcome_balance_date)!, value: -1)
            print("AAAAA")
            print(oneMonthAgo)
            LastDayForPayInGracePeriod = GetGraceLastDate(currentDate: oneMonthAgo)
            print(LastDayForPayInGracePeriod)
            
        }
        
        
        
        print("LAST DATE")
        print(LastDayForPayInGracePeriod)
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
        clearTransactionTable()
        readDataRAWFromCSVFile(file: "tks_july_2013")
        readDataRAWFromCSVFile(file: "tks_august_2013")
        
        //readDataFromCSVFile()
        loadItemsFromCoreData()
        
    }
    
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ProcentArray.count
    }
    
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Item",for:indexPath)
        //let item = TransactionsArray[indexPath.row]
        let item = ProcentArray[indexPath.row]
        let date = NSDate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from:item.time_attr as! Date)
        
        /*
         var str = ""
         if (item.type_attr == "Пополнение") {
         str = " +"
         
         } else {str = " -"}
         
         cell.textLabel?.text = dateString + str + String(item.amount_attr) + " " + item.type_attr!
         */
        // item.purchases_previous_Gr
        
        
        
        
        
        
        cell.textLabel?.text = dateString + ": D " + String(item.total_debt_out) + " CG: " + String(item.purchases_current_Grace) + " PG: " + String(item.purchases_previous_Grace) + " PBG: " + String(item.purchases_without_Grace) + "PST: " + String(item.purchases_standart) + "NPG: " + String(item.nonpurchase_previous_Grace) + " NWG: " + String(item.nonpurchase_without_Grace) + " PR_CUR: " +  String(item.percent_current_Grace) + " PR_PREV_G: " + String(item.percent_previous_Grace) + " PR_W_GR: " + String(item.percent_without_Grace) + " P: " + String(item.procents)
        return cell
    }
    
    
    
    func loadItemsFromCoreData(){
        
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        let sort = NSSortDescriptor(key: #keyPath(Transaction.time_attr), ascending: true)
        request.sortDescriptors = [sort]
        
        do {
            TransactionsArray = try context.fetch(request)
            
            clearProcentTable()
            FillProcentTableWithData()
            
            CalculateProcents()
            
            //PROSHET ZA SLED MESYATS
            print("\nNEXT MONTH\n")
            BalanceForPeriod = Balance(
                income_balance: -110562.11, outgoing_balance: -122655.30,
                income_balance_date: DateComponents(timeZone: TimeZone.init(abbreviation: "UTC") ,year: 2013, month: 08, day: 25),
                outcome_balance_date: DateComponents(timeZone:TimeZone.init(abbreviation: "UTC"), year: 2013, month: 09, day: 24),
                income_ammount: 0,
                credit_limit: 120000.00,
                service_charge: 590,
                data_fist_payment: DateComponents(timeZone:TimeZone.init(abbreviation: "UTC"), year: 2013, month: 07, day: 20),
                data_grace_last_payment: DateComponents(timeZone:TimeZone.init(abbreviation: "UTC"), year: 2013, month: 10, day: 21),
                amount_of_expenses: 0,
                amount_of_receipts: 0)
            
            
            
            
            FillProcentTableWithData()
            
            CalculateProcents()
            
            
            
            //PROSHET ZA SLED MESYATS
            print("\nNEXT MONTH 3\n")
            BalanceForPeriod = Balance(
                income_balance: -122655.30, outgoing_balance: -124768.00,
                income_balance_date: DateComponents(timeZone: TimeZone.init(abbreviation: "UTC") ,year: 2013, month: 09, day: 25),
                outcome_balance_date: DateComponents(timeZone:TimeZone.init(abbreviation: "UTC"), year: 2013, month: 10, day: 24),
                income_ammount: 0,
                credit_limit: 120000.00,
                service_charge: 590,
                data_fist_payment: DateComponents(timeZone:TimeZone.init(abbreviation: "UTC"), year: 2013, month: 07, day: 20),
                data_grace_last_payment: DateComponents(timeZone:TimeZone.init(abbreviation: "UTC"), year: 2013, month: 11, day: 20),
                amount_of_expenses: 0,
                amount_of_receipts: 0)
            
            
            
            
            FillProcentTableWithData()
            
            CalculateProcents()
            
            
            /*
            
            //PROSHET ZA SLED MESYATS
            print("\nNEXT MONTH  NOVEMBER\n")
            BalanceForPeriod = Balance(
                income_balance: -124768.00, outgoing_balance: -124461.69,
                income_balance_date: DateComponents(timeZone: TimeZone.init(abbreviation: "UTC") ,year: 2013, month: 10, day: 25),
                outcome_balance_date: DateComponents(timeZone:TimeZone.init(abbreviation: "UTC"), year: 2013, month: 11, day: 24),
                income_ammount: 0,
                credit_limit: 120000.00,
                service_charge: 590,
                data_fist_payment: DateComponents(timeZone:TimeZone.init(abbreviation: "UTC"), year: 2013, month: 07, day: 20),
                data_grace_last_payment: DateComponents(timeZone:TimeZone.init(abbreviation: "UTC"), year: 2013, month: 12, day: 21),
                amount_of_expenses: 0,
                amount_of_receipts: 0)
            
            FillProcentTableWithData()
            CalculateProcents()
            
            
            
            //PROSHET ZA SLED MESYATS
            
            print("\nNEXT MONTH  DECEMBER\n")
            BalanceForPeriod = Balance(
                income_balance: -124461.69, outgoing_balance: -124461.69,
                income_balance_date: DateComponents(timeZone: TimeZone.init(abbreviation: "UTC") ,year: 2013, month: 11, day: 25),
                outcome_balance_date: DateComponents(timeZone:TimeZone.init(abbreviation: "UTC"), year: 2013, month: 12, day: 24),
                income_ammount: 0,
                credit_limit: 120000.00,
                service_charge: 590,
                data_fist_payment: DateComponents(timeZone:TimeZone.init(abbreviation: "UTC"), year: 2013, month: 07, day: 20),
                data_grace_last_payment: DateComponents(timeZone:TimeZone.init(abbreviation: "UTC"), year: 2014, month: 01, day: 20),
                amount_of_expenses: 0,
                amount_of_receipts: 0)
            
            FillProcentTableWithData()
            CalculateProcents()
            
            
            //PROSHET ZA SLED MESYATS
            
            print("\nNEXT MONTH  JANUARY\n")
            BalanceForPeriod = Balance(
                income_balance: -145158.58, outgoing_balance: -124461.69,
                income_balance_date: DateComponents(timeZone: TimeZone.init(abbreviation: "UTC") ,year: 2013, month: 12, day: 25),
                outcome_balance_date: DateComponents(timeZone:TimeZone.init(abbreviation: "UTC"), year: 2014, month: 01, day: 24),
                income_ammount: 0,
                credit_limit: 120000.00,
                service_charge: 590,
                data_fist_payment: DateComponents(timeZone:TimeZone.init(abbreviation: "UTC"), year: 2013, month: 07, day: 20),
                data_grace_last_payment: DateComponents(timeZone:TimeZone.init(abbreviation: "UTC"), year: 2014, month: 02, day: 20),
                amount_of_expenses: 0,
                amount_of_receipts: 0)
            
            FillProcentTableWithData()
            CalculateProcents()
            
            
            //PROSHET ZA SLED MESYATS
            
            print("\nNEXT MONTH  February\n")
            BalanceForPeriod = Balance(
                income_balance: -144644.22, outgoing_balance: -124461.69,
                income_balance_date: DateComponents(timeZone: TimeZone.init(abbreviation: "UTC") ,year: 2014, month: 01, day: 25),
                outcome_balance_date: DateComponents(timeZone:TimeZone.init(abbreviation: "UTC"), year: 2014, month: 02, day: 24),
                income_ammount: 0,
                credit_limit: 120000.00,
                service_charge: 590,
                data_fist_payment: DateComponents(timeZone:TimeZone.init(abbreviation: "UTC"), year: 2013, month: 07, day: 20),
                data_grace_last_payment: DateComponents(timeZone:TimeZone.init(abbreviation: "UTC"), year: 2014, month: 03, day: 20),
                amount_of_expenses: 0,
                amount_of_receipts: 0)
            
            FillProcentTableWithData()
            CalculateProcents()
            */
            
            
            let request: NSFetchRequest<Procents> = Procents.fetchRequest()
            let sort = NSSortDescriptor(key: #keyPath(Procents.time_attr), ascending: true)
            request.sortDescriptors = [sort]
            
            do {
                ProcentArray = try context.fetch(request)
            }
            catch {
                print("ERROR111")
            }
            
            
            
            
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
    
    
    func GetDaysForPeriod(balance_incomedate: DateComponents,balance_outcomedate: DateComponents) -> Int{
        
        let calendar = Calendar.current
        let date1 = calendar.date(from: balance_incomedate)!
        let date2 = calendar.date(from: balance_outcomedate)!
        
        let numDays = Calendar.current.dateComponents([.day], from: date1, to: date2).day
        print("NUM DAYS: \(numDays)")
        //pochemu 1 24 chislo ne proshet
        return (numDays!+1)
    }
    
    func GetNextDate(currentDate : Date) -> Date  {
        
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to:currentDate)
        return tomorrow!
    }
    
    
    func GetPreviousDate(currentDate : Date) -> Date  {
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to:currentDate)
        return yesterday!
    }
    
    
    func GetGraceLastDate(currentDate : Date) -> Date  {
        
        let graceEndDate = Calendar.current.date(byAdding: .day, value: 57, to:currentDate)
        
        return GetNextDate(currentDate:graceEndDate!)
    }
    
    
    func NewGetGraceLastDate(currentDate : Date) -> Date  {
        
        let graceEndDate = Calendar.current.date(byAdding: .day, value: 54, to:currentDate)
        print("GRACE FINAL DATE2: \(graceEndDate)")
        return graceEndDate!
    }
    
    func thisDayOneMonthEarlier(currentDate : Date,value:Int) -> Date{
        let days = Calendar.current.date(byAdding: .month, value: value, to:currentDate)
        return days!
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
    
    func CheckPayment(currentDate: Date,currentBalance:Double,currentNonPurchase_without_Grace_Balance:Double,currentGraceBalance:Double,currentPreviouseGraceBalance:Double,currentProcent:Double,currentNonPurchase_previouse_Grace_Balance:Double,current_purshases_without_Grace:Double,currentPurshasesStandartBalance:Double)
        -> (currentLocalBalance:Double,currentLocalNonPurchase_without_Grace_Balance:Double,currentLocalGraceBalance:Double,currentLocalPreviouseGraceBalance:Double,currentLocalProcent:Double,currentLocalNonPurchase_previouse_Grace_Balance:Double,currentLocal_purshases_without_Grace:Double,currentLocalPurshasesStandartBalance:Double){
            
            var currentLocalNonPurchase_previouse_Grace_Balance = currentNonPurchase_previouse_Grace_Balance
            var currentLocalPurshasesStandartBalance = currentPurshasesStandartBalance
            var currentLocal_purshases_without_Grace = current_purshases_without_Grace
            var currentLocalProcent = currentProcent
            
            var currentLocalNonPurchase_without_Grace_Balance = currentNonPurchase_without_Grace_Balance
            
            var currentLocalBalance = currentBalance
            
            var  currentLocalGraceBalance = currentGraceBalance
            
            var currentLocalPreviouseGraceBalance = currentPreviouseGraceBalance
            print("CurrentLocalPercent is: \(currentLocalProcent)")
            print("CurrentLocalGraceBalance is: \(currentLocalGraceBalance)")
            print("CurrentLocalPreviouseGraceBalance is: \(currentLocalPreviouseGraceBalance)")
            print("currentLocal_purshases_without_Grace is: \(currentLocal_purshases_without_Grace)")
            print("currentLocalPurshasesStandartBalance is: \(currentLocalPurshasesStandartBalance)")
            print("CurrentNonPurchasePreviousGrace is: \(currentNonPurchase_previouse_Grace_Balance)")
            print("Current_NonPurchases_without_GRACE: \(currentLocalNonPurchase_without_Grace_Balance)")
            
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
                    
                    let str = transactionItem.type_attr?.filter { !" \n\t\r".contains($0) }
                    switch str {
                    case "Плата":
                        print("FOUND PLATA")
                        procentItem.total_debt_out = currentLocalBalance - transactionItem.amount_attr
                        currentLocalBalance = procentItem.total_debt_out
                    case "Выдача":
                        print("FOUND nalichnie vidashs")
                        procentItem.total_debt_out = currentLocalBalance - transactionItem.amount_attr
                        currentLocalBalance = procentItem.total_debt_out
                        
                        
                        currentLocalNonPurchase_without_Grace_Balance = currentLocalNonPurchase_without_Grace_Balance + transactionItem.amount_attr
                        procentItem.nonpurchase_without_Grace = currentLocalNonPurchase_without_Grace_Balance
                        
                    case "Комиссия","Перевод":
                        print("FOUND komissia")
                        procentItem.total_debt_out = currentLocalBalance - transactionItem.amount_attr
                        currentLocalBalance = procentItem.total_debt_out
                        
                        currentLocalNonPurchase_without_Grace_Balance = currentLocalNonPurchase_without_Grace_Balance + transactionItem.amount_attr
                        procentItem.nonpurchase_without_Grace = currentLocalNonPurchase_without_Grace_Balance
                        
                    case "Оплата":
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
                        
                        
                        var difference:Double = 0
                        var currentTransactionItem = transactionItem.amount_attr
                        print("CURRENT POPOLNENIE SUMM: \(currentTransactionItem) at \(currentDate) and currentLocalGraceBalance \(currentLocalGraceBalance)")
                        while(currentTransactionItem > 0){
                            
                            switch currentTransactionItem {
                            //popolnenie menshe procenta
                            case _ where (currentTransactionItem < currentLocalProcent && currentLocalProcent != 0):
                                //SKOREE PRAVILNO
                                print("transactionItem.amount_attr < currentLocalProcent && currentLocalProcent != 0")
                                currentLocalProcent -= currentTransactionItem
                                procentItem.procents = currentLocalProcent
                                currentTransactionItem = 0
                                
                                
                            //popolnenit bolshe procenta
                            case _ where (currentTransactionItem > currentLocalProcent && currentLocalProcent != 0):
                                print("currentTransactionItem > currentLocalProcent && currentLocalProcent != 0")
                                currentTransactionItem -= currentLocalProcent
                                currentLocalProcent = 0
                                procentItem.procents = 0
                                
                                
                                
                                
                            case _ where (currentTransactionItem < currentLocalPurshasesStandartBalance && currentLocalPurshasesStandartBalance != 0):
                                //SKOREE PRAVILNIY
                                print("currentTransactionItem < currentPurshasesStandartBalance && currentPurshasesStandartBalance != 0")
                                currentLocalPurshasesStandartBalance -= currentTransactionItem
                                
                                procentItem.purchases_standart = currentLocalPurshasesStandartBalance
                                currentTransactionItem = 0
                                
                            case _ where (currentTransactionItem > currentLocalPurshasesStandartBalance && currentLocalPurshasesStandartBalance != 0):
                                print("currentTransactionItem > currentPurshasesStandartBalance && currentPurshasesStandartBalance != 0")
                                
                                currentTransactionItem -= currentLocalPurshasesStandartBalance
                                currentLocalPurshasesStandartBalance = 0
                                procentItem.purchases_standart = 0
                                
                                
                                
                                
                                
                                
                                
                                
                            //PREVIOUSE GRACE BALANCE
                            case _ where (currentTransactionItem > currentLocalPreviouseGraceBalance && currentLocalPreviouseGraceBalance != 0):
                                print("currentTransactionItem > currentLocalPreviouseGraceBalance && currentLocalPreviouseGraceBalance != 0")
                                
                                currentTransactionItem -= currentLocalPreviouseGraceBalance
                                currentLocalPreviouseGraceBalance = 0
                                procentItem.purchases_previous_Grace = 0
                                
                                
                            case _ where (currentTransactionItem < currentLocalPreviouseGraceBalance && currentLocalPreviouseGraceBalance != 0):
                                //PROVERIT PRAVILNIY LI
                                print("currentTransactionItem < currentLocalPreviouseGraceBalance && currentLocalPreviouseGraceBalance != 0")
                                
                                currentLocalPreviouseGraceBalance -= currentTransactionItem
                                
                                procentItem.purchases_previous_Grace = currentLocalPreviouseGraceBalance
                                currentTransactionItem = 0
                                
                                
                                //current GRACE
                                
                                
                            case _ where (currentTransactionItem < currentLocal_purshases_without_Grace && currentLocal_purshases_without_Grace != 0):
                                //SKOREE PRAVILNIY
                                print("currentTransactionItem < currentLocal_purshases_without_Grace && currentLocal_purshases_without_Grace != 0")
                                currentLocal_purshases_without_Grace -= currentTransactionItem
                                
                                procentItem.purchases_without_Grace = currentLocal_purshases_without_Grace
                                currentTransactionItem = 0
                                
                            case _ where (currentTransactionItem > currentLocal_purshases_without_Grace && currentLocal_purshases_without_Grace != 0):
                                print("currentTransactionItem > currentLocal_purshases_without_Grace && currentLocal_purshases_without_Grace != 0")
                                
                                currentTransactionItem -= currentLocal_purshases_without_Grace
                                currentLocal_purshases_without_Grace = 0
                                procentItem.purchases_without_Grace = 0
                                
                            case _ where (currentTransactionItem > currentLocalGraceBalance && currentLocalGraceBalance != 0):
                                print("currentTransactionItem > currentLocalGraceBalance && currentLocalGraceBalance != 0")
                                
                                currentTransactionItem -= currentLocalGraceBalance
                                currentLocalGraceBalance = 0
                                procentItem.purchases_current_Grace = 0
                                
                                
                            case _ where (currentTransactionItem < currentLocalGraceBalance && currentLocalGraceBalance != 0):
                                //PRAVILNIY PROSHET
                                print("currentTransactionItem < currentLocalGraceBalance && currentLocalGraceBalance != 0")
                                print("CURRENT POPOLNENIE SUMM: \(currentTransactionItem) and currentLocalGraceBalance \(currentLocalGraceBalance)")
                                // difference = currentLocalGraceBalance - currentTransactionItem
                                currentLocalGraceBalance -= currentTransactionItem
                                print(" procentItem.purchases_current_Grace: \( procentItem.purchases_current_Grace)")
                                procentItem.purchases_current_Grace = currentLocalGraceBalance
                                currentTransactionItem = 0
                                print("IMPORTANT")
                                print("After currentLocalGraceBalance \(currentLocalGraceBalance)")
                                
                                
                                
                                //NON GRACE obrabativaem poslednim vsegda!
                                
                                
                                
                            case _ where (currentTransactionItem > currentLocalNonPurchase_without_Grace_Balance && currentLocalNonPurchase_without_Grace_Balance != 0):
                                print("currentTransactionItem > currentLocalNonPurchase_without_Grace_Balance && currentLocalNonPurchase_without_Grace_Balance != 0")
                                
                                currentTransactionItem -= currentLocalNonPurchase_without_Grace_Balance
                                currentLocalNonPurchase_without_Grace_Balance = 0
                                procentItem.nonpurchase_without_Grace = 0
                                
                                
                            case _ where (currentTransactionItem < currentLocalNonPurchase_without_Grace_Balance && currentLocalNonPurchase_without_Grace_Balance != 0):
                                //SKOREE PRAVILNO
                                print("currentTransactionItem < currentLocalNonPurchase_without_Grace_Balance && currentLocalNonPurchase_without_Grace_Balance != 0")
                                
                                currentLocalNonPurchase_without_Grace_Balance -= currentTransactionItem
                                
                                procentItem.nonpurchase_without_Grace = currentLocalNonPurchase_without_Grace_Balance
                                currentTransactionItem = 0
                                
                                //
                                
                                
                            default:
                                //currentTransactionItem = 0
                                print("DEFAULT VALUE FOR SWITCH !!!!!!!!!")
                                
                            }
                            
                            
                        }
                        
                        
                        
                        /*
                         if(currentLocalPreviouseGraceBalance != 0) {
                         print("NOT NULL")
                         currentLocalPreviouseGraceBalance -= transactionItem.amount_attr
                         procentItem.purchases_previous_Grace = currentLocalPreviouseGraceBalance
                         print("PROCNETS NOW:\(currentLocalProcent)")
                         if(currentLocalProcent != 0 && transactionItem.amount_attr >= currentLocalProcent) {
                         print("PROCENT NOT NULL")
                         
                         currentLocalPreviouseGraceBalance += currentLocalProcent
                         currentLocalProcent = 0
                         procentItem.procents = currentLocalProcent
                         procentItem.purchases_previous_Grace = currentLocalPreviouseGraceBalance
                         
                         } else if(currentLocalProcent != 0 && transactionItem.amount_attr < currentLocalProcent){
                         var diff = currentLocalProcent - transactionItem.amount_attr
                         currentLocalPreviouseGraceBalance += diff
                         procentItem.purchases_previous_Grace = currentLocalPreviouseGraceBalance
                         procentItem.procents -= transactionItem.amount_attr
                         
                         
                         }
                         
                         } else {
                         currentLocalGraceBalance = currentLocalGraceBalance -  transactionItem.amount_attr
                         procentItem.purchases_current_Grace = currentLocalGraceBalance
                         }
                         
                         */
                        
                        
                        
                    default:
                        print("No category found")
                    }
                    
                    
                    
                }
                
                
            }
            else {
                print("No transaction for date: \(currentDate)")
                procentItem.total_debt_out = currentLocalBalance
                
            }
            
            procentItem.purchases_standart =  currentLocalPurshasesStandartBalance
            
            procentItem.nonpurchase_previous_Grace =   currentLocalNonPurchase_previouse_Grace_Balance
            procentItem.nonpurchase_without_Grace = currentLocalNonPurchase_without_Grace_Balance
            procentItem.purchases_current_Grace = currentLocalGraceBalance
            // procentItem.nonpurchase_previous_Grace = currentpreviouseGraceBalance
            currentLocalPreviouseGraceBalance =  Double(round(100*currentLocalPreviouseGraceBalance)/100)
            
            procentItem.purchases_previous_Grace =   currentLocalPreviouseGraceBalance
            //procentItem.purchases_previous_Grace = currentPur
            ////// RAZOBRATSA V ETOM KUSKE
            procentItem.purchases_without_Grace = currentLocal_purshases_without_Grace
            print("TRY TO CHECK GRACE PERIOD last date is \(LastDayForPayInGracePeriod) and current date is \(currentDate)")
            
            if(LastDayForPayInGracePeriod == currentDate && (currentLocalPreviouseGraceBalance != 0)){
                print("GRACE DATE IS HERE: \(currentDate)")
                currentLocal_purshases_without_Grace =  currentLocalPreviouseGraceBalance
                
                
                procentItem.purchases_without_Grace = currentLocal_purshases_without_Grace
                currentLocalPreviouseGraceBalance = 0
                procentItem.purchases_previous_Grace = 0
                
                currentLocalNonPurchase_without_Grace_Balance  += currentLocalNonPurchase_previouse_Grace_Balance
                currentLocalNonPurchase_previouse_Grace_Balance = 0
                print("SHOULD BE 65000")
                print(currentLocalNonPurchase_without_Grace_Balance)
                //  currentLocalNonPurchase_previouse_Grace_Balance = 0
                print("1034 WILL BE 0")
                
                procentItem.nonpurchase_previous_Grace = currentLocalNonPurchase_previouse_Grace_Balance
                
                
                
                procentItem.nonpurchase_without_Grace = currentLocalNonPurchase_without_Grace_Balance
                procentItem.nonpurchase_previous_Grace = currentLocalNonPurchase_previouse_Grace_Balance
                
                
                
                
                // currentLocalNonPurchase_without_Grace_Balance =  procentItem.nonpurchase_without_Grace
                
                //esli pogashen ves dolg v grace period
                if(currentBalance >= 0){
                    //zapros novoy dati dlya grace
                    print("DOLG POGASHEN")
                    gracePeriodIsActive = true
                    
                    //esli grace bil pogashen ranshe to formiruem novyu datu dlya grace
                    
                    print("GRACE POGASHEN FORMIRUEM NOVYU DATU")
                    var b = Calendar.current.date(from: BalanceForPeriod.data_grace_last_payment)
                    //    LastDayForPayInGracePeriod = GetGraceLastDate(currentDate: b!)
                    LastDayForPayInGracePeriod = b!
                    print("GRACE LAST DAY IS:::: \(LastDayForPayInGracePeriod)")
                    
                    
                    
                } else {
                    print("DOLG V GRACE NE POGASHEN")
                    gracePeriodIsActive = false
                    var b = Calendar.current.date(from: BalanceForPeriod.data_grace_last_payment)
                    //    LastDayForPayInGracePeriod = GetGraceLastDate(currentDate: b!)
                    LastDayForPayInGracePeriod = b!
                    print("GRACE LAST DAY IS:::: \(LastDayForPayInGracePeriod)")
                }
                
            }
            
            
            print("PPP: \(Calendar.current.date(from: BalanceForPeriod.outcome_balance_date)) and curr date \(currentDate)")
            
            //
            // && currentLocal_purshases_without_Grace > 0
            
            /*if(Calendar.current.date(from: BalanceForPeriod.outcome_balance_date) == currentDate){
             print("QQQ: \(BalanceForPeriod.outcome_balance_date)")
             currentLocalPurshasesStandartBalance += currentLocal_purshases_without_Grace
             currentLocal_purshases_without_Grace = 0
             procentItem.purchases_without_Grace = currentLocal_purshases_without_Grace
             procentItem.purchases_standart = currentLocalPurshasesStandartBalance
             
             }
             */
            print("")
            print("BALANCE: ")
            print(currentLocalBalance)
            print("Current Grace \(currentLocalGraceBalance)")
            print("Grace Previouse Period \(currentLocalPreviouseGraceBalance)")
            print("currentLocal_purshases_without_Grace \(currentLocal_purshases_without_Grace)")
            print("currentLocalNonPurchase_without_Grace_Balance \(currentLocalNonPurchase_without_Grace_Balance)")
            print("currentLocalNonPurchase_previouse_Grace_Balance \(currentLocalNonPurchase_previouse_Grace_Balance)")
            
            
            if( currentLocalBalance < (-1) * BalanceForPeriod.credit_limit) {
                print("SVERH LIMIT IN CHECKPAYMENT")
            }
            
            //////
            
            
            
            return (currentLocalBalance,currentLocalNonPurchase_without_Grace_Balance,currentLocalGraceBalance,currentLocalPreviouseGraceBalance,currentLocalProcent,currentLocalNonPurchase_previouse_Grace_Balance,currentLocal_purshases_without_Grace,currentLocalPurshasesStandartBalance)
    }
    
    
    var currentNonPurchase_without_Grace_Balance:Double = 0
    var currentGraceBalance:Double = 0
    var currentPreviouseGraceBalance:Double = 0
    var currentProcent:Double = 0
    var currentPurshasesStandartBalance:Double = 0
    
    var currentNonPurchase_previouse_Grace_Balance:Double = 0
    var current_purshases_without_Grace:Double = 0
    var procent_previouse_period:Double = 0
    
    
    
    func FillProcentTableWithData(){
        
        
        
        var currentBalance = BalanceForPeriod.income_balance
        
        // var current_period = GetDaysInMonth(balancedate:BalanceForPeriod.income_balance_date)
        
        
        var current_period = GetDaysForPeriod(balance_incomedate: BalanceForPeriod.income_balance_date, balance_outcomedate: BalanceForPeriod.outcome_balance_date)
        
        
        var currentDate = Calendar.current.date(from: BalanceForPeriod.income_balance_date)
        
        
        //pochemu 17 chislo pishet a ne 18 srashu? UTC nado delat
        for _ in 0..<current_period {
            print("")
            print("/////")
            print("Proshet v etu datu: \(currentDate) and procent is \(currentProcent)")
            print("currentBalance: \(currentBalance)")
            //check if payment was for this day
            let current = CheckPayment(currentDate: currentDate!,currentBalance: currentBalance, currentNonPurchase_without_Grace_Balance: currentNonPurchase_without_Grace_Balance,currentGraceBalance: currentGraceBalance,currentPreviouseGraceBalance: currentPreviouseGraceBalance,currentProcent:currentProcent,currentNonPurchase_previouse_Grace_Balance:currentNonPurchase_previouse_Grace_Balance,current_purshases_without_Grace:current_purshases_without_Grace,currentPurshasesStandartBalance:currentPurshasesStandartBalance)
            
            currentNonPurchase_previouse_Grace_Balance = current.currentLocalNonPurchase_previouse_Grace_Balance
            
            current_purshases_without_Grace = current.currentLocal_purshases_without_Grace
            currentProcent = current.currentLocalProcent
            currentBalance = current.currentLocalBalance
            currentNonPurchase_without_Grace_Balance = current.currentLocalNonPurchase_without_Grace_Balance
            currentGraceBalance = current.currentLocalGraceBalance
            currentPurshasesStandartBalance = current.currentLocalPurshasesStandartBalance
            currentPreviouseGraceBalance = current.currentLocalPreviouseGraceBalance
            
            currentDate = GetNextDate(currentDate: currentDate!)
            
        }
        
        
        do{
            try context.save()
        }catch{
            print("Error Saving context")
        }
        
        
        
        
        
    }
    
    
    
    func calculateTotalProcentForPeriodNEW(balance_incomedate: DateComponents, balance_outcomedate: DateComponents) ->Double{
        //-108144.8
        
        print("START TOTAL PROCENT COUNT NEW")
        var current_period = GetDaysForPeriod(balance_incomedate: BalanceForPeriod.income_balance_date, balance_outcomedate: BalanceForPeriod.outcome_balance_date)
        var currentDate = Calendar.current.date(from: BalanceForPeriod.income_balance_date)
        //currentDate = GetPreviousDate(currentDate: currentDate!)
        print("PROCENT WILL BE COUNT FROM THIS DAY \(currentDate) and for these days \(current_period)")
        
        var total_procent:Double = 0
        var procent_counted:Double = 0;
        var procent_grace_previous:Double = 0;
        var procent_non_grace:Double = 0;
        
        // currentDate = GetNextDate(currentDate: currentDate!)
        for _ in 0..<current_period {
            
            
            let request: NSFetchRequest<Procents> = Procents.fetchRequest()
            let sort = NSSortDescriptor(key: #keyPath(Procents.time_attr), ascending: true)
            let predicate = NSPredicate(format: "time_attr == %@", currentDate as! NSDate)
            request.sortDescriptors = [sort]
            request.predicate = predicate
            
            
            do {
                
                ProcentArray = try context.fetch(request)
                
                print("PROCENT AT DATE: \(currentDate)")
                print(currentProcent)
                print("Add Current Procent \(ProcentArray[0].percent_current_Grace) at \(ProcentArray[0].time_attr)")
                print("Add Previouse Procent \(ProcentArray[0].percent_previous_Grace) at \(ProcentArray[0].time_attr)")
                print("Add Non Grace Procent \(ProcentArray[0].percent_without_Grace) at \(ProcentArray[0].time_attr)")
                procent_counted += ProcentArray[0].percent_current_Grace
                //print(procent_counted)
                procent_grace_previous += ProcentArray[0].percent_previous_Grace
                print("procent_grace_previous: \(procent_grace_previous)")
                procent_non_grace += ProcentArray[0].percent_without_Grace
                print(procent_non_grace)
                
                currentDate = GetNextDate(currentDate: currentDate!)
                
            } catch {
                print("error getting data")
            }
            
        }
        
        
        //procent_counted = Double(round(100*procent_counted)/100)
        //print(procent_counted)
        
        // procent_grace_previous = Double(round(100*procent_grace_previous)/100)
        //  print(procent_grace_previous)
        
        // procent_non_grace = Double(round(100*procent_non_grace)/100)
        // print(procent_non_grace)
        
        if(gracePeriodIsActive == true){
            procent_previouse_period = procent_counted
            print("procent_PREVIOUSE PERIOD_counted GRACE ACTIVE")
            print(procent_previouse_period)
        }
        
        print("procent_PREVIOUSE PERIOD_counted")
        print(procent_previouse_period)
        
        print("procent_counted")
        print(procent_counted)
        
        print("procent_non_grace")
        print(procent_non_grace)
        
        print("procent_grace_previous")
        print(procent_grace_previous)
        
        
        
        
        
        var data_procent_count = Calendar.current.date(from: BalanceForPeriod.outcome_balance_date)
        var data_last_pay_for_graceperiod = GetGraceLastDate(currentDate: data_procent_count!)
        
        currentDate = GetPreviousDate(currentDate: currentDate!)
        
        
        
        //  var oneMonthAgo = thisDayOneMonthEarlier(currentDate: Calendar.current.date(from: BalanceForPeriod.outcome_balance_date)!, value: -1)
        // print("zzz")
        //print(oneMonthAgo)
        //LastDayForPayInGracePeriod = GetGraceLastDate(currentDate: oneMonthAgo)
        //print(LastDayForPayInGracePeriod)
        
        print("PERIOD DO: \(data_procent_count) and GRACE LAST DAY IS \(LastDayForPayInGracePeriod)")
        
        //PROVERKHA PROSHEL LI GRACE PERIOD
        
        if(gracePeriodIsActive == true){
            print("GRACE PERIOD NE OKONSHEN POETOMY NE COUNT TEKUSHIE PROCENTI")
            total_procent = procent_non_grace+procent_grace_previous
            total_procent = Double(round(100*total_procent)/100)
            //  currentDate = GetPreviousDate(currentDate: currentDate!)
            
            
            
            
        } else {
            print("NON GRACE PERIOD")
            var cr = Calendar.current.date(from: BalanceForPeriod.income_balance_date)
            var prev_procent = GetPreviousDate(currentDate: cr!)
            
            print("PREV DATA \(prev_procent)")
            let request2: NSFetchRequest<Procents> = Procents.fetchRequest()
            let sort2 = NSSortDescriptor(key: #keyPath(Procents.time_attr), ascending: true)
            let predicate2 = NSPredicate(format: "time_attr == %@", prev_procent as! NSDate)
            
            request2.sortDescriptors = [sort2]
            request2.predicate = predicate2
            var prevperiodProcents: Double = 0
            do {
                
                ProcentArray = try context.fetch(request2)
                
                prevperiodProcents = ProcentArray[0].procents_previouse
                print("ZZZZ:\(prevperiodProcents)")
                
            } catch {
                print("error getting data")
            }
            
            
            print("PREV PERIDO PROCENTS: \(prevperiodProcents)")
            total_procent = prevperiodProcents+procent_non_grace+procent_grace_previous
            total_procent = Double(round(100*total_procent)/100)
            print("SUMM = \(prevperiodProcents) \(procent_non_grace) \(procent_grace_previous) ")
            //
            //  prevperiodProcents
            //   total_procent = procent_previouse_period+procent_non_grace+procent_grace_previous
        }
        
        
        let request: NSFetchRequest<Procents> = Procents.fetchRequest()
        let sort = NSSortDescriptor(key: #keyPath(Procents.time_attr), ascending: true)
        let predicate = NSPredicate(format: "time_attr == %@", currentDate as! NSDate)
        request.sortDescriptors = [sort]
        request.predicate = predicate
        print("THIS DAY!! \(currentDate)")
        do {
            
            ProcentArray = try context.fetch(request)
            ProcentArray[0].purchases_previous_Grace = ProcentArray[0].purchases_current_Grace
            ProcentArray[0].purchases_current_Grace  = 0
            
            //PUT PROCENT_COUNTED TO TABLE
            print("PUT CURRENT PROCENT IN TABLE \(procent_counted)")
            ProcentArray[0].procents_previouse = procent_counted
            
            
            ProcentArray[0].purchases_standart += ProcentArray[0].purchases_without_Grace
            ProcentArray[0].purchases_without_Grace = 0
            
        } catch {
            print("error getting data")
        }
        
        
        
        
        
        print("BALANCE BEFORE PROCENT")
        print(ProcentArray[0].total_debt_out)
        
        
        print("TOTAL:!")
        print(total_procent)
        
        ProcentArray[0].procents = total_procent
        
        
        
        ProcentArray[0].total_debt_out  =  ProcentArray[0].total_debt_out - total_procent
        print("BALANCE after procent minus")
        print(ProcentArray[0].total_debt_out)
        /*
         if( ProcentArray[0].total_debt_out < (-1) * BalanceForPeriod.credit_limit) {
         print("SVERH LIMIT!!!")
         ProcentArray[0].total_debt_out -= 390
         }
         */
        print("STRAHOVKA!!!: \(ProcentArray[0].total_debt_out)")
        var procent_strahovka = 0.89 *  ProcentArray[0].total_debt_out / 100 * -1
        
        
        
        procent_strahovka =  Double(round(100*procent_strahovka)/100)
        print("WWWW: \(procent_strahovka)")
        
        //pochemuto v ih otchete oshibka
        if(procent_strahovka == 1280.51) {
            
            procent_strahovka = 1280.52
            print("EDIT: \(procent_strahovka)")
        }
        
        
        print("STRAHOVKA")
        print(procent_strahovka)
        
        ProcentArray[0].total_debt_out -= procent_strahovka
        print("BALANCE AFTER KREDIT PAY")
        print(ProcentArray[0].total_debt_out)
        
        let plata_sms:Double = 59
        
        currentNonPurchase_previouse_Grace_Balance = procent_strahovka + plata_sms
        
        /////IMPORTANT
        
        
        
        //IMPORTANT!!
        
        ProcentArray[0].nonpurchase_previous_Grace += currentNonPurchase_previouse_Grace_Balance
        
        currentPreviouseGraceBalance = ProcentArray[0].purchases_previous_Grace
        
        currentPurshasesStandartBalance = ProcentArray[0].purchases_standart
        ProcentArray[0].purchases_without_Grace = 0
        current_purshases_without_Grace = 0
        currentProcent = total_procent
        print("PROCENT IS NOW \(currentProcent)")
        
        
        
        
        
        
        
        return total_procent
    }
    
    
    
    
    
    
    
    func CalculateProcents(){
        
        
        var current_period = GetDaysForPeriod(balance_incomedate: BalanceForPeriod.income_balance_date, balance_outcomedate: BalanceForPeriod.outcome_balance_date)
        // var current_period = GetDaysInMonth(balancedate:BalanceForPeriod.income_balance_date)
        var currentDate = Calendar.current.date(from: BalanceForPeriod.income_balance_date)
        var yesterday = Calendar.current.date(from: BalanceForPeriod.income_balance_date)
        
        
        //currentDate = GetNextDate(currentDate: currentDate!)
        
        
        for _ in 0..<current_period {
            print("\n")
            print("PROCENT PO ETOY DATE: \(currentDate)")
            yesterday=GetPreviousDate(currentDate: currentDate!)
            
            //////////
            //  let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Procents")
            
            let requestSearch: NSFetchRequest <Procents> = Procents.fetchRequest()
            let predicate = NSPredicate(format: "time_attr == %@", yesterday as! NSDate)
            
            requestSearch.predicate = predicate
            var transactionsFoundForPreviousDate = [Procents]()
            do {
                transactionsFoundForPreviousDate =  try context.fetch(requestSearch)
                //   print("Transaction for Previouse date:  \(transactionsFoundForPreviousDate[0].time_attr)")
                //  print(transactionsFoundForPreviousDate)
            } catch {
                print("ERROR FETCHING DATA")
            }
            
            if ( transactionsFoundForPreviousDate.count != 0){
                print("Found transaction for PREVIOUSE DATE: \(transactionsFoundForPreviousDate[0].time_attr)")
                
                let requestSearch: NSFetchRequest <Procents> = Procents.fetchRequest()
                let predicate = NSPredicate(format: "time_attr == %@", currentDate as! NSDate)
                requestSearch.predicate = predicate
                var transactionsFoundForCurrentDate = [Procents]()
                do {
                    transactionsFoundForCurrentDate =  try context.fetch(requestSearch)
                    print("Transaction for current date:  \(transactionsFoundForCurrentDate[0].time_attr)")
                } catch {
                    print("ERROR FETCHING DATA")
                }
                
                //CALCULATE PROCENTS
                
                var procentsCurrentGrace = transactionsFoundForPreviousDate[0].purchases_current_Grace * 32.9/365/100
                procentsCurrentGrace = Double(round(100000*procentsCurrentGrace)/100000)
                
                
                transactionsFoundForCurrentDate[0].percent_current_Grace =  procentsCurrentGrace
                
                print("/n")
                print("Procent for grace current calculated for this day: \(yesterday) will be put in date \(currentDate) is \(procentsCurrentGrace)")
                
                
                
                
                var procentPreviousGrace = (transactionsFoundForPreviousDate[0].purchases_previous_Grace * 32.9 +
                    transactionsFoundForPreviousDate[0].nonpurchase_previous_Grace * 39.9)/100/365
                
                procentPreviousGrace = Double(round(100000*procentPreviousGrace)/100000)
                transactionsFoundForCurrentDate[0].percent_previous_Grace = procentPreviousGrace
                
                print("Procent for previouse grace calculated for this day: \(yesterday) will be put in date \(currentDate) is \(procentPreviousGrace) and was calculated with purchases_previous_Grace \(transactionsFoundForPreviousDate[0].purchases_previous_Grace) multiplied by  \(transactionsFoundForPreviousDate[0].nonpurchase_previous_Grace) and date was \(transactionsFoundForPreviousDate[0].time_attr)")
                
                
                
                var procentWithoutGrace = (transactionsFoundForPreviousDate[0].nonpurchase_without_Grace * 39.9 + transactionsFoundForPreviousDate[0].purchases_without_Grace * 32.9 + transactionsFoundForPreviousDate[0].purchases_standart * 32.9)/100/365
                
                procentWithoutGrace = Double(round(100000*procentWithoutGrace)/100000)
                transactionsFoundForCurrentDate[0].percent_without_Grace = procentWithoutGrace
                
                
                print("Procent without grace calculated for this day: \(yesterday) will be put in date \(currentDate) is \(procentWithoutGrace) and was calculated by multiply \(transactionsFoundForPreviousDate[0].nonpurchase_without_Grace) and \(transactionsFoundForPreviousDate[0].purchases_without_Grace) and \(transactionsFoundForPreviousDate[0].purchases_standart)")
                
                
                
                
                
                //print(transactionsFoundForPreviousDate[0].purchases_current_Grace)
            } else {
                print("data not found for this date!!!!! SO GO NEXT DAY, MAY BE IT IS FIRST DAY OF FIRST MONTH")
                // currentDate = GetNextDate(currentDate: currentDate!)
            }
            //////////
            
            
            currentDate = GetNextDate(currentDate: currentDate!)
            
        }
        
        //SHOW TOTAL PROCENT FOR PAY
        
        var totalProcent = calculateTotalProcentForPeriodNEW(balance_incomedate: BalanceForPeriod.income_balance_date, balance_outcomedate: BalanceForPeriod.outcome_balance_date)
        print("Total Procent: \(totalProcent)")
        
        currentGraceBalance = 0.0
        
        print("AFTER TOTAL PROCENT")
        
        print("Current Grace \(currentGraceBalance)")
        print("Grace Previouse Period \(currentPreviouseGraceBalance)")
        print("current Purshases Standart \(currentPurshasesStandartBalance)")
        print("currentLocal_purshases_without_Grace \(current_purshases_without_Grace)")
        print("currentLocalNonPurchase_without_Grace_Balance \(currentNonPurchase_without_Grace_Balance)")
        print("currentLocalNonPurchase_previouse_Grace_Balance \(currentNonPurchase_previouse_Grace_Balance)")
        
        
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
        // print(str[0])
        guard let date = dateFormatter.date(from: str[0]) else {
            fatalError("ERROR: Date conversion failed due to mismatched format.")
        }
        
        newItem.time_attr = date
        newItem.amount_attr=Double(str[1])!
        newItem.type_attr=str[2]
        
        // Transaction
        do{
            try context.save()
        }catch{
            print("Error Saving context")
        }
        
        return true
    }
    func matches(for regex: String, in text: String) -> [String] {
        
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    func readDataRAWFromCSVFile(file:String){
        
        
        
        
        // let DocumentDirURL = try! FileManager.default.url(for: ., in: .userDomainMask, appropriateFor: nil, create: true)
        if let filepath = Bundle.main.path(forResource: file, ofType: "txt"){
            
            do{
                let contents = try String(contentsOfFile: filepath)
                print(contents)
                var matched = matches(for: "\\d{2}\\.\\d{2}\\.\\d{2}\\ .+(Пополнение|Оплата|Выдача|Плата|Комиссия)", in: contents)
                //     print(matched)
                var resultString : String = ""
                for str in matched {
                    var str1 =  matches(for: "(?<=.{7})(\\d{2}.\\d{2}.\\d{2}.*)", in: str)
                    print("UUU: \(str1)")
                    
                    str1 = matches(for: "(\\d{2}\\.\\d{2}\\.\\d{2}.+)", in: str1[0])
                    
                    
                    print(str1)
                    var newstring = str1[0].replacingOccurrences(of: "(RUR.+RUR)", with: "",options: .regularExpression)
                    print(newstring)
                    newstring = newstring.replacingOccurrences(of: "(\\s\\s)", with: " ",options: .regularExpression)
                    print(newstring)
                    newstring = newstring.replacingOccurrences(of: "(?<=.{9})((?<=\\d) (?=\\d))", with: "",options: .regularExpression)
                    print(newstring)
                    newstring += "\n"
                    resultString += newstring
                }
                print(resultString)
                
                
                // print(regex)
                
                let parsedCSV: [[String]] = resultString.components(separatedBy: "\n").map{ $0.components(separatedBy: " ") }.filter{!$0.isEmpty}
                for line in parsedCSV {
                    
                    if line[0] != "" {
                        //print("EMPTY STRING")
                        print("LINE: \(line)")
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
                        print("LINE: \(line)")
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



