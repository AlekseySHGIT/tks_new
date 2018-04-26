//
//  ViewController.swift
//  tkstest
//
//  Created by Admin on 26.04.2018.
//  Copyright © 2018 Alex. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
  
    
    //readCSV
    
    readDataFromCSVFile()
    
    
    }
    
    func writeLineToCoreData(str:[String]) ->Bool{
        print(str[0])
        print(str[1])
        print(str[2])
        
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
                  
                    writeLineToCoreData(str:line)
                   // for element in line{
                     //   print(element)
                   // }
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

