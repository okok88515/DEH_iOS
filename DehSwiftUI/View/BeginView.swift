//
//  BeginView.swift
//  DehSwiftUI
//
//  Created by 廖偉博 on 2022/11/6.
//  Copyright © 2023 mmlab. All rights reserved.
//

import SwiftUI
import Combine
import Alamofire

struct BeginView: View {
    
    @EnvironmentObject var settingStorage:SettingStorage
//    @State var groupSelectedOver: Bool = false
    @State var searchText:String = ""
    @Binding var selectOverState:Bool
//    @State var resAlertState:Bool = false
    @State var alertText:String = ""
    @Binding var region:Field
//    @State var groupList:[Group] = []
    @State var regionList:[Field] = []
    @State private var cancellable: AnyCancellable?
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        VStack {
            //            NavigationView{
//            NavigationLink(destination: ContentView(), isActive: self.$selectOverState) { EmptyView() }
            SearchBar(text: $searchText)
            List {
                ForEach(self.regionList) { region in
                    if(region.name.hasPrefix(searchText)) {
                        Button {
                            self.region = region
                            self.selectOverState = true
                            self.presentationMode.wrappedValue.dismiss()
                        } label: {
                            Text(region.name)
                        }
//                        .alert(isPresented: $reqAlertState) { () -> Alert in
//                            return Alert(title: Text("Join".localized),
//                                         message: Text("Join".localized + "\(selectedGroup)?"),
//                                         primaryButton: .default(Text("Yes".localized),
//                                                                 action: {             self.resAlertState = true
//                                self.groupSelectedOver = true}),
//                                         secondaryButton: .default(Text("No".localized), action: {}))
//                        }
                    }
                }
            }
            .listStyle(PlainListStyle())

            //            }
        }
        .onAppear { getFieldList() }
    }
}

extension BeginView {
    func getFieldList() {
        let url = FieldGetAllListUrl
        print(settingStorage.account)
        let parameters = ["coi_name":coi, "language":"中文"]
        let publisher:DataResponsePublisher<FieldList> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters)
        self.cancellable = publisher
            .sink(receiveValue: {(values) in
                print(values.debugDescription)
                self.regionList = values.value?.results ?? []
            })
    }
}

struct FieldList:Decodable{
    let results:[Field]
}

struct BeginView_Previews: PreviewProvider {
    static var previews: some View {
        GroupSearchView()
    }
}

