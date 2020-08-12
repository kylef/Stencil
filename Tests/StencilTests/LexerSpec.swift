import PathKit
import Spectre
@testable import Stencil
import XCTest

final class LexerTests: XCTestCase {
  func testText() throws {
    let lexer = Lexer(templateString: "Hello World")
    let tokens = lexer.tokenize()

    try expect(tokens.count) == 1
    try expect(tokens.first) == .text(value: "Hello World", at: makeSourceMap("Hello World", for: lexer))
  }

  func testComment() throws {
    let lexer = Lexer(templateString: "{# Comment #}")
    let tokens = lexer.tokenize()

    try expect(tokens.count) == 1
    try expect(tokens.first) == .comment(value: "Comment", at: makeSourceMap("Comment", for: lexer))
  }

  func testVariable() throws {
    let lexer = Lexer(templateString: "{{ Variable }}")
    let tokens = lexer.tokenize()

    try expect(tokens.count) == 1
    try expect(tokens.first) == .variable(value: "Variable", at: makeSourceMap("Variable", for: lexer))
  }

  func testTokenWithoutSpaces() throws {
    let lexer = Lexer(templateString: "{{Variable}}")
    let tokens = lexer.tokenize()

    try expect(tokens.count) == 1
    try expect(tokens.first) == .variable(value: "Variable", at: makeSourceMap("Variable", for: lexer))
  }

  func testUnclosedTag() throws {
    let templateString = "{{ thing"
    let lexer = Lexer(templateString: templateString)
    let tokens = lexer.tokenize()

    try expect(tokens.count) == 1
    try expect(tokens.first) == .text(value: "", at: makeSourceMap("{{ thing", for: lexer))
  }

  func testContentMixture() throws {
    let templateString = "My name is {{ myname }}."
    let lexer = Lexer(templateString: templateString)
    let tokens = lexer.tokenize()

    try expect(tokens.count) == 3
    try expect(tokens[0]) == Token.text(value: "My name is ", at: makeSourceMap("My name is ", for: lexer))
    try expect(tokens[1]) == Token.variable(value: "myname", at: makeSourceMap("myname", for: lexer))
    try expect(tokens[2]) == Token.text(value: ".", at: makeSourceMap(".", for: lexer))
  }

  func testVariablesWithoutBeingGreedy() throws {
    let templateString = "{{ thing }}{{ name }}"
    let lexer = Lexer(templateString: templateString)
    let tokens = lexer.tokenize()

    try expect(tokens.count) == 2
    try expect(tokens[0]) == Token.variable(value: "thing", at: makeSourceMap("thing", for: lexer))
    try expect(tokens[1]) == Token.variable(value: "name", at: makeSourceMap("name", for: lexer))
  }

  func testUnclosedBlock() throws {
    let lexer = Lexer(templateString: "{%}")
    _ = lexer.tokenize()
  }

  func testTokenizeIncorrectSyntaxWithoutCrashing() throws {
    let lexer = Lexer(templateString: "func some() {{% if %}")
    _ = lexer.tokenize()
  }

  func testEmptyVariable() throws {
    let lexer = Lexer(templateString: "{{}}")
    _ = lexer.tokenize()
  }

  func testNewlines() throws {
    let templateString = """
      My name is {%
          if name
           and
          name
      %}{{
      name
      }}{%
      endif %}.
      """
    let lexer = Lexer(templateString: templateString)
    let tokens = lexer.tokenize()

    try expect(tokens.count) == 5
    try expect(tokens[0]) == Token.text(value: "My name is ", at: makeSourceMap("My name is", for: lexer))
    try expect(tokens[1]) == Token.block(value: "if name and name", at: makeSourceMap("{%", for: lexer))
    try expect(tokens[2]) == Token.variable(value: "name", at: makeSourceMap("name", for: lexer, options: .backwards))
    try expect(tokens[3]) == Token.block(value: "endif", at: makeSourceMap("endif", for: lexer))
    try expect(tokens[4]) == Token.text(value: ".", at: makeSourceMap(".", for: lexer))
  }

  func testTrimSymbols() throws {

    let fBlock = "if hello"
    let sBlock = "ta da"
    let lexer = Lexer(templateString: "{%+ \(fBlock) -%}{% \(sBlock) -%}")
    let tokens = lexer.tokenize()
    let whitespaceBehaviors = (WhitespaceBehavior(leading: .keep, trailing: .trim), WhitespaceBehavior(leading: .unspecified, trailing: .trim))

    try expect(tokens.count) == 2
    try expect(tokens[0]) == Token.block(value: fBlock, at: makeSourceMap(fBlock, for: lexer), whitespace: whitespaceBehaviors.0)
    try expect(tokens[1]) == Token.block(value: sBlock, at: makeSourceMap(sBlock, for: lexer), whitespace: whitespaceBehaviors.1)
  }

  func testEscapeSequence() throws {
    let templateString = "class Some {{ '{' }}{% if true %}{{ stuff }}{% endif %}"
    let lexer = Lexer(templateString: templateString)
    let tokens = lexer.tokenize()

    try expect(tokens.count) == 5
    try expect(tokens[0]) == Token.text(value: "class Some ", at: makeSourceMap("class Some ", for: lexer))
    try expect(tokens[1]) == Token.variable(value: "'{'", at: makeSourceMap("'{'", for: lexer))
    try expect(tokens[2]) == Token.block(value: "if true", at: makeSourceMap("if true", for: lexer))
    try expect(tokens[3]) == Token.variable(value: "stuff", at: makeSourceMap("stuff", for: lexer))
    try expect(tokens[4]) == Token.block(value: "endif", at: makeSourceMap("endif", for: lexer))
  }

  func testPerformance() throws {
    let path = Path(#file as String) + ".."  + "fixtures" + "huge.html"
    let content: String = try path.read()

    measure {
      let lexer = Lexer(templateString: content)
      _ = lexer.tokenize()
    }
  }

  func testCombiningDiaeresis() throws {
    // the symbol "ü" in the `templateString` is unusually encoded as 0x75 0xCC 0x88 (LATIN SMALL LETTER U + COMBINING DIAERESIS) instead of 0xC3 0xBC (LATIN SMALL LETTER U WITH DIAERESIS)
    let templateString = "ü\n{% if test %}ü{% endif %}\n{% if ü %}ü{% endif %}\n"
    let lexer = Lexer(templateString: templateString)
    let tokens = lexer.tokenize()

    try expect(tokens.count) == 9
    assert(tokens[1].contents == "if test")
  }

  private func makeSourceMap(_ token: String, for lexer: Lexer, options: String.CompareOptions = []) -> SourceMap {
    guard let range = lexer.templateString.range(of: token, options: options) else { fatalError("Token not found") }
    return SourceMap(location: lexer.rangeLocation(range))
  }
}
