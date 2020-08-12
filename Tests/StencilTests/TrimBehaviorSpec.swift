import Spectre
import Stencil
import XCTest

final class TrimBehaviorTests: XCTestCase {

  func testSmartTrimBehaviour() {

    let environment = Environment(trimBehavior: .smart)

    it("can remove newlines from blocks") {

      let templateString = """
            {% for item in items %}
              - {{item}}
            {% endfor %}
            text
            """

      let context = ["items": ["item 1", "item 2"]]

      let template = Template(templateString: templateString, environment: environment)
      let result = try template.render(context)

      let fixture = """
        - item 1
        - item 2
      text
      """

      try expect(result) == fixture
    }

    it("only removes a single newlines from blocks") {

      let templateString = """
            {% for item in items %}

              - {{item}}
            {% endfor %}
            text
            """

      let context = ["items": ["item 1", "item 2"]]

      let template = Template(templateString: templateString, environment: environment)
      let result = try template.render(context)

      let fixture = """

        - item 1

        - item 2
      text
      """

      try expect(result) == fixture
    }

    it("can remove newlines from blocks while keeping whitespace") {

      let templateString = """
          Items:
          {% for item in items %}
              - {{item}}
          {% endfor %}
      """

      let context = ["items": ["item 1", "item 2"]]

      let template = Template(templateString: templateString, environment: environment)
      let result = try template.render(context)

      let fixture = """
                    Items:
                        - item 1
                        - item 2

                """

      try expect(result) == fixture
    }

  }

  func testTrimSymbols() {

    it("Respects whitespace control symbols in for tags") {
      let template: Template = """
      {% for num in numbers -%}
          {{num}}
      {%- endfor %}
      """
      let result = try template.render([ "numbers": Array(1...9) ])
      try expect(result) == "123456789"
    }
    it("Respects whitespace control symbols in if tags") {
      let template: Template = """
      {% if value -%}
        {{text}}
      {%- endif %}
      """
      let result = try template.render([ "text": "hello", "value": true ])
      try expect(result) == "hello"
    }
  }

  func testTrimSymbolsOverridingEnvironment() {

    let environment = Environment(trimBehavior: .all)

    it("respects whitespace control symbols in if tags") {
      let templateString = """
        {% if value +%}
        {{text}}
      {%+ endif %}

      """
      let template = Template(templateString: templateString, environment: environment)
      let result = try template.render([ "text": "hello", "value": true ])
      try expect(result) == "\n  hello\n"
    }

    it("can customize blocks on same line as text") {

      let templateString = """
          Items:{% for item in items +%}
              - {{item}}
          {%- endfor %}
      """

      let context = ["items": ["item 1", "item 2"]]

      let template = Template(templateString: templateString, environment: environment)
      let result = try template.render(context)

      let fixture = """
                    Items:
                        - item 1
                        - item 2
                """

      try expect(result) == fixture
    }
  }
}
