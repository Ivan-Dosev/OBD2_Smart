//
//  Utils.swift
//  OBD2_Smart
//
//  Created by Dosi Dimitrov on 28.01.24.
//

import SwiftUI

enum SetupError: Error {
  
    case invalidResponse
    case ignitionOff
}

enum OBDCommands : Identifiable ,Hashable , CaseIterable {
   
    case ATD
    case ATZ
    case ATE0
    case ATL0
    case ATS0
    case ATH0
    case ATDPN
    case ATSP
    case vin
    case distance

    
    var id: String { self.description}
    var hex : String {
        switch self {
            
        case .ATD:  return   "ATD"
        case .ATZ:  return   "ATZ"
        case .ATE0:  return  "ATE0"
        case .ATL0:  return  "ATL0"
        case .ATS0:  return  "ATS0"
        case .ATH0:  return  "ATH0"
        case .ATDPN: return  "ATDPN"
        case .ATSP:  return  "ATSP"
        case .vin:   return  "0902"
        case .distance: return "0131"
        }
    }
    
    var codeText : String {
        switch self {
        case .vin: return "090"
        case .distance: return "013"

        default: return "XYZ"
        }
    }
    
    var description : String {
        switch self {
            
        case .ATD: return "Set all defaults"
        case .ATZ: return "Reset OBD"
        case .ATE0: return "Eho off"
        case .ATL0: return "Line feed off"
        case .ATS0: return "Space off"
        case .ATH0: return "Headers off"
        case .ATDPN: return "View protocol"
        case .ATSP: return "Set protocol N"
        case .vin:   return "vin"
        case .distance: return "Distance since last clear"
        }
    }
    
    func  decodeFunc(item: String) -> String {
        
        switch self {
        case .vin:   return "vin"
        case .distance: return "\(Int(item, radix: 16) ?? 0)"
        default:  return ""
        }
    }

}

struct PrimaryButton: ViewModifier {

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    Color(red: 224 / 255, green: 229 / 255, blue: 236 / 255)
                    Circle()
                        .foregroundColor(.white)
                        .blur(radius: 4.0)
                        .offset(x: -8.0, y: -8.0) })
            .foregroundColor(.gray)
            .clipShape(Circle())

    }
}

struct Article: Identifiable {
    var id: String { title }
    let title: String
    let description: String
}
