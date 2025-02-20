import SwiftUI
import Alamofire
import Combine
import simd

struct GroupDetailView: View {
    @State var invitedMemberName: String = ""
    @State var textState: Bool = true
    @State var buttonState: Bool = true
    @State var buttonText: String = ""
    @State var editState: Bool = true
    @State var alertState: Bool = false
    @State var alertText: String = ""
    @State var groupInfo: String = ""
    var group: Group
    @State var description: String = ""
    @State var name: String = ""
    @State private var textStyle = UIFont.TextStyle.body
    @State private var cancellable: AnyCancellable?
    @State var groupMembers: [GroupMember] = []
    @EnvironmentObject var settingStorage: SettingStorage
    
    init(_ group: Group) {
        self.group = group
    }
    
    var body: some View {
        TabView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Group name:".localized)
                        .font(.system(size: 20, weight: .medium, design: .default))
                        .padding(.leading)
                        .padding(.top)
                    
                    TextField("", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .padding(.trailing)
                        .padding(.top)
                        .disabled(textState)
                }
                
                Text("Group information:".localized)
                    .font(.system(size: 20, weight: .medium, design: .default))
                    .textFieldStyle(.roundedBorder)
                    .padding(.top)
                    .padding(.leading)
                
                TextEditor(text: $description)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(lineWidth: 0.05))
                    .padding(.horizontal)
                    .padding(.top, 5)
                    .disabled(textState)
                
                Button {
                    if(isLeader()) {
                        if(editState) {
                            self.textState = false
                            buttonText = "Save".localized
                            self.editState = false
                        } else {
                            UpdateGroup()
                            self.editState = true
                            self.buttonText = "Edit".localized
                            self.textState = true
                            self.alertState = true
                        }
                    }
                } label: {
                    Text(buttonText)
                        .frame(minWidth: 50, minHeight: 30)
                        .font(.system(size: 20, weight: .regular, design: .default))
                        .padding(.horizontal)
                        .foregroundColor(.black)
                        .background(Color.orange)
                        .disabled(buttonState)
                        .hidden(buttonState)
                }
                .padding()
                .alert(isPresented: $alertState) { () -> Alert in
                    return Alert(title: Text(alertText), dismissButton: .default(Text("OK".localized), action: {}))
                }
            }
            .tabItem {
                Image("file")
                Text("Group info".localized)
            }
            .onAppear {
                groupInfo = group.info ?? ""
                description = group.info ?? ""
                name = group.name
                if(isLeader()) {
                    self.buttonState = false
                    buttonText = "Edit".localized
                }
            }
            
            VStack {
                HStack {
                    if(isLeader()) {
                        Text("Invite member:".localized)
                        TextField("", text: $invitedMemberName)
                            .textFieldStyle(.roundedBorder)
                        Button {
                            InviteGroupMember()
                            self.alertState = true
                        } label: {
                            Image(systemName: "plus.circle")
                                .foregroundColor(Color.init(UIColor(rgba: darkGreen)))
                                .padding(.trailing)
                        }
                        .alert(isPresented: $alertState) { () -> Alert in
                            return Alert(title: Text(alertText), dismissButton: .default(Text("OK".localized), action: {}))
                        }
                    }
                }
                .padding(.vertical)
                .padding(.leading)
                
                Text("Group member")
                    .font(.system(size: 20, weight: .bold, design: .default))
                
                List {
                    ForEach(self.groupMembers) { groupMember in
                        HStack {
                            Image(groupMember.memberRole == "leader" ? "leaderrr" : "leaderlisticon")
                            Text(groupMember.memberName)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .onAppear {
                    getGroupMemberList()
                }
            }
            .tabItem {
                Image("groupmember")
                Text("Group member".localized)
            }
        }
        .onAppear {
            addGroupCount()
        }
    }
}

extension GroupDetailView {
    func isLeader() -> Bool {
        if(settingStorage.userID == String(group.leaderId ?? -1)) { return true }
        else { return false }
    }
    
    /* Commented out create group functionality
    func isCreater() -> Bool {
        if(group.id == -1) { return true }
        else { return false }
    }
    
    func CreateGroup() {
        let url = GroupCreatUrl
        let temp = """
        {
            "group_name":"\(name)",
            "group_leader_name":"\(settingStorage.account)",
            "group_info":"\(description)",
            "language": "\(language)",
            "verification": "0",
            "open":"1",
            "coi_name":"\(coi)"
        }
"""
        print(temp)
        let parameters:[String:String] = ["group_information":temp]
        let publisher:DataResponsePublisher<GroupMessage> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters, addLogs: true)
        self.cancellable = publisher
            .sink(receiveValue: { (values) in
                print(values.debugDescription)
                alertText = values.value?.message.localized ?? ""
                self.alertState = true
            })
    }
    */
    
    func getGroupMemberList() {
        print("[API] Starting member list fetch for group: \(group.id)")
        
        let parameters: [String: Any] = [
            "groupId": group.id
        ]
        
        print("[API] Request URL: \(GroupGetMemberUrl)")
        print("[API] Parameters: \(parameters)")
        
        let publisher: DataResponsePublisher<GroupMemberList> = NetworkConnector()
            .getDataPublisherDecodable(
                url: GroupGetMemberUrl,
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
                
                if let members = values.value?.results {
                    print("[SUCCESS] Received \(members.count) group members")
                    self.groupMembers = members  // members already are GroupMember objects
                    print("[DATA] Processed member list")
                } else {
                    print("[WARNING] No members found in response")
                    self.groupMembers = []
                }
            })
    }
    
    func InviteGroupMember() {
        let url = GroupInviteUrl
        let temp = """
        {
            "sender_name":"\(settingStorage.account)",
            "receiver_name":"\(invitedMemberName)",
            "group_id":"\(group.id)",
            "message_type":"Invite",
            "coi_name":"\(coi)"
        }
        """
        let parameters = ["group_message_info": temp]
        let publisher: DataResponsePublisher<GroupMessage> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters, addLogs: true)
        self.cancellable = publisher
            .sink(receiveValue: { (values) in
                print(values.debugDescription)
                alertText = values.value?.message.localized ?? ""
            })
    }
    
    func UpdateGroup() {
        let url = GroupUpdateUrl
        let temp = [
            "group_name": "\(name)",
            "group_info": "\(description)",
            "group_id": "\(group.id)"
        ]
        
        let parameters = ["group_update_info": temp]
        let publisher: DataResponsePublisher<GroupMessage> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters, addLogs: true)
        self.cancellable = publisher
            .sink(receiveValue: { (values) in
                alertText = values.value?.message.localized ?? ""
            })
    }
    
    func addGroupCount() {
        let parameters: Parameters = [
            "user_id": settingStorage.userID,
            "ip": "127.0.0.1",
            "page": "/API/test/manage_group/\(group.id)"
        ]
        let url = addGroupCountUrl
        let publisher: DataResponsePublisher<Result> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters, addLogs: true)
        self.cancellable = publisher
            .sink(receiveValue: { (values) in
                print(values.value?.result ?? "")
            })
    }
}

struct GroupDetailView_Previews: PreviewProvider {
    static var previews: some View {
        GroupDetailView(Group(id: -1, name: "", leaderId: -1, info: ""))
            .environmentObject(SettingStorage())
    }
}
