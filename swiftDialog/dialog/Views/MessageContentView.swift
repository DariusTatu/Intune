//
//  MessageContentView.swift
//  Dialog
//
//  Created by Reardon, Bart  on 19/3/21.
//

import Foundation
import SwiftUI
import MarkdownUI

struct MessageContent: View {

    @ObservedObject var observedData: DialogUpdatableContent
    @State private var messageHeight: CGFloat = 100

    var fieldPadding: CGFloat = 15
    var dataEntryMaxWidth: CGFloat = 700

    var messageColour: Color

    var iconDisplayWidth: CGFloat

    let theAllignment: Alignment = .topLeading

    init(observedDialogContent: DialogUpdatableContent) {
        writeLog("Displaying main message content")
        self.observedData = observedDialogContent
        if !observedDialogContent.args.iconOption.present { //cloptions.hideIcon.present {
            writeLog("Icon is hidden")
            fieldPadding = 30
            iconDisplayWidth = 0
        } else {
            fieldPadding = 20
            iconDisplayWidth = observedDialogContent.iconSize
        }
        messageColour = observedDialogContent.appProperties.messageFontColour
    }

    var body: some View {
        VStack {
            if observedData.args.centreIcon.present && observedData.args.iconOption.present {
                IconView(image: observedData.args.iconOption.value,
                         overlay: observedData.args.overlayIconOption.value,
                         alpha: observedData.iconAlpha)
                    .frame(width: iconDisplayWidth, alignment: .top)
                    .padding(.bottom, observedData.appProperties.bottomPadding)
                    .border(observedData.appProperties.debugBorderColour, width: 2)
                    .accessibilityHint(observedData.args.iconAccessabilityLabel.value)
            }

            if observedData.args.mainImage.present {
                ImageView(imageArray: observedData.imageArray, captionArray: observedData.appProperties.imageCaptionArray, autoPlaySeconds: observedData.args.autoPlay.value.floatValue())
            }

            if !["", "none"].contains(observedData.args.messageOption.value) {
                if ["centre", "center", "bottom"].contains(observedData.args.messageVerticalAlignment.value) {
                    Spacer()
                }

                GeometryReader { messageGeometry in
                        if observedData.args.eulaMode.present {
                            HStack {
                                List {
                                    Text(observedData.args.messageOption.value)
                                        .font(.system(size: 12, design: .monospaced))
                                        .background(GeometryReader {child -> Color in
                                            DispatchQueue.main.async {
                                                // update on next cycle with calculated height
                                                self.messageHeight = child.size.height
                                            }
                                            return Color.clear
                                        })
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .background(Color("editorBackgroundColour"))
                                .cornerRadius(5.0)
                            }
                        } else {
                            ScrollView {
                                Markdown(observedData.args.messageOption.value, baseURL: URL(string: "http://"))
                                    .frame(width: messageGeometry.size.width, alignment: observedData.appProperties.messagePosition)
                                    .multilineTextAlignment(observedData.appProperties.messageAlignment)
                                    .lineSpacing(2)
                                    .fixedSize()
                                    .background(GeometryReader {child -> Color in
                                        DispatchQueue.main.async {
                                            // update on next cycle with calculated height
                                            self.messageHeight = child.size.height
                                        }
                                        return Color.clear
                                    })
                                    .markdownTheme(.sdMarkdown)
                                    .markdownTextStyle {
                                        FontSize(appvars.messageFontSize)
                                        ForegroundColor(messageColour)
                                    }
                                    .accessibilityHint(observedData.args.messageOption.value)
                                    .focusable(false)
                                //.scrollOnOverflow()
                            }
                        }
                }
                .frame(maxHeight: messageHeight)
                if !observedData.args.messageVerticalAlignment.present || ["centre", "center", "top"].contains(observedData.args.messageVerticalAlignment.value) {
                    Spacer()
                }
            }

            Group {
                TextFileView(logFilePath: observedData.args.logFileToTail.value)
                    .padding(.bottom, observedData.appProperties.contentPadding)
                WebContentView(observedDialogContent: observedData, url: observedData.args.webcontent.value)
                    .border(observedData.appProperties.debugBorderColour, width: 2)
                    .padding(.bottom, observedData.appProperties.contentPadding)

                ListView(observedDialogContent: observedData)
                    .border(observedData.appProperties.debugBorderColour, width: 2)
                    .padding(.bottom, observedData.appProperties.contentPadding)

                CheckboxView(observedDialogContent: observedData)
                    .border(observedData.appProperties.debugBorderColour, width: 2)
                    .frame(maxWidth: dataEntryMaxWidth)

                TextEntryView(observedDialogContent: observedData, textfieldContent: userInputState.textFields)
                    .padding(.bottom, observedData.appProperties.contentPadding)
                    .border(observedData.appProperties.debugBorderColour, width: 2)
                    .frame(maxWidth: dataEntryMaxWidth)

                RadioView(observedDialogContent: observedData)
                    .padding(.bottom, observedData.appProperties.contentPadding)
                    .border(observedData.appProperties.debugBorderColour, width: 2)
                    .frame(maxWidth: dataEntryMaxWidth)

                DropdownView(observedDialogContent: observedData)
                    .padding(.bottom, observedData.appProperties.contentPadding)
                    .border(observedData.appProperties.debugBorderColour, width: 2)
                    .frame(maxWidth: dataEntryMaxWidth, alignment: .leading)
            }

            if ["top"].contains(observedData.args.messageVerticalAlignment.value) {
                Spacer()
            }
            if observedData.appProperties.userInputRequired {
                HStack {
                    Spacer()
                    Text("required-note")
                        .font(.system(size: 10)
                                .weight(.light))
                }
            }
        }
        .padding(.leading, observedData.appProperties.sidePadding)
        .padding(.trailing, observedData.appProperties.sidePadding)
        .padding(.top, observedData.appProperties.topPadding)
        .textSelection(.enabled)
    }
}

struct PriorityView<Content: View>: View {
    private var content: () -> Content
    private var priority: Int

    init(priority: Int, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.priority = priority
    }

    var body: some View {
        EmptyView()
            .overlay(content())
            .zIndex(Double(priority))
    }
}
