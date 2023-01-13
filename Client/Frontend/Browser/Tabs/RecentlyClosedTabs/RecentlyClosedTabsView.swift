// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import Shared
import BraveShared
import Data
import CoreData
import BraveUI
import BraveCore

struct RecentlyClosedTabsView: View {
  @Environment(\.presentationMode) @Binding private var presentationMode

  @State var recentlyClosedTabs: [RecentlyClosed] = []
  @State private var recentlyClosedLoading = true
  
  @State private var showClearDataPrompt: Bool = false
  var onDismiss: ((Bool) -> Void)?
  var onRecentlyClosedSelected: ((RecentlyClosed) -> Void)?
  
  private let tabManager: TabManager?

  private var clearAllDataButton: some View {
    Button(Strings.RecentlyClosed.recentlyClosedClearActionTitle, action: {
      showClearDataPrompt = true
    })
    .accessibility(label: Text(Strings.RecentlyClosed.recentlyClosedClearActionConfirmation))
    .foregroundColor(Color(.braveBlurpleTint))
    .actionSheet(isPresented: $showClearDataPrompt) {
      .init(title: Text(Strings.RecentlyClosed.recentlyClosedClearActionConfirmation),
        buttons: [
          .destructive(Text(Strings.RecentlyClosed.recentlyClosedClearActionTitle), action: {
            RecentlyClosed.removeAll()
            dismissView(cleared: true)
          }),
          .cancel()
        ]
      )
    }
  }
  
  private var doneButton: some View {
    Button(Strings.done, action: {
      dismissView()
    })
    .foregroundColor(Color(.braveBlurpleTint))
  }
  
  private var websitesList: some View {
    List {
      Section {
        ForEach(recentlyClosedTabs, id: \.url) { recentlyClosed in
          Button(action: {
            dismissView()
            onRecentlyClosedSelected?(recentlyClosed)
          }) {
            HStack {
              FaviconImage(url: recentlyClosed.url)  
              VStack(alignment: .leading) {
                Text(recentlyClosed.title ?? "")
                  .font(.footnote)
                  .fontWeight(.semibold)
                  .foregroundColor(Color(.bravePrimary))
                  .lineLimit(1)
                Text("\(URLFormatter.formatURL(recentlyClosed.url))")
                  .font(.caption)
                  .foregroundColor(Color(.braveLabel))
                  .lineLimit(1)
              }
              Spacer()
            }
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 6)
          .accessibilityElement()
          .accessibilityLabel(recentlyClosed.title ?? "")
        }
        .onDelete { indexSet in
          // Delete an individual info from recently closed
          let tabsToRemove = indexSet.map { recentlyClosedTabs[$0] }
          withAnimation(.default) {
            for tab in tabsToRemove {
              RecentlyClosed.remove(with: tab.url)
            }
          }
        }
      }
      .listRowBackground(Color(.secondaryBraveGroupedBackground))
    }
    .environment(\.defaultMinListHeaderHeight, 0)
    .listStyle(.insetGrouped)
    .listBackgroundColor(Color(UIColor.braveGroupedBackground))
  }
  
  init(tabManager: TabManager? = nil) {
    self.tabManager = tabManager
  }
  
  var body: some View {
    NavigationView {
        VStack(spacing: 0) {
          if recentlyClosedLoading {
            ProgressView()
              .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
          } else {
            if recentlyClosedTabs.isEmpty {
              Text(Strings.RecentlyClosed.recentlyClosedEmptyListTitle)
                .font(.headline)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(.bravePrimary))
                .padding(.horizontal, 20)
            } else {
              websitesList
            }
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.braveGroupedBackground).ignoresSafeArea())
        .navigationTitle(Strings.RecentlyClosed.recentlyClosedTabsScreenTitle)
        .navigationBarTitleDisplayMode(.inline)
        .osAvailabilityModifiers { content in
          if #available(iOS 15.0, *) {
            content
              .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                  doneButton
                }
                ToolbarItem(placement: .cancellationAction) {
                  clearAllDataButton
                }
              }
          } else {
            content
              .navigationBarItems(leading: clearAllDataButton, trailing: doneButton)
          }
        }
    }
    .navigationViewStyle(.stack)
    .environment(\.managedObjectContext, DataController.swiftUIContext)
    .onAppear {
      tabManager?.deleteOutdatedRecentlyClosed()
      recentlyClosedTabs = RecentlyClosed.all()
      recentlyClosedLoading = false
    }
  }
  
  private func dismissView(cleared: Bool = false) {
    presentationMode.dismiss()
    onDismiss?(cleared)
  }
}