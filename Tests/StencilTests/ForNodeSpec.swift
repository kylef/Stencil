import Spectre
@testable import Stencil
import Foundation


func testForNode() {
  describe("ForNode") {
    let context = Context(dictionary: [
      "items": [1, 2, 3],
      "emptyItems": [Int](),
      "dict": [
        "one": "I",
        "two": "II",
      ]
    ])

    $0.it("renders the given nodes for each item") {
      let nodes: [NodeType] = [VariableNode(variable: "item")]
      let node = ForNode(resolvable: Variable("items"), loopVariables: ["item"], nodes: nodes, emptyNodes: [])
      try expect(try node.render(context)) == "123"
    }

    $0.it("renders the given empty nodes when no items found item") {
      let nodes: [NodeType] = [VariableNode(variable: "item")]
      let emptyNodes: [NodeType] = [TextNode(text: "empty")]
      let node = ForNode(resolvable: Variable("emptyItems"), loopVariables: ["item"], nodes: nodes, emptyNodes: emptyNodes)
      try expect(try node.render(context)) == "empty"
    }

    $0.it("renders a context variable of type Array<Any>") {
      let any_context = Context(dictionary: [
        "items": ([1, 2, 3] as [Any])
      ])

      let nodes: [NodeType] = [VariableNode(variable: "item")]
      let node = ForNode(resolvable: Variable("items"), loopVariables: ["item"], nodes: nodes, emptyNodes: [])
      try expect(try node.render(any_context)) == "123"
    }

    $0.it("renders a context variable of type CountableClosedRange<Int>") {
      let context = Context(dictionary: ["range": 1...3])
      let nodes: [NodeType] = [VariableNode(variable: "item")]
      let node = ForNode(resolvable: Variable("range"), loopVariables: ["item"], nodes: nodes, emptyNodes: [])

      try expect(try node.render(context)) == "123"
    }

    $0.it("renders a context variable of type CountableRange<Int>") {
      let context = Context(dictionary: ["range": 1..<4])
      let nodes: [NodeType] = [VariableNode(variable: "item")]
      let node = ForNode(resolvable: Variable("range"), loopVariables: ["item"], nodes: nodes, emptyNodes: [])

      try expect(try node.render(context)) == "123"
    }

#if os(OSX)
    $0.it("renders a context variable of type NSArray") {
      let nsarray_context = Context(dictionary: [
        "items": NSArray(array: [1, 2, 3])
      ])

      let nodes: [NodeType] = [VariableNode(variable: "item")]
      let node = ForNode(resolvable: Variable("items"), loopVariables: ["item"], nodes: nodes, emptyNodes: [])
      try expect(try node.render(nsarray_context)) == "123"
    }
#endif

    $0.it("renders the given nodes while providing if the item is first in the context") {
      let nodes: [NodeType] = [VariableNode(variable: "item"), VariableNode(variable: "forloop.first")]
      let node = ForNode(resolvable: Variable("items"), loopVariables: ["item"], nodes: nodes, emptyNodes: [])
      try expect(try node.render(context)) == "1true2false3false"
    }

    $0.it("renders the given nodes while providing if the item is last in the context") {
      let nodes: [NodeType] = [VariableNode(variable: "item"), VariableNode(variable: "forloop.last")]
      let node = ForNode(resolvable: Variable("items"), loopVariables: ["item"], nodes: nodes, emptyNodes: [])
      try expect(try node.render(context)) == "1false2false3true"
    }

    $0.it("renders the given nodes while providing item counter") {
      let nodes: [NodeType] = [VariableNode(variable: "item"), VariableNode(variable: "forloop.counter")]
      let node = ForNode(resolvable: Variable("items"), loopVariables: ["item"], nodes: nodes, emptyNodes: [])
      try expect(try node.render(context)) == "112233"
    }

    $0.it("renders the given nodes while providing item counter") {
      let nodes: [NodeType] = [VariableNode(variable: "item"), VariableNode(variable: "forloop.counter0")]
      let node = ForNode(resolvable: Variable("items"), loopVariables: ["item"], nodes: nodes, emptyNodes: [])
      try expect(try node.render(context)) == "102132"
    }

    $0.it("renders the given nodes while filtering items using where expression") {
        let nodes: [NodeType] = [VariableNode(variable: "item"), VariableNode(variable: "forloop.counter")]
        let `where` = try parseExpression(components: ["item", ">", "1"], tokenParser: TokenParser(tokens: [], environment: Environment()))
        let node = ForNode(resolvable: Variable("items"), loopVariables: ["item"], nodes: nodes, emptyNodes: [], where: `where`)
        try expect(try node.render(context)) == "2132"
    }

    $0.it("renders the given empty nodes when all items filtered out with where expression") {
        let nodes: [NodeType] = [VariableNode(variable: "item")]
        let emptyNodes: [NodeType] = [TextNode(text: "empty")]
        let `where` = try parseExpression(components: ["item", "==", "0"], tokenParser: TokenParser(tokens: [], environment: Environment()))
        let node = ForNode(resolvable: Variable("emptyItems"), loopVariables: ["item"], nodes: nodes, emptyNodes: emptyNodes, where: `where`)
        try expect(try node.render(context)) == "empty"
    }

    $0.it("can render a filter") {
      let templateString = "{% for article in ars|default:articles %}" +
        "- {{ article.title }} by {{ article.author }}.\n" +
        "{% endfor %}\n"

      let context = Context(dictionary: [
        "articles": [
          Article(title: "Migrating from OCUnit to XCTest", author: "Kyle Fuller"),
          Article(title: "Memory Management with ARC", author: "Kyle Fuller"),
        ]
      ])

      let template = Template(templateString: templateString)
      let result = try template.render(context)

      let fixture = "" +
        "- Migrating from OCUnit to XCTest by Kyle Fuller.\n" +
        "- Memory Management with ARC by Kyle Fuller.\n" +
        "\n"

      try expect(result) == fixture
    }

    $0.it("can iterate over dictionary") {
      let templateString = "{% for key,value in dict %}" +
        "{{ key }}: {{ value }}," +
        "{% endfor %}"

      let template = Template(templateString: templateString)
      let result = try template.render(context)

      let sortedResult = result.characters.split(separator: ",").map(String.init).sorted(by: <)
      try expect(sortedResult) == ["one: I", "two: II"]
    }

    $0.it("renders supports iterating over dictionary") {
      let nodes: [NodeType] = [
        VariableNode(variable: "key"),
        TextNode(text: ","),
      ]
      let emptyNodes: [NodeType] = [TextNode(text: "empty")]
      let node = ForNode(resolvable: Variable("dict"), loopVariables: ["key"], nodes: nodes, emptyNodes: emptyNodes, where: nil)
      let result = try node.render(context)

      let sortedResult = result.characters.split(separator: ",").map(String.init).sorted(by: <)
      try expect(sortedResult) == ["one", "two"]
    }

    $0.it("renders supports iterating over dictionary") {
      let nodes: [NodeType] = [
        VariableNode(variable: "key"),
        TextNode(text: "="),
        VariableNode(variable: "value"),
        TextNode(text: ","),
      ]
      let emptyNodes: [NodeType] = [TextNode(text: "empty")]
      let node = ForNode(resolvable: Variable("dict"), loopVariables: ["key", "value"], nodes: nodes, emptyNodes: emptyNodes, where: nil)

      let result = try node.render(context)

      let sortedResult = result.characters.split(separator: ",").map(String.init).sorted(by: <)
      try expect(sortedResult) == ["one=I", "two=II"]
    }

    $0.it("handles invalid input") {
      let tokens: [Token] = [
          .block(value: "for i"),
      ]
      let parser = TokenParser(tokens: tokens, environment: Environment())
      let error = TemplateSyntaxError("'for' statements should use the following 'for x in y where condition' `for i`.")
      try expect(try parser.parse()).toThrow(error)
    }

    $0.it("can iterate over struct properties") {
      struct MyStruct {
        let string: String
        let number: Int
      }

      let context = Context(dictionary: [
        "struct": MyStruct(string: "abc", number: 123)
      ])

      let nodes: [NodeType] = [
        VariableNode(variable: "property"),
        TextNode(text: "="),
        VariableNode(variable: "value"),
        TextNode(text: "\n"),
      ]
      let node = ForNode(resolvable: Variable("struct"), loopVariables: ["property", "value"], nodes: nodes, emptyNodes: [])
      let result = try node.render(context)

      try expect(result) == "string=abc\nnumber=123\n"
    }

    $0.it("can iterate tuple items") {
      let context = Context(dictionary: [
        "tuple": (one: 1, two: "dva"),
      ])

      let nodes: [NodeType] = [
        VariableNode(variable: "label"),
        TextNode(text: "="),
        VariableNode(variable: "value"),
        TextNode(text: "\n"),
      ]

      let node = ForNode(resolvable: Variable("tuple"), loopVariables: ["label", "value"], nodes: nodes, emptyNodes: [])
      let result = try node.render(context)

      try expect(result) == "one=1\ntwo=dva\n"
    }

    $0.it("can iterate over class properties") {
      class MyClass {
        var baseString: String
        var baseInt: Int
        init(_ string: String, _ int: Int) {
          baseString = string
          baseInt = int
        }
      }

      class MySubclass: MyClass {
        var childString: String
        init(_ childString: String, _ string: String, _ int: Int) {
          self.childString = childString
          super.init(string, int)
        }
      }

      let context = Context(dictionary: [
        "class": MySubclass("child", "base", 1)
      ])

      let nodes: [NodeType] = [
        VariableNode(variable: "label"),
        TextNode(text: "="),
        VariableNode(variable: "value"),
        TextNode(text: "\n"),
      ]

      let node = ForNode(resolvable: Variable("class"), loopVariables: ["label", "value"], nodes: nodes, emptyNodes: [])
      let result = try node.render(context)

      try expect(result) == "childString=child\nbaseString=base\nbaseInt=1\n"
    }

    
    $0.it("can break from loop") {
      let templateString = "{% for item in items %}" +
        "{{ item }}{% break %}\n" +
      "{% endfor %}\n"
      
      let template = Template(templateString: templateString)
      let result = try template.render(context)
      
      try expect(result) == "1\n"
    }
    
    $0.it("can break from inner node") {
      let templateString = "{% for item in items %}" +
        "{{ item }}" +
        "{% if forloop.first %}<{% break %}>{% endif %}!" +
      "{% endfor %}\n"
      
      let template = Template(templateString: templateString)
      let result = try template.render(context)
      
      try expect(result) == "1<\n"
    }
    
    $0.it("does not allow break outside loop") {
      let template = Template(templateString: "{% for item in items %}{% endfor %}{% break %}")
      try expect(template.render(context)).toThrow(TemplateSyntaxError("'break' can be used only inside loop body"))
    }
    
    $0.it("can continue loop") {
      let templateString = "{% for item in items %}" +
        "{{ item }}\n{% continue %}!" +
      "{% endfor %}\n"
      
      let template = Template(templateString: templateString)
      let result = try template.render(context)
      
      try expect(result) == "1\n2\n3\n\n"
    }
    
    $0.it("can continue from inner node") {
      let templateString = "{% for item in items %}" +
        "{% if forloop.last %}<{% continue %}>{% endif %}!" +
        "{{ item }}" +
      "{% endfor %}\n"
      
      let template = Template(templateString: templateString)
      let result = try template.render(context)
      
      try expect(result) == "!1!2<\n"
    }

    $0.it("does not allow continue outside loop") {
      let templateString = "{% for item in items %}" +
        "{{ item }}\n" +
        "{% endfor %}\n" + "{% continue %}"
      let template = Template(templateString: templateString)
      
      try expect(template.render(context)).toThrow(TemplateSyntaxError("'continue' can be used only inside loop body"))
    }

    $0.context("given nested loops") {
      
      $0.it("breaks outer loop") {
        let template = Template(templateString: "{% for item in items %}" +
          "outer: {{ item }}\n" +
          "{% for item in items %}" +
          "inner: {{ item }}\n" +
          "{% endfor %}" +
          "{% break %}" +
          "{% endfor %}\n")
        
        try expect(template.render(context)) == "outer: 1\ninner: 1\ninner: 2\ninner: 3\n\n"
      }
      
      $0.it("breaks inner loop") {
        let template = Template(templateString: "{% for item in items %}" +
          "outer: {{ item }}\n" +
          "{% for item in items %}" +
          "inner: {{ item }}\n" +
          "{% break %}" +
          "{% endfor %}" +
          "{% endfor %}\n")
        
        try expect(template.render(context)) == "outer: 1\ninner: 1\nouter: 2\ninner: 1\nouter: 3\ninner: 1\n\n"
      }

      $0.it("continues outer loop") {
        let template = Template(templateString: "{% for item in items %}" +
          "{% for item in items %}" +
          "inner: {{ item }}\n" +
          "{% endfor %}" +
          "{% continue %}" +
          "outer: {{ item }}\n" +
          "{% endfor %}\n")
        
        try expect(template.render(context)) == "inner: 1\ninner: 2\ninner: 3\ninner: 1\ninner: 2\ninner: 3\ninner: 1\ninner: 2\ninner: 3\n\n"
      }
      
      $0.it("continues inner loop") {
        let template = Template(templateString: "{% for item in items %}" +
          "{% for item in items %}" +
          "{% continue %}" +
          "inner: {{ item }}\n" +
          "{% endfor %}" +
          "outer: {{ item }}\n" +
          "{% endfor %}\n")
        
        try expect(template.render(context)) == "outer: 1\nouter: 2\nouter: 3\n\n"
      }

      $0.context("given labeled loop") {

        $0.it("can access labeled outer loop context from inner loop") {
          let template = Template(templateString: "{% outer: for item in items %}" +
            "{% for item in items %}" +
            "{{ forloop.counter }}-{{ forloop.outer.counter }}\n" +
            "{% endfor %}" +
            "{% endfor %}\n")

          try expect(template.render(context)) == "1-1\n2-1\n3-1\n1-2\n2-2\n3-2\n1-3\n2-3\n3-3\n\n"
        }

        $0.it("breaks labeled loop") {
          let template = Template(templateString: "{% outer: for item in items %}" +
            "outer: {{ item }}\n" +
            "{% for item in items %}" +
            "{% break outer %}" +
            "inner: {{ item }}\n" +
            "{% endfor %}" +
            "{% endfor %}\n")

          try expect(template.render(context)) == "outer: 1\n\n"
        }

        $0.it("continues labeled loop") {
          let template = Template(templateString: "{% outer: for item in items %}" +
            "{% for item in items %}" +
            "inner: {{ item }}\n" +
            "{% continue outer %}" +
            "{% endfor %}" +
            "outer: {{ item }}\n" +
            "{% endfor %}\n")

          try expect(template.render(context)) == "inner: 1\ninner: 1\ninner: 1\n\n"
        }

        $0.it("throws when breaking with unknown label") {
          let template = Template(templateString: "{% outer: for item in items %}" +
            "{% break inner %}" +
            "{% endfor %}\n")

          try expect(template.render(context)).toThrow()
        }

        $0.it("throws when continuing with unknown label") {
          let template = Template(templateString: "{% outer: for item in items %}" +
            "{% continue inner %}" +
            "{% endfor %}\n")

          try expect(template.render(context)).toThrow()
        }

      }
    }
    
  }

}


fileprivate struct Article {
  let title: String
  let author: String
}
