//
//  ViewController.swift
//  tkstest
//
//  Created by Admin on 26.04.2018.
//  Copyright © 2018 Alex. All rights reserved.
//

import UIKit
import CoreData
class ViewController: UIViewController {

    var TransactionsArray = [Transaction]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
  
    
    //readCSV
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
    //readDataFromCSVFile()
    loadItemsFromCoreData()
    
    }
     let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    func loadItemsFromCoreData(){
        
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        do {
        TransactionsArray = try context.fetch(request)
        } catch {
            print("error getting data")
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
        if let filepath = Bundle.main.path(forResource: "FirstCSVTinkoff", ofType: "csv"){
            
            do{
                let contents = try String(contentsOfFile: filepath)
             //   print(contents)
                
                let parsedCSV: [[String]] = contents.components(separatedBy: "\n").map{ $0.components(separatedBy: " ") }
               // print(parsedCSV)
                
                 for line in parsedCSV {
                  
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

