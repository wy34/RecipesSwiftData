//
//  MainView.swift
//  RecipesSwiftData
//
//  Created by William Yeung on 6/20/23.
//

import SwiftUI
import SwiftData

// Previously
// @ObservableObject -> Whoever instantiates this can mark it as @StateObject

// iOS 17
// @Observable (replacing ObservableObject) -> Whoever instantiates this can mark it as @State
// @Binding -> A child view who needs to bind to a single value
// @Bindable -> A child view who needs to bind to an entire Observable object; replaces @ObservedObject

// When to use @State, @StateObject, or nothing in iOS 17
// @StateObject is gone
// @State when 2 way binding is needed ($)
// Nothing if its just a read-only situation

// MARK: - Variables
let placeholderColor = Color(#colorLiteral(red: 0.7848425508, green: 0.7855817676, blue: 0.7926406264, alpha: 1))

// MARK: - Models
// Relationships
// @Model
// class Category {
//     @Relationship(inverse: \Recipe.category) var recipes: [Recipe]
// }

@Model
class Recipe {
    @Attribute(.unique) var name: String
    var about: String
    var ingredients: [String]
    var instruction: String
    
    // Relationships if there is any
    // @Relationship var category: Category
    
    init(name: String, about: String, ingredients: [String], instruction: String) {
        self.name = name
        self.about = about
        self.ingredients = ingredients
        self.instruction = instruction
    }
}

// MARK: - Views
struct MainView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \.name, order: .forward) var allRecipes: [Recipe]
    
    @State private var beginAnimation = false
    @State private var showAddRecipeSheet = false

    @State private var newRecipeName = ""
    @State private var newRecipeAbout = ""
    @State private var newRecipeInstruction = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                if allRecipes.isEmpty {
                    ContentUnavailableView("You do not have any recipes saved yet. Press `+` to start.", systemImage: "fork.knife.circle")
                        .symbolEffect(.bounce, options: .repeating.speed(0.25), value: beginAnimation)
                } else {
                    List {
                        ForEach(allRecipes) { recipe in
                            NavigationLink(value: recipe) {
                                Text(recipe.name)
                            }
                        }
                            .onDelete(perform: { indexSet in
                                indexSet.forEach { modelContext.delete(allRecipes[$0]) }
                            })
                    }
                }
            }
                .navigationTitle("Recipes")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showAddRecipeSheet.toggle() }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showAddRecipeSheet) {
                    EditRecipeView()
                }
                .navigationDestination(for: Recipe.self, destination: { recipe in
                    RecipeDetailView(recipe: recipe)
                })
                .onAppear {
                    beginAnimation.toggle()
                }
        }
    }
}

struct EditRecipeView: View {
    private var recipe: Recipe?
    
    init(recipe: Recipe? = nil) {
        self.recipe = recipe
        
        if let recipe = recipe {
            _recipeName = State(initialValue: recipe.name)
            _recipeAbout = State(initialValue: recipe.about)
            _recipeInstruction = State(initialValue: recipe.instruction)
            _recipeIngredients = State(initialValue: recipe.ingredients)
        }
    }
    
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State private var recipeName = ""
    @State private var recipeAbout = ""
    @State private var recipeInstruction = ""
    @State private var singleRecipeIngredient = ""
    @State private var recipeIngredients = [String]()
    @FocusState var singleRecipeIngredientTextfieldFocus: Bool
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 3)
    
    var validForm: Bool {
        !recipeName.isEmpty && !recipeAbout.isEmpty && !recipeInstruction.isEmpty && !recipeIngredients.isEmpty
    }
    
    var navTitle: String {
        guard let _ = recipe else { return "New Recipe" }
        return "Edit Recipe"
    }
    
    var body: some View {
        NavigationStack {
                List {
                    Section {
                        TextField("Jumbo Breakfast Cookies", text: $recipeName)
                    } header: {
                        Text("Name")
                    }
                    
                    Section {
                        TextField("Extremely large cookies", text: $recipeAbout, axis: .vertical)
                    } header: {
                        Text("about")
                    }
                    
                    Section {
                        TextField("1. Make the dough", text: $recipeInstruction, axis: .vertical)
                    } header: {
                        Text("Instructions")
                    }
                    
                    Section {
                        TextField("Flour", text: $singleRecipeIngredient)
                            .focused($singleRecipeIngredientTextfieldFocus)
                            .onSubmit {
                                recipeIngredients.append(singleRecipeIngredient)
                                singleRecipeIngredient = ""
                                singleRecipeIngredientTextfieldFocus = true
                            }
                    } header: {
                        Text("Ingredients")
                    } footer: {
                        LazyVGrid(columns: columns) {
                            ForEach(recipeIngredients, id: \.self) { ingredient in
                                Text(ingredient)
                                    .foregroundStyle(.white)
                                    .padding()
                                    .background(.gray)
                                    .clipShape(.capsule)
                                    .multilineTextAlignment(.center)
                                    .overlay(alignment: .topTrailing) {
                                        if recipe != nil {
                                            Button(action: { deleteIngredient(ingredient) }) {
                                                Image(systemName: "xmark")
                                                    .padding()
                                                    .background(.red)
                                                    .clipShape(Circle())
                                                    .scaleEffect(0.5)
                                                    .offset(x: 15, y: -15)
                                            }
                                        } else {
                                            EmptyView()
                                        }
                                    }
                            }
                        }
                            .padding(.vertical)
                    }
                }
                    .overlay(alignment: .bottomTrailing) {
                        Button(action: {
                            if recipe != nil {
                                recipe?.name = recipeName
                                recipe?.about = recipeAbout
                                recipe?.ingredients = recipeIngredients
                                recipe?.instruction = recipeInstruction
                                dismiss()
                            } else {
                                let newRecipe = Recipe(name: recipeName, about: recipeAbout, ingredients: recipeIngredients, instruction: recipeInstruction)
                                modelContext.insert(newRecipe)
                                dismiss()
                            }
                        }) {
                            Text("Save")
                                .padding()
                                .foregroundStyle(.white)
                                .background(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding()
                        }
                            .disabled(!validForm)
                    }
                        .navigationTitle(navTitle)
                        .scrollDismissesKeyboard(.immediately)
        }
    }
    
    func deleteIngredient(_ ingredient: String) {
        if let index = recipeIngredients.firstIndex(of: ingredient) {
            recipeIngredients.remove(at: index)
        }
    }
}

struct RecipeDetailView: View {
    var recipe: Recipe
    @State private var showEditSheet = false
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 3)
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .padding()
                    .background(.gray)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(recipe.about)
                
                    
                    LazyVGrid(columns: columns) {
                        ForEach(recipe.ingredients, id: \.self) { ingredient in
                            Text(ingredient)
                                .foregroundStyle(.white)
                                .padding()
                                .background(.gray)
                                .clipShape(.capsule)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    Text(recipe.instruction)
                }
                    .padding()
            }
                .navigationTitle(recipe.name)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Edit") {
                            showEditSheet.toggle()
                        }
                    }
                }
                .sheet(isPresented: $showEditSheet) {
                    EditRecipeView(recipe: recipe)
                }
        }
    }
}

// MARK: - Preview
#Preview {
    MainView()
}
