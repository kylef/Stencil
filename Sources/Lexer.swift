struct Lexer {
  let fileName: String?
  let templateString: String

  init(fileName: String?, templateString: String) {
    self.fileName = fileName
    self.templateString = templateString
  }

  func createToken(string: String, sourceMap: SourceMap) -> Token {
    func strip() -> String {
      let start = string.index(string.startIndex, offsetBy: 2)
      let end = string.index(string.endIndex, offsetBy: -2)
      return string[start..<end].trim(character: " ")
    }

    if string.hasPrefix("{{") {
      return .variable(value: strip(), sourceMap: sourceMap)
    } else if string.hasPrefix("{%") {
      return .block(value: strip(), sourceMap: sourceMap)
    } else if string.hasPrefix("{#") {
      return .comment(value: strip(), sourceMap: sourceMap)
    }

    return .text(value: string, sourceMap: sourceMap)
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

    // TODO compute sm
    let sm = SourceMap(fileName: fileName, start: templateString.startIndex, end: templateString.endIndex)

    while !scanner.isEmpty {
      if let text = scanner.scan(until: ["{{", "{%", "{#"]) {
        if !text.1.isEmpty {
          tokens.append(createToken(string: text.1, sourceMap: sm))
        }

        let end = map[text.0]!
        let result = scanner.scan(until: end, returnUntil: true)
        tokens.append(createToken(string: result, sourceMap: sm))
      } else {
        tokens.append(createToken(string: scanner.content, sourceMap: sm))
        scanner.content = ""
      }
    }

    return tokens
  }
}


class Scanner {
  var content: String

  init(_ content: String) {
    self.content = content
  }

  var isEmpty: Bool {
    return content.isEmpty
  }

  func scan(until: String, returnUntil: Bool = false) -> String {
    if until.isEmpty {
      return ""
    }

    var index = content.startIndex
    while index != content.endIndex {
      let substring = content.substring(from: index)

      if substring.hasPrefix(until) {
        let result = content.substring(to: index)
        content = substring

        if returnUntil {
          content = content.substring(from: until.endIndex)
          return result + until
        }

        return result
      }

      index = content.index(after: index)
    }

    content = ""
    return ""
  }

  func scan(until: [String]) -> (String, String)? {
    if until.isEmpty {
      return nil
    }

    var index = content.startIndex
    while index != content.endIndex {
      let substring = content.substring(from: index)
      for string in until {
        if substring.hasPrefix(string) {
          let result = content.substring(to: index)
          content = substring
          return (string, result)
        }
      }

      index = content.index(after: index)
    }

    return nil
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
    return self[first..<last]
  }
}
