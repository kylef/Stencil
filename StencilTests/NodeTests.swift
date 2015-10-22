import Foundation
import XCTest
@testable import Stencil


class ErrorNode : NodeType {
  func render(context: Context) throws -> String {
    throw TemplateSyntaxError("Custom Error")
  }
}

class NodeTests: XCTestCase {
  var context:Context!

  override func setUp() {
    context = Context(dictionary: [
      "name": "Kyle",
      "age": 27,
      "items": [1,2,3],
      ])
  }
}

class TextNodeTests: NodeTests {
  func testTextNodeResolvesText() {
    let node = TextNode(text:"Hello World")
    XCTAssertEqual(try? node.render(context), "Hello World")
  }
}

class VariableNodeTests: NodeTests {
  func testVariableNodeResolvesVariable() {
    let node = VariableNode(variable:Variable("name"))
    XCTAssertEqual(try? node.render(context), "Kyle")
  }

  func testVariableNodeResolvesNonStringVariable() {
    let node = VariableNode(variable:Variable("age"))
    XCTAssertEqual(try? node.render(context), "27")
  }
}

class RenderNodeTests: NodeTests {
  func testRenderingNodes() {
    let nodes = [TextNode(text:"Hello "), VariableNode(variable: "name")] as [NodeType]
    XCTAssertEqual(try? renderNodes(nodes, context), "Hello Kyle")
  }

  func testRenderingNodesWithFailure() {
    let nodes = [TextNode(text:"Hello "), VariableNode(variable: "name"), ErrorNode()] as [NodeType]

    assertFailure(try renderNodes(nodes, context), TemplateSyntaxError("Custom Error"))
  }
}

class ForNodeTests: NodeTests {
  func testParseFor() {
    let tokens = [
      Token.Block(value: "for item in items"),
      .Text(value: "\nan item\n"),
      .Block(value: "endfor"),
      .Text(value: "\nthe end\n")
    ]
    
    let parser = TokenParser(tokens: tokens)
    assertSuccess(try parser.parse()) { nodes in
      XCTAssertEqual(nodes.count, 2)
      let forNode = nodes[0] as! ForNode
      XCTAssertEqual(forNode.variable, Variable("items"))
      XCTAssertEqual(forNode.loopVariable, "item")
      XCTAssertEqual(forNode.nodes.count, 1)
      let loopNode = forNode.nodes[0] as? TextNode
      XCTAssertEqual(loopNode?.text, "an item\n")
      let textNode = nodes[1] as! TextNode
      XCTAssertEqual(textNode.text, "the end\n")
    }
  }
  
  func testForNodeRender() {
    let node = ForNode(variable: "items", loopVariable: "item", nodes: [VariableNode(variable: "item")], emptyNodes:[])
    XCTAssertEqual(try? node.render(context), "123")
  }
}

class IfNodeTests: NodeTests {

  // MARK: Parsing

  func testParseIf() {
    let tokens = [
      Token.Block(value: "if value"),
      Token.Text(value: "\ntrue"),
      Token.Block(value: "else"),
      Token.Text(value: "\nfalse"),
      Token.Block(value: "endif")
    ]

    let parser = TokenParser(tokens: tokens)
    assertSuccess(try parser.parse()) { nodes in
      let node = nodes.first as! IfNode
      let trueNode = node.trueNodes.first as! TextNode
      let falseNode = node.falseNodes.first as! TextNode

      XCTAssertEqual(nodes.count, 1)
      XCTAssertEqual(node.variable.variable, "value")
      XCTAssertEqual(node.trueNodes.count, 1)
      XCTAssertEqual(trueNode.text, "true")
      XCTAssertEqual(node.falseNodes.count, 1)
      XCTAssertEqual(falseNode.text, "false")
    }
  }

  func testParseIfNot() {
    let tokens = [
      Token.Block(value: "ifnot value"),
      Token.Text(value: "\nfalse"),
      Token.Block(value: "else"),
      Token.Text(value: "\ntrue"),
      Token.Block(value: "endif")
    ]

    let parser = TokenParser(tokens: tokens)
    assertSuccess(try parser.parse()) { nodes in
      let node = nodes.first as! IfNode
      let trueNode = node.trueNodes.first as! TextNode
      let falseNode = node.falseNodes.first as! TextNode

      XCTAssertEqual(nodes.count, 1)
      XCTAssertEqual(node.variable.variable, "value")
      XCTAssertEqual(node.trueNodes.count, 1)
      XCTAssertEqual(trueNode.text, "true")
      XCTAssertEqual(node.falseNodes.count, 1)
      XCTAssertEqual(falseNode.text, "false")
    }
  }

  func testParseIfWithoutEndIfError() {
    let tokens = [
      Token.Block(value: "if value"),
    ]

    let parser = TokenParser(tokens: tokens)
    assertFailure(try parser.parse(), TemplateSyntaxError("`endif` was not found."))
  }

  func testParseIfNotWithoutEndIfError() {
    let tokens = [
      Token.Block(value: "ifnot value"),
    ]

    let parser = TokenParser(tokens: tokens)
    assertFailure(try parser.parse(), TemplateSyntaxError("`endif` was not found."))
  }

  // MARK: Rendering

  func testIfNodeRenderTruth() {
    let node = IfNode(variable: "items", trueNodes: [TextNode(text: "true")], falseNodes: [TextNode(text: "false")])
    XCTAssertEqual(try? node.render(context), "true")
  }

  func testIfNodeRenderFalse() {
    let node = IfNode(variable: "unknown", trueNodes: [TextNode(text: "true")], falseNodes: [TextNode(text: "false")])
    XCTAssertEqual(try? node.render(context), "false")
  }

}

class NowNodeTests: NodeTests {

  // MARK: Parsing

  func testParseDefaultNow() {
    let tokens = [ Token.Block(value: "now") ]
    let parser = TokenParser(tokens: tokens)

    assertSuccess(try parser.parse()) { nodes in
      let node = nodes.first as! NowNode
      XCTAssertEqual(nodes.count, 1)
      XCTAssertEqual(node.format.variable, "\"yyyy-MM-dd 'at' HH:mm\"")
    }
  }

  func testParseNowWithFormat() {
    let tokens = [ Token.Block(value: "now \"HH:mm\"") ]
    let parser = TokenParser(tokens: tokens)

    assertSuccess(try parser.parse()) { nodes in
      let node = nodes.first as! NowNode
      XCTAssertEqual(nodes.count, 1)
      XCTAssertEqual(node.format.variable, "\"HH:mm\"")
    }
  }

  // MARK: Rendering

  func testRenderNowNode() {
    let node = NowNode(format: Variable("\"yyyy-MM-dd\""))

    let formatter = NSDateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let date = formatter.stringFromDate(NSDate())

    XCTAssertEqual(try? node.render(context), date)
  }
}
