//
//  MeasurementChartView+ChartPagerView.swift
//  MeasurementChartsUI
//
//  Created by fcollf on 3/3/24.
//


import Foundation
import SwiftUI


extension MeasurementChartView {
    
    
    /// Component that enables horizontal paging through dynamic content with interactive swipe gestures.
    ///
    struct ChartPagerView<C: View>: View {
        
        
        // MARK: - Environment
        
        
        /// The environment object that provides the view model containing the state and logic
        @Environment(ViewModel.self) private var viewModel
        
        
        // MARK: - Private Properties
        
        
        /// Indicates the current scrolling state of the chart
        @Binding private var isScrolling: Bool
        
        /// The current index of the page being displayed
        @State private var index: Int = 1
        
        /// The animation effect used during page transitions.
        @State private var animation: Animation? = .interactiveSpring()
        
        /// Translation gesture
        @GestureState private var translation: CGFloat = 0
        
        /// Number of pages
        private let pageCount = 3
        
        /// The content to be displayed within the pager
        private let content: C
        
        
        // MARK: - Initializer
        
        
        /// Initializes a `ChartPagerView`.
        ///
        /// - Parameters:
        ///   - isScrolling: A binding to a boolean value provided by the caller, which will be updated by the pager to reflect its current scrolling state.
        ///   - content: A closure that returns the content to be displayed within the pager.
        ///
        init(isScrolling: Binding<Bool>, @ViewBuilder _ content: @escaping () -> C) {
            
            self._isScrolling = isScrolling
            self.content = content()
        }
        
        
        // MARK: - Body

        
        var body: some View {
            
            GeometryReader { geometry in
                
                HStack(alignment: .top, spacing: 0) {
                    
                    content
                        .frame(width: geometry.size.width)
                }
                .frame(width: geometry.size.width, alignment: .leading)
                .animation(animation, value: translation)
                .offset(x: -CGFloat(index) * geometry.size.width)
                .offset(x: translation)
                .simultaneousGesture(
                    
                    DragGesture().updating($translation) { value, state, transaction in
                        
                        state = value.translation.width
                        transaction.animation = .interactiveSpring
                        
                    }.onEnded { value in
                        
                        // Smooth animation at the end of the translation
                        animation = .smooth(duration: 0.25)
                        
                        // Updates to new index
                        let offset = value.translation.width / geometry.size.width
                        let newIndex = min(max(Int((CGFloat(index) - offset).rounded()),0), pageCount - 1)

                        if newIndex != index, viewModel.canMove(to: newIndex) {

                            index = newIndex
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                
                                // Notifies the model
                                viewModel.didMove(to: index)
                                
                                // Repositions the page in the middle
                                self.index = 1
                                
                                // Restores the animation for the drag gesture
                                animation = .interactiveSpring()
                            }
                            
                        } else {
                            
                            // Restores the animation for the drag gesture
                            animation = .interactiveSpring()
                        }
                    }
                )
                .onChange(of: translation) {
                    
                    isScrolling = translation != 0
                }
            }
        }
    }
}
