public func until(_ tags: [String]) -> ((TokenParser, Token) -> Bool) {
  return { parser, token in
    if let name = token.components().first {
      for tag in tags {
        if name == tag {
          return true
        }
      }
    }

    return false
  }
}


/// A class for parsing an array of tokens and converts them into a collection of Node's
public class TokenParser {
  public typealias TagParser = (TokenParser, Token) throws -> NodeType

  fileprivate var tokens: [Token]
  fileprivate let environment: Environment

  public init(tokens: [Token], environment: Environment) {
    self.tokens = tokens
    self.environment = environment
  }

  /// Parse the given tokens into nodes
  public func parse() throws -> [NodeType] {
    return try parse(nil)
  }

  public func parse(_ parse_until:((_ parser:TokenParser, _ token:Token) -> (Bool))?) throws -> [NodeType] {
    var nodes = [NodeType]()

    while tokens.count > 0 {
      let token = nextToken()!

      switch token {
      case .text(let text, _):
        nodes.append(TextNode(text: text))
      case .variable:
        let filter = try compileFilter(token.contents, containedIn: token)
        nodes.append(VariableNode(variable: filter, token: token))
      case .block:
        if let parse_until = parse_until , parse_until(self, token) {
          prependToken(token)
          return nodes
        }

        if let tag = token.components().first {
          do {
            let parser = try findTag(name: tag)
            let node = try parser(self, token)
            nodes.append(node)
          } catch {
            if var error = error as? TemplateSyntaxError {
              error.token = error.token ?? token
              throw error
            } else {
              throw error
            }
          }
        }
      case .comment:
        continue
      }
    }

    return nodes
  }

  public func nextToken() -> Token? {
    if tokens.count > 0 {
      return tokens.remove(at: 0)
    }

    return nil
  }

  public func prependToken(_ token:Token) {
    tokens.insert(token, at: 0)
  }

  func findTag(name: String) throws -> Extension.TagParser {
    for ext in environment.extensions {
      if let filter = ext.tags[name] {
        return filter
      }
    }

    throw TemplateSyntaxError("Unknown template tag '\(name)'")
  }

  func findFilter(_ name: String) throws -> FilterType {
    for ext in environment.extensions {
      if let filter = ext.filters[name] {
        return filter
      }
    }

    throw TemplateSyntaxError("Unknown filter '\(name)'")
  }

  public func compileFilter(_ filterToken: String, containedIn containingToken: Token) throws -> Resolvable {
    do {
      return try FilterExpression(token: filterToken, parser: self)
    } catch {
      if var error = error as? TemplateSyntaxError, error.token == nil {
        // find offset of filter in the containing token so that only filter is highligted, not the whole token
        if let filterTokenRange = containingToken.contents.range(of: filterToken) {
          var rangeLine = containingToken.sourceMap.line
          rangeLine.offset += containingToken.contents.distance(from: containingToken.contents.startIndex, to: filterTokenRange.lowerBound)
          error.token = .variable(value: filterToken, at: SourceMap(filename: containingToken.sourceMap.filename, line: rangeLine))
        } else {
          error.token = containingToken
        }
        throw error
      } else {
        throw error
      }
    }
  }

  @available(*, deprecated, message: "Use compileFilter(_:containedIn:)")
  public func compileFilter(_ token: String) throws -> Resolvable {
    return try FilterExpression(token: token, parser: self)
  }

}
