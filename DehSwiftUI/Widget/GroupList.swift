//
//  GroupList.swift
//  DehSwiftUI
//
//  Created by 阮盟雄 on 2021/4/14.
//  Copyright © 2021 mmlab. All rights reserved.

//往上跳一層
//https://stackoverflow.com/questions/56513568/ios-swiftui-pop-or-dismiss-view-programmatically/57279591

import SwiftUI
import Combine
import Alamofire
class GroupLists:Decodable{
    let results: [Group]?
    let eventList:[Group]?
    let groupList:[Group]?
}

struct GroupList: View {
    @State private var cancellable: AnyCancellable?
    @EnvironmentObject var settingStorage:SettingStorage
    @State var groups:[Group] = []
    @Binding var group:Group
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    var body: some View{
        List{
            ForEach(self.groups) {group in
                Button(action:{
                    print(group.name)
                    self.group = group
                    self.presentationMode.wrappedValue.dismiss()
                }){
                    Text(group.name)
                        .foregroundColor(Color.white)
//                        .allowsTightening(true)
//                        .lineLimit(1)
                }
                .listRowBackground(Color.init(UIColor(rgba:lightGreen)))
                
            }
        }
        .onAppear(perform: {
            getGroupList()
        })
    }
}
extension GroupList{
    func getGroupList() {
        let url = GroupGetUserGroupListUrl
        let parameters: [String: Any] = [
            "userId": Int(settingStorage.userID) ?? -1,
            "coiName": coi,
            "language": "中文"
        ]
        
        print("API Call to: \(url)")
        print("Parameters: \(parameters)")
        
        let publisher: DataResponsePublisher<GroupLists> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters, addLogs: true)
        self.cancellable = publisher
            .sink(receiveValue: { (values) in
                print("Response: \(values.debugDescription)")
                
                if let error = values.error {
                    print("Error: \(error)")
                    return
                }
                
                if let rawData = values.data {
                    print("Raw Data: \(String(data: rawData, encoding: .utf8) ?? "Unable to decode raw data")")
                }
                
                if let results = values.value?.results {
                    print("Successfully got \(results.count) groups")
                    self.groups = results
                    print("Groups: \(results)")
                } else {
                    print("No results in response")
                }
            })
    }
}

//struct GroupList_Previews: PreviewProvider {
//    static var previews: some View {
//        GroupList(groups:[Group(id: 0, name: "123"),Group(id: 0, name: "123")], group: <#Binding<Group>#>)
//    }
//}
