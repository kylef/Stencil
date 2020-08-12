import Spectre
@testable import Stencil
import XCTest

final class TokenParserTests: XCTestCase {
  func testTokenParser() {
    it("can parse a text token") {
      let parser = TokenParser(tokens: [
        .text(value: "Hello World", at: .unknown)
      ], environment: Environment())

      let nodes = try parser.parse()
      let node = nodes.first as? TextNode

      try expect(nodes.count) == 1
      try expect(node?.text) == "Hello World"
    }

    it("can parse a variable token") {
      let parser = TokenParser(tokens: [
        .variable(value: "'name'", at: .unknown)
      ], environment: Environment())

      let nodes = try parser.parse()
      let node = nodes.first as? VariableNode
      try expect(nodes.count) == 1
      let result = try node?.render(Context())
      try expect(result) == "name"
    }

    it("can parse a comment token") {
      let parser = TokenParser(tokens: [
        .comment(value: "Secret stuff!", at: .unknown)
      ], environment: Environment())

      let nodes = try parser.parse()
      try expect(nodes.count) == 0
    }

    it("can parse a tag token") {
      let simpleExtension = Extension()
      simpleExtension.registerSimpleTag("known") { _ in
        ""
      }

      let parser = TokenParser(tokens: [
        .block(value: "known", at: .unknown)
      ], environment: Environment(extensions: [simpleExtension]))

      let nodes = try parser.parse()
      try expect(nodes.count) == 1
    }

    it("errors when parsing an unknown tag") {
      let tokens: [Token] = [.block(value: "unknown", at: .unknown)]
      let parser = TokenParser(tokens: tokens, environment: Environment())

      try expect(try parser.parse()).toThrow(TemplateSyntaxError(
        reason: "Unknown template tag 'unknown'",
        token: tokens.first)
      )
    }

    it("transforms WhitespaceBehavior to TrimBehaviour") {

      let simpleExtension = Extension()
      simpleExtension.registerSimpleTag("known") { _ in
        return ""
      }

      let parser = TokenParser(tokens: [
        Token.block(value: "known", at: .unknown, whitespace: WhitespaceBehavior(leading: .unspecified, trailing: .trim)),
        Token.text(value: "      \nSome text     ", at: .unknown),
        Token.block(value: "known", at: .unknown, whitespace: WhitespaceBehavior(leading: .keep, trailing: .trim))
      ], environment: Environment(extensions: [simpleExtension]))

      let nodes = try parser.parse()
      try expect(nodes.count) == 3
      let textNode = nodes[1] as? TextNode
      try expect(textNode?.text) == "      \nSome text     "
      try expect(textNode?.trimBehavior) == TrimBehavior(leading: .whitespaceAndNewLines, trailing: .none)
    }
  }
}
