//
//  SpeciesSearchView.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 10/21/25.
//

import SwiftUI

struct SpeciesSearchView: View {
    @ObservedObject private var viewModel: SpeciesViewModel
    @State private var searchText: String = ""
    @State private var lastSearchLength: Int = 0
    private let onSpeciesSelected: (SpeciesData) -> Void
    
    init(vm: SpeciesViewModel, onSpeciesSelected: @escaping (SpeciesData) -> Void) {
        self.viewModel = vm
        self.onSpeciesSelected = onSpeciesSelected
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Species list or no results message
                if viewModel.state.species.isEmpty && !viewModel.state.loading {
                    Text("No species were found. Try modifying your search.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List {
                        ForEach(viewModel.state.species, id: \.englishName) { species in
                            VStack(alignment: .leading) {
                                Text(species.englishName)
                                    .font(.headline)
                                if let scientificName = species.scientificName, !scientificName.isEmpty {
                                    Text(scientificName)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .onTapGesture {
                                onSpeciesSelected(species)
                            }
                            .onAppear {
                                // Check if this is the last item to trigger next page fetch
                                if species.scientificName == viewModel.state.species.last?.scientificName {
                                    viewModel.fetchNextPage(query: searchText)
                                }
                            }
                        }
                        
                        // Loading indicator at the bottom
                        if viewModel.state.loading {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Spacer()
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search species...")
            .onChange(of: searchText) { newValue in
                let characterCount = newValue.count
                // Trigger search after 3 characters or every 2 additional characters
                if characterCount >= 3 && (characterCount == 3 || (characterCount > 3 && (characterCount - lastSearchLength) >= 2)) {
                    viewModel.resetAndFetch(query: newValue)
                    lastSearchLength = characterCount
                }
            }
            .navigationTitle("Species Search")
            .snackBar(isPresented: Binding(get: {
                viewModel.state.errorMessage != nil
            }, set: { _ in
                // no op
            }), type: .error, message: viewModel.state.errorMessage ?? "Something went wrong. Please try again later.")
        }
    }
}

struct SpeciesSearchView_Previews: PreviewProvider {
    static var previews: some View {
        SpeciesSearchView(vm: SpeciesViewModel()) { _ in }
    }
}
