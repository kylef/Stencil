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
      try expect(try template.render()) == "Super_Header Child_Header\nChild_Body\n"
    }

    $0.it("can inherit from another template inheriting from another template") {
      let template = try environment.loadTemplate(name: "child-child.html")
      try expect(try template.render()) == "Super_Header Child_Header Child_Child_Header\nChild_Body\n"
    }

    $0.it("can inherit from a template that calls a super block") {
      let template = try environment.loadTemplate(name: "child-super.html")
      try expect(try template.render()) == "Header\nChild_Body\n"
    }

    $0.it("can call block twice") {
      let template: Template = "{% block repeat %}Block{% endblock %}{{ block.repeat }}"
      try expect(try template.render()) == "BlockBlock"
    }

    $0.it("renders child content when calling block twice in base template") {
      let template = try environment.loadTemplate(name: "child-repeat.html")
      try expect(try template.render()) == "Super_Header Child_Header\nChild_Body\n" +
        "Repeat\n" +
      "Super_Header Child_Header\nChild_Body\n"
    }

  }
}
