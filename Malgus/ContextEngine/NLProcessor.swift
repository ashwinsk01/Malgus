//
//  NLProcessor.swift
//  Malgus
//
//  Created by Ashwin SK on 30/03/2025.
//

import Foundation
import NaturalLanguage

class NLProcessor {
    func extractKeywords(from text: String) async -> [String] {
        guard !text.isEmpty else { return [] }
        
        let tagger = NLTagger(tagSchemes: [.nameType, .lemma])
        tagger.string = text
        
        var keywords = [String: Int]()
        
        // Set options for tokenization
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
        
        // Tag the text for parts of speech
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
            if let tag = tag {
                let token = String(text[tokenRange])
                
                // Only include nouns, verbs, and adjectives as keywords
                if tag == .noun || tag == .verb || tag == .adjective {
                    // Exclude common stop words
                    if !isStopWord(token) && token.count > 2 {
                        keywords[token.lowercased(), default: 0] += 1
                    }
                }
            }
            return true
        }
        
        // Sort keywords by frequency
        let sortedKeywords = keywords.sorted { $0.value > $1.value }.prefix(10)
        
        return sortedKeywords.map { $0.key }
    }
    
    func generateSummary(from text: String, activities: [Activity]) async -> String {
        // If there's no text, create a basic summary based on activities
        if text.isEmpty {
            return generateBasicSummary(from: activities)
        }
        
        // Extract sentences using NLTokenizer
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        
        var sentences = [String]()
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = String(text[range])
            sentences.append(sentence)
            return true
        }
        
        // If we have too few sentences, return them all
        if sentences.count <= 2 {
            return sentences.joined(separator: " ")
        }
        
        // For simplicity, take the first and last sentence as summary
        // In a full implementation, we would use a more sophisticated summarization algorithm
        let summary = [sentences.first, sentences.last].compactMap { $0 }.joined(separator: " ")
        
        // If summary is too short, generate a basic one
        if summary.count < 20 {
            return generateBasicSummary(from: activities)
        }
        
        return summary
    }
    
    private func generateBasicSummary(from activities: [Activity]) -> String {
        // Group activities by application
        let groupedActivities = Dictionary(grouping: activities) { $0.application }
        
        // Build a summary based on application usage
        let appSummaries = groupedActivities.map { app, acts in
            "\(acts.count) activities in \(app)"
        }
        
        if appSummaries.isEmpty {
            return "No significant activity detected"
        }
        
        return "User performed " + appSummaries.joined(separator: ", ")
    }
    
    private func isStopWord(_ word: String) -> Bool {
        let stopWords = ["the", "and", "a", "to", "of", "is", "in", "that", "it", "with", "as", "for", "on", "was", "be", "at", "this", "by", "are", "or", "an", "but", "not", "from"]
        return stopWords.contains(word.lowercased())
    }
}
