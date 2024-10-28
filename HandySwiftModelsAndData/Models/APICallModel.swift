//
//  CreaturesViewModel.swift
//  CatchEmAll
//
//  Created by Brett Buchholz on 10/10/24.
//

import Foundation

@Observable
class Creatures {
    
    //These variables are the Swift objects that hold the JSON data. They are unique to your project.
    var urlString = "https://pokeapi.co/api/v2/pokemon"
    var count = 0
    var creaturesArray: [Creature] = []
    
    //This is the struct we created to match the JSON data. The names and data types must be an exact match to the Key:Value pairs of the JSON
    private struct Returned: Codable {
        var count: Int
        var next: String?
        var results: [Creature]
    }
    
    //Because the "results" variable in "Returned" contained an array, we created a second struct for the individual elements of that array. This data is modeling the JSON so you still need to make sure that the names and data types are an exact match to the Key:Value pairs of the JSON
    struct Creature: Codable, Hashable {
        var name: String
        var url: String
    }
    
    
    //This method creates a URL object, calls URLSession on that object, returns JSON data, decodes it and then converts it into the Swift class
    func getData() async {
        print("🕸️ We are accessing the url \(urlString)")
        
        //Convert urlString to a special URL Type
        guard let url = URL(string: urlString) else {
            return
        }
        
        do {
            //Call URLSession on the URL object
            let (data, response) = try await URLSession.shared.data(from: url)
            
            //Try to decode JSON data into our own data structures
            guard let returned = try? JSONDecoder().decode(Returned.self, from: data) else {
                print("😡 JSON ERROR: Could not decode returned JSON data")
                return
            }
            
            //Convert the Returned struct into class properties
            self.count = returned.count
            self.urlString = returned.next ?? ""
            self.creaturesArray = returned.results
            
        } catch {
            print("😡 ERROR: Could not use URL at \(urlString) to get data and response")
        }
    }
}
