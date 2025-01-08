//
//  NLProcessor.swift
//  WatchAI Watch App
//
//  Created by Rafat Nami, Sasan on 08.01.25.
//

import NaturalLanguage
import Foundation

/// Utility-Klasse für die Verarbeitung natürlicher Sprache.
final class NLProcessor {

    /// Führt eine Sentiment-Analyse auf einem Text durch.
    static func analyzeSentiment(for text: String) -> String {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text

        // Extrahiere den Sentiment-Score
        let (sentimentScore, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)

        // Konvertiere den Score in einen Double-Wert
        guard let scoreString = sentimentScore?.rawValue, let score = Double(scoreString) else {
            return "neutral"
        }

        // Rückgabe basierend auf dem Score
        if score > 0.2 {
            return "positiv"
        } else if score < -0.2 {
            return "negativ"
        } else {
            return "neutral"
        }
    }


    /// Führt Named Entity Recognition (NER) durch und gibt erkannte Entitäten zurück.
    static func extractEntities(from text: String) -> [String: [String]] {
        var entities: [String: [String]] = ["Person": [], "Place": [], "Organization": []]
        
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: [.omitPunctuation, .omitWhitespace]) { tag, tokenRange in
            if let tag = tag {
                let entity = tag.rawValue
                entities[entity, default: []].append(String(text[tokenRange]))
            }
            return true
        }
        
        return entities
    }

    /// Erkennt die Sprache des gegebenen Textes.
    static func detectLanguage(for text: String) -> String {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage?.rawValue ?? "unknown"
    }

    /// Extrahiert Schlüsselwörter aus einem Text.
    static func extractKeywords(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = text
        
        var keywords: [String] = []
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lemma, options: [.omitPunctuation, .omitWhitespace]) { _, tokenRange in
            keywords.append(String(text[tokenRange]))
            return true
        }
        
        return keywords
    }
}
