import Spectre
import Stencil
import PathKit


func testInheritence() {
  describe("Inheritence") {
    let path = Path(#file) + ".." + "fixtures"
    let loader = FileSystemLoader(paths: [path])
    let environment = Environment(loader: loader)

    $0.it("can inherit from another template") {
      let template = try environment.loadTemplate(name: "child.html")
      try expect(try template.render()) == """
        Super_Header Child_Header
        Child_Body
        """
    }

    $0.it("can inherit from another template inheriting from another template") {
      let template = try environment.loadTemplate(name: "child-child.html")
      try expect(try template.render()) == """
        Super_Header Child_Header Child_Child_Header
        Child_Body
        """
    }

    $0.it("can inherit from a template that calls a super block") {
      let template = try environment.loadTemplate(name: "child-super.html")
      try expect(try template.render()) == """
        Header
        Child_Body
        """
    }
  }
}
