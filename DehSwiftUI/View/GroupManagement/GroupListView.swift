//
//  GroupList.swift
//  DehSwiftUI
//
//  Created by 陳家庠 on 2021/10/14.
//  Copyright © 2021 mmlab. All rights reserved.
//

import SwiftUI
import Combine
import Alamofire
struct GroupListView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State var messageNotify: Bool = false
    @State var selection: Int? = nil
    @State var cellSelection: Int? = nil
    @State private var groupListCancellable: AnyCancellable?
    @State private var messageCancellable: AnyCancellable?
    @EnvironmentObject var settingStorage: SettingStorage
    @StateObject private var groupsModel = GroupsViewModel()
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            List(groupsModel.groups){ group in
                NavigationLink(tag: group.id, selection: $cellSelection) {
                    GroupDetailView(group)
                } label: {
                    Button {
                        self.cellSelection = group.id
                    } label: {
                        HStack{
                            Image((String(group.leaderId ?? -1) == settingStorage.userID) ? "leaderrr":"leaderlisticon")
                            VStack (alignment: .leading, spacing: 0){
                                Text(group.name)
                                    .font(.system(size: 20, weight: .medium, design: .default))
                                    .foregroundColor(.black)
                                Spacer(minLength: 3)
                                Text((String(group.leaderId ?? -1) == settingStorage.userID) ? "Leader".localized:"Member".localized)
                                    .font(.system(size: 16, weight: .light, design: .default))
                                    .foregroundColor(.black)
                            }
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            .navigationBarBackButtonHidden(true)
            .navigationTitle("Group list".localized)
            .navigationBarItems(leading: Button {
                UITableView.appearance().backgroundColor = UIColor(rgba: darkGreen)
                self.presentationMode.wrappedValue.dismiss()
            } label: {
                Text("back".localized)
            }, trailing: HStack {
                NavigationLink(tag: 1, selection: $selection) {
                    GroupMessageView()
                } label: {
                    Button {
                        self.selection = 1
                    } label: {
                        Image(systemName: "message.circle.fill")
                            .foregroundColor(messageNotify ? .red:.blue)
                    }
                }
                
                NavigationLink(tag: 2, selection: $selection) {
                    GroupSearchView()
                } label: {
                    Button(action: {
                        self.selection = 2
                    }) {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            })
            
            // Commented out Create Group functionality
            /*
            NavigationLink(tag: 3, selection: $selection) {
                GroupDetailView(Group(id: -1, name: "", leaderId: -1, info: ""))
            } label: {
                Button {
                    self.selection = 3
                } label: {
                    Text("Create a group".localized)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .foregroundColor(.white)
                        .background(Color.init(UIColor(rgba: lightGreen)))
                        .font(.system(size: 30, weight: .bold, design: .default))
                }
            }
            */
        }
        .onAppear {
            getGroupList()
            getGroupMessage()
            UITableView.appearance().backgroundColor = .white
        }
    }
}

extension GroupListView {
    func getGroupList() {
        let url = GroupGetUserGroupListUrl
        let parameters: [String: Any] = [
            "userId": Int(settingStorage.userID) ?? -1,
            "coiName": coi,
            "language": language
        ]
        
        print("API Call to: \(url)")
        print("Parameters: \(parameters)")
        
        let publisher: DataResponsePublisher<GroupLists> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters, addLogs: true)
        self.groupListCancellable = publisher
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
                    groupsModel.groups = results
                } else {
                    print("No results in response")
                }
            })
    }
    
    func getGroupMessage() {
        let url = GroupGetNotifiUrl
        let temp = """
        {
            "username":"\(settingStorage.account)"
        }
        """
        let parameters = ["notification":temp]
        let publisher: DataResponsePublisher<GroupMessage> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters, addLogs: true)
        self.messageCancellable = publisher
            .sink(receiveValue: { (values) in
                let message = values.value?.message ?? ""
                messageNotify = message == "have notification"
            })
    }
}

private class GroupsViewModel: ObservableObject {
    @Published var groups: [Group] = []
}
struct GroupManagement_Previews: PreviewProvider {
    static var previews: some View {
        GroupListView()
            .environmentObject(SettingStorage())
    }
}
