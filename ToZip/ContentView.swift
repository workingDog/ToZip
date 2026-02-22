//
//  ContentView.swift
//  ToZip
//
//  Created by Ringo Wathelet on 2026/02/22.
//
import SwiftUI


struct ContentView: View {
    var body: some View {
#if os(iOS)
        ContentViewIOS()
#else
        ContentViewMAC()
#endif
        
    }
}
