import Foundation

struct Lexer {
  let templateName: String?
  let templateString: String

  init(templateName: String? = nil, templateString: String) {
    self.templateName = templateName
    self.templateString = templateString
  }

  func createToken(string: String, at range: Range<String.Index>) -> Token {
    func strip() -> String {
      guard string.count > 4 else { return "" }
      let start = string.index(string.startIndex, offsetBy: 2)
      let end = string.index(string.endIndex, offsetBy: -2)
      let trimmed = String(string[start..<end])
        .components(separatedBy: "\n")
        .filter({ !$0.isEmpty })
        .map({ $0.trim(character: " ") })
        .joined(separator: " ")
      return trimmed
    }

    if string.hasPrefix("{{") || string.hasPrefix("{%") || string.hasPrefix("{#") {
      let value = strip()
      let range = templateString.range(of: value, range: range) ?? range
      let line = templateString.rangeLine(range)
      let sourceMap = SourceMap(filename: templateName, line: line)

      if string.hasPrefix("{{") {
        return .variable(value: value, at: sourceMap)
      } else if string.hasPrefix("{%") {
        return .block(value: value, at: sourceMap)
      } else if string.hasPrefix("{#") {
        return .comment(value: value, at: sourceMap)
      }
    }

    let line = templateString.rangeLine(range)
    let sourceMap = SourceMap(filename: templateName, line: line)
    return .text(value: string, at: sourceMap)
  }

  /// Returns an array of tokens from a given template string.
  func tokenize() -> [Token] {
    var tokens: [Token] = []

    let scanner = Scanner(templateString)

    let map = [
      "{{": "}}",
      "{%": "%}",
      "{#": "#}",
    ]
    //let startTokens = ["{{", "{%", "{#"]
    let tokenChars:[Unicode.Scalar] = ["{", "%", "#"]

    while !scanner.isEmpty {
      if let text = scanner.scanForTokenStart(tokenChars) {
        if !text.1.isEmpty {
          tokens.append(createToken(string: text.1, at: scanner.range))
        }

        let end = map[text.0]!
        let result = scanner.scan(until: end, returnUntil: true)
        tokens.append(createToken(string: result, at: scanner.range))
      } else {
        tokens.append(createToken(string: scanner.content, at: scanner.range))
        scanner.content = ""
      }
    }

    return tokens
  }

}

class Scanner {
  let originalContent: String
  var content: String
  var range: Range<String.Index>

  init(_ content: String) {
    self.originalContent = content
    self.content = content
    range = content.startIndex..<content.startIndex
  }

  var isEmpty: Bool {
    return content.isEmpty
  }

  func scan(until: String, returnUntil: Bool = false) -> String {
    guard let first = until.unicodeScalars.first else {
      return ""
    }

    var index = 0;
    for char in content.unicodeScalars {
      if char == first {
        //Check the rest
        let startIndex = content.startIndex.advanced(by: index)
        if String(content[startIndex..<content.startIndex.advanced(by: index + until.count)]) == until {
          let result = String(content[..<startIndex])
          content = String(content[startIndex...])
          if returnUntil {
            content = String(content[content.startIndex.advanced(by: until.count)...])
            return result + until
          }
          return result
        }
      }
      index += 1
    }

    content = ""
    return ""
  }
  func scan(until: [String]) -> (String, String)? {
    if until.isEmpty {
      return nil
    }

    var index = 0;
    for char in content.unicodeScalars {
      for string in until {
        if string.unicodeScalars.first == char {
          let startIndex = content.startIndex.advanced(by: index)
          let endIndex = content.startIndex.advanced(by: index + string.count)
          if endIndex > content.endIndex {
            continue;
          }
          if String(content[startIndex..<endIndex]) == string {
            let result = String(content[..<startIndex])
            content = String(content[startIndex...])
            return (string, result)
          }
        }
      }
      index += 1
    }

    return nil;
  }
  func scanForTokenStart(_ tokenChars:[Unicode.Scalar]) -> (String, String)? {
    var foundBrace = false
    var index = 0;
    for char in content.unicodeScalars {
      if foundBrace {
        let string:String
        if tokenChars.contains(char) {
          string = "{\(char)"
        } else {
          foundBrace = false
          index += 2
          continue;
        }
        let startIndex = content.startIndex.advanced(by: index)
        let result = String(content[..<startIndex])
        content = String(content[startIndex...])
        return (string, result)
      } else {
        if char == "{" {
          //Check next char
          foundBrace = true
        } else {
          index += 1
        }
      }
    }    
    return nil;
  }
}


extension String {
  func findFirstNot(character: Character) -> String.Index? {
    var index = startIndex

    while index != endIndex {
      if character != self[index] {
        return index
      }
      index = self.index(after: index)
    }

    return nil
  }

  func findLastNot(character: Character) -> String.Index? {
    var index = self.index(before: endIndex)

    while index != startIndex {
      if character != self[index] {
        return self.index(after: index)
      }
      index = self.index(before: index)
    }

    return nil
  }

  func trim(character: Character) -> String {
    let first = findFirstNot(character: character) ?? startIndex
    let last = findLastNot(character: character) ?? endIndex
    return String(self[first..<last])
  }

  public func rangeLine(_ range: Range<String.Index>) -> RangeLine {
    var lineNumber: UInt = 0
    var offset: Int = 0
    var lineContent = ""

    for line in components(separatedBy: CharacterSet.newlines) {
      lineNumber += 1
      lineContent = line
      if let rangeOfLine = self.range(of: line), rangeOfLine.contains(range.lowerBound) {
        offset = distance(from: rangeOfLine.lowerBound, to: range.lowerBound)
        break
      }
    }

    return (lineContent, lineNumber, offset)
  }
}

public typealias RangeLine = (content: String, number: UInt, offset: Int)
