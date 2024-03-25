//
//  MainView.swift
//  OBD2_Smart
//
//  Created by Dosi Dimitrov on 28.01.24.
//

import SwiftUI

struct MainView: View {
    
    var width : CGFloat = UIScreen.main.bounds.width
    var height : CGFloat = UIScreen.main.bounds.height
    @StateObject var vm = CoreBLE()
    @State var responce : String = ""
    
    @State private var showAlert = false
    @State private var article = Article(title: "OBD Smart", description: "Do you want a recording")
      
    
    var body: some View {
        ZStack {
           
            VStack {
                VStack {
                    VStack {
                        Text("OBD2")
                            .fontWeight(.heavy)
                            .padding(.horizontal)
                            .font(.system(size: 30))
                 
                        Text(vm.peripheral?.name ?? "")
                                .font(.system(size: 26))
                        Text(vm.characteristic?.uuid.uuidString ?? "")
                                .font(.system(size: 12))
                     //   ForEach(vm.km , id:\.self) { item in
                     //       Text("\(item)")
                     //   }

                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                    HStack{
                        Text("km: ")
                        Spacer()
                        Text("[ \(vm.kmString) ]")
                    }
                    .padding()
                    
                    HStack{
                        
                        Text("Vin:")
                        Spacer()
                        Text("[ \(responce) ]")
                            .onChange(of: responce) { res in
                                if !res.isEmpty {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                       showAlert = true
                                    }
                                }
                            }
                        
                    }
                    .padding(.horizontal)

                    Text("Vin: \(vm.vinString)")
                        .opacity(0)
                        .onChange(of: vm.kmString) { item in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                Task{
                                    self.responce =  try await vm.decode_VIN(response: vm.vinString)
                                    print("[\(responce)]")
                                }
                            }

                         
                        }
                   
                    

                   
                    VStack {

                        Text("status: \(vm.connected ?  "connected" : "disconnected" )")
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                        
                }
                .padding()
                .frame(width: width * 0.9, height: height * 0.5)
            
               
                .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
                
                if vm.connected {
                    
                    VStack{
                        Button(action: {
                            
                            Task{
                                do{
                                    
                                    try await vm.adapterInitialization()
                                    
                                }catch(let error){
                                    print("error: \(error)")
                                }
                            }
                            
                        }, label: {
                            Text(" RUN ")
                                .padding()
                                .frame(width: 100,height: 100)
                                .foregroundColor(.gray)
                                .fontWeight(.heavy)
                              
                                .modifier(PrimaryButton())
                            
                        })
                    }
                }

                Spacer()
                
                VStack {
                    Button(action: {
                        
                        if vm.connected {
                            
                            vm.disconnectPeripheral()
                            vm.kmString = ""
                            vm.vinString = ""
                            self.responce = ""
                           
                            
                        }else{
                            vm.connectTo(peripheral: vm.peripheral!)
                        }
                        
                    }, label: {
                        Text( vm.connected ?  "DISCONNECT" :"CONNECT" )
                            .foregroundColor(.white)
                            .font(.system(size: 30))
                    })
                    .disabled(!vm.isVisible)
                    .opacity(vm.isVisible ? 1 : 0)
                    
                    

                  
                }
                .padding()
                .frame(width: width * 0.9, height: height * 0.1)
                .background(RoundedRectangle(cornerRadius: 20).fill(vm.connected ?  .green : .red ))
                .overlay(content: {
                    if !vm.isVisible {
                        Text("Turn on your OBD2 device")
                            .foregroundColor(.white)
                    }
                })
            }
            .padding(.horizontal)
            if vm.isProgress {
                ProgressView()
                    .scaleEffect(3)
                    .offset(y: -150)
            }
        }
        .alert(article.title, isPresented: $showAlert, presenting: article) {article in
            Button("Ok") { }
            Button("Cancel", role: .cancel) {}
        } message: {article in
            Text(article.description)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
