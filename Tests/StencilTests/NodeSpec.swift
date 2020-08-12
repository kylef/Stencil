import Spectre
@testable import Stencil
import XCTest

class ErrorNode: NodeType {
  let token: Token?
  init(token: Token? = nil) {
    self.token = token
  }

  func render(_ context: Context) throws -> String {
    throw TemplateSyntaxError("Custom Error")
  }
}

final class NodeTests: XCTestCase {
  let context = Context(dictionary: [
    "name": "Kyle",
    "age": 27,
    "items": [1, 2, 3]
  ])

  func testTextNode() {
    it("renders the given text") {
      let node = TextNode(text: "Hello World")
      try expect(try node.render(self.context)) == "Hello World"
    }
    it("Trims leading whitespace") {
      let text = "      \n Some text     "
        let node = TextNode(text: text, trimBehavior: TrimBehavior(leading: .whitespace, trailing: .none))
        try expect(try node.render(self.context)) == "\n Some text     "
    }
    it("Trims leading whitespace and one newline") {
      let text = "\n\n Some text     "
        let node = TextNode(text: text, trimBehavior: TrimBehavior(leading: .whitespaceAndOneNewLine, trailing: .none))
        try expect(try node.render(self.context)) == "\n Some text     "
    }
    it("Trims leading whitespace and one newline") {
      let text = "\n\n Some text     "
        let node = TextNode(text: text, trimBehavior: TrimBehavior(leading: .whitespaceAndNewLines, trailing: .none))
        try expect(try node.render(self.context)) == "Some text     "
    }
    it("Trims trailing whitespace") {
      let text = "      Some text     \n"
        let node = TextNode(text: text, trimBehavior: TrimBehavior(leading: .none, trailing: .whitespace))
      try expect(try node.render(self.context)) == "      Some text\n"
    }
    it("Trims trailing whitespace and one newline") {
      let text = "      Some text     \n \n "
        let node = TextNode(text: text, trimBehavior: TrimBehavior(leading: .none, trailing: .whitespaceAndOneNewLine))
      try expect(try node.render(self.context)) == "      Some text     \n "
    }
    it("Trims trailing whitespace and newlines") {
      let text = "      Some text     \n \n "
        let node = TextNode(text: text, trimBehavior: TrimBehavior(leading: .none, trailing: .whitespaceAndNewLines))
      try expect(try node.render(self.context)) == "      Some text"
    }
    it("Trims all whitespace") {
      let text = "    \n  \nSome text \n    "
        let node = TextNode(text: text, trimBehavior: TrimBehavior(leading: .whitespaceAndNewLines, trailing: .whitespaceAndNewLines))
      try expect(try node.render(self.context)) == "Some text"
    }
  }

  func testVariableNode() {
    it("resolves and renders the variable") {
      let node = VariableNode(variable: Variable("name"))
      try expect(try node.render(self.context)) == "Kyle"
    }

    it("resolves and renders a non string variable") {
      let node = VariableNode(variable: Variable("age"))
      try expect(try node.render(self.context)) == "27"
    }
  }

  func testRendering() {
    it("renders the nodes") {
      let nodes: [NodeType] = [
        TextNode(text: "Hello "),
        VariableNode(variable: "name")
      ]

      try expect(try renderNodes(nodes, self.context)) == "Hello Kyle"
    }

    it("correctly throws a nodes failure") {
      let nodes: [NodeType] = [
        TextNode(text: "Hello "),
        VariableNode(variable: "name"),
        ErrorNode()
      ]

      try expect(try renderNodes(nodes, self.context)).toThrow(TemplateSyntaxError("Custom Error"))
    }
  }
}
