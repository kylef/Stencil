import Spectre
import Stencil
import XCTest

private struct CustomNode: NodeType {
  let token: Token?
  func render(_ context: Context) throws -> String {
    return "Hello World"
  }
}

private struct Article {
  let title: String
  let author: String
}

final class StencilTests: XCTestCase {
  lazy var environment: Environment = {
    let exampleExtension = Extension()
    exampleExtension.registerSimpleTag("simpletag") { _ in
      "Hello World"
    }
    exampleExtension.registerTag("customtag") { _, token in
      CustomNode(token: token)
    }
    return Environment(extensions: [exampleExtension])
  }()

  func testStencil() {
    it("can render the README example") {
      let templateString = """
        There are {{ articles.count }} articles.

        {% for article in articles %}\
            - {{ article.title }} by {{ article.author }}.
        {% endfor %}
        """

      let context = [
        "articles": [
          Article(title: "Migrating from OCUnit to XCTest", author: "Kyle Fuller"),
          Article(title: "Memory Management with ARC", author: "Kyle Fuller")
        ]
      ]

      let template = Template(templateString: templateString)
      let result = try template.render(object: context)

      try expect(result) == """
        There are 2 articles.

            - Migrating from OCUnit to XCTest by Kyle Fuller.
            - Memory Management with ARC by Kyle Fuller.

        """
    }

    it("can render a custom template tag") {
      let result = try self.environment.renderTemplate(string: "{% customtag %}")
      try expect(result) == "Hello World"
    }

    it("can render a simple custom tag") {
      let result = try self.environment.renderTemplate(string: "{% simpletag %}")
      try expect(result) == "Hello World"
    }
  }
}
