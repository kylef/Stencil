import PathKit
import Spectre
import Stencil
import XCTest

final class InheritanceTests: XCTestCase {
  let path = Path(#file as String) + ".." + "fixtures"
  lazy var loader = FileSystemLoader(paths: [path])
  lazy var environment = Environment(loader: loader)

  func testInheritance() {
    it("can inherit from another template") {
      let template = try self.environment.loadTemplate(name: "child.html")
      try expect(try template.render()) == """
        Super_Header Child_Header
        Child_Body
        """
    }

    it("can inherit from another template inheriting from another template") {
      let template = try self.environment.loadTemplate(name: "child-child.html")
      try expect(try template.render()) == """
        Super_Header Child_Header Child_Child_Header
        Child_Body
        """
    }

    it("can inherit from a template that calls a super block") {
      let template = try self.environment.loadTemplate(name: "child-super.html")
      try expect(try template.render()) == """
        Header
        Child_Body
        """
    }

    it("can render block.super in if tag") {
      let template = try self.environment.loadTemplate(name: "if-block-child.html")

      try expect(try template.render(["sort": "new"])) == """
      Title - Nieuwste spellen

      """

      try expect(try template.render(["sort": "upcoming"])) == """
      Title - Binnenkort op de agenda

      """

      try expect(try template.render(["sort": "near-me"])) == """
      Title - In mijn buurt

      """
    }
  }
}
