import Spectre
@testable import Stencil
import XCTest

final class TemplateTests: XCTestCase {
  func testTemplate() {
    it("can render a template from a string") {
      let template = Template(templateString: "Hello World")
      let result = try template.render(object: ["name": "Kyle"])
      try expect(result) == "Hello World"
    }

    it("can render a template from a string literal") {
        let template: Template = "Hello World"
        let result = try template.render(object: ["name": "Kyle"])
        try expect(result) == "Hello World"
    }
  }
}
