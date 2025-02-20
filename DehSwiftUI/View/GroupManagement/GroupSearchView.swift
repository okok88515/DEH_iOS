import SwiftUI
import Combine
import Alamofire

struct GroupSearchView: View {
    @EnvironmentObject var settingStorage: SettingStorage
    @State var searchText: String = ""
    @State var reqAlertState: Bool = false
    @State var resAlertState: Bool = false
    @State var alertText: String = ""
    @State var selectedGroup: String = ""
    @State var groupNameList: [GroupName] = []
    @State private var cancellable: AnyCancellable?
    
    var body: some View {
        VStack {
            SearchBar(text: $searchText)
            List {
                ForEach(self.groupNameList) { groupName in
                    if(groupName.name.hasPrefix(searchText)) {
                        Button {
                            self.selectedGroup = groupName.name
                            self.reqAlertState = true
                            MemberApplyMessage()
                        } label: {
                            Text(groupName.name)
                        }
                        .alert(isPresented: $reqAlertState) { () -> Alert in
                            return Alert(
                                title: Text("Join".localized),
                                message: Text("Join".localized + "\(selectedGroup)?"),
                                primaryButton: .default(Text("Yes".localized),
                                                      action: { self.resAlertState = true }),
                                secondaryButton: .default(Text("No".localized), action: {})
                            )
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
        .onAppear { getGroupNameList() }
        .alert(isPresented: $resAlertState) {
            return Alert(
                title: Text(alertText.localized),
                dismissButton: .default(Text("OK".localized), action: {})
            )
        }
    }
}

extension GroupSearchView {
    func getGroupNameList() {
        print("[API] Starting group name list fetch")
        
        let parameters: [String: Any] = [
            "coiName": coi,
            "language": "中文"
        ]
        
        print("[API] Request URL: \(GroupGetListUrl)")
        print("[API] Parameters: \(parameters)")
        
        let publisher: DataResponsePublisher<GroupNameList> = NetworkConnector()
            .getDataPublisherDecodable(
                url: GroupGetListUrl,
                para: parameters,
                addLogs: true
            )
        
        self.cancellable = publisher
            .sink(receiveValue: { (values) in
                print("[API] Received response: \(values.debugDescription)")
                
                if let error = values.error {
                    print("[ERROR] Request failed: \(error)")
                    return
                }
                
                if let rawData = values.data {
                    print("[API] Raw response data: \(String(data: rawData, encoding: .utf8) ?? "Unable to decode")")
                }
                
                if let groups = values.value?.results {
                    print("[SUCCESS] Received \(groups.count) groups")
                    self.groupNameList = groups
                    print("[DATA] Updated group name list")
                } else {
                    print("[WARNING] No groups found in response")
                    self.groupNameList = []
                }
            })
    }
    
    func MemberApplyMessage() {
        print("[API] Starting member join request")
        let url = GroupMemberJoinUrl
        
        let temp = """
        {
            "sender_name": "\(settingStorage.account)",
            "group_name": "\(selectedGroup)"
        }
"""
        let parameters = ["join_info": temp]
        
        print("[API] Join request parameters: \(parameters)")
        
        let publisher: DataResponsePublisher<GroupMessage> = NetworkConnector()
            .getDataPublisherDecodable(
                url: url,
                para: parameters,
                addLogs: true
            )
        
        self.cancellable = publisher
            .sink(receiveValue: { (values) in
                print("[API] Received join response: \(values.debugDescription)")
                
                if let message = values.value?.message {
                    print("[SUCCESS] Join request message: \(message)")
                    self.alertText = message
                } else {
                    print("[WARNING] No message in join response")
                    self.alertText = "Error processing request"
                }
            })
    }
}

struct GroupSearchView_Previews: PreviewProvider {
    static var previews: some View {
        GroupSearchView()
            .environmentObject(SettingStorage())
    }
}
