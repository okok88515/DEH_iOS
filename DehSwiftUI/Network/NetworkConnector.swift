import SwiftUI
import Combine
import Alamofire
import UIKit
import MapKit

class NetworkConnector: ObservableObject {
    private let locationManager = LocationManager()
    
    // Store the public IP as a static variable shared among all instances
    private static var publicIP: String?
    
    // A list of closures representing queued requests waiting for the IP
    private var requestQueue: [() -> Void] = []
    
    init() {
        fetchPublicIP()
    }
    
    private func fetchPublicIP() {
        // Asynchronously fetch the public IP
        AF.request("https://api.ipify.org?format=json").responseJSON { [weak self] response in
            if let json = response.value as? [String: Any],
               let ip = json["ip"] as? String {
                NetworkConnector.publicIP = ip
                print("Fetched public IP: \(ip)")
                self?.processQueuedRequests()
            } else {
                print("Failed to fetch public IP.")
                // Optionally retry fetching here
            }
        }
    }
    
    private func processQueuedRequests() {
        // Execute all queued requests now that IP is available
        for request in requestQueue {
            request()
        }
        requestQueue.removeAll()
    }
    
    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return "DEH IOS Mini " + version
        }
        return "DEH IOS Mini 1.0"
    }
    
    private func addLogParameters(_ parameters: Parameters) -> Parameters {
        var newParams = parameters
        
        // Generate or retrieve a persistent unique device ID
        let deviceId = UserDefaults.standard.string(forKey: "deviceID") ?? UUID().uuidString
        if UserDefaults.standard.string(forKey: "deviceID") == nil {
            UserDefaults.standard.set(deviceId, forKey: "deviceID")
        }
        
        newParams["logParameters"] = [
            "deviceID": deviceId,
            "appVer": appVersion,
            "userLatitude": locationManager.coordinateRegion.center.latitude.description,
            "userLongitude": locationManager.coordinateRegion.center.longitude.description,
            "pre_page": "",
            "userId": Int(SettingStorage.shared.userID) ?? -1,
            // Use the fetched public IP if available, otherwise an empty string
            "ip": NetworkConnector.publicIP ?? ""
        ]
        
        return newParams
    }
    
    // Wrapper to ensure IP is fetched before making a request
    private func performAfterIPReady(_ action: @escaping () -> Void) {
        if NetworkConnector.publicIP != nil {
            // If IP is ready, perform the action immediately
            action()
        } else {
            // Otherwise, queue the action until IP is fetched
            requestQueue.append(action)
        }
    }
    
    func getDataPublisherDecodable<T: Decodable>(url: String, para: Parameters, addLogs: Bool = true) -> DataResponsePublisher<T> {
        let parameters = addLogs ? addLogParameters(para) : para
        return AF.request(url, method: .post, parameters: parameters)
            .publishDecodable(type: T.self, queue: .main)
    }
    
    func getDataPublisherData(url: String, para: Parameters, addLogs: Bool = true) -> DataResponsePublisher<XOI> {
        let parameters = addLogs ? addLogParameters(para) : para
        return AF.request(url, method: .post, parameters: parameters)
            .publishDecodable(type: XOI.self, queue: .main)
    }
    
    func getDataPublisher(url: String, para: Parameters, addLogs: Bool = true) -> DataResponsePublisher<Data> {
        let parameters = addLogs ? addLogParameters(para) : para
        return AF.request(url, method: .post, parameters: parameters)
            .publishData()
    }
    
    func getMediaPublisher(url: String) -> DataResponsePublisher<Data> {
        return AF.request(url, method: .get)
            .validate()
            .responseData(emptyResponseCodes: [200, 204, 205]) { response in
                debugPrint(response)
            }
            .publishData()
    }
    
    func getMediaPublisher(url: URL) -> DataResponsePublisher<Data> {
        return AF.request(url, method: .get)
            .validate()
            .responseData(emptyResponseCodes: [200, 204, 205]) { response in
                debugPrint(response)
            }
            .publishData()
    }
    
    func uploadMediaPublisher<T: Decodable>(url: String, para: Parameters, inputData: Data, addLogs: Bool = true) -> DataResponsePublisher<T> {
        let parameters = addLogParameters(para)
        return AF.upload(multipartFormData: { formData in
            for (key, value) in parameters {
                if let stringValue = value as? String,
                   let valueData = stringValue.data(using: .utf8) {
                    formData.append(valueData, withName: key)
                }
            }
            formData.append(inputData, withName: "imageData")
        }, to: url)
        .publishDecodable(type: T.self, queue: .main)
    }
}
